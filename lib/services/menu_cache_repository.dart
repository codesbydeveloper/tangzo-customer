import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer/constant/collection_name.dart';
import 'package:customer/models/product_model.dart';
import 'package:customer/services/firestore_cache_metrics.dart';
import 'package:customer/services/menu_api.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Multi-level restaurant menu cache:
/// UI → Memory → Device disk → Redis (shared via Cloud Function) → Firestore
///
/// Device cache is free (no Firestore billing). Redis is the shared layer so
/// many users share one Firestore fill. Direct Firestore is only a fallback.
///
/// Includes in-flight request deduplication so concurrent callers share one Future.
class MenuCacheRepository {
  MenuCacheRepository._();

  static final MenuCacheRepository instance = MenuCacheRepository._();

  /// Soft TTL when [menuVersion] is unavailable on the vendor document.
  static const Duration cacheTtl = Duration(minutes: 20);

  final Map<String, _CachedMenu> _memoryCache = {};
  final Map<String, Future<List<ProductModel>>> _inFlight = {};

  Directory? _cacheDir;

  Future<Directory> _dir() async {
    if (_cacheDir != null) return _cacheDir!;
    final base = await getApplicationDocumentsDirectory();
    _cacheDir = Directory('${base.path}/menu_cache');
    if (!await _cacheDir!.exists()) {
      await _cacheDir!.create(recursive: true);
    }
    return _cacheDir!;
  }

  String _filePath(String vendorId) =>
      '${_cacheDir?.path ?? ''}/menu_$vendorId.json';

  /// Returns published menu products for [vendorId].
  ///
  /// [menuVersion] comes from the already-loaded vendor document (no extra read).
  /// When it matches the cache, Firestore is skipped.
  Future<List<ProductModel>> getMenu(
    String vendorId, {
    int? menuVersion,
    bool forceRefresh = false,
  }) {
    if (vendorId.isEmpty) {
      return Future.value(const <ProductModel>[]);
    }

    if (!forceRefresh) {
      final memory = _memoryCache[vendorId];
      if (memory != null && memory.isValid(menuVersion: menuVersion)) {
        FirestoreCacheMetrics.menuCacheHits++;
        FirestoreCacheMetrics.log('memory_hit', data: {
          'vendorId': vendorId,
          'items': memory.products.length,
          'menuVersion': memory.menuVersion,
        });
        return Future.value(List<ProductModel>.from(memory.products));
      }
    }

    final existing = _inFlight[vendorId];
    if (existing != null) {
      FirestoreCacheMetrics.menuDedupedRequests++;
      FirestoreCacheMetrics.log('deduped', data: {'vendorId': vendorId});
      return existing;
    }

    final future = _loadMenu(
      vendorId,
      menuVersion: menuVersion,
      forceRefresh: forceRefresh,
    );
    _inFlight[vendorId] = future;
    return future.whenComplete(() => _inFlight.remove(vendorId));
  }

  Future<List<ProductModel>> _loadMenu(
    String vendorId, {
    int? menuVersion,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final disk = await _readPersistent(vendorId);
      if (disk != null && disk.isValid(menuVersion: menuVersion)) {
        _memoryCache[vendorId] = disk;
        FirestoreCacheMetrics.menuCacheHits++;
        FirestoreCacheMetrics.log('disk_hit', data: {
          'vendorId': vendorId,
          'items': disk.products.length,
          'menuVersion': disk.menuVersion,
        });
        return List<ProductModel>.from(disk.products);
      }
    }

    FirestoreCacheMetrics.menuCacheMisses++;
    FirestoreCacheMetrics.menuFetches++;
    FirestoreCacheMetrics.log('shared_fetch', data: {
      'vendorId': vendorId,
      'forceRefresh': forceRefresh,
      'menuVersion': menuVersion,
    });

    final fetched = await fetchProductsShared(
      vendorId,
      forceRefresh: forceRefresh,
    );
    final cached = _CachedMenu(
      vendorId: vendorId,
      products: fetched.products,
      cachedAt: DateTime.now(),
      menuVersion: fetched.menuVersion ?? menuVersion,
    );
    _memoryCache[vendorId] = cached;
    await _writePersistent(cached);
    return List<ProductModel>.from(fetched.products);
  }

  /// Prefer Redis-backed Cloud Function; fall back to direct Firestore only if
  /// the function is unreachable so the app still works.
  static Future<({List<ProductModel> products, int? menuVersion})>
      fetchProductsShared(
    String vendorId, {
    bool forceRefresh = false,
  }) async {
    final api = await MenuApi.getVendorMenu(
      vendorId: vendorId,
      forceRefresh: forceRefresh,
    );
    if (api != null) {
      FirestoreCacheMetrics.log('redis_api_${api.source}', data: {
        'vendorId': vendorId,
        'items': api.products.length,
        'menuVersion': api.menuVersion,
      });
      final products = api.products
          .map((raw) => ProductModel.fromJson(
                MenuCacheRepository._deserializeProductMap(raw),
              ))
          .toList();
      return (products: products, menuVersion: api.menuVersion);
    }

    FirestoreCacheMetrics.log('firestore_fallback', data: {
      'vendorId': vendorId,
    });
    final products = await fetchProductsFromFirestore(vendorId);
    return (products: products, menuVersion: null);
  }

