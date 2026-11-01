import 'dart:async';
import 'dart:developer';
import 'package:customer/constant/constant.dart';
import 'package:customer/models/AttributesModel.dart';
import 'package:customer/models/cart_product_model.dart';
import 'package:customer/models/coupon_model.dart';
import 'package:customer/models/favourite_item_model.dart';
import 'package:customer/models/favourite_model.dart';
import 'package:customer/models/product_model.dart';
import 'package:customer/models/vendor_category_model.dart';
import 'package:customer/models/vendor_model.dart';
import 'package:customer/services/cart_provider.dart';
import 'package:customer/services/firestore_cache_metrics.dart';
import 'package:customer/services/firestore_read_cache.dart';
import 'package:customer/services/menu_cache_repository.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:intl/intl.dart';

class RestaurantDetailsController extends GetxController {
  Rx<TextEditingController> searchEditingController = TextEditingController().obs;

  RxBool isLoading = true.obs;
  Rx<PageController> pageController = PageController().obs;
  RxInt currentPage = 0.obs;

  RxBool isVag = false.obs;
  RxBool isNonVag = false.obs;
  RxBool isMenuOpen = false.obs;

  RxList<FavouriteModel> favouriteList = <FavouriteModel>[].obs;
  RxList<FavouriteItemModel> favouriteItemList = <FavouriteItemModel>[].obs;
  RxList<ProductModel> allProductList = <ProductModel>[].obs;
  RxList<ProductModel> productList = <ProductModel>[].obs;
  RxList<VendorCategoryModel> vendorCategoryList = <VendorCategoryModel>[].obs;

  RxList<CouponModel> couponList = <CouponModel>[].obs;

  StreamSubscription? _cartSubscription;
  bool _productsLoaded = false;

  @override
  void onInit() {
    getArgument();
    super.onInit();
  }

  @override
  void onClose() {
    _cartSubscription?.cancel();
    super.onClose();
  }

  void animateSlider() {
    if (vendorModel.value.photos != null && vendorModel.value.photos!.isNotEmpty) {
      Timer.periodic(const Duration(seconds: 2), (Timer timer) {
        if (currentPage < vendorModel.value.photos!.length - 1) {
          currentPage++;
        } else {
          currentPage.value = 0;
        }

        if (pageController.value.hasClients) {
          pageController.value.animateToPage(
            currentPage.value,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeIn,
          );
        }
      });
    }
  }

  Rx<VendorModel> vendorModel = VendorModel().obs;

  final CartProvider cartProvider = CartProvider();

  Future<void> getArgument() async {
    _cartSubscription?.cancel();
    _cartSubscription = cartProvider.cartStream.listen(
      (event) async {
        cartItem.clear();
        cartItem.addAll(event);
      },
    );
    await syncFromArguments(force: true);
  }

  /// Safe to call when the screen is reused (GetX autoRemove: false).
  /// Reloads only when the vendor changes or [force] is true.
  Future<void> syncFromArguments({bool force = false}) async {
    dynamic argumentData = Get.arguments;
    if (argumentData == null || argumentData['vendorModel'] == null) return;

    final incoming = argumentData['vendorModel'] as VendorModel;
    final sameVendor = vendorModel.value.id == incoming.id && _productsLoaded;
    if (sameVendor && !force) {
      return;
    }

    isLoading.value = true;
    vendorModel.value = incoming;
    FirestoreReadCache.putVendor(vendorModel.value);
    allProductList.clear();
    productList.clear();
    vendorCategoryList.clear();
    _productsLoaded = false;

    animateSlider();
    statusCheck();

    await getProduct();

    isLoading.value = false;
    await getFavouriteList();
    update();
  }

  Future<void> getProduct({bool forceRefresh = false}) async {
    // Guard against duplicate concurrent loads from rebuilds / re-entry.
    if (_productsLoaded && !forceRefresh && productList.isNotEmpty) {
      return;
    }

    final vendorId = vendorModel.value.id.toString();
    final value = await FireStoreUtils.getProductByVendorId(
      vendorId,
      menuVersion: vendorModel.value.menuVersion,
      forceRefresh: forceRefresh,
    );

    if ((Constant.isSubscriptionModelApplied == true || Constant.adminCommission?.isEnabled == true) &&
        vendorModel.value.subscriptionPlan != null) {
      if (vendorModel.value.subscriptionPlan?.itemLimit == '-1') {
        allProductList.value = value;
        productList.value = value;
      } else {
        int selectedProduct = value.length <
                int.parse(vendorModel.value.subscriptionPlan?.itemLimit ?? '0')
            ? (value.isEmpty ? 0 : (value.length))
            : int.parse(vendorModel.value.subscriptionPlan?.itemLimit ?? '0');
        allProductList.value = value.sublist(0, selectedProduct);
        productList.value = value.sublist(0, selectedProduct);
      }
    } else {
      allProductList.value = value;
      productList.value = value;
    }

    await _loadCategoriesForProducts();
    _productsLoaded = true;

    if (kDebugMode) {
      FirestoreCacheMetrics.log('restaurant_menu_ready', data: {
        'vendorId': vendorId,
        'products': productList.length,
        'categories': vendorCategoryList.length,
      });
    }
  }

