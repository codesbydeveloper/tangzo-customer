import 'package:customer/app/auth_screen/login_screen.dart';
import 'package:customer/app/auth_screen/signup_screen.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/controllers/otp_controller.dart';
import 'package:customer/models/user_model.dart';
import 'package:customer/themes/app_them_data.dart';
import 'package:customer/themes/round_button_fill.dart';
import 'package:customer/utils/dark_theme_provider.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:customer/utils/translation_notifier.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:customer/widget/translated_text.dart';
import 'package:get/get.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';

class OtpScreen extends StatelessWidget {
  const OtpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX<OtpController>(
        init: OtpController(),
        builder: (controller) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: themeChange.getThem()
                  ? AppThemeData.surfaceDark
                  : AppThemeData.surface,
            ),
            body: controller.isLoading.value
                ? Constant.loader()
                : SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TranslatedText(
                            "Verify Your WhatsApp Number 💬",
                            style: TextStyle(
                                color: themeChange.getThem()
                                    ? AppThemeData.grey50
                                    : AppThemeData.grey900,
                                fontSize: 22,
                                fontFamily: AppThemeData.semiBold),
                          ),
                          TranslatedText(
                            "${'Enter the OTP sent to your WhatsApp number.'} ${controller.countryCode.value} ${Constant.maskingString(controller.phoneNumber.value, 3)}",
                            textAlign: TextAlign.start,
                            style: TextStyle(
                              color: themeChange.getThem()
                                  ? AppThemeData.grey200
                                  : AppThemeData.grey700,
                              fontSize: 16,
                              fontFamily: AppThemeData.regular,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 60),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              const otpLength = 6;
                              const spacing = 6.0;
                              final cellWidth = (constraints.maxWidth -
                                      spacing * (otpLength - 1)) /
                                  otpLength;
                              return MaterialPinField(
                                length: otpLength,
                                keyboardType: TextInputType.number,
                                enableAutofill: true,
                                autofillHints: const [
                                  AutofillHints.oneTimeCode
                                ],
                                hintCharacter: "-",
                                pinController: controller.otpController.value,
                                theme: MaterialPinTheme(
                                  cellSize: Size(cellWidth, 50),
                                  spacing: spacing,
                                  shape: MaterialPinShape.outlined,
                                  borderRadius: BorderRadius.circular(10),
                                  textStyle: TextStyle(
                                    fontFamily: AppThemeData.regular,
                                    color: themeChange.getThem()
                                        ? AppThemeData.grey50
                                        : AppThemeData.grey900,
                                  ),
                                  fillColor: themeChange.getThem()
                                      ? AppThemeData.grey900
                                      : AppThemeData.grey50,
                                  borderColor: themeChange.getThem()
                                      ? AppThemeData.grey900
                                      : AppThemeData.grey50,
                                  focusedBorderColor: AppThemeData.primary300,
                                  cursorColor: AppThemeData.primary300,
                                  errorColor: themeChange.getThem()
                                      ? AppThemeData.grey600
                                      : AppThemeData.grey300,
                                ),
                                onChanged: (value) {},
                                onCompleted: (pin) async {},
                              );
                            },
                          ),
                          const SizedBox(height: 50),
                          RoundedButtonFill(
                            title: "Verify & Next",
                            color: AppThemeData.primary300,
                            textColor: AppThemeData.grey50,
                            onPress: () async {
                              final entered =
                                  controller.otpController.value.text.trim();
                              if (entered.length != 6) {
                                ShowToastDialog.showToast(
                                    "Enter a valid 6-digit OTP");
                                return;
                              }

                              if (!controller.verifyOtp(entered)) {
                                ShowToastDialog.showToast(
                                    "Incorrect OTP. Please try again.");
                                return;
                              }

                              ShowToastDialog.showLoader("Please wait");

                              try {
                                final existingUser =
                                    await FireStoreUtils.getUserByPhoneNumber(
                                  countryCode: controller.countryCode.value,
                                  phoneNumber: controller.phoneNumber.value,
                                );

                                ShowToastDialog.closeLoader();

                                if (existingUser != null) {
                                  ShowToastDialog.showToast(
                                    "This WhatsApp number is already registered. Please login with your email and password.",
                                  );
                                  Get.offAll(const LoginScreen());
                                  return;
                                }

                                final UserModel userModel = UserModel()
                                  ..countryCode = controller.countryCode.value
                                  ..countryISOCode =
                                      controller.countryISOCode.value
                                  ..phoneNumber = controller.phoneNumber.value
                                  ..provider = 'whatsapp';

                                Get.off(const SignupScreen(), arguments: {
                                  "userModel": userModel,
                                  "type": "whatsapp",
                                });
                              } catch (e) {
                                ShowToastDialog.closeLoader();
                                ShowToastDialog.showToast(e.toString());
                              }
                            },
                          ),
                          const SizedBox(height: 40),
                          ValueListenableBuilder(
                              valueListenable: TranslationNotifier.refresh,
                              builder: (_, __, ___) {
                                return Text.rich(
                                  textAlign: TextAlign.start,
                                  TextSpan(
                                    text: "${'Didn\'t receive the OTP? '} ".tr,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                      fontFamily: AppThemeData.medium,
                                      color: themeChange.getThem()
                                          ? AppThemeData.grey100
                                          : AppThemeData.grey800,
                                    ),
                                    children: <TextSpan>[
                                      TextSpan(
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () {
                                            controller.otpController.value
                                                .clear();
                                            controller.sendOTP();
                                          },
                                        text: 'Send Again'.tr,
                                        style: TextStyle(
                                            color: themeChange.getThem()
                                                ? AppThemeData.primary300
                                                : AppThemeData.primary300,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14,
                                            fontFamily: AppThemeData.medium,
                                            decoration:
                                                TextDecoration.underline,
                                            decorationColor:
                                                AppThemeData.primary300),
                                      ),
                                    ],
                                  ),
                                );
                              })
                        ],
                      ),
                    ),
                  ),
          );
        });
  }
}