  /// Raw one-shot Firestore query (fallback only — avoid for shared traffic).
  static Future<List<ProductModel>> fetchProductsFromFirestore(
      String vendorId) async {
    final list = <ProductModel>[];
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(CollectionName.vendorProducts)
          .where('vendorID', isEqualTo: vendorId)
          .where('publish', isEqualTo: true)
          .orderBy('createdAt', descending: false)
          .get();
      for (final doc in snapshot.docs) {
        list.add(ProductModel.fromJson(doc.data()));
      }
    } catch (e, s) {
      if (kDebugMode) {
        debugPrint('[MenuCacheRepository] fetch failed: $e\n$s');
      }
    }
    return list;
  }

  Future<_CachedMenu?> _readPersistent(String vendorId) async {
    try {
      await _dir();
      final file = File(_filePath(vendorId));
      if (!await file.exists()) return null;
      final raw = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final productsJson = (raw['products'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      final products = productsJson
          .map((e) => ProductModel.fromJson(_deserializeProductMap(e)))
          .toList();
      return _CachedMenu(
        vendorId: vendorId,
        products: products,
        cachedAt: DateTime.tryParse(raw['cachedAt']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        menuVersion: raw['menuVersion'] is int
            ? raw['menuVersion'] as int
            : int.tryParse(raw['menuVersion']?.toString() ?? ''),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[MenuCacheRepository] disk read failed: $e');
      }
      return null;
    }
  }

  Future<void> _writePersistent(_CachedMenu cached) async {
    try {
      await _dir();
      final file = File(_filePath(cached.vendorId));
      final payload = <String, dynamic>{
        'vendorId': cached.vendorId,
        'cachedAt': cached.cachedAt.toIso8601String(),
        'menuVersion': cached.menuVersion,
        'products':
            cached.products.map((p) => _serializeProductMap(p.toJson())).toList(),
      };
      await file.writeAsString(jsonEncode(payload));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[MenuCacheRepository] disk write failed: $e');
      }
    }
  }

  /// Invalidate one restaurant menu (e.g. after forced pull-to-refresh).
  Future<void> invalidate(String vendorId) async {
    _memoryCache.remove(vendorId);
    try {
      await _dir();
      final file = File(_filePath(vendorId));
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
    FirestoreCacheMetrics.log('invalidate', data: {'vendorId': vendorId});
  }

  void clearMemory() {
    _memoryCache.clear();
  }

  static Map<String, dynamic> _serializeProductMap(Map<String, dynamic> map) {
    final out = <String, dynamic>{};
    map.forEach((key, value) {
      out[key] = _encodeValue(value);
    });
    return out;
  }

  static Map<String, dynamic> _deserializeProductMap(Map<String, dynamic> map) {
    final out = <String, dynamic>{};
    map.forEach((key, value) {
      out[key] = _decodeValue(value);
    });
    return out;
  }

  static dynamic _encodeValue(dynamic value) {
    if (value is Timestamp) {
      return <String, dynamic>{
        '__type': 'timestamp',
        'seconds': value.seconds,
        'nanoseconds': value.nanoseconds,
      };
    }
    if (value is DateTime) {
      return <String, dynamic>{
        '__type': 'datetime',
        'iso': value.toIso8601String(),
      };
    }
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), _encodeValue(v)));
    }
    if (value is List) {
      return value.map(_encodeValue).toList();
    }
    return value;
  }

  static dynamic _decodeValue(dynamic value) {
    if (value is Map) {
      final type = value['__type'];
      if (type == 'timestamp') {
        return Timestamp(
          value['seconds'] as int? ?? 0,
          value['nanoseconds'] as int? ?? 0,
        );
      }
      if (type == 'datetime') {
        return Timestamp.fromDate(
            DateTime.tryParse(value['iso']?.toString() ?? '') ?? DateTime.now());
      }
      return value.map((k, v) => MapEntry(k.toString(), _decodeValue(v)));
    }
    if (value is List) {
      return value.map(_decodeValue).toList();
    }
    return value;
  }
}

class _CachedMenu {
  _CachedMenu({
    required this.vendorId,
    required this.products,
    required this.cachedAt,
    this.menuVersion,
  });

  final String vendorId;
  final List<ProductModel> products;
  final DateTime cachedAt;
  final int? menuVersion;

  bool isValid({int? menuVersion}) {
    if (menuVersion != null) {
      // Vendor doc already carried the version — no extra Firestore read.
      if (this.menuVersion != null) {
        return this.menuVersion == menuVersion;
      }
      // Cache predates versioning: treat as stale so we refresh once.
      return false;
    }
    return DateTime.now().difference(cachedAt) < MenuCacheRepository.cacheTtl;
  }
}
