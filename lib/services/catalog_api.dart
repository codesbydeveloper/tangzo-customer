import 'dart:convert';

import 'package:customer/firebase_options.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Feature flag — set false to force Firestore-only catalog reads.
const bool kUseCatalogCache = true;

/// Background / warm-path timeout. Cold starts + India↔us-central1 often exceed 4s.
const Duration kCatalogCfTimeout = Duration(seconds: 20);

/// Skip further CF attempts after a timeout/failure for a short window.
const Duration kCatalogCircuitCooldown = Duration(minutes: 2);

class CatalogApi {
  CatalogApi._();

  static DateTime? _circuitOpenUntil;
  static final Set<String> _inFlightWarm = <String>{};

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

  /// Families: categories, categories_home, attributes, zones, tax,
  /// banners_top, banners_middle, currencies
  ///
  /// Returns null quickly when cache flag is off or circuit is open so callers
  /// can use Firestore without waiting on CF cold starts.
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
      return items;
    } catch (e, s) {
      _tripCircuit();
      if (kDebugMode) {
        debugPrint('[CatalogApi] getFamily($family) failed: $e\n$s');
      }
      return null;
    }
  }

  /// Fire-and-forget CF warm. Never await on UI / boot paths.
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
}
