import 'package:flutter/foundation.dart';

/// Dev-only counters for menu/vendor Firestore cache behavior.
class FirestoreCacheMetrics {
  FirestoreCacheMetrics._();

  static int menuFetches = 0;
  static int menuCacheHits = 0;
  static int menuCacheMisses = 0;
  static int menuDedupedRequests = 0;
  static int vendorCacheHits = 0;
  static int vendorCacheMisses = 0;
  static int categoryCacheHits = 0;
  static int categoryCacheMisses = 0;
  static int attributesCacheHits = 0;
  static int attributesCacheMisses = 0;

  static void reset() {
    menuFetches = 0;
    menuCacheHits = 0;
    menuCacheMisses = 0;
    menuDedupedRequests = 0;
    vendorCacheHits = 0;
    vendorCacheMisses = 0;
    categoryCacheHits = 0;
    categoryCacheMisses = 0;
    attributesCacheHits = 0;
    attributesCacheMisses = 0;
  }

  static void log(String event, {Map<String, Object?>? data}) {
    if (!kDebugMode) return;
    final extras = data == null || data.isEmpty
        ? ''
        : ' ${data.entries.map((e) => '${e.key}=${e.value}').join(' ')}';
    debugPrint(
      '[FirestoreCache] $event$extras | '
      'menuHits=$menuCacheHits menuMisses=$menuCacheMisses '
      'menuFetches=$menuFetches deduped=$menuDedupedRequests '
      'vendorHits=$vendorCacheHits catHits=$categoryCacheHits '
      'attrHits=$attributesCacheHits',
    );
  }

  static String snapshot() {
    return 'menuHits=$menuCacheHits menuMisses=$menuCacheMisses '
        'menuFetches=$menuFetches deduped=$menuDedupedRequests '
        'vendorHits=$vendorCacheHits vendorMisses=$vendorCacheMisses '
        'catHits=$categoryCacheHits catMisses=$categoryCacheMisses '
        'attrHits=$attributesCacheHits attrMisses=$attributesCacheMisses';
  }
}
