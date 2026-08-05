import 'dart:io';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:customer/app/auth_screen/signup_screen.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/controllers/phone_number_controller.dart';
import 'package:customer/themes/app_them_data.dart';
import 'package:customer/themes/round_button_border.dart';
import 'package:customer/themes/round_button_fill.dart';
import 'package:customer/themes/text_field_widget.dart';
import 'package:customer/utils/dark_theme_provider.dart';
import 'package:customer/utils/dynamic_traslator.dart';
import 'package:customer/utils/translation_notifier.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:customer/widget/translated_text.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class PhoneNumberScreen extends StatelessWidget {
  const PhoneNumberScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX(
        init: PhoneNumberController(),
        builder: (controller) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: themeChange.getThem() ? AppThemeData.surfaceDark : AppThemeData.surface,
            ),
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TranslatedText(
                      "Welcome Back! 👋",
                      style: TextStyle(color: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey900, fontSize: 22, fontFamily: AppThemeData.semiBold),
                    ),
                    TranslatedText(
                      "Log in to continue enjoying delicious food delivered to your doorstep.",
                      style: TextStyle(color: themeChange.getThem() ? AppThemeData.grey400 : AppThemeData.grey500, fontSize: 16, fontFamily: AppThemeData.regular),
                    ),
                    const SizedBox(
                      height: 32,
                    ),
                    TextFieldWidget(
                      title: 'Phone Number',
                      controller: controller.phoneNUmberEditingController.value,
                      hintText: 'Enter Phone Number',
                      textInputType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                      textInputAction: TextInputAction.done,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp('[0-9]')),
                      ],
                      prefix: ValueListenableBuilder(
                          valueListenable: TranslationNotifier.refresh,
                          builder: (_, __, ___) {
                            return CountryCodePicker(
                              headerText: 'Select Country'.tr,
                              onInit: (value) {
                                controller.countryCodeEditingController.value.text = value?.dialCode ?? Constant.defaultCountryCode;
                                controller.countryISOCodeEditingController.value.text = value?.code ?? Constant.defaultCountryCode;
                              },
                              onChanged: (value) {
                                controller.countryCodeEditingController.value.text = value.dialCode.toString();
                                controller.countryISOCodeEditingController.value.text = value.code ?? Constant.defaultCountryCode;
                              },
                              dialogTextStyle: TextStyle(color: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey900, fontWeight: FontWeight.w500, fontFamily: AppThemeData.medium),
                              dialogBackgroundColor: themeChange.getThem() ? AppThemeData.grey800 : AppThemeData.grey100,
                              initialSelection: controller.countryISOCodeEditingController.value.text,
                              comparator: (a, b) => b.name!.compareTo(a.name.toString()),
                              textStyle: TextStyle(fontSize: 14, color: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey900, fontFamily: AppThemeData.medium),
                              searchDecoration: InputDecoration(iconColor: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey900),
                              searchStyle: TextStyle(color: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey900, fontWeight: FontWeight.w500, fontFamily: AppThemeData.medium),
                            );
                          }),
                    ),
                    const SizedBox(
                      height: 36,
                    ),
                    RoundedButtonFill(
                      title: "Send OTP",
                      color: AppThemeData.primary300,
                      textColor: AppThemeData.grey50,
                      onPress: () async {
                        if (controller.phoneNUmberEditingController.value.text.isEmpty) {
                          ShowToastDialog.showToast("Please enter mobile number");
                        } else {
                          controller.sendCode();
                        }
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Row(
                        children: [
                          const Expanded(child: Divider(thickness: 1)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                            child: TranslatedText(
                              "or",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: themeChange.getThem() ? AppThemeData.grey500 : AppThemeData.grey400,
                                fontSize: 16,
                                fontFamily: AppThemeData.medium,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                    ),
                    RoundedButtonBorder(
                      title: "Continue with Email",
                      textColor: AppThemeData.primary300,
                      icon: SvgPicture.asset("assets/icons/ic_mail.svg"),
                      isRight: false,
                      onPress: () async {
                        Get.back();
                      },
                    ),
                  ],
                ),
              ),
            ),
            bottomNavigationBar: Padding(
              padding: EdgeInsets.symmetric(vertical: Platform.isAndroid ? 10 : 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ValueListenableBuilder(
                      valueListenable: TranslationNotifier.refresh,
                      builder: (_, __, ___) {
                        return Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                  text: 'Didn’t have an account?'.tr,
                                  style: TextStyle(
                                    color: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey900,
                                    fontFamily: AppThemeData.medium,
                                    fontWeight: FontWeight.w500,
                                  )),
                              const WidgetSpan(
                                  child: SizedBox(
                                width: 10,
                              )),
                              TextSpan(
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      Get.to(const SignupScreen());
                                    },
                                  text: 'Sign up'.tr,
                                  style: TextStyle(
                                      color: AppThemeData.primary300,
                                      fontFamily: AppThemeData.bold,
                                      fontWeight: FontWeight.w500,
                                      decoration: TextDecoration.underline,
                                      decorationColor: AppThemeData.primary300)),
                            ],
                          ),
                        );
                      }),
                ],
              ),
            ),
          );
        });
  }
}
