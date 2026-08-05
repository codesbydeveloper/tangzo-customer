import 'package:customer/app/auth_screen/login_screen.dart';
import 'package:customer/app/order_list_screen/live_tracking_screen.dart';
import 'package:customer/app/order_list_screen/order_details_screen.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/controllers/order_controller.dart';
import 'package:customer/models/cart_product_model.dart';
import 'package:customer/models/order_model.dart';
import 'package:customer/models/vendor_model.dart';
import 'package:customer/themes/app_them_data.dart';
import 'package:customer/themes/responsive.dart';
import 'package:customer/themes/round_button_fill.dart';
import 'package:customer/utils/dark_theme_provider.dart';
import 'package:customer/utils/dynamic_traslator.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:customer/utils/network_image_widget.dart';
import 'package:customer/utils/translation_notifier.dart';
import 'package:customer/widget/my_separator.dart';
import 'package:flutter/material.dart';
import 'package:customer/widget/translated_text.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class OrderScreen extends StatelessWidget {
  const OrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX(
        init: OrderController(),
        builder: (controller) {
          return Scaffold(
            body: Padding(
              padding: EdgeInsets.only(top: MediaQuery.of(context).viewPadding.top),
              child: controller.isLoading.value
                  ? Constant.loader()
                  : Constant.userModel == null
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Image.asset(
                                "assets/images/login.gif",
                                height: 120,
                              ),
                              const SizedBox(
                                height: 12,
                              ),
                              TranslatedText(
                                "Please Log In to Continue",
                                style: TextStyle(color: themeChange.getThem() ? AppThemeData.grey100 : AppThemeData.grey800, fontSize: 22, fontFamily: AppThemeData.semiBold),
                              ),
                              const SizedBox(
                                height: 5,
                              ),
                              TranslatedText(
                                "You’re not logged in. Please sign in to access your account and explore all features.",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey500, fontSize: 16, fontFamily: AppThemeData.bold),
                              ),
                              const SizedBox(
                                height: 20,
                              ),
                              RoundedButtonFill(
                                title: "Log in",
                                width: 55,
                                height: 5.5,
                                color: AppThemeData.primary300,
                                textColor: AppThemeData.grey50,
                                onPress: () async {
                                  Get.offAll(const LoginScreen());
                                },
                              ),
                            ],
                          ),
                        )
                      : DefaultTabController(
                          length: 5,
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          TranslatedText(
                                            "My Order",
                                            style: TextStyle(
                                              fontSize: 24,
                                              color: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey900,
                                              fontFamily: AppThemeData.semiBold,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          TranslatedText(
                                            "Keep track your delivered, In Progress and Rejected food all in just one place.",
                                            style: TextStyle(
                                              color: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey900,
                                              fontFamily: AppThemeData.regular,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              Expanded(
                                child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: ValueListenableBuilder(
                                        valueListenable: TranslationNotifier.refresh,
                                        builder: (_, __, ___) {
                                          return Column(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                                                decoration: ShapeDecoration(
                                                  color: themeChange.getThem() ? AppThemeData.grey800 : AppThemeData.grey100,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(120),
                                                  ),
                                                ),
                                                child: TabBar(
                                                  indicator: BoxDecoration(
                                                      borderRadius: BorderRadius.circular(50), // Creates border
                                                      color: AppThemeData.primary300),
                                                  labelColor: AppThemeData.grey50,
                                                  isScrollable: true,
                                                  tabAlignment: TabAlignment.start,
                                                  indicatorWeight: 0.5,
                                                  unselectedLabelColor: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey900,
                                                  dividerColor: Colors.transparent,
                                                  indicatorSize: TabBarIndicatorSize.tab,
                                                  tabs: [
                                                    Padding(
                                                      padding: const EdgeInsets.symmetric(horizontal: 18),
                                                      child: Tab(text: 'All'.tr),
                                                    ),
                                                    Tab(
                                                      text: 'In Progress'.tr,
                                                    ),
                                                    Tab(
                                                      text: 'Delivered'.tr,
                                                    ),
                                                    Tab(
                                                      text: 'Cancelled'.tr,
                                                    ),
                                                    Tab(
                                                      text: 'Rejected'.tr,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(
                                                height: 10,
                                              ),
                                              Expanded(
                                                child: TabBarView(
                                                  children: [
                                                    controller.allList.isEmpty
                                                        ? Constant.showEmptyView(message: "Order Not Found")
                                                        : RefreshIndicator(
                                                            onRefresh: () => controller.getOrder(),
                                                            child: ListView.builder(
                                                              itemCount: controller.allList.length,
                                                              shrinkWrap: true,
                                                              padding: EdgeInsets.zero,
                                                              itemBuilder: (context, index) {
                                                                OrderModel orderModel = controller.allList[index];
                                                                return itemView(themeChange, context, orderModel, controller);
                                                              },
                                                            ),
                                                          ),
                                                    controller.inProgressList.isEmpty
                                                        ? Constant.showEmptyView(message: "Order Not Found")
                                                        : RefreshIndicator(
                                                            onRefresh: () => controller.getOrder(),
                                                            child: ListView.builder(
                                                              itemCount: controller.inProgressList.length,
                                                              shrinkWrap: true,
                                                              padding: EdgeInsets.zero,
                                                              itemBuilder: (context, index) {
                                                                OrderModel orderModel = controller.inProgressList[index];
                                                                return itemView(themeChange, context, orderModel, controller);
                                                              },
                                                            ),
                                                          ),
                                                    controller.deliveredList.isEmpty
                                                        ? Constant.showEmptyView(message: "Order Not Found")
                                                        : RefreshIndicator(
                                                            onRefresh: () => controller.getOrder(),
                                                            child: ListView.builder(
                                                              itemCount: controller.deliveredList.length,
                                                              shrinkWrap: true,
                                                              padding: EdgeInsets.zero,
                                                              itemBuilder: (context, index) {
                                                                OrderModel orderModel = controller.deliveredList[index];
                                                                return itemView(themeChange, context, orderModel, controller);
                                                              },
                                                            ),
                                                          ),
                                                    controller.cancelledList.isEmpty
                                                        ? Constant.showEmptyView(message: "Order Not Found")
                                                        : RefreshIndicator(
                                                            onRefresh: () => controller.getOrder(),
                                                            child: ListView.builder(
                                                              itemCount: controller.cancelledList.length,
                                                              shrinkWrap: true,
                                                              padding: EdgeInsets.zero,
                                                              itemBuilder: (context, index) {
                                                                OrderModel orderModel = controller.cancelledList[index];
                                                                return itemView(themeChange, context, orderModel, controller);
                                                              },
                                                            ),
                                                          ),
                                                    controller.rejectedList.isEmpty
                                                        ? Constant.showEmptyView(message: "Order Not Found")
                                                        : RefreshIndicator(
                                                            onRefresh: () => controller.getOrder(),
                                                            child: ListView.builder(
                                                              itemCount: controller.rejectedList.length,
                                                              shrinkWrap: true,
                                                              padding: EdgeInsets.zero,
                                                              itemBuilder: (context, index) {
                                                                OrderModel orderModel = controller.rejectedList[index];
                                                                return itemView(themeChange, context, orderModel, controller);
                                                              },
                                                            ),
                                                          ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          );
                                        })),
                              )
                            ],
                          ),
                        ),
            ),
          );
        });
  }

  Padding itemView(DarkThemeProvider themeChange, BuildContext context, OrderModel orderModel, OrderController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Container(
        decoration: ShapeDecoration(
          color: themeChange.getThem() ? AppThemeData.grey900 : AppThemeData.grey50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(16)),
                    child: Stack(
                      children: [
                        NetworkImageWidget(
                          imageUrl: orderModel.vendor!.photo.toString(),
                          fit: BoxFit.cover,
                          height: Responsive.height(10, context),
                          width: Responsive.width(20, context),
                        ),
                        Container(
                          height: Responsive.height(10, context),
                          width: Responsive.width(20, context),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: const Alignment(0.00, 1.00),
                              end: const Alignment(0, -1),
                              colors: [Colors.black.withOpacity(0), AppThemeData.grey900],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TranslatedText(
                          orderModel.status.toString(),
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: Constant.statusColor(status: orderModel.status.toString()),
                            fontFamily: AppThemeData.semiBold,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        TranslatedText(
                          orderModel.vendor!.title.toString(),
                          style: TextStyle(
                            fontSize: 16,
                            color: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey900,
                            fontFamily: AppThemeData.medium,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        TranslatedText(
                          Constant.timestampToDateTime(orderModel.createdAt!),
                          style: TextStyle(
                            color: themeChange.getThem() ? AppThemeData.grey300 : AppThemeData.grey600,
                            fontFamily: AppThemeData.medium,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 10,
              ),
              ListView.builder(
                itemCount: orderModel.products!.length,
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  CartProductModel cartProduct = orderModel.products![index];
                  return Row(
                    children: [
                      Expanded(
                        child: TranslatedText(
                          "${cartProduct.quantity} x ${cartProduct.name.toString()}",
                          style: TextStyle(
                            color: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey900,
                            fontFamily: AppThemeData.regular,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      Text(
                        Constant.amountShow(
                            amount: double.parse(cartProduct.discountPrice.toString()) <= 0
                                ? (double.parse('${cartProduct.price ?? 0}') * double.parse('${cartProduct.quantity ?? 0}')).toString()
                                : (double.parse('${cartProduct.discountPrice ?? 0}') * double.parse('${cartProduct.quantity ?? 0}')).toString()),
                        style: TextStyle(
                          color: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey900,
                          fontFamily: AppThemeData.semiBold,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    ],
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: MySeparator(color: themeChange.getThem() ? AppThemeData.grey700 : AppThemeData.grey200),
              ),
              Row(
                children: [
                  orderModel.status == Constant.orderCompleted
                      ? FutureBuilder<bool>(
                          future: controller.hasAnyPublishedProduct(orderModel.products),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const SizedBox();
                            } else {
                              if (snapshot.hasError) {
                                return const SizedBox();
                              } else if (snapshot.data == null) {
                                return const SizedBox();
                              } else {
                                if (snapshot.data == false) {
                                  return const SizedBox();
                                } else {
                                  return FutureBuilder(
                                      future: FireStoreUtils.getVendorById(orderModel.vendorID!),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                          return const SizedBox();
                                        } else {
                                          if (snapshot.hasError) {
                                            return const SizedBox();
                                          } else if (snapshot.data == null) {
                                            return const SizedBox();
                                          } else {
                                            VendorModel vendorModel = snapshot.data!;
                                            if ((Constant.isSubscriptionModelApplied == true || Constant.adminCommission?.isEnabled == true) && vendorModel.subscriptionPlan != null) {
                                              if (vendorModel.subscriptionTotalOrders == "-1") {
                                                return Expanded(
                                                  child: InkWell(
                                                    onTap: () {
                                                      for (var element in orderModel.products!) {
                                                        controller.addToCart(cartProductModel: element);
                                                        ShowToastDialog.showToast("Item Added In a cart");
                                                      }
                                                    },
                                                    child: TranslatedText(
                                                      "Reorder",
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(
                                                          color: themeChange.getThem() ? AppThemeData.primary300 : AppThemeData.primary300,
                                                          fontFamily: AppThemeData.semiBold,
                                                          fontWeight: FontWeight.w600,
                                                          fontSize: 16),
                                                    ),
                                                  ),
                                                );
                                              } else {
                                                if ((vendorModel.subscriptionExpiryDate != null && vendorModel.subscriptionExpiryDate!.toDate().isBefore(DateTime.now()) == false) ||
                                                    vendorModel.subscriptionPlan?.expiryDay == '-1') {
                                                  if (vendorModel.subscriptionTotalOrders != '0') {
                                                    return Expanded(
                                                      child: InkWell(
                                                        onTap: () {
                                                          for (var element in orderModel.products!) {
                                                            controller.addToCart(cartProductModel: element);
                                                            ShowToastDialog.showToast("Item Added In a cart");
                                                          }
                                                        },
                                                        child: TranslatedText(
                                                          "Reorder",
                                                          textAlign: TextAlign.center,
                                                          style: TextStyle(
                                                              color: themeChange.getThem() ? AppThemeData.primary300 : AppThemeData.primary300,
                                                              fontFamily: AppThemeData.semiBold,
                                                              fontWeight: FontWeight.w600,
                                                              fontSize: 16),
                                                        ),
                                                      ),
                                                    );
                                                  } else {
                                                    return SizedBox();
                                                  }
                                                } else {
                                                  return SizedBox();
                                                }
                                              }
                                            } else {
                                              return Expanded(
                                                child: InkWell(
                                                  onTap: () {
                                                    for (var element in orderModel.products!) {
                                                      controller.addToCart(cartProductModel: element);
                                                      ShowToastDialog.showToast("Item Added In a cart");
                                                    }
                                                  },
                                                  child: TranslatedText(
                                                    "Reorder",
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                        color: themeChange.getThem() ? AppThemeData.primary300 : AppThemeData.primary300,
                                                        fontFamily: AppThemeData.semiBold,
                                                        fontWeight: FontWeight.w600,
                                                        fontSize: 16),
                                                  ),
                                                ),
                                              );
                                            }
                                          }
                                        }
                                      });
                                }
                              }
                            }
                          })
                      : orderModel.status == Constant.orderShipped || orderModel.status == Constant.orderInTransit
                          ? Expanded(
                              child: InkWell(
                                onTap: () {
                                  Get.to(const LiveTrackingScreen(), arguments: {"orderModel": orderModel});
                                },
                                child: TranslatedText(
                                  "Track Order",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: themeChange.getThem() ? AppThemeData.primary300 : AppThemeData.primary300, fontFamily: AppThemeData.semiBold, fontWeight: FontWeight.w600, fontSize: 16),
                                ),
                              ),
                            )
                          : const SizedBox(),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Get.to(const OrderDetailsScreen(), arguments: {"orderModel": orderModel})?.then((value) {
                          if (value == true) {
                            controller.getOrder();
                          }
                        });
                        // Get.off(const OrderPlacingScreen(), arguments: {"orderModel": orderModel});
                      },
                      child: TranslatedText(
                        "View Details",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey900, fontFamily: AppThemeData.semiBold, fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 10,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
