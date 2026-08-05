import 'package:cloud_firestore/cloud_firestore.dart' hide Constant;
import 'package:customer/app/chat_screens/chat_screen.dart';
import 'package:customer/app/order_list_screen/live_tracking_screen.dart';
import 'package:customer/app/rate_us_screen/rate_product_screen.dart';
import 'package:customer/constant/collection_name.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/constant/send_notification.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/controllers/order_details_controller.dart';
import 'package:customer/models/cart_product_model.dart';
import 'package:customer/models/user_model.dart';
import 'package:customer/models/vendor_model.dart';
import 'package:customer/models/wallet_transaction_model.dart';
import 'package:customer/themes/app_them_data.dart';
import 'package:customer/themes/responsive.dart';
import 'package:customer/themes/round_button_fill.dart';
import 'package:customer/utils/dark_theme_provider.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:customer/utils/network_image_widget.dart';
import 'package:customer/widget/my_separator.dart';
import 'package:flutter/material.dart';
import 'package:customer/widget/translated_text.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:timelines_plus/timelines_plus.dart';
import 'package:uuid/uuid.dart';

class OrderDetailsScreen extends StatelessWidget {
  const OrderDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX(
        init: OrderDetailsController(),
        builder: (controller) {
          return Scaffold(
            backgroundColor: themeChange.getThem() ? AppThemeData.surfaceDark : AppThemeData.surface,
            appBar: AppBar(
              backgroundColor: themeChange.getThem() ? AppThemeData.surfaceDark : AppThemeData.surface,
              centerTitle: false,
              titleSpacing: 0,
              title: TranslatedText(
                "Order Details",
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontFamily: AppThemeData.medium,
                  fontSize: 16,
                  color: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey900,
                ),
              ),
            ),
            body: controller.isLoading.value
                ? Constant.loader()
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TranslatedText(
                                      "${'Order'} ${Constant.orderId(orderId: controller.orderModel.value.id.toString())}",
                                      textAlign: TextAlign.start,
                                      style: TextStyle(
                                        fontFamily: AppThemeData.semiBold,
                                        fontSize: 18,
                                        color: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              RoundedButtonFill(
                                title: controller.orderModel.value.status.toString(),
                                color: Constant.statusColor(status: controller.orderModel.value.status.toString()),
                                width: 32,
                                height: 4.5,
                                radius: 10,
                                textColor: Constant.statusText(status: controller.orderModel.value.status.toString()),
                                onPress: () async {},
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 14,
                          ),
                          controller.orderModel.value.isPosOrder == true
                              ? Container(
                                  decoration: ShapeDecoration(
                                    color: themeChange.getThem() ? AppThemeData.grey900 : AppThemeData.grey50,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                      child: Row(children: [
                                        SvgPicture.asset("assets/icons/ic_location.svg"),
                                        SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              TranslatedText(
                                                "${controller.orderModel.value.vendor!.title}",
                                                textAlign: TextAlign.start,
                                                style: TextStyle(
                                                  fontFamily: AppThemeData.semiBold,
                                                  fontSize: 16,
                                                  color: themeChange.getThem() ? AppThemeData.primary300 : AppThemeData.primary300,
                                                ),
                                              ),
                                              TranslatedText(
                                                "${controller.orderModel.value.vendor!.location}",
                                                textAlign: TextAlign.start,
                                                style: TextStyle(
                                                  fontFamily: AppThemeData.medium,
                                                  fontSize: 14,
                                                  color: themeChange.getThem() ? AppThemeData.grey300 : AppThemeData.grey600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ])))
                              : controller.orderModel.value.takeAway == true
                                  ? Container(
                                      decoration: ShapeDecoration(
                                        color: themeChange.getThem() ? AppThemeData.grey900 : AppThemeData.grey50,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  TranslatedText(
                                                    "${controller.orderModel.value.vendor!.title}",
                                                    textAlign: TextAlign.start,
                                                    style: TextStyle(
                                                      fontFamily: AppThemeData.semiBold,
                                                      fontSize: 16,
                                                      color: themeChange.getThem() ? AppThemeData.primary300 : AppThemeData.primary300,
                                                    ),
                                                  ),
                                                  TranslatedText(
                                                    "${controller.orderModel.value.vendor!.location}",
                                                    textAlign: TextAlign.start,
                                                    style: TextStyle(
                                                      fontFamily: AppThemeData.medium,
                                                      fontSize: 14,
                                                      color: themeChange.getThem() ? AppThemeData.grey300 : AppThemeData.grey600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            controller.orderModel.value.status == Constant.orderPlaced ||
                                                    controller.orderModel.value.status == Constant.orderRejected ||
                                                    controller.orderModel.value.status == Constant.orderCompleted
                                                ? const SizedBox()
                                                : InkWell(
                                                    onTap: () {
                                                      Constant.makePhoneCall(controller.orderModel.value.vendor!.phonenumber.toString());
                                                    },
                                                    child: Container(
                                                      width: 42,
                                                      height: 42,
                                                      decoration: ShapeDecoration(
                                                        shape: RoundedRectangleBorder(
                                                          side: BorderSide(width: 1, color: themeChange.getThem() ? AppThemeData.grey700 : AppThemeData.grey200),
                                                          borderRadius: BorderRadius.circular(120),
                                                        ),
                                                      ),
                                                      child: Padding(
                                                        padding: const EdgeInsets.all(8.0),
                                                        child: SvgPicture.asset("assets/icons/ic_phone_call.svg"),
                                                      ),
                                                    ),
                                                  ),
                                            const SizedBox(
                                              width: 10,
                                            ),
                                            controller.orderModel.value.status == Constant.orderPlaced ||
                                                    controller.orderModel.value.status == Constant.orderRejected ||
                                                    controller.orderModel.value.status == Constant.orderCompleted
                                                ? const SizedBox()
                                                : InkWell(
                                                    onTap: () async {
                                                      ShowToastDialog.showLoader("Please wait");

                                                      UserModel? customer = await FireStoreUtils.getUserProfile(controller.orderModel.value.authorID.toString());
                                                      UserModel? restaurantUser = await FireStoreUtils.getUserProfile(controller.orderModel.value.vendor!.author.toString());
                                                      VendorModel? vendorModel = await FireStoreUtils.getVendorById(restaurantUser!.vendorID.toString());
                                                      ShowToastDialog.closeLoader();

                                                      Get.to(const ChatScreen(), arguments: {
                                                        "senderName": '${customer!.fullName()}',
                                                        "senderId": customer.id,
                                                        "senderProfileUrl": customer.profilePictureURL,
                                                        "receivedName": vendorModel!.title,
                                                        "receivedId": restaurantUser.id,
                                                        "receivedProfileUrl": vendorModel.photo,
                                                        "orderId": "${Constant.userRoleVendor}${controller.orderModel.value.id}",
                                                        "token": restaurantUser.fcmToken,
                                                        "chatType": Constant.userRoleVendor,
                                                      });
                                                    },
                                                    child: Container(
                                                      width: 42,
                                                      height: 42,
                                                      decoration: ShapeDecoration(
                                                        shape: RoundedRectangleBorder(
                                                          side: BorderSide(width: 1, color: themeChange.getThem() ? AppThemeData.grey700 : AppThemeData.grey200),
                                                          borderRadius: BorderRadius.circular(120),
                                                        ),
                                                      ),
                                                      child: Padding(
                                                        padding: const EdgeInsets.all(8.0),
                                                        child: SvgPicture.asset("assets/icons/ic_wechat.svg"),
                                                      ),
                                                    ),
                                                  )
                                          ],
                                        ),
                                      ),
                                    )
                                  : Container(
                                      decoration: ShapeDecoration(
                                        color: themeChange.getThem() ? AppThemeData.grey900 : AppThemeData.grey50,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        child: Column(
                                          children: [
                                            Timeline.tileBuilder(
                                              shrinkWrap: true,
                                              padding: EdgeInsets.zero,
                                              physics: const NeverScrollableScrollPhysics(),
                                              theme: TimelineThemeData(
                                                nodePosition: 0,
                                                // indicatorPosition: 0,
                                              ),
                                              builder: TimelineTileBuilder.connected(
                                                contentsAlign: ContentsAlign.basic,
                                                indicatorBuilder: (context, index) {
                                                  return SvgPicture.asset("assets/icons/ic_location.svg");
                                                },
                                                connectorBuilder: (context, index, connectorType) {
                                                  return const DashedLineConnector(
                                                    color: AppThemeData.grey300,
                                                    gap: 3,
                                                  );
                                                },
                                                contentsBuilder: (context, index) {
                                                  return Padding(
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                                    child: index == 0
                                                        ? Row(
                                                            children: [
                                                              Expanded(
                                                                child: Column(
                                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                                  children: [
                                                                    TranslatedText(
                                                                      "${controller.orderModel.value.vendor!.title}",
                                                                      textAlign: TextAlign.start,
                                                                      style: TextStyle(
                                                                        fontFamily: AppThemeData.semiBold,
                                                                        fontSize: 16,
                                                                        color: themeChange.getThem() ? AppThemeData.primary300 : AppThemeData.primary300,
                                                                      ),
                                                                    ),
                                                                    TranslatedText(
                                                                      "${controller.orderModel.value.vendor!.location}",
                                                                      textAlign: TextAlign.start,
                                                                      style: TextStyle(
                                                                        fontFamily: AppThemeData.medium,
                                                                        fontSize: 14,
                                                                        color: themeChange.getThem() ? AppThemeData.grey300 : AppThemeData.grey600,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                              controller.orderModel.value.status == Constant.orderPlaced ||
                                                                      controller.orderModel.value.status == Constant.orderRejected ||
                                                                      controller.orderModel.value.status == Constant.orderCompleted
                                                                  ? const SizedBox()
                                                                  : InkWell(
                                                                      onTap: () {
                                                                        Constant.makePhoneCall(controller.orderModel.value.vendor!.phonenumber.toString());
                                                                      },
                                                                      child: Container(
                                                                        width: 42,
                                                                        height: 42,
                                                                        decoration: ShapeDecoration(
                                                                          shape: RoundedRectangleBorder(
                                                                            side: BorderSide(width: 1, color: themeChange.getThem() ? AppThemeData.grey700 : AppThemeData.grey200),
                                                                            borderRadius: BorderRadius.circular(120),
                                                                          ),
                                                                        ),
                                                                        child: Padding(
                                                                          padding: const EdgeInsets.all(8.0),
                                                                          child: SvgPicture.asset("assets/icons/ic_phone_call.svg"),
                                                                        ),
                                                                      ),
                                                                    ),
                                                              const SizedBox(
                                                                width: 10,
                                                              ),
                                                              controller.orderModel.value.status == Constant.orderPlaced ||
                                                                      controller.orderModel.value.status == Constant.orderRejected ||
                                                                      controller.orderModel.value.status == Constant.orderCompleted
                                                                  ? const SizedBox()
                                                                  : InkWell(
                                                                      onTap: () async {
                                                                        ShowToastDialog.showLoader("Please wait");

                                                                        UserModel? customer = await FireStoreUtils.getUserProfile(controller.orderModel.value.authorID.toString());
                                                                        UserModel? restaurantUser = await FireStoreUtils.getUserProfile(controller.orderModel.value.vendor!.author.toString());
                                                                        VendorModel? vendorModel = await FireStoreUtils.getVendorById(restaurantUser!.vendorID.toString());
                                                                        ShowToastDialog.closeLoader();

                                                                        Get.to(const ChatScreen(), arguments: {
                                                                          "senderName": '${customer!.fullName()}',
                                                                          "senderId": customer.id,
                                                                          "senderProfileUrl": customer.profilePictureURL,
                                                                          "receivedName": vendorModel!.title,
                                                                          "receivedId": restaurantUser.id,
                                                                          "receivedProfileUrl": vendorModel.photo,
                                                                          "orderId": "${Constant.userRoleVendor}${controller.orderModel.value.id}",
                                                                          "token": restaurantUser.fcmToken,
                                                                          "chatType": Constant.userRoleVendor,
                                                                        });
                                                                      },
                                                                      child: Container(
                                                                        width: 42,
                                                                        height: 42,
                                                                        decoration: ShapeDecoration(
                                                                          shape: RoundedRectangleBorder(
                                                                            side: BorderSide(width: 1, color: themeChange.getThem() ? AppThemeData.grey700 : AppThemeData.grey200),
                                                                            borderRadius: BorderRadius.circular(120),
                                                                          ),
                                                                        ),
                                                                        child: Padding(
                                                                          padding: const EdgeInsets.all(8.0),
                                                                          child: SvgPicture.asset("assets/icons/ic_wechat.svg"),
                                                                        ),
                                                                      ),
                                                                    )
                                                            ],
                                                          )
                                                        : Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              TranslatedText(
                                                                controller.orderModel.value.address?.addressAs ?? '',
                                                                textAlign: TextAlign.start,
                                                                style: TextStyle(
                                                                  fontFamily: AppThemeData.semiBold,
                                                                  fontSize: 16,
                                                                  color: themeChange.getThem() ? AppThemeData.primary300 : AppThemeData.primary300,
                                                                ),
                                                              ),
                                                              TranslatedText(
                                                                controller.orderModel.value.address?.getFullAddress() ?? '',
                                                                textAlign: TextAlign.start,
                                                                style: TextStyle(
                                                                  fontFamily: AppThemeData.medium,
                                                                  fontSize: 14,
                                                                  color: themeChange.getThem() ? AppThemeData.grey300 : AppThemeData.grey600,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                  );
                                                },
                                                itemCount: 2,
                                              ),
                                            ),
                                            controller.orderModel.value.status == Constant.orderRejected
                                                ? const SizedBox()
                                                : Column(
                                                    children: [
                                                      Padding(
                                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                                        child: MySeparator(color: themeChange.getThem() ? AppThemeData.grey700 : AppThemeData.grey200),
                                                      ),
                                                      controller.orderModel.value.status == Constant.orderCompleted && controller.orderModel.value.driver != null
                                                          ? Row(
                                                              children: [
                                                                SvgPicture.asset("assets/icons/ic_check_small.svg"),
                                                                const SizedBox(
                                                                  width: 5,
                                                                ),
                                                                TranslatedText(
                                                                  controller.orderModel.value.driver!.fullName(),
                                                                  textAlign: TextAlign.right,
                                                                  style: TextStyle(
                                                                    color: themeChange.getThem() ? AppThemeData.grey100 : AppThemeData.grey800,
                                                                    fontFamily: AppThemeData.semiBold,
                                                                    fontWeight: FontWeight.w500,
                                                                    fontSize: 14,
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                  width: 5,
                                                                ),
                                                                TranslatedText(
                                                                  "Order Delivered.",
                                                                  textAlign: TextAlign.right,
                                                                  style: TextStyle(
                                                                    color: themeChange.getThem() ? AppThemeData.grey100 : AppThemeData.grey800,
                                                                    fontFamily: AppThemeData.regular,
                                                                    fontWeight: FontWeight.w500,
                                                                    fontSize: 14,
                                                                  ),
                                                                ),
                                                              ],
                                                            )
                                                          : controller.orderModel.value.status == Constant.orderAccepted || controller.orderModel.value.status == Constant.driverPending
                                                              ? Row(
                                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                                  children: [
                                                                    SvgPicture.asset("assets/icons/ic_timer.svg"),
                                                                    const SizedBox(
                                                                      width: 5,
                                                                    ),
                                                                    Expanded(
                                                                      child: TranslatedText(
                                                                        "${'Your Order has been Preparing and assign to the driver'}\n${'Preparation Time'} ${controller.orderModel.value.estimatedTimeToPrepare}",
                                                                        textAlign: TextAlign.start,
                                                                        style: TextStyle(
                                                                          color: themeChange.getThem() ? AppThemeData.warning400 : AppThemeData.warning400,
                                                                          fontFamily: AppThemeData.semiBold,
                                                                          fontWeight: FontWeight.w500,
                                                                          fontSize: 14,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                )
                                                              : controller.orderModel.value.driver != null
                                                                  ? Row(
                                                                      children: [
                                                                        ClipOval(
                                                                          child: NetworkImageWidget(
                                                                            imageUrl: controller.orderModel.value.author!.profilePictureURL.toString(),
                                                                            fit: BoxFit.cover,
                                                                            height: Responsive.height(5, context),
                                                                            width: Responsive.width(10, context),
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
                                                                                controller.orderModel.value.driver!.fullName().toString(),
                                                                                textAlign: TextAlign.start,
                                                                                style: TextStyle(
                                                                                  color: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey900,
                                                                                  fontFamily: AppThemeData.semiBold,
                                                                                  fontWeight: FontWeight.w600,
                                                                                  fontSize: 16,
                                                                                ),
                                                                              ),
                                                                              TranslatedText(
                                                                                controller.orderModel.value.driver!.email.toString(),
                                                                                textAlign: TextAlign.start,
                                                                                style: TextStyle(
                                                                                  color: themeChange.getThem() ? AppThemeData.success400 : AppThemeData.success400,
                                                                                  fontFamily: AppThemeData.regular,
                                                                                  fontWeight: FontWeight.w400,
                                                                                  fontSize: 12,
                                                                                ),
                                                                              ),
                                                                            ],
                                                                          ),
                                                                        ),
                                                                        InkWell(
                                                                          onTap: () {
                                                                            Constant.makePhoneCall(controller.orderModel.value.driver!.phoneNumber.toString());
                                                                          },
                                                                          child: Container(
                                                                            width: 42,
                                                                            height: 42,
                                                                            decoration: ShapeDecoration(
                                                                              shape: RoundedRectangleBorder(
                                                                                side: BorderSide(width: 1, color: themeChange.getThem() ? AppThemeData.grey700 : AppThemeData.grey200),
                                                                                borderRadius: BorderRadius.circular(120),
                                                                              ),
                                                                            ),
                                                                            child: Padding(
                                                                              padding: const EdgeInsets.all(8.0),
                                                                              child: SvgPicture.asset("assets/icons/ic_phone_call.svg"),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        const SizedBox(
                                                                          width: 10,
                                                                        ),
                                                                        InkWell(
                                                                          onTap: () async {
                                                                            ShowToastDialog.showLoader("Please wait");

                                                                            UserModel? customer = await FireStoreUtils.getUserProfile(controller.orderModel.value.authorID.toString());
                                                                            UserModel? driverUser = await FireStoreUtils.getUserProfile(controller.orderModel.value.driverID.toString());

                                                                            ShowToastDialog.closeLoader();

                                                                            Get.to(const ChatScreen(), arguments: {
                                                                              "senderName": '${customer!.fullName()}',
                                                                              "senderId": customer.id,
                                                                              "senderProfileUrl": customer.profilePictureURL,
                                                                              "receivedName": driverUser!.fullName(),
                                                                              "receivedId": driverUser.id,
                                                                              "receivedProfileUrl": driverUser.profilePictureURL,
                                                                              "orderId": controller.orderModel.value.id,
                                                                              "token": driverUser.fcmToken,
                                                                              "chatType": Constant.userRoleDriver,
                                                                            });
                                                                          },
                                                                          child: Container(
                                                                            width: 42,
                                                                            height: 42,
                                                                            decoration: ShapeDecoration(
                                                                              shape: RoundedRectangleBorder(
                                                                                side: BorderSide(width: 1, color: themeChange.getThem() ? AppThemeData.grey700 : AppThemeData.grey200),
                                                                                borderRadius: BorderRadius.circular(120),
                                                                              ),
                                                                            ),
                                                                            child: Padding(
                                                                              padding: const EdgeInsets.all(8.0),
                                                                              child: SvgPicture.asset("assets/icons/ic_wechat.svg"),
                                                                            ),
                                                                          ),
                                                                        )
                                                                      ],
                                                                    )
                                                                  : const SizedBox(),
                                                    ],
                                                  ),
                                            const SizedBox(
                                              height: 10,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                          const SizedBox(
                            height: 14,
                          ),
                          TranslatedText(
                            "Your Order",
                            textAlign: TextAlign.start,
                            style: TextStyle(
                              fontFamily: AppThemeData.semiBold,
                              fontSize: 16,
                              color: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey900,
                            ),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Container(
                            decoration: ShapeDecoration(
                              color: themeChange.getThem() ? AppThemeData.grey900 : AppThemeData.grey50,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              child: ListView.separated(
                                shrinkWrap: true,
                                padding: EdgeInsets.zero,
                                itemCount: controller.orderModel.value.products!.length,
                                physics: const NeverScrollableScrollPhysics(),
                                itemBuilder: (context, index) {
                                  CartProductModel cartProductModel = controller.orderModel.value.products![index];
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          ClipRRect(
                                            borderRadius: const BorderRadius.all(Radius.circular(14)),
                                            child: Stack(
                                              children: [
                                                NetworkImageWidget(
                                                  imageUrl: cartProductModel.photo.toString(),
                                                  height: Responsive.height(8, context),
                                                  width: Responsive.width(16, context),
                                                  fit: BoxFit.cover,
                                                ),
                                                Container(
                                                  height: Responsive.height(8, context),
                                                  width: Responsive.width(16, context),
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      begin: const Alignment(-0.00, -1.00),
                                                      end: const Alignment(0, 1),
                                                      colors: [Colors.black.withOpacity(0), const Color(0xFF111827)],
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
                                              mainAxisAlignment: MainAxisAlignment.start,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.start,
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Expanded(
                                                      child: TranslatedText(
                                                        "${cartProductModel.name}",
                                                        textAlign: TextAlign.start,
                                                        style: TextStyle(
                                                          fontFamily: AppThemeData.regular,
                                                          color: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey900,
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                    ),
                                                    TranslatedText(
                                                      "x ${cartProductModel.quantity}",
                                                      textAlign: TextAlign.start,
                                                      style: TextStyle(
                                                        fontFamily: AppThemeData.regular,
                                                        color: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey900,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                double.parse(cartProductModel.discountPrice == null || cartProductModel.discountPrice?.isEmpty == true
                                                            ? "0.0"
                                                            : cartProductModel.discountPrice.toString()) <=
                                                        0
                                                    ? Text(
                                                        Constant.amountShow(amount: cartProductModel.price),
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          color: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey900,
                                                          fontFamily: AppThemeData.semiBold,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      )
                                                    : Row(
                                                        children: [
                                                          Text(
                                                            Constant.amountShow(amount: cartProductModel.discountPrice.toString()),
                                                            style: TextStyle(
                                                              fontSize: 16,
                                                              color: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey900,
                                                              fontFamily: AppThemeData.semiBold,
                                                              fontWeight: FontWeight.w600,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 5,
                                                          ),
                                                          Text(
                                                            Constant.amountShow(amount: cartProductModel.price),
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              decoration: TextDecoration.lineThrough,
                                                              decorationColor: themeChange.getThem() ? AppThemeData.grey500 : AppThemeData.grey400,
                                                              color: themeChange.getThem() ? AppThemeData.grey500 : AppThemeData.grey400,
                                                              fontFamily: AppThemeData.semiBold,
                                                              fontWeight: FontWeight.w600,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                if (Constant.taxScope == "product")
                                                  cartProductModel.taxSetting?.isEmpty == true
                                                      ? SizedBox()
                                                      : TranslatedText(
                                                          "${'Tax:'} ${Constant.getTaxDisplayText(cartProductModel.taxSetting)}",
                                                          maxLines: 2,
                                                          overflow: TextOverflow.ellipsis,
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: themeChange.getThem() ? AppThemeData.secondary300 : AppThemeData.secondary300,
                                                            fontFamily: AppThemeData.semiBold,
                                                          ),
                                                        ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      cartProductModel.variantInfo == null || cartProductModel.variantInfo!.variantOptions!.isEmpty
                                          ? Container()
                                          : Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  TranslatedText(
                                                    "Variants",
                                                    textAlign: TextAlign.start,
                                                    style: TextStyle(
                                                      fontFamily: AppThemeData.semiBold,
                                                      color: themeChange.getThem() ? AppThemeData.grey300 : AppThemeData.grey600,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                    height: 5,
                                                  ),
                                                  Wrap(
                                                    spacing: 6.0,
                                                    runSpacing: 6.0,
                                                    children: List.generate(
                                                      cartProductModel.variantInfo!.variantOptions!.length,
                                                      (i) {
                                                        return Container(
                                                          decoration: ShapeDecoration(
                                                            color: themeChange.getThem() ? AppThemeData.grey800 : AppThemeData.grey100,
                                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                          ),
                                                          child: Padding(
                                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                                                            child: TranslatedText(
                                                              "${cartProductModel.variantInfo!.variantOptions!.keys.elementAt(i)} : ${cartProductModel.variantInfo!.variantOptions![cartProductModel.variantInfo!.variantOptions!.keys.elementAt(i)]}",
                                                              textAlign: TextAlign.start,
                                                              style: TextStyle(
                                                                fontFamily: AppThemeData.medium,
                                                                color: themeChange.getThem() ? AppThemeData.grey500 : AppThemeData.grey400,
                                                              ),
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                    ).toList(),
                                                  ),
                                                ],
                                              ),
                                            ),
                                      cartProductModel.extras == null || cartProductModel.extras!.isEmpty
                                          ? const SizedBox()
                                          : Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: TranslatedText(
                                                        "Addons",
                                                        textAlign: TextAlign.start,
                                                        style: TextStyle(
                                                          fontFamily: AppThemeData.semiBold,
                                                          color: themeChange.getThem() ? AppThemeData.grey300 : AppThemeData.grey600,
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                    ),
                                                    Text(
                                                      Constant.amountShow(
                                                          amount: (double.parse(cartProductModel.extrasPrice.toString()) * double.parse(cartProductModel.quantity.toString())).toString()),
                                                      textAlign: TextAlign.start,
                                                      style: TextStyle(
                                                        fontFamily: AppThemeData.semiBold,
                                                        color: themeChange.getThem() ? AppThemeData.primary300 : AppThemeData.primary300,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Wrap(
                                                  spacing: 6.0,
                                                  runSpacing: 6.0,
                                                  children: List.generate(
                                                    cartProductModel.extras!.length,
                                                    (i) {
                                                      return Container(
                                                        decoration: ShapeDecoration(
                                                          color: themeChange.getThem() ? AppThemeData.grey800 : AppThemeData.grey100,
                                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                        ),
                                                        child: Padding(
                                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                                                          child: TranslatedText(
                                                            cartProductModel.extras![i].toString(),
                                                            textAlign: TextAlign.start,
                                                            style: TextStyle(
                                                              fontFamily: AppThemeData.medium,
                                                              color: themeChange.getThem() ? AppThemeData.grey500 : AppThemeData.grey400,
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  ).toList(),
                                                ),
                                              ],
                                            ),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: RoundedButtonFill(
                                          title: "Rate us",
                                          height: 3.8,
                                          width: 20,
                                          color: themeChange.getThem() ? AppThemeData.warning300 : AppThemeData.warning300,
                                          textColor: themeChange.getThem() ? AppThemeData.grey100 : AppThemeData.grey800,
                                          onPress: () async {
                                            Get.to(const RateProductScreen(), arguments: {"orderModel": controller.orderModel.value, "productId": cartProductModel.id});
                                          },
                                        ),
                                      )
                                    ],
                                  );
                                },
                                separatorBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    child: MySeparator(color: themeChange.getThem() ? AppThemeData.grey700 : AppThemeData.grey200),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 14,
                          ),
                          // if (controller.orderModel.value.takeAway != true &&
                          //     controller.orderModel.value.status ==
                          //         Constant.orderCompleted)
                          //   Column(
                          //     crossAxisAlignment: CrossAxisAlignment.start,
                          //     children: [
                          //       TranslatedText(
                          //         "Delivery Man",
                          //         textAlign: TextAlign.start,
                          //         style: TextStyle(
                          //           fontFamily: AppThemeData.semiBold,
                          //           fontSize: 16,
                          //           color: themeChange.getThem()
                          //               ? AppThemeData.grey50
                          //               : AppThemeData.grey900,
                          //         ),
                          //       ),
                          //       const SizedBox(
                          //         height: 10,
                          //       ),
                          //       const SizedBox(
                          //         height: 14,
                          //       ),
                          //     ],
                          //   ),
                          TranslatedText(
                            "Bill Details",
                            textAlign: TextAlign.start,
                            style: TextStyle(
                              fontFamily: AppThemeData.semiBold,
                              fontSize: 16,
                              color: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey900,
                            ),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Container(
                            width: Responsive.width(100, context),
                            decoration: ShapeDecoration(
                              color: themeChange.getThem() ? AppThemeData.grey900 : AppThemeData.grey50,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              shadows: const [
                                BoxShadow(
                                  color: Color(0x14000000),
                                  blurRadius: 52,
                                )
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                              child: Column(
                                children: [
                                  /// Item Total
                                  amountRow(
                                    title: "Item totals",
                                    amount: Constant.amountShow(amount: controller.subTotal.value.toString()),
                                    isDark: themeChange.getThem(),
                                  ),

                                  sectionDivider(themeChange.getThem()),

                                  /// Coupon Discount
                                  amountRow(
                                    title: "Coupon Discount",
                                    amount: "- (${Constant.amountShow(amount: controller.couponAmount.value.toString())})",
                                    isDark: themeChange.getThem(),
                                    amountColor: AppThemeData.danger300,
                                  ),

                                  sectionDivider(themeChange.getThem()),

                                  /// Special Discount
                                  if (controller.orderModel.value.vendor!.specialDiscountEnable == true) ...[
                                    // const SizedBox(height: 5),
                                    amountRow(
                                      title: "Special Discount",
                                      amount: "- (${Constant.amountShow(amount: controller.specialDiscountAmount.value.toString())})",
                                      isDark: themeChange.getThem(),
                                      amountColor: AppThemeData.danger300,
                                    ),
                                  ],
                                  if (controller.specialDiscountAmount.value > 0.0) const SizedBox(height: 5),

                                  /// Packaging
                                  amountRow(
                                    title: "Packaging charge",
                                    amount: Constant.amountShow(amount: controller.packagingCharge.value.toString()),
                                    isDark: themeChange.getThem(),
                                  ),

                                  sectionDivider(themeChange.getThem()),

                                  /// Delivery Fee
                                  if (controller.orderModel.value.takeAway == false)
                                    amountRow(
                                      title: "Delivery Fee",
                                      isDark: themeChange.getThem(),
                                      trailing: (controller.orderModel.value.vendor!.isSelfDelivery == true || controller.orderModel.value.isFreeDelivery == true)
                                          ? TranslatedText(
                                              'Free Delivery',
                                              style: TextStyle(
                                                fontFamily: AppThemeData.regular,
                                                color: AppThemeData.success400,
                                                fontSize: 16,
                                              ),
                                            )
                                          : Text(
                                              Constant.amountShow(amount: controller.deliveryCharges.value.toString()),
                                              style: TextStyle(
                                                fontFamily: AppThemeData.regular,
                                                color: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey900,
                                                fontSize: 16,
                                              ),
                                            ),
                                      amount: '',
                                    ),

                                  /// Delivery Tips
                                  if (!(controller.orderModel.value.takeAway == true ||
                                      controller.orderModel.value.vendor!.isSelfDelivery == true ||
                                      controller.orderModel.value.isFreeDelivery == true)) ...[
                                    const SizedBox(height: 10),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              TranslatedText(
                                                "Delivery Tips",
                                                style: TextStyle(
                                                  fontFamily: AppThemeData.regular,
                                                  color: themeChange.getThem() ? AppThemeData.grey300 : AppThemeData.grey600,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              // if (controller.deliveryTips.value != 0)
                                              //   InkWell(
                                              //     onTap: () {
                                              //       controller.deliveryTips.value = 0;
                                              //       controller.calculatePrice();
                                              //     },
                                              //     child: TranslatedText(
                                              //       "Remove",
                                              //       style: TextStyle(
                                              //         fontFamily: AppThemeData.medium,
                                              //         color: AppThemeData.primary300,
                                              //       ),
                                              //     ),
                                              //   ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          Constant.amountShow(amount: controller.deliveryTips.toString()),
                                          style: TextStyle(
                                            fontFamily: AppThemeData.regular,
                                            color: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey900,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  if (!(controller.orderModel.value.takeAway == true ||
                                      controller.orderModel.value.vendor!.isSelfDelivery == true ||
                                      controller.orderModel.value.isFreeDelivery == true))
                                    sectionDivider(themeChange.getThem()),

                                  /// Platform Fee
                                  amountRow(
                                    title: "Platform fee",
                                    amount: Constant.amountShow(amount: controller.platformFee.value.toString()),
                                    isDark: themeChange.getThem(),
                                  ),

                                  sectionDivider(themeChange.getThem()),

                                  /// Tax
                                  InkWell(
                                    onTap: () {
                                      showBillBifurcationDialog(context, themeChange.getThem(), controller);
                                    },
                                    child: amountRow(
                                        title: "Tax amount",
                                        amount: Constant.amountShow(amount: controller.totalTaxAmount.value.toString()),
                                        isDark: themeChange.getThem(),
                                        textColour: AppThemeData.secondary300,
                                        underline: true),
                                  ),

                                  sectionDivider(themeChange.getThem()),

                                  /// To Pay
                                  amountRow(
                                    title: "To Pay",
                                    amount: Constant.amountShow(amount: controller.totalAmount.value.toString()),
                                    amountColor: AppThemeData.primary300,
                                    isDark: themeChange.getThem(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 14,
                          ),
                          TranslatedText(
                            "Order Details",
                            textAlign: TextAlign.start,
                            style: TextStyle(
                              fontFamily: AppThemeData.semiBold,
                              fontSize: 16,
                              color: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey900,
                            ),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Container(
                            width: Responsive.width(100, context),
                            decoration: ShapeDecoration(
                              color: themeChange.getThem() ? AppThemeData.grey900 : AppThemeData.grey50,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                              child: Column(
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: TranslatedText(
                                          "Delivery type",
                                          textAlign: TextAlign.start,
                                          style: TextStyle(
                                            fontFamily: AppThemeData.regular,
                                            color: themeChange.getThem() ? AppThemeData.grey300 : AppThemeData.grey600,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      TranslatedText(
                                        controller.orderModel.value.takeAway == true
                                            ? "TakeAway".tr
                                            : controller.orderModel.value.scheduleTime == null
                                                ? "Standard".tr
                                                : "Schedule",
                                        textAlign: TextAlign.start,
                                        style: TextStyle(
                                          fontFamily: AppThemeData.medium,
                                          color: controller.orderModel.value.scheduleTime != null
                                              ? AppThemeData.primary300
                                              : themeChange.getThem()
                                                  ? AppThemeData.grey50
                                                  : AppThemeData.grey900,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: TranslatedText(
                                          "Payment Method",
                                          textAlign: TextAlign.start,
                                          style: TextStyle(
                                            fontFamily: AppThemeData.regular,
                                            color: themeChange.getThem() ? AppThemeData.grey300 : AppThemeData.grey600,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      TranslatedText(
                                        controller.orderModel.value.paymentMethod.toString(),
                                        textAlign: TextAlign.start,
                                        style: TextStyle(
                                          fontFamily: AppThemeData.regular,
                                          color: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey900,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: TranslatedText(
                                          "Date and Time",
                                          textAlign: TextAlign.start,
                                          style: TextStyle(
                                            fontFamily: AppThemeData.regular,
                                            color: themeChange.getThem() ? AppThemeData.grey300 : AppThemeData.grey600,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      TranslatedText(
                                        Constant.timestampToDateTime(controller.orderModel.value.createdAt!),
                                        textAlign: TextAlign.start,
                                        style: TextStyle(
                                          fontFamily: AppThemeData.regular,
                                          color: themeChange.getThem() ? AppThemeData.grey300 : AppThemeData.grey600,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            TranslatedText(
                                              "Phone Number",
                                              textAlign: TextAlign.start,
                                              style: TextStyle(
                                                fontFamily: AppThemeData.regular,
                                                color: themeChange.getThem() ? AppThemeData.grey300 : AppThemeData.grey600,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      TranslatedText(
                                        controller.orderModel.value.author!.phoneNumber.toString(),
                                        textAlign: TextAlign.start,
                                        style: TextStyle(
                                          fontFamily: AppThemeData.regular,
                                          color: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey900,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          controller.orderModel.value.notes == null || controller.orderModel.value.notes!.isEmpty
                              ? const SizedBox()
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TranslatedText(
                                      "Remarks",
                                      textAlign: TextAlign.start,
                                      style: TextStyle(
                                        fontFamily: AppThemeData.semiBold,
                                        fontSize: 16,
                                        color: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey900,
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                    Container(
                                      width: Responsive.width(100, context),
                                      decoration: ShapeDecoration(
                                        color: themeChange.getThem() ? AppThemeData.grey900 : AppThemeData.grey50,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                                        child: TranslatedText(
                                          controller.orderModel.value.notes.toString(),
                                          textAlign: TextAlign.start,
                                          style: TextStyle(
                                            fontFamily: AppThemeData.regular,
                                            color: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey900,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                        ],
                      ),
                    ),
                  ),
            bottomNavigationBar: controller.orderModel.value.status == Constant.orderPlaced
                ? Container(
                    color: themeChange.getThem() ? AppThemeData.grey900 : AppThemeData.grey50,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: RoundedButtonFill(
                        title: "Cancel Order",
                        color: AppThemeData.danger300,
                        textColor: AppThemeData.grey50,
                        height: 5,
                        onPress: () async {
                          ShowToastDialog.showLoader('Please wait...');
                          controller.orderModel.value.status = Constant.orderCancelled;
                          await FireStoreUtils.setOrder(controller.orderModel.value);
                          UserModel? vendorUserModel = await FireStoreUtils.getUserProfile(controller.orderModel.value.vendor?.author ?? '');
                          SendNotification.sendFcmMessage(Constant.customerCancelled, vendorUserModel?.fcmToken ?? '', {});
                          if (controller.orderModel.value.paymentMethod!.toLowerCase() != 'cod') {
                            WalletTransactionModel historyModel = WalletTransactionModel(
                                amount: controller.totalAmount.value,
                                id: const Uuid().v4(),
                                orderId: controller.orderModel.value.id,
                                userId: controller.orderModel.value.author?.id,
                                date: Timestamp.now(),
                                isTopup: true,
                                paymentMethod: "Wallet",
                                paymentStatus: "success",
                                note: "Order Refund success",
                                transactionUser: "user");

                            await FireStoreUtils.fireStore.collection(CollectionName.wallet).doc(historyModel.id).set(historyModel.toJson());
                            await FireStoreUtils.updateUserWallet(amount: controller.totalAmount.value.toString(), userId: controller.orderModel.value.author!.id.toString());
                          }
                          ShowToastDialog.closeLoader();
                          ShowToastDialog.showToast("You have successfully canceled your order.");
                          Get.back(result: true);
                        },
                      ),
                    ))
                : controller.orderModel.value.status == Constant.orderShipped ||
                        controller.orderModel.value.status == Constant.orderInTransit ||
                        controller.orderModel.value.status == Constant.orderCompleted
                    ? Container(
                        color: themeChange.getThem() ? AppThemeData.grey900 : AppThemeData.grey50,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: controller.orderModel.value.status == Constant.orderShipped || controller.orderModel.value.status == Constant.orderInTransit
                              ? RoundedButtonFill(
                                  title: "Track Order",
                                  height: 5.5,
                                  color: AppThemeData.warning300,
                                  textColor: AppThemeData.grey900,
                                  onPress: () async {
                                    Get.to(const LiveTrackingScreen(), arguments: {"orderModel": controller.orderModel.value});
                                  },
                                )
                              : FutureBuilder<bool>(
                                  future: controller.hasAnyPublishedProduct(controller.orderModel.value.products),
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
                                              future: FireStoreUtils.getVendorById(controller.orderModel.value.vendorID!),
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
                                                        return RoundedButtonFill(
                                                          title: "Reorder",
                                                          height: 5.5,
                                                          color: AppThemeData.warning300,
                                                          textColor: AppThemeData.grey900,
                                                          onPress: () async {
                                                            for (var element in controller.orderModel.value.products!) {
                                                              controller.addToCart(cartProductModel: element);
                                                              ShowToastDialog.showToast("Item Added In a cart");
                                                            }
                                                          },
                                                        );
                                                      } else {
                                                        if ((vendorModel.subscriptionExpiryDate != null && vendorModel.subscriptionExpiryDate!.toDate().isBefore(DateTime.now()) == false) ||
                                                            vendorModel.subscriptionPlan?.expiryDay == '-1') {
                                                          if (vendorModel.subscriptionTotalOrders != '0') {
                                                            return RoundedButtonFill(
                                                              title: "Reorder",
                                                              height: 5.5,
                                                              color: AppThemeData.warning300,
                                                              textColor: AppThemeData.grey900,
                                                              onPress: () async {
                                                                for (var element in controller.orderModel.value.products!) {
                                                                  controller.addToCart(cartProductModel: element);
                                                                  ShowToastDialog.showToast("Item Added In a cart");
                                                                }
                                                              },
                                                            );
                                                          } else {
                                                            return SizedBox();
                                                          }
                                                        } else {
                                                          return SizedBox();
                                                        }
                                                      }
                                                    } else {
                                                      return RoundedButtonFill(
                                                        title: "Reorder",
                                                        height: 5.5,
                                                        color: AppThemeData.warning300,
                                                        textColor: AppThemeData.grey900,
                                                        onPress: () async {
                                                          for (var element in controller.orderModel.value.products!) {
                                                            controller.addToCart(cartProductModel: element);
                                                            ShowToastDialog.showToast("Item Added In a cart");
                                                          }
                                                        },
                                                      );
                                                    }
                                                  }
                                                }
                                              });
                                        }
                                      }
                                    }
                                  }),
                        ),
                      )
                    : const SizedBox(),
          );
        });
  }

  void showBillBifurcationDialog(BuildContext context, bool isDark, OrderDetailsController controller) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: isDark ? AppThemeData.grey900 : AppThemeData.grey50,
          insetPadding: const EdgeInsets.symmetric(horizontal: 10), // 🔥 KEY FIX
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: SizedBox(
            width: Responsive.width(100, context), // ✅ 90% width
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  TranslatedText(
                    "Tax Details",
                    style: TextStyle(
                      fontFamily: AppThemeData.medium,
                      fontSize: 18,
                      color: isDark ? AppThemeData.grey50 : AppThemeData.grey900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  sectionDivider(isDark),
                  controller.orderModel.value.taxScope == 'product'
                      ? amountRow(
                          title: "Tax on item total",
                          amount: Constant.amountShow(
                            amount: controller.productTaxAmount.value.toString(),
                          ),
                          isDark: isDark,
                        )
                      : amountRow(
                          title: "Tax on Order Total",
                          amount: Constant.amountShow(
                            amount: controller.orderTaxAmount.value.toString(),
                          ),
                          isDark: isDark,
                        ),
                  sectionDivider(isDark),
                  if (controller.orderModel.value.takeAway != true && controller.orderModel.value.vendor?.isSelfDelivery != true)
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: controller.orderModel.value.driverDeliveryTax?.length,
                      itemBuilder: (context, index) {
                        return amountRow(
                          title: "${controller.orderModel.value.driverDeliveryTax![index].title} ${'Tax on Delivery Fee'}",
                          amount: Constant.amountShow(
                              amount: Constant.calculateTax(
                            taxModel: controller.orderModel.value.driverDeliveryTax![index],
                            amount: (controller.deliveryCharges.value).toString(),
                          ).toString()),
                          isDark: isDark,
                        );
                      },
                    ),
                  if (controller.orderModel.value.packagingTax?.isNotEmpty == true) sectionDivider(isDark),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: controller.orderModel.value.packagingTax!.length,
                    itemBuilder: (context, index) {
                      return amountRow(
                        title: "${controller.orderModel.value.packagingTax![index].title} ${'Tax on Packaging Fee'}",
                        amount: controller.packagingCharge.value == 0.0
                            ? Constant.amountShow(amount: controller.packagingCharge.value.toString())
                            : Constant.amountShow(
                                amount: Constant.calculateTax(
                                taxModel: controller.orderModel.value.packagingTax![index],
                                amount: controller.packagingCharge.value.toString(),
                              ).toString()),
                        isDark: isDark,
                      );
                    },
                  ),
                  if (controller.orderModel.value.platformTax?.isNotEmpty == true) sectionDivider(isDark),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: controller.orderModel.value.platformTax!.length,
                    itemBuilder: (context, index) {
                      return amountRow(
                        title: "${controller.orderModel.value.platformTax?[index].title} ${'Tax on Platform Fee'}",
                        amount: Constant.amountShow(
                            amount: controller.platformFee.value == 0.0
                                ? Constant.calculateTax(amount: controller.platformFee.value.toString()).toString()
                                : Constant.calculateTax(
                                    taxModel: controller.orderModel.value.platformTax![index],
                                    amount: controller.platformFee.value.toString(),
                                  ).toString()),
                        isDark: isDark,
                      );
                    },
                  ),
                  sectionDivider(isDark),
                  amountRow(
                    title: "Total Tax Amount",
                    amount: Constant.amountShow(amount: controller.totalTaxAmount.value.toString()),
                    amountColor: AppThemeData.primary300,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: TranslatedText("Close"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget amountRow({
    required String title,
    required String amount,
    required bool isDark,
    Color? textColour,
    Color? amountColor,
    bool? underline,
    Widget? trailing,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TranslatedText(
            title,
            style: TextStyle(
                fontFamily: AppThemeData.regular,
                color: textColour ?? (isDark ? AppThemeData.grey300 : AppThemeData.grey600),
                fontSize: 16,
                decoration: underline == true ? TextDecoration.underline : TextDecoration.none),
          ),
        ),
        trailing ??
            Text(
              amount,
              style: TextStyle(
                fontFamily: AppThemeData.regular,
                color: amountColor ?? (isDark ? AppThemeData.grey50 : AppThemeData.grey900),
                fontSize: 16,
              ),
            ),
      ],
    );
  }

  Widget sectionDivider(bool isDark) {
    return Column(
      children: [
        const SizedBox(height: 10),
        MySeparator(color: isDark ? AppThemeData.grey700 : AppThemeData.grey200),
        const SizedBox(height: 10),
      ],
    );
  }
}
