import 'package:bottom_picker/bottom_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Constant;
import 'package:customer/app/address_screens/address_list_screen.dart';
import 'package:customer/app/cart_screen/coupon_list_screen.dart';
import 'package:customer/app/cart_screen/select_payment_screen.dart';
import 'package:customer/app/restaurant_details_screen/restaurant_details_screen.dart';
import 'package:customer/app/wallet_screen/wallet_screen.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/controllers/cart_controller.dart';
import 'package:customer/controllers/phonepay_controller.dart';
import 'package:customer/models/cart_product_model.dart';
import 'package:customer/models/product_model.dart';
import 'package:customer/models/user_model.dart';
import 'package:customer/payment/createRazorPayOrderModel.dart';
import 'package:customer/payment/rozorpayConroller.dart';
import 'package:customer/themes/app_them_data.dart';
import 'package:customer/themes/responsive.dart';
import 'package:customer/themes/round_button_fill.dart';
import 'package:customer/themes/text_field_widget.dart';
import 'package:customer/utils/dark_theme_provider.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:customer/utils/network_image_widget.dart';
import 'package:customer/widget/my_separator.dart';
import 'package:flutter/material.dart';
import 'package:customer/widget/translated_text.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX(
        init: CartController(),
        builder: (controller) {
          return Scaffold(
            backgroundColor: themeChange.getThem() ? AppThemeData.surfaceDark : AppThemeData.surface,
            appBar: AppBar(
              backgroundColor: themeChange.getThem() ? AppThemeData.surfaceDark : AppThemeData.surface,
            ),
            body: cartItem.isEmpty
                ? Constant.showEmptyView(message: "Item Not available")
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        controller.selectedFoodType.value == 'TakeAway'
                            ? const SizedBox()
                            : Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: InkWell(
                                  onTap: () {
                                    Get.to(const AddressListScreen())!.then(
                                      (value) {
                                        if (value != null) {
                                          ShippingAddress addressModel = value;
                                          controller.selectedAddress.value = addressModel;
                                          controller.calculatePrice();
                                        }
                                      },
                                    );
                                  },
                                  child: Column(
                                    children: [
                                      Container(
                                        decoration: ShapeDecoration(
                                          color: themeChange.getThem() ? AppThemeData.grey900 : AppThemeData.grey50,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(10),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.start,
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  SvgPicture.asset(
                                                    "assets/icons/ic_send_one.svg",
                                                    colorFilter: ColorFilter.mode(AppThemeData.primary300, BlendMode.srcIn),
                                                  ),
                                                  const SizedBox(
                                                    width: 10,
                                                  ),
                                                  Expanded(
                                                    child: TranslatedText(
                                                      controller.selectedAddress.value.addressAs.toString(),
                                                      textAlign: TextAlign.start,
                                                      style: TextStyle(
                                                        fontFamily: AppThemeData.semiBold,
                                                        color: themeChange.getThem() ? AppThemeData.primary300 : AppThemeData.primary300,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ),
                                                  SvgPicture.asset("assets/icons/ic_down.svg"),
                                                ],
                                              ),
                                              const SizedBox(
                                                height: 5,
                                              ),
                                              TranslatedText(
                                                controller.selectedAddress.value.getFullAddress(),
                                                textAlign: TextAlign.start,
                                                style: TextStyle(
                                                  fontFamily: AppThemeData.medium,
                                                  color: themeChange.getThem() ? AppThemeData.grey400 : AppThemeData.grey500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            decoration: ShapeDecoration(
                              color: themeChange.getThem() ? AppThemeData.grey900 : AppThemeData.grey50,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                              child: ListView.separated(
                                shrinkWrap: true,
                                padding: EdgeInsets.zero,
                                itemCount: cartItem.length,
                                physics: const NeverScrollableScrollPhysics(),
                                itemBuilder: (context, index) {
                                  CartProductModel cartProductModel = cartItem[index];
                                  ProductModel? productModel;
                                  FireStoreUtils.getProductById(cartProductModel.id!.split('~').first).then((value) {
                                    productModel = value;
                                  });
                                  return InkWell(
                                    onTap: () async {
                                      await FireStoreUtils.getVendorById(productModel!.vendorID.toString()).then(
                                        (value) {
                                          if (value != null) {
                                            Get.to(const RestaurantDetailsScreen(), arguments: {"vendorModel": value});
                                          }
                                        },
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              ClipRRect(
                                                borderRadius: const BorderRadius.all(Radius.circular(16)),
                                                child: NetworkImageWidget(
                                                  imageUrl: cartProductModel.photo.toString(),
                                                  height: Responsive.height(10, context),
                                                  width: Responsive.width(20, context),
                                                  fit: BoxFit.cover,
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
                                                      "${cartProductModel.name}",
                                                      textAlign: TextAlign.start,
                                                      style: TextStyle(
                                                        fontFamily: AppThemeData.regular,
                                                        color: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey900,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                    double.parse(cartProductModel.discountPrice.toString()) <= 0
                                                        ? Text(
                                                            Constant.amountShow(amount: cartProductModel.price),
                                                            style: TextStyle(
                                                              fontSize: 16,
                                                              color: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey900,
                                                              fontFamily: AppThemeData.semiBold,
                                                              fontWeight: FontWeight.w600,
                                                            ),
                                                          )
                                                        : SingleChildScrollView(
                                                            scrollDirection: Axis.horizontal,
                                                            child: Row(
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
                                                            )
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                width: Responsive.width(26, context),
                                                decoration: ShapeDecoration(
                                                  color: themeChange.getThem() ? AppThemeData.grey900 : AppThemeData.grey50,
                                                  shape: RoundedRectangleBorder(
                                                    side: const BorderSide(width: 1, color: Color(0xFFD1D5DB)),
                                                    borderRadius: BorderRadius.circular(200),
                                                  ),
                                                ),
                                                child: Padding(
                                                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 5),
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    crossAxisAlignment: CrossAxisAlignment.center,
                                                    children: [
                                                      InkWell(
                                                          onTap: () {
                                                            controller.addToCart(cartProductModel: cartProductModel, isIncrement: false, quantity: cartProductModel.quantity! - 1);
                                                          },
                                                          child: const Icon(Icons.remove)),
                                                      Padding(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                                        child: Text(
                                                          cartProductModel.quantity.toString(),
                                                          textAlign: TextAlign.start,
                                                          maxLines: 1,
                                                          style: TextStyle(
                                                            fontSize: 16,
                                                            overflow: TextOverflow.ellipsis,
                                                            fontFamily: AppThemeData.medium,
                                                            fontWeight: FontWeight.w500,
                                                            color: themeChange.getThem() ? AppThemeData.grey100 : AppThemeData.grey800,
                                                          ),
                                                        ),
                                                      ),
                                                      InkWell(
                                                          onTap: () {
                                                            if (productModel?.itemAttribute != null) {
                                                              if (productModel!.itemAttribute!.variants!
                                                                  .where((element) => element.variantSku == cartProductModel.variantInfo!.variantSku)
                                                                  .isNotEmpty) {
                                                                if (int.parse(productModel!.itemAttribute!.variants!
                                                                            .where((element) => element.variantSku == cartProductModel.variantInfo!.variantSku)
                                                                            .first
                                                                            .variantQuantity
                                                                            .toString()) >
                                                                        (cartProductModel.quantity ?? 0) ||
                                                                    int.parse(productModel!.itemAttribute!.variants!
                                                                            .where((element) => element.variantSku == cartProductModel.variantInfo!.variantSku)
                                                                            .first
                                                                            .variantQuantity
                                                                            .toString()) ==
                                                                        -1) {
                                                                  controller.addToCart(cartProductModel: cartProductModel, isIncrement: true, quantity: cartProductModel.quantity! + 1);
                                                                } else {
                                                                  ShowToastDialog.showToast("Out of stock");
                                                                }
                                                              } else {
                                                                if ((productModel?.quantity ?? 0) > (cartProductModel.quantity ?? 0) || productModel!.quantity == -1) {
                                                                  controller.addToCart(cartProductModel: cartProductModel, isIncrement: true, quantity: cartProductModel.quantity! + 1);
                                                                } else {
                                                                  ShowToastDialog.showToast("Out of stock");
                                                                }
                                                              }
                                                            } else {
                                                              if ((productModel?.quantity ?? 0) > (cartProductModel.quantity ?? 0) || productModel!.quantity == -1) {
                                                                controller.addToCart(cartProductModel: cartProductModel, isIncrement: true, quantity: cartProductModel.quantity! + 1);
                                                              } else {
                                                                ShowToastDialog.showToast("Out of stock");
                                                              }
                                                            }
                                                          },
                                                          child: const Icon(Icons.add)),
                                                    ],
                                                  ),
                                                ),
                                              )
                                            ],
                                          ),
                                          cartProductModel.variantInfo == null || cartProductModel.variantInfo!.variantOptions == null || cartProductModel.variantInfo!.variantOptions!.isEmpty
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
                                          cartProductModel.extras == null || cartProductModel.extras!.isEmpty || cartProductModel.extrasPrice == '0'
                                              ? const SizedBox()
                                              : Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    const SizedBox(
                                                      height: 10,
                                                    ),
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
                                                    const SizedBox(
                                                      height: 5,
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
                                        ],
                                      ),
                                    ),
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
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TranslatedText(
                                "${'Delivery Type'} ${'(${controller.selectedFoodType.value})'}",
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                  fontFamily: AppThemeData.semiBold,
                                  color: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey900,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              controller.selectedFoodType.value == 'TakeAway'
                                  ? const SizedBox()
                                  : Container(
                                      width: Responsive.width(100, context),
                                      decoration: ShapeDecoration(
                                        color: themeChange.getThem() ? AppThemeData.grey900 : AppThemeData.grey50,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  TranslatedText(
                                                    "Instant Delivery",
                                                    textAlign: TextAlign.start,
                                                    style: TextStyle(
                                                      fontFamily: AppThemeData.medium,
                                                      color: themeChange.getThem() ? AppThemeData.primary300 : AppThemeData.primary300,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                    height: 5,
                                                  ),
                                                  TranslatedText(
                                                    "Standard",
                                                    textAlign: TextAlign.start,
                                                    style: TextStyle(
                                                      fontFamily: AppThemeData.medium,
                                                      fontSize: 12,
                                                      color: themeChange.getThem() ? AppThemeData.grey400 : AppThemeData.grey500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Radio(
                                              value: controller.deliveryType.value,
                                              groupValue: "instant",
                                              activeColor: AppThemeData.primary300,
                                              onChanged: (value) {
                                                controller.deliveryType.value = "instant";
                                              },
                                            )
                                          ],
                                        ),
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
                                child: InkWell(
                                  onTap: () {
                                    controller.deliveryType.value = "schedule";
                                    BottomPicker.dateTime(
                                      onSubmit: (index) {
                                        controller.scheduleDateTime.value = index;
                                      },
                                      minDateTime: DateTime.now(),
                                      displaySubmitButton: true,
                                      pickerTitle: TranslatedText('Schedule Time'),
                                      buttonSingleColor: AppThemeData.primary300,
                                    ).show(context);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              TranslatedText(
                                                "Schedule Time",
                                                textAlign: TextAlign.start,
                                                style: TextStyle(
                                                  fontFamily: AppThemeData.medium,
                                                  color: themeChange.getThem() ? AppThemeData.primary300 : AppThemeData.primary300,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(
                                                height: 5,
                                              ),
                                              TranslatedText(
                                                "${'Your preferred time'} ${controller.deliveryType.value == "schedule" ? Constant.timestampToDateTime(Timestamp.fromDate(controller.scheduleDateTime.value)) : ""}",
                                                textAlign: TextAlign.start,
                                                style: TextStyle(
                                                  fontFamily: AppThemeData.medium,
                                                  fontSize: 12,
                                                  color: themeChange.getThem() ? AppThemeData.grey400 : AppThemeData.grey500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Radio(
                                          value: controller.deliveryType.value,
                                          groupValue: "schedule",
                                          activeColor: AppThemeData.primary300,
                                          onChanged: (value) {
                                            controller.deliveryType.value = "schedule";
                                            BottomPicker.dateTime(
                                              initialDateTime: controller.scheduleDateTime.value,
                                              onSubmit: (index) {
                                                controller.scheduleDateTime.value = index;
                                              },
                                              minDateTime: controller.scheduleDateTime.value,
                                              displaySubmitButton: true,
                                              pickerTitle: TranslatedText('Schedule Time'),
                                              buttonSingleColor: AppThemeData.primary300,
                                            ).show(context);
                                          },
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TranslatedText(
                                "Offers & Benefits",
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                  fontFamily: AppThemeData.semiBold,
                                  color: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey900,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              InkWell(
                                onTap: () {
                                  Get.to(const CouponListScreen());
                                },
                                child: Container(
                                  width: Responsive.width(100, context),
                                  decoration: ShapeDecoration(
                                    color: themeChange.getThem() ? AppThemeData.grey900 : AppThemeData.grey50,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    shadows: const [
                                      BoxShadow(
                                        color: Color(0x14000000),
                                        blurRadius: 52,
                                        offset: Offset(0, 0),
                                        spreadRadius: 0,
                                      )
                                    ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: TranslatedText(
                                            "Apply Coupons",
                                            textAlign: TextAlign.start,
                                            style: TextStyle(
                                              fontFamily: AppThemeData.semiBold,
                                              color: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey900,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 5,
                                        ),
                                        const Icon(Icons.keyboard_arrow_right)
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TranslatedText(
                                "Bill Details",
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                  fontFamily: AppThemeData.semiBold,
                                  color: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey900,
                                  fontSize: 16,
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

                                      const SizedBox(height: 10),

                                      /// Coupon Discount
                                      amountRow(
                                        title: "Coupon Discount",
                                        amount: "- (${Constant.amountShow(amount: controller.couponAmount.value.toString())})",
                                        isDark: themeChange.getThem(),
                                        amountColor: AppThemeData.danger300,
                                      ),

                                      /// Special Discount
                                      if (controller.vendorModel.value.specialDiscountEnable == true && Constant.specialDiscountOffer == true) ...[
                                        const SizedBox(height: 10),
                                        amountRow(
                                          title: "Special Discount",
                                          amount: "- (${Constant.amountShow(amount: controller.specialDiscountAmount.value.toString())})",
                                          isDark: themeChange.getThem(),
                                          amountColor: AppThemeData.danger300,
                                        ),
                                      ],

                                      const SizedBox(height: 10),

                                      /// Packaging
                                      amountRow(
                                        title: "Packaging charge",
                                        amount: Constant.amountShow(amount: controller.packagingCharge.value.toString()),
                                        isDark: themeChange.getThem(),
                                      ),

                                      sectionDivider(themeChange.getThem()),

                                      /// Delivery Fee
                                      if (controller.selectedFoodType.value != 'TakeAway')
                                        amountRow(
                                          title: "Delivery Fee",
                                          isDark: themeChange.getThem(),
                                          trailing:
                                              ((controller.vendorModel.value.isSelfDelivery == true && Constant.isSelfDeliveryFeature == true) || controller.isEnableFreeDeliveryByAdmin.value == true)
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
                                      if (!(controller.selectedFoodType.value == 'TakeAway' ||
                                          controller.isEnableFreeDeliveryByAdmin.value == true ||
                                          (controller.vendorModel.value.isSelfDelivery == true && Constant.isSelfDeliveryFeature == true))) ...[
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
                                                  if (controller.deliveryTips.value != 0)
                                                    InkWell(
                                                      onTap: () {
                                                        controller.deliveryTips.value = 0;
                                                        controller.calculatePrice();
                                                      },
                                                      child: TranslatedText(
                                                        "Remove",
                                                        style: TextStyle(
                                                          fontFamily: AppThemeData.medium,
                                                          color: AppThemeData.primary300,
                                                        ),
                                                      ),
                                                    ),
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
                                      if (!(controller.selectedFoodType.value == 'TakeAway' ||
                                          controller.isEnableFreeDeliveryByAdmin.value == true ||
                                          (controller.vendorModel.value.isSelfDelivery == true && Constant.isSelfDeliveryFeature == true)))
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
                              )
                            ],
                          ),
                        ),
                        ((controller.selectedFoodType.value == 'TakeAway' || (controller.vendorModel.value.isSelfDelivery == true && Constant.isSelfDeliveryFeature == true)) ||
                                controller.isEnableFreeDeliveryByAdmin.value == true)
                            ? const SizedBox()
                            : Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    TranslatedText(
                                      "Thanks with a tip!",
                                      textAlign: TextAlign.start,
                                      style: TextStyle(
                                        fontFamily: AppThemeData.semiBold,
                                        color: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey900,
                                        fontSize: 16,
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
                                            offset: Offset(0, 0),
                                            spreadRadius: 0,
                                          )
                                        ],
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
                                                    "Around the clock, our delivery partners bring you your favorite meals. Show your appreciation with a tip.",
                                                    textAlign: TextAlign.start,
                                                    style: TextStyle(
                                                      fontFamily: AppThemeData.medium,
                                                      color: themeChange.getThem() ? AppThemeData.grey300 : AppThemeData.grey600,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(
                                                  width: 10,
                                                ),
                                                SvgPicture.asset("assets/images/ic_tips.svg")
                                              ],
                                            ),
                                            const SizedBox(
                                              height: 20,
                                            ),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: InkWell(
                                                    onTap: () {
                                                      controller.deliveryTips.value = 20;
                                                      controller.calculatePrice();
                                                    },
                                                    child: Container(
                                                      decoration: ShapeDecoration(
                                                        shape: RoundedRectangleBorder(
                                                          side: BorderSide(
                                                              width: 1,
                                                              color: controller.deliveryTips.value == 20
                                                                  ? AppThemeData.primary300
                                                                  : themeChange.getThem()
                                                                      ? AppThemeData.grey800
                                                                      : AppThemeData.grey100),
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                      ),
                                                      child: Padding(
                                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                                        child: Center(
                                                          child: Text(
                                                            Constant.amountShow(amount: "20"),
                                                            style: TextStyle(
                                                              color: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey900,
                                                              fontSize: 14,
                                                              fontFamily: AppThemeData.medium,
                                                              fontWeight: FontWeight.w600,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(
                                                  width: 10,
                                                ),
                                                Expanded(
                                                  child: InkWell(
                                                    onTap: () {
                                                      controller.deliveryTips.value = 30;
                                                      controller.calculatePrice();
                                                    },
                                                    child: Container(
                                                      decoration: ShapeDecoration(
                                                        shape: RoundedRectangleBorder(
                                                          side: BorderSide(
                                                              width: 1,
                                                              color: controller.deliveryTips.value == 30
                                                                  ? AppThemeData.primary300
                                                                  : themeChange.getThem()
                                                                      ? AppThemeData.grey800
                                                                      : AppThemeData.grey100),
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                      ),
                                                      child: Padding(
                                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                                        child: Center(
                                                          child: Text(
                                                            Constant.amountShow(amount: "30"),
                                                            style: TextStyle(
                                                              color: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey900,
                                                              fontSize: 14,
                                                              fontFamily: AppThemeData.medium,
                                                              fontWeight: FontWeight.w600,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(
                                                  width: 10,
                                                ),
                                                Expanded(
                                                  child: InkWell(
                                                    onTap: () {
                                                      controller.deliveryTips.value = 40;
                                                      controller.calculatePrice();
                                                    },
                                                    child: Container(
                                                      decoration: ShapeDecoration(
                                                        shape: RoundedRectangleBorder(
                                                          side: BorderSide(
                                                              width: 1,
                                                              color: controller.deliveryTips.value == 40
                                                                  ? AppThemeData.primary300
                                                                  : themeChange.getThem()
                                                                      ? AppThemeData.grey800
                                                                      : AppThemeData.grey100),
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                      ),
                                                      child: Padding(
                                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                                        child: Center(
                                                          child: Text(
                                                            Constant.amountShow(amount: "40"),
                                                            style: TextStyle(
                                                              color: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey900,
                                                              fontSize: 14,
                                                              fontFamily: AppThemeData.medium,
                                                              fontWeight: FontWeight.w600,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(
                                                  width: 10,
                                                ),
                                                Expanded(
                                                  child: InkWell(
                                                    onTap: () {
                                                      showDialog(
                                                        context: context,
                                                        builder: (BuildContext context) {
                                                          return tipsDialog(controller, themeChange);
                                                        },
                                                      );
                                                    },
                                                    child: Container(
                                                      decoration: ShapeDecoration(
                                                        shape: RoundedRectangleBorder(
                                                          side: BorderSide(width: 1, color: themeChange.getThem() ? AppThemeData.grey800 : AppThemeData.grey100),
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                      ),
                                                      child: Padding(
                                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                                        child: Center(
                                                          child: TranslatedText(
                                                            'Other',
                                                            style: TextStyle(
                                                              color: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey900,
                                                              fontSize: 14,
                                                              fontFamily: AppThemeData.medium,
                                                              fontWeight: FontWeight.w600,
                                                            ),
                                                          ),
                                                        ),
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
                                  ],
                                ),
                              ),
                        const SizedBox(
                          height: 20,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              TextFieldWidget(
                                title: 'Remarks',
                                controller: controller.reMarkController.value,
                                hintText: 'Write remarks for the restaurant',
                                maxLine: 4,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
            bottomNavigationBar: cartItem.isEmpty
                ? null
                : Container(
                    decoration: BoxDecoration(color: themeChange.getThem() ? AppThemeData.grey900 : AppThemeData.grey50),
                    height: controller.selectedPaymentMethod.value == ''
                        ? 100
                        : controller.isCashbackApply.value == true
                            ? controller.isEnableFreeDeliveryByAdmin.value == false &&
                                    controller.freeDeliveryByAdminModel.value.isEnableFreeDelivery == true &&
                                    controller.selectedFoodType.value != 'TakeAway'
                                ? 200
                                : 170
                            : controller.freeDeliveryByAdminModel.value.isEnableFreeDelivery == true &&
                                    controller.isEnableFreeDeliveryByAdmin.value == false &&
                                    controller.selectedFoodType.value != 'TakeAway'
                                ? 170
                                : 100,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (controller.isCashbackApply.value == true && controller.selectedPaymentMethod.value != '')
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: TranslatedText(
                                    "Cashback Offer",
                                    style: TextStyle(
                                      color: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey900,
                                      fontFamily: AppThemeData.semiBold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                TranslatedText(
                                  "${"Cashback Name :"} ${controller.bestCashback.value.title ?? ''}",
                                  style: TextStyle(
                                    color: AppThemeData.darkGreen,
                                    fontFamily: AppThemeData.semiBold,
                                    fontSize: 13,
                                  ),
                                ),
                                TranslatedText(
                                  "${"You will get"} ${Constant.amountShow(amount: controller.bestCashback.value.cashbackValue?.toStringAsFixed(2))} ${"cashback after completing the order."}",
                                  style: TextStyle(
                                    color: AppThemeData.darkGreen,
                                    fontFamily: AppThemeData.semiBold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if ((controller.isEnableFreeDeliveryByAdmin.value == false &&
                                controller.freeDeliveryByAdminModel.value.isEnableFreeDelivery == true &&
                                controller.selectedFoodType.value != 'TakeAway') &&
                            controller.selectedPaymentMethod.value != '')
                          Padding(
                            padding: EdgeInsets.only(
                                left: 16, right: 16, top: (controller.freeDeliveryByAdminModel.value.isEnableFreeDelivery == true && controller.isEnableFreeDeliveryByAdmin.value == false) ? 10 : 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 25,
                                      height: 25,
                                      decoration: const BoxDecoration(image: DecorationImage(image: AssetImage("assets/images/offer_gif.gif"), fit: BoxFit.fill)),
                                      child: Center(
                                          child: TranslatedText(
                                        "%",
                                        style: TextStyle(
                                            color: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey50, fontFamily: AppThemeData.semiBold, fontWeight: FontWeight.w600, fontSize: 12),
                                      )),
                                    ),
                                    TranslatedText(
                                      "${'Buy'} ${Constant.amountShow(amount: "${double.parse("${controller.freeDeliveryByAdminModel.value.freeDeliveryOver ?? 0.0}") - controller.subTotal.value}")} ${"more for free delivery"}",
                                      style: TextStyle(
                                        color: AppThemeData.primary300,
                                        fontFamily: AppThemeData.semiBold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        Padding(
                          padding: EdgeInsets.only(left: 16, right: 16, top: controller.isCashbackApply.value == false ? 16 : 12, bottom: 20),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: InkWell(
                                  onTap: () {
                                    Get.to(const SelectPaymentScreen())?.then((v) {
                                      controller.getCashback();
                                    });
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      controller.selectedPaymentMethod.value == ''
                                          ? cardDecoration(controller, PaymentGateway.wallet, themeChange, "")
                                          : controller.selectedPaymentMethod.value == PaymentGateway.wallet.name
                                              ? cardDecoration(controller, PaymentGateway.wallet, themeChange, "assets/images/ic_wallet.png")
                                              : controller.selectedPaymentMethod.value == PaymentGateway.cod.name
                                                  ? cardDecoration(controller, PaymentGateway.cod, themeChange, "assets/images/ic_cash.png")
                                                  : controller.selectedPaymentMethod.value == PaymentGateway.stripe.name
                                                      ? cardDecoration(controller, PaymentGateway.stripe, themeChange, "assets/images/stripe.png")
                                                      : controller.selectedPaymentMethod.value == PaymentGateway.paypal.name
                                                          ? cardDecoration(controller, PaymentGateway.paypal, themeChange, "assets/images/paypal.png")
                                                          : controller.selectedPaymentMethod.value == PaymentGateway.payStack.name
                                                              ? cardDecoration(controller, PaymentGateway.payStack, themeChange, "assets/images/paystack.png")
                                                              : controller.selectedPaymentMethod.value == PaymentGateway.mercadoPago.name
                                                                  ? cardDecoration(controller, PaymentGateway.mercadoPago, themeChange, "assets/images/mercado-pago.png")
                                                                  : controller.selectedPaymentMethod.value == PaymentGateway.flutterWave.name
                                                                      ? cardDecoration(controller, PaymentGateway.flutterWave, themeChange, "assets/images/flutterwave_logo.png")
                                                                      : controller.selectedPaymentMethod.value == PaymentGateway.payFast.name
                                                                          ? cardDecoration(controller, PaymentGateway.payFast, themeChange, "assets/images/payfast.png")
                                                                          : controller.selectedPaymentMethod.value == PaymentGateway.paytm.name
                                                                              ? cardDecoration(controller, PaymentGateway.paytm, themeChange, "assets/images/paytm.png")
                                                                              : controller.selectedPaymentMethod.value == PaymentGateway.midTrans.name
                                                                                  ? cardDecoration(controller, PaymentGateway.midTrans, themeChange, "assets/images/midtrans.png")
                                                                                  : controller.selectedPaymentMethod.value == PaymentGateway.orangeMoney.name
                                                                                      ? cardDecoration(controller, PaymentGateway.orangeMoney, themeChange, "assets/images/orange_money.png")
                                                                                      : controller.selectedPaymentMethod.value == PaymentGateway.xendit.name
                                                                                          ? cardDecoration(controller, PaymentGateway.mtnMomo, themeChange, "assets/images/xendit.png")
                                                                                          : controller.selectedPaymentMethod.value == PaymentGateway.razorpay.name
                                                                                              ? cardDecoration(controller, PaymentGateway.razorpay, themeChange, "assets/images/razorpay.png")
                                                                                              : controller.selectedPaymentMethod.value == PaymentGateway.mtnMomo.name
                                                                                                  ? cardDecoration(controller, PaymentGateway.razorpay, themeChange, "assets/images/mtnmom.png")
                                                                                                  : controller.selectedPaymentMethod.value == PaymentGateway.phonePe.name
                                                                                                      ? cardDecoration(controller, PaymentGateway.razorpay, themeChange, "assets/images/phonepe.png")
                                                                                                      : controller.selectedPaymentMethod.value == PaymentGateway.cashfree.name
                                                                                                          ? cardDecoration(
                                                                                                              controller, PaymentGateway.razorpay, themeChange, "assets/images/cashfree.png")
                                                                                                          : controller.selectedPaymentMethod.value == PaymentGateway.instamojo.name
                                                                                                              ? cardDecoration(
                                                                                                                  controller, PaymentGateway.razorpay, themeChange, "assets/images/instamojo.png")
                                                                                                              : controller.selectedPaymentMethod.value == PaymentGateway.foloosi.name
                                                                                                                  ? cardDecoration(
                                                                                                                      controller, PaymentGateway.razorpay, themeChange, "assets/images/foloosi.png")
                                                                                                                  : controller.selectedPaymentMethod.value == PaymentGateway.payMongo.name
                                                                                                                      ? cardDecoration(controller, PaymentGateway.razorpay, themeChange,
                                                                                                                          "assets/images/payMongo.png")
                                                                                                                      : const SizedBox(
                                                                                                                          width: 10,
                                                                                                                        ),
                                      Padding(
                                        padding: const EdgeInsets.only(left: 8, right: 8),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            TranslatedText(
                                              "Pay Via",
                                              textAlign: TextAlign.start,
                                              style: TextStyle(
                                                fontFamily: AppThemeData.semiBold,
                                                color: themeChange.getThem() ? AppThemeData.grey400 : AppThemeData.grey500,
                                                fontSize: 12,
                                              ),
                                            ),
                                            controller.selectedPaymentMethod.value == ''
                                                ? Padding(
                                                    padding: const EdgeInsets.only(top: 4),
                                                    child: Container(width: 60, height: 12, color: themeChange.getThem() ? AppThemeData.grey800 : AppThemeData.grey100),
                                                  )
                                                : Row(
                                                    children: [
                                                      TranslatedText(
                                                        controller.selectedPaymentMethod.value,
                                                        textAlign: TextAlign.start,
                                                        style: TextStyle(
                                                          fontFamily: AppThemeData.semiBold,
                                                          color: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey900,
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                      SizedBox(width: 5),
                                                      TranslatedText(
                                                        "(Change)",
                                                        textAlign: TextAlign.start,
                                                        style: TextStyle(
                                                          fontFamily: AppThemeData.semiBold,
                                                          color: AppThemeData.primary300,
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Expanded(
                                child: RoundedButtonFill(
                                  textColor: controller.selectedPaymentMethod.value != ''
                                      ? AppThemeData.surface
                                      : themeChange.getThem()
                                          ? AppThemeData.grey800
                                          : AppThemeData.grey100,
                                  isEnabled: controller.selectedPaymentMethod.value != '',
                                  title: "Pay Now",
                                  height: 5,
                                  color: controller.selectedPaymentMethod.value != ''
                                      ? AppThemeData.primary300
                                      : themeChange.getThem()
                                          ? AppThemeData.grey800
                                          : AppThemeData.grey100,
                                  fontSizes: 16,
                                  onPress: () async {
                                    if (controller.deliveryType.value == "schedule") {
                                      bool isOpen = controller.isSelectedDateRestaurantOpen(selectedDateTime: controller.scheduleDateTime.value);
                                      if (isOpen == false) {
                                        ShowToastDialog.showToast("The restaurant will be closed at the selected scheduled time. Please choose a different date and time.");
                                        return;
                                      }
                                    }
                                    if ((controller.couponAmount.value >= 1) && (controller.couponAmount.value > controller.totalAmount.value)) {
                                      ShowToastDialog.showToast("The total price must be greater than or equal to the coupon discount value for the code to apply. Please review your cart total.");
                                      return;
                                    }
                                    if ((controller.specialDiscountAmount.value >= 1) && (controller.specialDiscountAmount.value > controller.totalAmount.value)) {
                                      ShowToastDialog.showToast("The total price must be greater than or equal to the special discount value for the code to apply. Please review your cart total.");
                                      return;
                                    }
                                    if (Constant.statusCheckOpenORClose(vendorModel: controller.vendorModel.value) != true) {
                                      ShowToastDialog.showToast("The restaurant is closed at the moment. Please try placing your order later.");
                                      return;
                                    }
                                    if (controller.isOrderPlaced.value == false) {
                                      ShowToastDialog.showLoader("Please wait");
                                      bool? isZoneAvailable = await FireStoreUtils.getNearbyVendor(
                                          latitude: controller.selectedAddress.value.location!.latitude!,
                                          longitude: controller.selectedAddress.value.location!.longitude!,
                                          vendor: controller.vendorModel.value);

                                      if (isZoneAvailable == false) {
                                        ShowToastDialog.closeLoader();
                                        ShowToastDialog.showToast("The selected product is not available at your delivery address.");
                                        return;
                                      }
                                      controller.isOrderPlaced.value = true;
                                      await controller.getCashback();
                                      if (controller.selectedPaymentMethod.value == PaymentGateway.stripe.name) {
                                        controller.stripeMakePayment(amount: controller.totalAmount.value.toString());
                                      } else if (controller.selectedPaymentMethod.value == PaymentGateway.paypal.name) {
                                        controller.paypalPaymentSheet(controller.totalAmount.value.toString(), context);
                                      } else if (controller.selectedPaymentMethod.value == PaymentGateway.payStack.name) {
                                        controller.payStackPayment(controller.totalAmount.value.toString());
                                      } else if (controller.selectedPaymentMethod.value == PaymentGateway.mercadoPago.name) {
                                        controller.mercadoPagoMakePayment(context: context, amount: controller.totalAmount.value.toString());
                                      } else if (controller.selectedPaymentMethod.value == PaymentGateway.flutterWave.name) {
                                        controller.flutterWaveInitiatePayment(context: context, amount: controller.totalAmount.value.toString());
                                      } else if (controller.selectedPaymentMethod.value == PaymentGateway.payFast.name) {
                                        controller.payFastPayment(context: context, amount: controller.totalAmount.value.toStringAsFixed(2));
                                      } else if (controller.selectedPaymentMethod.value == PaymentGateway.paytm.name) {
                                        controller.getPaytmCheckSum(context, amount: double.parse(controller.totalAmount.value.toString()));
                                      } else if (controller.selectedPaymentMethod.value == PaymentGateway.cod.name) {
                                        controller.placeOrder();
                                      } else if (controller.selectedPaymentMethod.value == PaymentGateway.wallet.name) {
                                        controller.placeOrder();
                                      } else if (controller.selectedPaymentMethod.value == PaymentGateway.midTrans.name) {
                                        controller.midtransMakePayment(context: context, amount: controller.totalAmount.value.toString());
                                      } else if (controller.selectedPaymentMethod.value == PaymentGateway.orangeMoney.name) {
                                        controller.orangeMakePayment(context: context, amount: controller.totalAmount.value.toStringAsFixed(2));
                                      } else if (controller.selectedPaymentMethod.value == PaymentGateway.xendit.name) {
                                        controller.xenditPayment(context, controller.totalAmount.value.toString());
                                      } else if (controller.selectedPaymentMethod.value == PaymentGateway.razorpay.name) {
                                        ShowToastDialog.showLoader("Please wait");
                                        RazorPayController()
                                            .createOrderRazorPay(amount: double.parse(controller.totalAmount.value.toString()), razorpayModel: controller.razorPayModel.value)
                                            .then((value) {
                                          if (value == null) {
                                            ShowToastDialog.showToast("Something went wrong, please contact admin.");
                                          } else {
                                            CreateRazorPayOrderModel result = value;
                                            controller.openCheckout(amount: controller.totalAmount.value.toString(), orderId: result.id);
                                          }
                                        });
                                      } else if (controller.selectedPaymentMethod.value.toLowerCase() == controller.mtnMomoModel.value.name?.toLowerCase()) {
                                        await controller.mtnMomoMakePayment(amount: controller.totalAmount.value.toString());
                                      } else if (controller.selectedPaymentMethod.value.toLowerCase() == controller.phonePeModel.value.name?.toLowerCase()) {
                                        PhonePePaymentService.phonePe = controller.phonePeModel.value;
                                        await PhonePePaymentService.payNow(amountInPaise: (controller.totalAmount.value * 100).round());
                                        if (PhonePePaymentService.isSucess) {
                                          controller.placeOrder();
                                        }
                                      } else if (controller.selectedPaymentMethod.value.toLowerCase() == controller.cashfreeModel.value.name?.toLowerCase()) {
                                        controller.cashFreeMakePayment(context: context, amount: controller.totalAmount.value.toString(), paymentDesc: "Order Payment");
                                      } else if (controller.selectedPaymentMethod.value.toLowerCase() == controller.instamojoModel.value.name?.toLowerCase()) {
                                        controller.makeInstamojoPayment(amount: controller.totalAmount.value.toString(), paymentDesc: "Order Payment");
                                      } else if (controller.selectedPaymentMethod.value.toLowerCase() == controller.foloosiModel.value.name?.toLowerCase()) {
                                        controller.makeFoloosiPayment(amount: controller.totalAmount.value.toString(), paymentDesc: "Order Payment");
                                      } else if (controller.selectedPaymentMethod.value.toLowerCase() == controller.payMongoModel.value.name?.toLowerCase()) {
                                        controller.makePayMongoPayment(amount: controller.totalAmount.value.toString(), paymentDesc: "Order Payment");
                                      } else {
                                        controller.isOrderPlaced.value = false;
                                        ShowToastDialog.showToast("Please select payment method");
                                        ShowToastDialog.closeLoader();
                                      }
                                      controller.isOrderPlaced.value = false;
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          );
        });
  }

  void showBillBifurcationDialog(BuildContext context, bool isDark, CartController controller) {
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
                  SizedBox(height: 10),
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
                  const SizedBox(height: 5),
                  Constant.taxScope == 'product'
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
                  if (controller.selectedFoodType.value != 'TakeAway' && controller.vendorModel.value.isSelfDelivery != true) sectionDivider(isDark),
                  if (controller.selectedFoodType.value != 'TakeAway' && controller.vendorModel.value.isSelfDelivery != true)
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: Constant.driverDeliveryTaxList!.length,
                      itemBuilder: (context, index) {
                        return amountRow(
                          title: "${Constant.driverDeliveryTaxList?[index].title} ${'Tax on Delivery Fee'}",
                          amount: Constant.amountShow(
                              amount: Constant.calculateTax(
                            taxModel: Constant.driverDeliveryTaxList![index],
                            amount: (controller.deliveryCharges.value).toString(),
                          ).toString()),
                          isDark: isDark,
                        );
                      },
                    ),
                  sectionDivider(isDark),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: Constant.packagingTaxList!.length,
                    itemBuilder: (context, index) {
                      return amountRow(
                        title: "${Constant.packagingTaxList![index].title} ${'Tax on Packaging Fee'}",
                        amount: controller.packagingCharge.value == 0.0
                            ? Constant.amountShow(amount: '0')
                            : Constant.amountShow(
                                amount: Constant.calculateTax(
                                taxModel: Constant.packagingTaxList![index],
                                amount: controller.packagingCharge.value.toString(),
                              ).toString()),
                        isDark: isDark,
                      );
                    },
                  ),
                  if (Constant.packagingTaxList!.isNotEmpty) sectionDivider(isDark),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: Constant.platformTaxList!.length,
                    itemBuilder: (context, index) {
                      return amountRow(
                        title: "${Constant.platformTaxList![index].title} ${'Tax on Platform Fee'}",
                        amount: controller.platformFee.value == 0.0
                            ? Constant.amountShow(amount: '0')
                            : Constant.amountShow(
                                amount: Constant.calculateTax(
                                taxModel: Constant.platformTaxList![index],
                                amount: controller.platformFee.value.toString(),
                              ).toString()),
                        isDark: isDark,
                      );
                    },
                  ),
                  if (Constant.platformTaxList!.isNotEmpty) sectionDivider(isDark),
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

  Padding cardDecoration(CartController controller, PaymentGateway value, themeChange, String image) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Container(
        width: 40,
        height: 40,
        decoration: ShapeDecoration(
          shape: RoundedRectangleBorder(
            side: const BorderSide(width: 1, color: Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(value.name == "payFast" ? 0 : 8.0),
          child: image == ''
              ? Container(color: themeChange.getThem() ? AppThemeData.grey800 : AppThemeData.grey100)
              : Image.asset(
                  image,
                ),
        ),
      ),
    );
  }

  Dialog tipsDialog(CartController controller, themeChange) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.all(10),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      backgroundColor: themeChange.getThem() ? AppThemeData.surfaceDark : AppThemeData.surface,
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: SizedBox(
          width: 500,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFieldWidget(
                title: 'Tips Amount',
                controller: controller.tipsController.value,
                textInputType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                textInputAction: TextInputAction.done,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp('[0-9]')),
                ],
                prefix: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Text(
                    "${Constant.currencyModel!.symbol}",
                    style: TextStyle(color: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey900, fontFamily: AppThemeData.semiBold, fontSize: 18),
                  ),
                ),
                hintText: 'Enter Tips Amount',
              ),
              Row(
                children: [
                  Expanded(
                    child: RoundedButtonFill(
                      title: "Cancel",
                      color: themeChange.getThem() ? AppThemeData.grey700 : AppThemeData.grey200,
                      textColor: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey900,
                      onPress: () async {
                        Get.back();
                      },
                    ),
                  ),
                  const SizedBox(
                    width: 20,
                  ),
                  Expanded(
                    child: RoundedButtonFill(
                      title: "Add",
                      color: AppThemeData.primary300,
                      textColor: AppThemeData.grey50,
                      onPress: () async {
                        if (controller.tipsController.value.text.isEmpty) {
                          ShowToastDialog.showToast("Please enter tips Amount");
                        } else {
                          controller.deliveryTips.value = double.parse(controller.tipsController.value.text);
                          controller.calculatePrice();
                          Get.back();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
