import 'dart:async';
import 'package:customer/constant/constant.dart';
import 'package:customer/models/BannerModel.dart';
import 'package:customer/models/advertisement_model.dart';
import 'package:customer/models/coupon_model.dart';
import 'package:customer/models/favourite_model.dart';
import 'package:customer/models/story_model.dart';
import 'package:customer/models/tax_model.dart';
import 'package:customer/models/vendor_category_model.dart';
import 'package:customer/models/vendor_model.dart';
import 'package:customer/services/cart_provider.dart';
import 'package:customer/services/firestore_read_cache.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:customer/utils/preferences.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomeController extends GetxController {
  final CartProvider cartProvider = CartProvider();

  RxBool isLoading = true.obs;
  RxBool isListView = true.obs;
  RxBool isPopular = false.obs;
  RxString selectedOrderTypeValue = "Delivery".tr.obs;

  final Rx<PageController> pageController =
      PageController(viewportFraction: 0.877).obs;
  final Rx<PageController> pageBottomController =
      PageController(viewportFraction: 0.877).obs;
  final RxInt currentPage = 0.obs;
  final RxInt currentBottomPage = 0.obs;

  late TabController tabController;

  final RxList<VendorCategoryModel> vendorCategoryModel =
      <VendorCategoryModel>[].obs;
  final RxList<VendorModel> allNearestRestaurant = <VendorModel>[].obs;
  final RxList<VendorModel> newArrivalRestaurantList = <VendorModel>[].obs;
  final RxList<VendorModel> popularRestaurantList = <VendorModel>[].obs;
  final RxList<VendorModel> couponRestaurantList = <VendorModel>[].obs;
  final RxList<AdvertisementModel> advertisementList =
      <AdvertisementModel>[].obs;
  final RxList<CouponModel> couponList = <CouponModel>[].obs;
  final RxList<StoryModel> storyList = <StoryModel>[].obs;
  final RxList<BannerModel> bannerModel = <BannerModel>[].obs;
  final RxList<BannerModel> bannerBottomModel = <BannerModel>[].obs;
  final RxList<FavouriteModel> favouriteList = <FavouriteModel>[].obs;

  StreamSubscription? _cartSubscription;
  StreamSubscription? _restaurantSubscription;
  Timer? _geoDebounce;
  Set<String> _lastExtrasVendorIds = {};
  bool _bootStarted = false;

  @override
  void onInit() {
    super.onInit();
    if (!_bootStarted) {
      _bootStarted = true;
      getData();
    }
  }

  Future<void> getData() async {
    isLoading.value = true;
    selectedOrderTypeValue.value = Preferences.getString(
      Preferences.foodDeliveryType,
      defaultValue: "Delivery",
    );
    await Future.wait([
      getTaxList(),
      getVendorCategory(),
      getZone(),
      getCartData(),
    ]);

    // Fast first paint: one-shot zone query.
    final once = await FireStoreUtils.getNearestRestaurantsOnce(
      isDining: selectedOrderTypeValue.value != "Delivery",
    );
    _applyRestaurantList(once);
    isLoading.value = false;
    FireStoreUtils.ensureCustomerLiveSettingsAttached();

    // Soft live updates via geo stream (debounced).
    _listenForRestaurants();
  }

  Future<void> getTaxList() async {
    await FireStoreUtils.getTaxList().then(
      (value) {
        if (value != null) {
          Constant.taxProductList = value
              .where((TaxModel taxModel) => taxModel.scope == "product")
              .toList();
          Constant.orderProductTaxList = value
              .where((TaxModel taxModel) => taxModel.scope == "order")
              .toList();
          Constant.driverDeliveryTaxList = value
              .where((TaxModel taxModel) => taxModel.scope == "delivery")
              .toList();

          if (Constant.packagingChargeEnable == true) {
            Constant.packagingTaxList = value
                .where((TaxModel taxModel) => taxModel.scope == "packaging")
                .toList();
          }
          if (Constant.platformFeeModel?.enable == true) {
            Constant.platformTaxList = value
                .where((TaxModel taxModel) => taxModel.scope == "platform")
                .toList();
          }
        }
      },
    );
  }

  Future<void> getCartData() async {
    _cartSubscription?.cancel();
    _cartSubscription = cartProvider.cartStream.listen((event) {
      cartItem
        ..clear()
        ..addAll(event);
      update(['cart']);
    });
  }

  void _listenForRestaurants() {
    _restaurantSubscription?.cancel();
    _restaurantSubscription =
        FireStoreUtils.getAllNearestRestaurant().listen((restaurants) {
      _geoDebounce?.cancel();
      _geoDebounce = Timer(const Duration(milliseconds: 1500), () {
        if (restaurants.isEmpty) return;
        _applyRestaurantList(restaurants);
      });
    });
  }

  void _applyRestaurantList(List<VendorModel> restaurants) {
    if (restaurants.isEmpty) return;

    restaurants.sort((a, b) {
      final aOpen = Constant.statusCheckOpenORClose(vendorModel: a);
      final bOpen = Constant.statusCheckOpenORClose(vendorModel: b);
      if (aOpen == bOpen) {
        final ratingA = Constant.calculateReview(
          reviewCount: a.reviewsCount.toString(),
          reviewSum: a.reviewsSum.toString(),
        );
        final ratingB = Constant.calculateReview(
          reviewCount: b.reviewsCount.toString(),
          reviewSum: b.reviewsSum.toString(),
        );
        return ratingB.compareTo(ratingA);
      }
      return aOpen ? -1 : 1;
    });

    allNearestRestaurant.assignAll(restaurants);
    newArrivalRestaurantList.assignAll(restaurants);
    newArrivalRestaurantList.sort((a, b) {
      final aAt = a.createdAt?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bAt = b.createdAt?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bAt.compareTo(aAt);
    });
    popularRestaurantList.assignAll(restaurants.take(10));
    Constant.restaurantList = allNearestRestaurant;
    for (final vendor in restaurants) {
      FirestoreReadCache.putVendor(vendor);
    }

    final usedCategoryIds =
        restaurants.expand((v) => v.categoryID ?? []).toSet();
    vendorCategoryModel.retainWhere((cat) => usedCategoryIds.contains(cat.id));

    final ids = restaurants.map((r) => r.id ?? '').toSet();
    if (ids.length != _lastExtrasVendorIds.length ||
        !ids.containsAll(_lastExtrasVendorIds)) {
      _lastExtrasVendorIds = ids;
      // ignore: unawaited_futures
      _loadAdditionalData(restaurants);
    }
  }

  Future<void> _loadAdditionalData(List<VendorModel> restaurants) async {
    await Future.wait([
      _fetchCoupons(restaurants),
      _fetchStories(restaurants),
      if (Constant.isEnableAdsFeature) _fetchAds(restaurants),
    ]);
  }

  Future<void> _fetchCoupons(List<VendorModel> restaurants) async {
    final values = await FireStoreUtils.getHomeCoupon();
    final now = DateTime.now();

    couponList.clear();
    couponRestaurantList.clear();
    for (final c in values) {
      if (c.expiresAt!.toDate().isAfter(now)) {
        final match =
            restaurants.firstWhereOrNull((r) => r.id == c.resturantId);
        if (match != null) {
          couponList.add(c);
          couponRestaurantList.add(match);
        }
      }
    }
  }

  Future<void> _fetchStories(List<VendorModel> restaurants) async {
    final values = await FireStoreUtils.getStory();
    final vendorIds = restaurants.map((r) => r.id).toSet();
    storyList
        .assignAll(values.where((s) => vendorIds.contains(s.vendorID)).toList());
  }

  Future<void> _fetchAds(List<VendorModel> restaurants) async {
    final values = await FireStoreUtils.getAllAdvertisement();
    final vendorIds = restaurants.map((r) => r.id).toSet();
    advertisementList.assignAll(
      values.where((a) => vendorIds.contains(a.vendorId)).toList(),
    );
  }

  Future<void> getVendorCategory() async {
    final results = await Future.wait([
      FireStoreUtils.getHomeVendorCategory(),
      FireStoreUtils.getHomeTopBanner(),
      FireStoreUtils.getHomeBottomBanner(),
    ]);

    vendorCategoryModel.assignAll(results[0] as List<VendorCategoryModel>);
    bannerModel.assignAll(results[1] as List<BannerModel>);
    bannerBottomModel.assignAll(results[2] as List<BannerModel>);

    await getFavouriteRestaurant();
  }

  Future<void> getFavouriteRestaurant() async {
    if (Constant.userModel != null) {
      final favs = await FireStoreUtils.getFavouriteRestaurant();
      favouriteList.assignAll(favs);
    }
  }

  Future<void> getZone() async {
    final zones = await FireStoreUtils.getZone();
    if (zones == null || zones.isEmpty) return;

    final current = LatLng(
      Constant.selectedLocation.location?.latitude ?? 0.0,
      Constant.selectedLocation.location?.longitude ?? 0.0,
    );

    for (final zone in zones) {
      final inside = Constant.isPointInPolygon(current, zone.area!);
      Constant.selectedZone = zone;
      Constant.isZoneAvailable = inside;
      if (inside) break;
    }
  }

  @override
  void onClose() {
    // Keep permanent controller alive across tabs — only cancel when truly disposed.
    _geoDebounce?.cancel();
    _cartSubscription?.cancel();
    _restaurantSubscription?.cancel();
    // ignore: unawaited_futures
    FireStoreUtils.cancelNearestRestaurantListeners();
    super.onClose();
  }
}
