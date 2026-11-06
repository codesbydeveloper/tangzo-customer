import 'package:customer/app/wallet_screen/wallet_screen.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/controllers/gift_card_controller.dart';
import 'package:customer/controllers/phonepay_controller.dart';
import 'package:customer/payment/createRazorPayOrderModel.dart';
import 'package:customer/payment/rozorpayConroller.dart';
import 'package:customer/themes/app_them_data.dart';
import 'package:customer/themes/round_button_fill.dart';
import 'package:customer/utils/dark_theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:customer/widget/translated_text.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class SelectGiftPaymentScreen extends StatelessWidget {
  const SelectGiftPaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX(
      init: GiftCardController(),
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
          body: controller.isLoadingPayment.value == true
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
                                if (controller.walletSettingModel.value.isEnabled == true)
                                  cardDecoration(controller, PaymentGateway.wallet, themeChange, "assets/images/ic_wallet.png"),
                                if (controller.cashfreeModel.value.enable == true)
                                  cardDecoration(controller, PaymentGateway.cashfree, themeChange, "assets/images/cashfree.png"),
                                if (controller.stripeModel.value.isEnabled == true)
                                  cardDecoration(controller, PaymentGateway.stripe, themeChange, "assets/images/stripe.png"),
                                if (controller.payPalModel.value.isEnabled == true)
                                  cardDecoration(controller, PaymentGateway.paypal, themeChange, "assets/images/paypal.png"),
                                if (controller.payStackModel.value.isEnable == true)
                                  cardDecoration(controller, PaymentGateway.payStack, themeChange, "assets/images/paystack.png"),
                                if (controller.razorPayModel.value.isEnabled == true)
                                  cardDecoration(controller, PaymentGateway.razorpay, themeChange, "assets/images/razorpay.png"),
                                if (controller.flutterWaveModel.value.isEnable == true)
                                  cardDecoration(controller, PaymentGateway.flutterWave, themeChange, "assets/images/flutterwave_logo.png"),
                                if (controller.payFastModel.value.isEnable == true)
                                  cardDecoration(controller, PaymentGateway.payFast, themeChange, "assets/images/payfast.png"),
                                if (controller.paytmModel.value.isEnabled == true)
                                  cardDecoration(controller, PaymentGateway.paytm, themeChange, "assets/images/paytm.png"),
                                if (controller.mercadoPagoModel.value.isEnabled == true)
                                  cardDecoration(controller, PaymentGateway.mercadoPago, themeChange, "assets/images/mercado-pago.png"),
                                if (controller.midTransModel.value.enable == true)
                                  cardDecoration(controller, PaymentGateway.midTrans, themeChange, "assets/images/midtrans.png"),
                                if (controller.orangeMoneyModel.value.enable == true)
                                  cardDecoration(controller, PaymentGateway.orangeMoney, themeChange, "assets/images/orange_money.png"),
                                if (controller.xenditModel.value.enable == true)
                                  cardDecoration(controller, PaymentGateway.xendit, themeChange, "assets/images/xendit.png"),
                                if (controller.mtnMomoModel.value.enable == true)
                                  cardDecoration(controller, PaymentGateway.mtnMomo, themeChange, "assets/images/mtnmom.png"),
                                if (controller.phonePeModel.value.enable == true)
                                  cardDecoration(controller, PaymentGateway.phonePe, themeChange, "assets/images/phonepe.png"),
                                if (controller.instamojoModel.value.enable == true)
                                  cardDecoration(controller, PaymentGateway.instamojo, themeChange, "assets/images/instamojo.png"),
                                if (controller.payMongoModel.value.enable == true)
                                  cardDecoration(controller, PaymentGateway.payMongo, themeChange, "assets/images/payMongo.png"),
                              ],
                            ),
                          ),
                        )
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
                title: "Pay Now",
                height: 5,
                color: AppThemeData.primary300,
                textColor: AppThemeData.grey50,
                fontSizes: 16,
                onPress: () async {
                  final amount = controller.amountController.value.text.toString();
                  final method = controller.selectedPaymentMethod.value;
                  if (method == PaymentGateway.wallet.name) {
                    await controller.placeOrder();
                  } else if (method == PaymentGateway.cashfree.name) {
                    controller.cashFreeMakePayment(context: context, amount: amount, paymentDesc: "GiftCard Payment");
                  } else if (method == PaymentGateway.stripe.name) {
                    controller.stripeMakePayment(amount: amount);
                  } else if (method == PaymentGateway.paypal.name) {
                    controller.paypalPaymentSheet(amount, context);
                  } else if (method == PaymentGateway.payStack.name) {
                    controller.payStackPayment(amount);
                  } else if (method == PaymentGateway.razorpay.name) {
                    ShowToastDialog.showLoader("Please wait");
                    RazorPayController().createOrderRazorPay(amount: double.parse(amount), razorpayModel: controller.razorPayModel.value).then((value) {
                      if (value == null) {
                        ShowToastDialog.closeLoader();
                        ShowToastDialog.showToast("Something went wrong, please contact admin.");
                      } else {
                        CreateRazorPayOrderModel result = value;
                        controller.openCheckout(amount: amount, orderId: result.id);
                      }
                    });
                  } else if (method == PaymentGateway.flutterWave.name) {
                    controller.flutterWaveInitiatePayment(context: context, amount: amount);
                  } else if (method == PaymentGateway.payFast.name) {
                    controller.payFastPayment(context: context, amount: amount);
                  } else if (method == PaymentGateway.paytm.name) {
                    controller.getPaytmCheckSum(context, amount: double.parse(amount));
                  } else if (method == PaymentGateway.mercadoPago.name) {
                    controller.mercadoPagoMakePayment(context: context, amount: amount);
                  } else if (method == PaymentGateway.midTrans.name) {
                    controller.midtransMakePayment(context: context, amount: amount);
                  } else if (method == PaymentGateway.orangeMoney.name) {
                    controller.orangeMakePayment(context: context, amount: amount);
                  } else if (method == PaymentGateway.xendit.name) {
                    controller.xenditPayment(context, amount);
                  } else if (method == PaymentGateway.mtnMomo.name) {
                    controller.mtnMomoMakePayment(amount: amount);
                  } else if (method == PaymentGateway.phonePe.name) {
                    PhonePePaymentService.phonePe = controller.phonePeModel.value;
                    await PhonePePaymentService.payNow(amountInPaise: (double.parse(amount) * 100).round());
                    if (PhonePePaymentService.isSucess) {
                      controller.placeOrder();
                    }
                  } else if (method == PaymentGateway.instamojo.name) {
                    controller.makeInstamojoPayment(amount: amount, paymentDesc: "GiftCard Payment");
                  } else if (method == PaymentGateway.payMongo.name) {
                    controller.makePayMongoPayment(amount: amount, paymentDesc: "GiftCard Payment");
                  } else {
                    ShowToastDialog.showToast("Please select payment method");
                  }
                },
              ),
            ),
          ),
        );
      },
    );
  }

  cardDecoration(GiftCardController controller, PaymentGateway value, themeChange, String image) {
    return Obx(
      () => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: InkWell(
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
                            value.name.capitalizeString(),
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
                        value.name.capitalizeString(),
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
      ),
    );
  }
}
