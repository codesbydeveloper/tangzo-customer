import 'package:customer/constant/constant.dart';
import 'package:customer/models/cart_product_model.dart';
import 'package:customer/models/order_model.dart';
import 'package:customer/services/cart_provider.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:get/get.dart';

class OrderController extends GetxController {
  RxList<OrderModel> allList = <OrderModel>[].obs;
  RxList<OrderModel> inProgressList = <OrderModel>[].obs;
  RxList<OrderModel> deliveredList = <OrderModel>[].obs;
  RxList<OrderModel> rejectedList = <OrderModel>[].obs;
  RxList<OrderModel> cancelledList = <OrderModel>[].obs;

  RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    getOrder();
  }

  Future<void> getOrder() async {
    if (Constant.userModel != null) {
      await FireStoreUtils.getAllOrder().then((value) {
        isLoading.value = true;
        allList.value = value;

        rejectedList.value = allList.where((p0) => p0.status == Constant.orderRejected).toList();
        inProgressList.value =
            allList.where((p0) => p0.status == Constant.orderAccepted || p0.status == Constant.driverPending || p0.status == Constant.orderShipped || p0.status == Constant.orderInTransit).toList();

        deliveredList.value = allList.where((p0) => p0.status == Constant.orderCompleted).toList();
        cancelledList.value = allList.where((p0) => p0.status == Constant.orderCancelled).toList();
      });
    }

    isLoading.value = false;
  }

  final CartProvider cartProvider = CartProvider();

  void addToCart({required CartProductModel cartProductModel}) {
    cartProvider.addToCart(Get.context!, cartProductModel, cartProductModel.quantity!);
    update();
  }

  Future<bool> hasAnyPublishedProduct(List<CartProductModel>? products) async {
    if (products == null || products.isEmpty) return false;
    for (final item in products) {
      final product = await FireStoreUtils.getProductById(item.id ?? '');
      if (product == null || product.publish == false) {
        return false;
      }
    }
    return true;
  }
}