  /// Unique category IDs only — avoids N+1 reads (one per product).
  Future<void> _loadCategoriesForProducts() async {
    vendorCategoryList.clear();
    final uniqueIds = productList
        .map((e) => e.categoryID)
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet();

    if (uniqueIds.isEmpty) return;

    // Prefer session category cache (single published-categories fetch).
    final allCats = await FirestoreReadCache.getAllPublishedCategories();
    final byId = {for (final c in allCats) if (c.id != null) c.id!: c};

    final resolved = <VendorCategoryModel>[];
    for (final id in uniqueIds) {
      final fromAll = byId[id];
      if (fromAll != null) {
        resolved.add(fromAll);
        continue;
      }
      final single = await FireStoreUtils.getVendorCategoryById(id);
      if (single != null) {
        resolved.add(single);
      }
    }
    vendorCategoryList.assignAll(resolved);
  }

  /// Pull-to-refresh / manual reload bypasses TTL and version cache.
  Future<void> refreshMenu() async {
    final vendorId = vendorModel.value.id.toString();
    await MenuCacheRepository.instance.invalidate(vendorId);
    // Refresh vendor doc so menuVersion stays accurate after restaurant edits.
    final freshVendor = await FireStoreUtils.fetchVendorByIdRaw(vendorId);
    if (freshVendor != null) {
      vendorModel.value = freshVendor;
      FirestoreReadCache.putVendor(freshVendor);
    }
    _productsLoaded = false;
    await getProduct(forceRefresh: true);
    update();
  }

  void searchProduct(String name) {
    if (name.isEmpty) {
      productList.clear();
      productList.addAll(allProductList);
    } else {
      isVag.value = false;
      isNonVag.value = false;
      productList.value = allProductList.where((p0) => p0.name!.toLowerCase().contains(name.toLowerCase())).toList();
    }
    update();
  }

  void filterRecord() {
    if (isVag.value == true && isNonVag.value == true) {
      productList.value = allProductList.where((p0) => p0.nonveg == true || p0.nonveg == false).toList();
    } else if (isVag.value == true && isNonVag.value == false) {
      productList.value = allProductList.where((p0) => p0.nonveg == false).toList();
    } else if (isVag.value == false && isNonVag.value == true) {
      productList.value = allProductList.where((p0) => p0.nonveg == true).toList();
    } else if (isVag.value == false && isNonVag.value == false) {
      productList.value = allProductList.where((p0) => p0.nonveg == true || p0.nonveg == false).toList();
    }
  }

  Future<List<ProductModel>> getProductByCategory(VendorCategoryModel vendorCategoryModel) async {
    return productList.where((p0) => p0.categoryID == vendorCategoryModel.id).toList();
  }

  Future<void> getFavouriteList() async {
    if (Constant.userModel != null) {
      await FireStoreUtils.getFavouriteRestaurant().then(
        (value) {
          favouriteList.value = value;
        },
      );

      await FireStoreUtils.getFavouriteItem().then(
        (value) {
          favouriteItemList.value = value;
        },
      );

      await FireStoreUtils.getOfferByVendorId(vendorModel.value.id.toString()).then(
        (value) {
          couponList.value = value;
        },
      );
    }
    await getAttributeData();
    update();
  }

  RxBool isOpen = false.obs;

  void statusCheck() {
    final now = DateTime.now();
    var day = DateFormat('EEEE', 'en_US').format(now);
    var date = DateFormat('dd-MM-yyyy').format(now);
    for (var element in vendorModel.value.workingHours ?? []) {
      if (day == element.day.toString()) {
        if (element.timeslot!.isNotEmpty) {
          for (var element in element.timeslot!) {
            var start = DateFormat("dd-MM-yyyy HH:mm").parse("$date ${element.from}");
            var end = DateFormat("dd-MM-yyyy HH:mm").parse("$date ${element.to}");
            if (isCurrentDateInRange(start, end)) {
              isOpen.value = true;
            }
          }
        }
      }
    }
  }

  bool isCurrentDateInRange(DateTime startDate, DateTime endDate) {
    print(startDate);
    print(endDate);
    final currentDate = DateTime.now();
    print(currentDate);
    return currentDate.isAfter(startDate) && currentDate.isBefore(endDate);
  }

