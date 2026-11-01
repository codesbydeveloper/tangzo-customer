import 'dart:async';
import 'dart:developer';

import 'package:customer/app/search_screen/voice_search_screen.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/controllers/voice_search_controller.dart';
import 'package:customer/models/product_model.dart';
import 'package:customer/models/vendor_model.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

class SearchScreenController extends GetxController {
  @override
  void onInit() {
    getArgument();
    super.onInit();
  }

  RxBool isLoading = true.obs;
  RxBool isLoadingProducts = false.obs;
  RxList<VendorModel> vendorList = <VendorModel>[].obs;
  RxList<VendorModel> vendorSearchList = <VendorModel>[].obs;

  RxList<ProductModel> productList = <ProductModel>[].obs;
  RxList<ProductModel> productSearchList = <ProductModel>[].obs;

  var searchTextController = TextEditingController().obs;

  /// Vendors whose menus have already been loaded into [productList] this session.
  final Set<String> _loadedVendorIds = {};
  Timer? _searchDebounce;
  String _lastProductQuery = '';

  Future<void> getArgument() async {
    dynamic argumentData = Get.arguments;
    if (argumentData != null) {
      vendorList.value = argumentData['vendorList'];
      productList.clear();
      _loadedVendorIds.clear();
    }
    // Do NOT prefetch every vendor's full menu on open — that was the main
    // read amplifier (O(vendors × products) before the user typed anything).
    isLoading.value = false;
  }

  void onSearchTextChanged(String text) {
    if (text.isEmpty) {
      vendorSearchList.clear();
      productSearchList.clear();
      _searchDebounce?.cancel();
      return;
    }

    vendorSearchList.clear();
    List<VendorModel> vendorSearchData = [];
    for (var element in vendorList) {
      if (element.title!.toLowerCase().contains(text.toLowerCase())) {
        vendorSearchData.add(element);
      }
    }
    vendorSearchData.sort((a, b) {
      final aOpen = Constant.statusCheckOpenORClose(vendorModel: a);
      final bOpen = Constant.statusCheckOpenORClose(vendorModel: b);
      if (aOpen == bOpen) return 0;
      return aOpen ? -1 : 1;
    });
    vendorSearchList.value = vendorSearchData;

    // Filter already-loaded products immediately.
    _filterProducts(text);

    // Lazily load remaining vendor menus (cached + deduped) after debounce.
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      _ensureProductsLoadedForSearch(text);
    });
  }

  void _filterProducts(String text) {
    productSearchList.clear();
    final q = text.toLowerCase();
    for (var element in productList) {
      if (element.name!.toLowerCase().contains(q)) {
        productSearchList.add(element);
      }
    }
  }

  Future<void> _ensureProductsLoadedForSearch(String text) async {
    if (text.trim().length < 2) return;
    if (text == _lastProductQuery && _loadedVendorIds.length == vendorList.length) {
      _filterProducts(text);
      return;
    }
    _lastProductQuery = text;

    final pending = vendorList.where((v) => !_loadedVendorIds.contains(v.id)).toList();
    if (pending.isEmpty) {
      _filterProducts(text);
      return;
    }

    isLoadingProducts.value = true;
    try {
      // Load in small parallel batches so first results appear quickly and
      // MenuCacheRepository can dedupe overlapping requests.
      const batchSize = 5;
      for (var i = 0; i < pending.length; i += batchSize) {
        if (searchTextController.value.text != text) {
          // User kept typing — abandon this wave.
          break;
        }
        final batch = pending.skip(i).take(batchSize);
        await Future.wait(batch.map((vendor) async {
          final vendorId = vendor.id?.toString() ?? '';
          if (vendorId.isEmpty || _loadedVendorIds.contains(vendorId)) return;
          final value = await FireStoreUtils.getProductByVendorId(
            vendorId,
            menuVersion: vendor.menuVersion,
          );
          if ((Constant.isSubscriptionModelApplied == true || Constant.adminCommission?.isEnabled == true) &&
              vendor.subscriptionPlan != null) {
            if (vendor.subscriptionPlan?.itemLimit == '-1') {
              productList.addAll(value);
            } else {
              int selectedProduct = value.length <
                      int.parse(vendor.subscriptionPlan?.itemLimit ?? '0')
                  ? (value.isEmpty ? 0 : (value.length))
                  : int.parse(vendor.subscriptionPlan?.itemLimit ?? '0');
              productList.addAll(value.sublist(0, selectedProduct));
            }
          } else {
            productList.addAll(value);
          }
          _loadedVendorIds.add(vendorId);
        }));
        _filterProducts(text);
      }
    } finally {
      isLoadingProducts.value = false;
    }
  }

  /// Resolve vendor from the in-memory list (no Firestore) when possible.
  VendorModel? findVendor(String? vendorId) {
    if (vendorId == null || vendorId.isEmpty) return null;
    return vendorList.firstWhereOrNull((v) => v.id == vendorId);
  }

  @override
  void onClose() {
    _searchDebounce?.cancel();
    vendorSearchList.clear();
    productSearchList.clear();
    super.onClose();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    vendorSearchList.clear();
    productSearchList.clear();
    super.dispose();
  }

  Future<void> voiceSearch() async {
    final result = await Get.to(() => const VoiceSearchScreen());
    Get.delete<VoiceSearchController>();
    if (result != null) {
      log("voiceSearch :::: $result");
      searchTextController.value.text = result ?? '';
      onSearchTextChanged(result);
    }
  }
}
