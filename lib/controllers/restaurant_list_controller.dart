import 'package:customer/constant/constant.dart';
import 'package:customer/models/favourite_model.dart';
import 'package:customer/models/vendor_model.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:get/get.dart';

class RestaurantListController extends GetxController {
  RxBool isLoading = true.obs;
  RxList<VendorModel> vendorList = <VendorModel>[].obs;
  RxList<VendorModel> vendorSearchList = <VendorModel>[].obs;

  RxString title = "Restaurants".obs;

  RxList<FavouriteModel> favouriteList = <FavouriteModel>[].obs;

  @override
  void onInit() {
    // TODO: implement onInit
    getArgument();
    super.onInit();
  }

  Future<void> getArgument() async {
    final argumentData = Get.arguments;

    if (argumentData != null && argumentData['vendorList'] != null) {
      final List<VendorModel> vendordata = List<VendorModel>.from(argumentData['vendorList']);

      vendordata.sort((a, b) {
        final aOpen = Constant.statusCheckOpenORClose(vendorModel: a);
        final bOpen = Constant.statusCheckOpenORClose(vendorModel: b);
        if (aOpen == bOpen) return 0;
        return aOpen ? -1 : 1;
      });

      vendorList.value = vendordata;
      vendorSearchList.value = vendordata;
      title.value = argumentData['title'] ?? "Restaurants";
    }

    await getFavouriteRestaurant();
    isLoading.value = false;
  }

  Future<void> getFavouriteRestaurant() async {
    if (Constant.userModel != null) {
      await FireStoreUtils.getFavouriteRestaurant().then(
        (value) {
          favouriteList.value = value;
        },
      );
    }
  }

  @override
  void dispose() {
    vendorSearchList.clear();
    super.dispose();
  }
}