  RxList<AttributesModel> attributesList = <AttributesModel>[].obs;
  RxList selectedVariants = [].obs;
  RxList selectedIndexVariants = [].obs;
  RxList selectedIndexArray = [].obs;

  RxList selectedAddOns = [].obs;

  RxInt quantity = 1.obs;

  String calculatePrice(ProductModel productModel) {
    String mainPrice = "0";
    String variantPrice = "0";
    String adOnsPrice = "0";

    if (productModel.itemAttribute != null) {
      if (productModel.itemAttribute!.variants!.where((element) => element.variantSku == selectedVariants.join('-')).isNotEmpty) {
        variantPrice =
            Constant.productCommissionPrice(vendorModel.value, productModel.itemAttribute!.variants!.where((element) => element.variantSku == selectedVariants.join('-')).first.variantPrice ?? '0');
      }
    } else {
      String price = Constant.productCommissionPrice(vendorModel.value, productModel.price.toString());
      String disPrice = double.parse(productModel.disPrice.toString()) <= 0 ? "0" : Constant.productCommissionPrice(vendorModel.value, productModel.disPrice.toString());
      if (double.parse(disPrice) <= 0) {
        variantPrice = price;
      } else {
        variantPrice = disPrice;
      }
    }

    for (int i = 0; i < productModel.addOnsPrice!.length; i++) {
      if (selectedAddOns.contains(productModel.addOnsTitle![i]) == true) {
        adOnsPrice = (double.parse(adOnsPrice.toString()) + double.parse(Constant.productCommissionPrice(vendorModel.value, productModel.addOnsPrice![i].toString()))).toString();
      }
    }
    adOnsPrice = (quantity.value * double.parse(adOnsPrice)).toString();
    mainPrice = ((double.parse(variantPrice.toString()) * double.parse(quantity.value.toString())) + double.parse(adOnsPrice.toString())).toString();
    return mainPrice;
  }

  Future<void> getAttributeData() async {
    await FireStoreUtils.getAttributes().then((value) {
      if (value != null) {
        attributesList.value = value;
      }
    });
  }

  Future<void> addToCart({
    required ProductModel productModel,
    required String price,
    required String discountPrice,
    required bool isIncrement,
    required int quantity,
    VariantInfo? variantInfo,
  }) async {
    CartProductModel cartProductModel = CartProductModel();

    String adOnsPrice = "0";
    for (int i = 0; i < productModel.addOnsPrice!.length; i++) {
      if (selectedAddOns.contains(productModel.addOnsTitle![i]) == true && productModel.addOnsPrice![i] != '0') {
        adOnsPrice = (double.parse(adOnsPrice.toString()) + double.parse(Constant.productCommissionPrice(vendorModel.value, productModel.addOnsPrice![i].toString()))).toString();
      }
    }

    if (variantInfo != null) {
      cartProductModel.id = "${productModel.id!}~${variantInfo.variantId.toString()}";
      cartProductModel.name = productModel.name!;
      cartProductModel.photo = productModel.photo!;
      cartProductModel.categoryId = productModel.categoryID!;
      cartProductModel.price = price;
      cartProductModel.discountPrice = discountPrice;
      cartProductModel.vendorID = vendorModel.value.id;
      cartProductModel.quantity = quantity;
      cartProductModel.variantInfo = variantInfo;
      cartProductModel.extrasPrice = adOnsPrice;
      cartProductModel.extras = selectedAddOns.isEmpty ? [] : selectedAddOns;
      cartProductModel.taxSetting =
          Constant.taxScope == "order" ? [] : Constant.taxProductList?.where((activeTax) => productModel.taxSetting?.any((productTax) => productTax.id == activeTax.id) ?? false).toList();
    } else {
      cartProductModel.id = productModel.id!;
      cartProductModel.name = productModel.name!;
      cartProductModel.photo = productModel.photo!;
      cartProductModel.categoryId = productModel.categoryID!;
      cartProductModel.price = price;
      cartProductModel.discountPrice = discountPrice;
      cartProductModel.vendorID = vendorModel.value.id;
      cartProductModel.quantity = quantity;
      cartProductModel.variantInfo = VariantInfo();
      cartProductModel.extrasPrice = adOnsPrice;
      cartProductModel.extras = selectedAddOns.isEmpty ? [] : selectedAddOns;
      cartProductModel.taxSetting =
          Constant.taxScope == "order" ? [] : Constant.taxProductList?.where((activeTax) => productModel.taxSetting?.any((productTax) => productTax.id == activeTax.id) ?? false).toList();
    }

    if (isIncrement) {
      await cartProvider.addToCart(Get.context!, cartProductModel, quantity);
    } else {
      await cartProvider.removeFromCart(cartProductModel, quantity);
    }
    log("===> new ${cartItem.length}");
    update();
  }
}
