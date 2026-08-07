import 'package:customer/app/auth_screen/login_screen.dart';
import 'package:customer/controllers/on_boarding_controller.dart';
import 'package:customer/themes/app_them_data.dart';
import 'package:customer/themes/round_button_fill.dart';
import 'package:customer/utils/dark_theme_provider.dart';
import 'package:customer/utils/preferences.dart';
import 'package:flutter/material.dart';
import 'package:customer/widget/translated_text.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../constant/constant.dart';

class OnBoardingScreen extends StatelessWidget {
  const OnBoardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX<OnBoardingController>(
      init: OnBoardingController(),
      builder: (controller) {
        return Scaffold(
          body: controller.isLoading.value
              ? Constant.loader()
              : Container(
                  decoration: const BoxDecoration(
                      image: DecorationImage(
                          image: AssetImage("assets/images/image_1.png"),
                          fit: BoxFit.cover)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.asset(
                                    "assets/icons/ic_logo.png",
                                    width: 72,
                                    height: 72,
                                  ),
                                ),
                                TranslatedText(
                                  "Tangzo",
                                  style: TextStyle(color: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey50, fontSize: 24, fontFamily: AppThemeData.bold),
                                ),
                                const SizedBox(
                                  height: 30,
                                ),
                                TranslatedText(
                                  controller.onBoardingList.isNotEmpty ? controller.onBoardingList.first.title.toString() : "Restaurants",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: themeChange.getThem() ? AppThemeData.primary300 : AppThemeData.primary300,
                                    fontSize: 28,
                                    fontFamily: AppThemeData.bold,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                TranslatedText(
                                  controller.onBoardingList.isNotEmpty
                                      ? controller.onBoardingList.first.description.toString()
                                      : "Discover a variety of restaurants near you.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: themeChange.getThem() ? AppThemeData.grey600 : AppThemeData.grey300,
                                    fontSize: 16,
                                    fontFamily: AppThemeData.regular,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        RoundedButtonFill(
                          title: "Get Started",
                          color: AppThemeData.primary300,
                          textColor: AppThemeData.grey50,
                          onPress: () {
                            Preferences.setBoolean(Preferences.isFinishOnBoardingKey, true);
                            Get.offAll(() => const LoginScreen());
                          },
                        ),
                        const SizedBox(
                          height: 50,
                        ),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }
}
