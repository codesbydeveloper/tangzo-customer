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
    // TODO: implement onInit
    getArgument();
    super.onInit();
  }

  RxBool isLoading = true.obs;
  RxList<VendorModel> vendorList = <VendorModel>[].obs;
  RxList<VendorModel> vendorSearchList = <VendorModel>[].obs;

  RxList<ProductModel> productList = <ProductModel>[].obs;
  RxList<ProductModel> productSearchList = <ProductModel>[].obs;

  var searchTextController = TextEditingController().obs;

  Future<void> getArgument() async {
    dynamic argumentData = Get.arguments;
    if (argumentData != null) {
      vendorList.value = argumentData['vendorList'];
      productList.clear();
    }
    isLoading.value = false;

    for (var element in vendorList) {
      await FireStoreUtils.getProductByVendorId(element.id.toString()).then((value) {
        if ((Constant.isSubscriptionModelApplied == true || Constant.adminCommission?.isEnabled == true) && element.subscriptionPlan != null) {
          if (element.subscriptionPlan?.itemLimit == '-1') {
            productList.addAll(value);
          } else {
            int selectedProduct = value.length < int.parse(element.subscriptionPlan?.itemLimit ?? '0') ? (value.isEmpty ? 0 : (value.length)) : int.parse(element.subscriptionPlan?.itemLimit ?? '0');
            productList.addAll(value.sublist(0, selectedProduct));
          }
        } else {
          productList.addAll(value);
        }
      });
    }
  }

  void onSearchTextChanged(String text) {
    if (text.isEmpty) {
      return;
    }
    vendorSearchList.clear();
    productSearchList.clear();
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

    for (var element in productList) {
      if (element.name!.toLowerCase().contains(text.toLowerCase())) {
        productSearchList.add(element);
      }
    }
  }

  @override
  void dispose() {
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
