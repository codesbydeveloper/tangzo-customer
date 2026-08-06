import 'package:customer/app/wallet_screen/wallet_screen.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/controllers/cart_controller.dart';
import 'package:customer/themes/app_them_data.dart';
import 'package:customer/themes/round_button_fill.dart';
import 'package:customer/utils/dark_theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:customer/widget/translated_text.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class SelectPaymentScreen extends StatelessWidget {
  const SelectPaymentScreen({super.key});

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
            centerTitle: false,
            titleSpacing: 0,
            title: TranslatedText(
              "Payment Option",
              textAlign: TextAlign.start,
              style: TextStyle(
                fontFamily: AppThemeData.medium,
                fontSize: 16,
                color: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey900,
              ),
            ),
          ),
          body: controller.isLoading.value == true
              ? Align(
                  alignment: Alignment.center,
                  child: TranslatedText(
                    "Loading, please wait...",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppThemeData.semiBold,
                      fontSize: 16,
                      color: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey900,
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TranslatedText(
                          "Preferred Payment",
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
                              borderRadius: BorderRadius.circular(16),
                            ),
                            shadows: const [
                              BoxShadow(
                                color: Color(0x07000000),
                                blurRadius: 20,
                                offset: Offset(0, 0),
                                spreadRadius: 0,
                              )
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                cardDecoration(controller, PaymentGateway.cashfree, themeChange, "assets/images/cashfree.png"),
                                // Wallet, COD and other gateways disabled — Cashfree only
                                // Visibility(visible: controller.walletSettingModel.value.isEnabled == true, child: cardDecoration(controller, PaymentGateway.wallet, themeChange, "assets/images/ic_wallet.png")),
                                // Visibility(visible: controller.cashOnDeliverySettingModel.value.isEnabled == true, child: cardDecoration(controller, PaymentGateway.cod, themeChange, "assets/images/ic_cash.png")),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
                color: themeChange.getThem() ? AppThemeData.grey900 : AppThemeData.grey50, borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: RoundedButtonFill(
                title: "${'Pay Now'} | ${Constant.amountShow(amount: controller.totalAmount.value.toString())}",
                height: 5,
                color: AppThemeData.primary300,
                textColor: AppThemeData.grey50,
                fontSizes: 16,
                onPress: () async {
                  Get.back();
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Obx cardDecoration(CartController controller, PaymentGateway value, themeChange, String image) {
    return Obx(
      () => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Column(
          children: [
            InkWell(
              onTap: () {
                controller.selectedPaymentMethod.value = value.name;
              },
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: ShapeDecoration(
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(width: 1, color: Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(value.name == "payFast" ? 0 : 8.0),
                      child: Image.asset(
                        image,
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  value.name == "wallet"
                      ? Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TranslatedText(
                                value.name.toString().capitalizeFirst ?? '',
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                  fontFamily: AppThemeData.medium,
                                  fontSize: 16,
                                  color: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey900,
                                ),
                              ),
                              Text(
                                Constant.amountShow(amount: controller.userModel.value.walletAmount == null ? '0.0' : controller.userModel.value.walletAmount.toString()),
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                  fontFamily: AppThemeData.semiBold,
                                  fontSize: 16,
                                  color: themeChange.getThem() ? AppThemeData.primary300 : AppThemeData.primary300,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Expanded(
                          child: TranslatedText(
                            value.name.toString().capitalizeFirst ?? '',
                            textAlign: TextAlign.start,
                            style: TextStyle(
                              fontFamily: AppThemeData.medium,
                              fontSize: 16,
                              color: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey900,
                            ),
                          ),
                        ),
                  const Expanded(
                    child: SizedBox(),
                  ),
                  Radio(
                    value: value.name,
                    groupValue: controller.selectedPaymentMethod.value,
                    activeColor: themeChange.getThem() ? AppThemeData.primary300 : AppThemeData.primary300,
                    onChanged: (value) {
                      controller.selectedPaymentMethod.value = value.toString();
                    },
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
