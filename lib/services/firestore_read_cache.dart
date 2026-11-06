import 'package:customer/models/AttributesModel.dart';
import 'package:customer/models/BannerModel.dart';
import 'package:customer/models/vendor_category_model.dart';
import 'package:customer/models/vendor_model.dart';
import 'package:customer/models/zone_model.dart';
import 'package:customer/services/firestore_cache_metrics.dart';
import 'package:customer/utils/fire_store_utils.dart';

/// Session-level memory caches for frequently re-read static/semi-static docs.
/// Prevents FutureBuilder rebuild storms from re-hitting Firestore.
class FirestoreReadCache {
  FirestoreReadCache._();

  static final Map<String, VendorModel> _vendors = {};
  static final Map<String, Future<VendorModel?>> _vendorInFlight = {};

  static final Map<String, VendorCategoryModel> _categories = {};
  static final Map<String, Future<VendorCategoryModel?>> _categoryInFlight = {};

  static List<VendorCategoryModel>? _allPublishedCategories;
  static Future<List<VendorCategoryModel>>? _allCategoriesInFlight;

  static List<AttributesModel>? _attributes;
  static Future<List<AttributesModel>?>? _attributesInFlight;

  static List<ZoneModel>? _zones;
  static List<VendorCategoryModel>? _homeCategories;
  static List<BannerModel>? _topBanners;
  static List<BannerModel>? _middleBanners;

  static const Duration vendorTtl = Duration(minutes: 10);
  static final Map<String, DateTime> _vendorCachedAt = {};

  static Future<VendorModel?> getVendorById(String vendorId) {
    if (vendorId.isEmpty) return Future.value(null);

    final cached = _vendors[vendorId];
    final cachedAt = _vendorCachedAt[vendorId];
    if (cached != null &&
        cachedAt != null &&
        DateTime.now().difference(cachedAt) < vendorTtl) {
      FirestoreCacheMetrics.vendorCacheHits++;
      FirestoreCacheMetrics.log('vendor_memory_hit', data: {'id': vendorId});
      return Future.value(cached);
    }

    final inflight = _vendorInFlight[vendorId];
    if (inflight != null) {
      FirestoreCacheMetrics.menuDedupedRequests++;
      return inflight;
    }

    final future = FireStoreUtils.fetchVendorByIdRaw(vendorId).then((vendor) {
      if (vendor != null) {
        _vendors[vendorId] = vendor;
        _vendorCachedAt[vendorId] = DateTime.now();
      }
      return vendor;
    });
    _vendorInFlight[vendorId] = future;
    FirestoreCacheMetrics.vendorCacheMisses++;
    return future.whenComplete(() => _vendorInFlight.remove(vendorId));
  }

  static void putVendor(VendorModel vendor) {
    if (vendor.id == null || vendor.id!.isEmpty) return;
    _vendors[vendor.id!] = vendor;
    _vendorCachedAt[vendor.id!] = DateTime.now();
  }

  static Future<VendorCategoryModel?> getCategoryById(String categoryId) {
    if (categoryId.isEmpty) return Future.value(null);

    final cached = _categories[categoryId];
    if (cached != null) {
      FirestoreCacheMetrics.categoryCacheHits++;
      return Future.value(cached);
    }

    final inflight = _categoryInFlight[categoryId];
    if (inflight != null) return inflight;

    final future =
        FireStoreUtils.fetchVendorCategoryByIdRaw(categoryId).then((cat) {
      if (cat != null) {
        _categories[categoryId] = cat;
      }
      return cat;
    });
    _categoryInFlight[categoryId] = future;
    FirestoreCacheMetrics.categoryCacheMisses++;
    return future.whenComplete(() => _categoryInFlight.remove(categoryId));
  }

  /// One full published-categories fetch per session, then local lookups.
  static Future<List<VendorCategoryModel>> getAllPublishedCategories() {
    if (_allPublishedCategories != null) {
      FirestoreCacheMetrics.categoryCacheHits++;
      return Future.value(_allPublishedCategories!);
    }
    if (_allCategoriesInFlight != null) {
      return _allCategoriesInFlight!;
    }
    FirestoreCacheMetrics.categoryCacheMisses++;
    _allCategoriesInFlight = FireStoreUtils.getVendorCategory().then((list) {
      _allPublishedCategories = list;
      for (final cat in list) {
        if (cat.id != null) {
          _categories[cat.id!] = cat;
        }
      }
      return list;
    }).whenComplete(() => _allCategoriesInFlight = null);
    return _allCategoriesInFlight!;
  }

  static Future<List<AttributesModel>?> getAttributes() {
    if (_attributes != null) {
      FirestoreCacheMetrics.attributesCacheHits++;
      FirestoreCacheMetrics.log('attributes_memory_hit');
      return Future.value(_attributes);
    }
    if (_attributesInFlight != null) {
      return _attributesInFlight!;
    }
    FirestoreCacheMetrics.attributesCacheMisses++;
    _attributesInFlight = FireStoreUtils.fetchAttributesRaw().then((list) {
      _attributes = list;
      return list;
    }).whenComplete(() => _attributesInFlight = null);
    return _attributesInFlight!;
  }

  static void putAttributes(List<AttributesModel>? list) {
    _attributes = list;
  }

  static Future<List<ZoneModel>?> getZones() async {
    if (_zones != null) {
      FirestoreCacheMetrics.categoryCacheHits++;
      return _zones;
    }
    return null;
  }

  static void putZones(List<ZoneModel> zones) {
    _zones = zones;
  }

  static Future<List<VendorCategoryModel>?> getHomeCategories() async {
    if (_homeCategories != null) {
      FirestoreCacheMetrics.categoryCacheHits++;
      return _homeCategories;
    }
    return null;
  }

  static void putHomeCategories(List<VendorCategoryModel> list) {
    _homeCategories = list;
  }

  static Future<List<BannerModel>?> getTopBanners() async {
    if (_topBanners != null) return _topBanners;
    return null;
  }

  static void putTopBanners(List<BannerModel> list) {
    _topBanners = list;
  }

  static Future<List<BannerModel>?> getMiddleBanners() async {
    if (_middleBanners != null) return _middleBanners;
    return null;
  }

  static void putMiddleBanners(List<BannerModel> list) {
    _middleBanners = list;
  }

  static void clear() {
    _vendors.clear();
    _vendorCachedAt.clear();
    _categories.clear();
    _allPublishedCategories = null;
    _attributes = null;
    _zones = null;
    _homeCategories = null;
    _topBanners = null;
    _middleBanners = null;
  }
}
