import 'dart:convert';

import 'package:customer/firebase_options.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Shared Redis-backed menu API (Cloud Functions).
/// Never talks to Redis directly — one Firestore fill serves many users.
class MenuApi {
  MenuApi._();

  static Uri _callableUri(String functionName) {
    final projectId = DefaultFirebaseOptions.currentPlatform.projectId;
    return Uri.parse(
      'https://us-central1-$projectId.cloudfunctions.net/$functionName',
    );
  }

  /// Returns published products + optional menuVersion from Redis/Firestore.
  /// Null means the function call failed (caller may fall back to Firestore).
  static Future<MenuApiResult?> getVendorMenu({
    required String vendorId,
    bool forceRefresh = false,
  }) async {
    if (vendorId.isEmpty) {
      return MenuApiResult(
        vendorId: vendorId,
        products: const [],
        menuVersion: null,
        source: 'empty',
      );
    }

    try {
      final response = await http
          .post(
            _callableUri('getVendorMenu'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'data': {
                'vendorId': vendorId,
                'forceRefresh': forceRefresh,
              },
            }),
          )
          .timeout(const Duration(seconds: 8));

      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['error'] != null) {
        if (kDebugMode) {
          debugPrint('[MenuApi] callable error: ${decoded['error']}');
        }
        return null;
      }
      if (response.statusCode != 200) {
        if (kDebugMode) {
          debugPrint(
              '[MenuApi] HTTP ${response.statusCode}: ${response.body}');
        }
        return null;
      }

      final result = decoded is Map ? decoded['result'] : null;
      if (result is! Map || result['ok'] != true) {
        return null;
      }

      final productsRaw = result['products'];
      final products = <Map<String, dynamic>>[];
      if (productsRaw is List) {
        for (final item in productsRaw) {
          if (item is Map) {
            products.add(Map<String, dynamic>.from(item));
          }
        }
      }

      final versionRaw = result['menuVersion'];
      final menuVersion = versionRaw is int
          ? versionRaw
          : int.tryParse(versionRaw?.toString() ?? '');

      return MenuApiResult(
        vendorId: result['vendorId']?.toString() ?? vendorId,
        products: products,
        menuVersion: menuVersion,
        source: result['source']?.toString() ?? 'unknown',
      );
    } catch (e, s) {
      if (kDebugMode) {
        debugPrint('[MenuApi] getVendorMenu failed: $e\n$s');
      }
      return null;
    }
  }
}

class MenuApiResult {
  final String vendorId;
  final List<Map<String, dynamic>> products;
  final int? menuVersion;
  final String source;

  const MenuApiResult({
    required this.vendorId,
    required this.products,
    required this.menuVersion,
    required this.source,
  });
}
