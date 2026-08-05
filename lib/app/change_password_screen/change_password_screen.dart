import 'package:customer/constant/constant.dart';
import 'package:customer/controllers/change_password_controller.dart';
import 'package:customer/themes/app_them_data.dart';
import 'package:customer/themes/round_button_fill.dart';
import 'package:customer/themes/text_field_widget.dart';
import 'package:customer/utils/dark_theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:customer/widget/translated_text.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class ChangePasswordScreen extends StatelessWidget {
  const ChangePasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX(
        init: ChangePasswordController(),
        builder: (controller) {
          return Scaffold(
              appBar: AppBar(
                backgroundColor: themeChange.getThem() ? AppThemeData.surfaceDark : AppThemeData.surface,
                centerTitle: false,
                titleSpacing: 0,
              ),
              body: controller.isLoading.value
                  ? Constant.loader()
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TranslatedText(
                            "Change Password",
                            style: TextStyle(
                              fontSize: 24,
                              color: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey900,
                              fontFamily: AppThemeData.semiBold,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          TranslatedText(
                            "Update your password to keep your account secure.",
                            style: TextStyle(
                              fontSize: 16,
                              color: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey900,
                              fontFamily: AppThemeData.regular,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          TranslatedText(
                            "Enter your registered email address and we’ll send you a secure link to reset your password. Open the link in your inbox and follow the steps to create a new password.",
                            style: TextStyle(
                              fontSize: 14,
                              color: themeChange.getThem() ? AppThemeData.danger300 : AppThemeData.danger300,
                              fontFamily: AppThemeData.regular,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          TextFieldWidget(
                            title: 'Email Address',
                            textInputType: TextInputType.emailAddress,
                            controller: controller.emailEditingController.value,
                            hintText: 'Enter Email Address',
                            prefix: Padding(
                              padding: const EdgeInsets.all(12),
                              child: SvgPicture.asset(
                                "assets/icons/ic_mail.svg",
                                colorFilter: ColorFilter.mode(
                                  themeChange.getThem() ? AppThemeData.grey300 : AppThemeData.grey600,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          RoundedButtonFill(
                            title: "Change Password",
                            color: AppThemeData.primary300,
                            textColor: AppThemeData.grey50,
                            onPress: () async {
                              controller.forgotPassword();
                            },
                          ),
                        ],
                      ),
                    ));
        });
  }
}
