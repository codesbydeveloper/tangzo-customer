import 'package:customer/models/cashbackModel.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:get/get.dart';

class CashbackController extends GetxController {
  RxList<CashbackModel> cashbackList = <CashbackModel>[].obs;
  RxBool isLoading = true.obs;

  @override
  void onInit() {
    // TODO: implement onInit
    getCashback();
    super.onInit();
  }

  Future<void> getCashback() async {
    await FireStoreUtils.getCashbackList().then((value) {
      if (value.isNotEmpty) {
        cashbackList.value = value;
      }
    });
    isLoading.value = false;
  }
}
