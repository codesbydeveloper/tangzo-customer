import 'dart:convert';

import 'package:customer/firebase_options.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Feature flag — set false to force Firestore-only catalog reads.
const bool kUseCatalogCache = true;

/// Background / warm-path timeout. Cold starts + India↔us-central1 often exceed 4s.
const Duration kCatalogCfTimeout = Duration(seconds: 20);

/// Short wait when racing CF on cold miss (boot path).
const Duration kCatalogCfRaceTimeout = Duration(milliseconds: 2500);

/// Skip further CF attempts after a timeout/failure for a short window.
const Duration kCatalogCircuitCooldown = Duration(minutes: 2);

class CatalogApi {
  CatalogApi._();

  static DateTime? _circuitOpenUntil;
  static final Set<String> _inFlightWarm = <String>{};

  static String _diskKey(String family) => 'catalog_family_${family}_v1';

  static Uri _callableUri(String functionName) {
    final projectId = DefaultFirebaseOptions.currentPlatform.projectId;
    return Uri.parse(
      'https://us-central1-$projectId.cloudfunctions.net/$functionName',
    );
  }

  static bool get _circuitOpen =>
      _circuitOpenUntil != null && DateTime.now().isBefore(_circuitOpenUntil!);

  static void _tripCircuit() {
    _circuitOpenUntil = DateTime.now().add(kCatalogCircuitCooldown);
  }

  /// Disk → CF (short) → null. Caller falls back to Firestore on null.
  static Future<List<Map<String, dynamic>>?> getFamilyPreferCache(
    String family,
  ) async {
    if (!kUseCatalogCache) return null;
    final disk = await readDisk(family);
    if (disk != null) return disk;
    if (_circuitOpen) return null;
    final cf = await getFamily(family).timeout(
      kCatalogCfRaceTimeout,
      onTimeout: () => null,
    );
    if (cf != null) {
      await writeDisk(family, cf);
      return cf;
    }
    return null;
  }

  /// Families: categories, categories_home, attributes, zones, tax,
  /// banners_top, banners_middle, currencies
  static Future<List<Map<String, dynamic>>?> getFamily(
    String family, {
    bool forceRefresh = false,
  }) async {
    if (!kUseCatalogCache) return null;
    if (!forceRefresh && _circuitOpen) return null;

    try {
      final response = await http
          .post(
            _callableUri('getCatalog'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'data': {
                'family': family,
                'forceRefresh': forceRefresh,
              },
            }),
          )
          .timeout(kCatalogCfTimeout);

      final decoded = jsonDecode(response.body);
      if (decoded is! Map || decoded['error'] != null) {
        if (kDebugMode) {
          debugPrint(
            '[CatalogApi] error: ${decoded is Map ? decoded['error'] : response.body}',
          );
        }
        return null;
      }
      if (response.statusCode != 200) return null;
      final result = decoded['result'];
      if (result is! Map || result['ok'] != true) return null;
      final itemsRaw = result['items'];
      if (itemsRaw is! List) return const [];
      final items = <Map<String, dynamic>>[];
      for (final item in itemsRaw) {
        if (item is Map) {
          items.add(Map<String, dynamic>.from(item));
        }
      }
      await writeDisk(family, items);
      return items;
    } catch (e, s) {
      _tripCircuit();
      if (kDebugMode) {
        debugPrint('[CatalogApi] getFamily($family) failed: $e\n$s');
      }
      return null;
    }
  }

  /// Fire-and-forget CF warm → disk + optional callback.
  static void warmFamilyInBackground(
    String family, {
    void Function(List<Map<String, dynamic>> items)? onSuccess,
  }) {
    if (!kUseCatalogCache || _circuitOpen) return;
    if (!_inFlightWarm.add(family)) return;
    () async {
      try {
        final items = await getFamily(family);
        if (items != null) onSuccess?.call(items);
      } finally {
        _inFlightWarm.remove(family);
      }
    }();
  }

  static Future<List<Map<String, dynamic>>?> readDisk(String family) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_diskKey(family));
      if (raw == null) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! List) return null;
      final items = <Map<String, dynamic>>[];
      for (final item in decoded) {
        if (item is Map) items.add(Map<String, dynamic>.from(item));
      }
      return items;
    } catch (_) {
      return null;
    }
  }

  static Future<void> writeDisk(
    String family,
    List<Map<String, dynamic>> items,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_diskKey(family), jsonEncode(items));
    } catch (_) {}
  }
}
