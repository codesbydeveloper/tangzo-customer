import 'dart:async';
import 'dart:convert';

import 'package:customer/firebase_options.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Feature flag — set false to force Firestore-only settings boot.
const bool kUseSettingsCache = true;

/// Full CF timeout (background / race loser).
const Duration kSettingsCfTimeout = Duration(seconds: 20);

/// Cap how long first-install race waits on CF before using Firestore.
const Duration kSettingsCfRaceTimeout = Duration(milliseconds: 2500);

/// Redis-backed settings boot bundle via Cloud Functions.
/// Prefs → race CF vs Firestore on miss → refresh applies in-session when newer.
class SettingsApi {
  SettingsApi._();

  static const _prefsKey = 'settings_bundle_customer_v2';
  static const _prefsVersionKey = 'settings_bundle_customer_version_v2';

  static Future<SettingsBundleResult?>? _prefetchFuture;
  static int? _appliedVersion;

  static Uri _callableUri(String functionName) {
    final projectId = DefaultFirebaseOptions.currentPlatform.projectId;
    return Uri.parse(
      'https://us-central1-$projectId.cloudfunctions.net/$functionName',
    );
  }

  /// Kick CF early from main() so cold-start race often wins.
  static void prefetch() {
    if (!kUseSettingsCache) return;
    _prefetchFuture ??= fetchFromCloudFunction().then((bundle) async {
      if (bundle != null) await writePrefs(bundle);
      return bundle;
    });
  }

  /// Instant prefs hit; null on miss (caller should race).
  static Future<SettingsBundleResult?> getBundle({
    bool forceRefresh = false,
  }) async {
    if (!kUseSettingsCache) return null;
    if (!forceRefresh) {
      final cached = await readPrefs();
      if (cached != null) return cached;
    }
    return null;
  }

  /// First-install: race CF (incl. prefetch) vs [firestoreLoader].
  static Future<SettingsBundleResult?> raceBundle({
    required Future<Map<String, Map<String, dynamic>?>> Function()
        firestoreLoader,
  }) async {
    if (!kUseSettingsCache) {
      final docs = await firestoreLoader();
      return SettingsBundleResult(
        docs: docs,
        version: DateTime.now().millisecondsSinceEpoch,
        source: 'firestore',
      );
    }

    final prefs = await readPrefs();
    if (prefs != null && prefs.docs.isNotEmpty) return prefs;

    prefetch();
    final cfFuture = (_prefetchFuture ?? fetchFromCloudFunction()).timeout(
      kSettingsCfRaceTimeout,
      onTimeout: () => null,
    );

    final fsFuture = firestoreLoader().then(
      (docs) => SettingsBundleResult(
        docs: docs,
        version: DateTime.now().millisecondsSinceEpoch,
        source: 'firestore',
      ),
    );

    final first = await Future.any<SettingsBundleResult?>([cfFuture, fsFuture]);
    if (first != null && first.docs.isNotEmpty) {
      await writePrefs(first);
      // Let the other path finish and keep prefs if CF returns later with real data.
      // ignore: unawaited_futures
      cfFuture.then((cf) async {
        if (cf != null && cf.docs.isNotEmpty) await writePrefs(cf);
      });
      return first;
    }

    final fallback = await fsFuture;
    await writePrefs(fallback);
    return fallback;
  }

  /// Background refresh; [onFresh] when server version is newer than applied.
  static Future<void> refreshInBackground({
    void Function(SettingsBundleResult bundle)? onFresh,
  }) async {
    if (!kUseSettingsCache) return;
    try {
      final bundle = await fetchFromCloudFunction();
      if (bundle == null) return;
      await writePrefs(bundle);
      final applied = _appliedVersion ?? 0;
      if (bundle.version > applied) {
        onFresh?.call(bundle);
      }
      if (kDebugMode) {
        debugPrint(
          '[SettingsApi] background CF refresh ok (${bundle.source}) v=${bundle.version}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[SettingsApi] background refresh failed: $e');
      }
    }
  }

  static void markApplied(SettingsBundleResult bundle) {
    _appliedVersion = bundle.version;
  }

  static Future<SettingsBundleResult?> fetchFromCloudFunction({
    bool forceRefresh = false,
  }) async {
    try {
      final response = await http
          .post(
            _callableUri('getSettingsBundle'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'data': {
                'app': 'customer',
                'forceRefresh': forceRefresh,
              },
            }),
          )
          .timeout(kSettingsCfTimeout);

      final decoded = jsonDecode(response.body);
      if (decoded is! Map || decoded['error'] != null) return null;
      if (response.statusCode != 200) return null;

      final result = decoded['result'];
      if (result is! Map || result['ok'] != true) return null;

      final docsRaw = result['docs'];
      final docs = <String, Map<String, dynamic>?>{};
      if (docsRaw is Map) {
        docsRaw.forEach((key, value) {
          if (value is Map) {
            docs[key.toString()] = Map<String, dynamic>.from(value);
          } else {
            docs[key.toString()] = null;
          }
        });
      }

      return SettingsBundleResult(
        docs: docs,
        version: result['version'] is int
            ? result['version'] as int
            : int.tryParse(result['version']?.toString() ?? '') ??
                DateTime.now().millisecondsSinceEpoch,
        source: result['source']?.toString() ?? 'unknown',
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[SettingsApi] CF fetch failed: $e');
      }
      return null;
    }
  }

  static Future<SettingsBundleResult?> readPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      final version = prefs.getInt(_prefsVersionKey);
      if (raw == null || version == null) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final docs = <String, Map<String, dynamic>?>{};
      decoded.forEach((key, value) {
        if (value is Map) {
          docs[key.toString()] = Map<String, dynamic>.from(value);
        } else {
          docs[key.toString()] = null;
        }
      });
      return SettingsBundleResult(
        docs: docs,
        version: version,
        source: 'prefs',
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> writePrefs(SettingsBundleResult bundle) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(bundle.docs));
      await prefs.setInt(_prefsVersionKey, bundle.version);
    } catch (_) {}
  }
}

class SettingsBundleResult {
  final Map<String, Map<String, dynamic>?> docs;
  final int version;
  final String source;

  const SettingsBundleResult({
    required this.docs,
    required this.version,
    required this.source,
  });

  Map<String, dynamic>? doc(String id) => docs[id];
}
