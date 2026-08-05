import 'package:customer/constant/constant.dart';
import 'package:customer/themes/app_them_data.dart';
import 'package:customer/utils/dark_theme_provider.dart';
import 'package:customer/utils/dynamic_traslator.dart';
import 'package:customer/utils/translation_notifier.dart';
import 'package:customer/widget/translated_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class TermsAndConditionScreen extends StatelessWidget {
  final String? type;

  const TermsAndConditionScreen({super.key, this.type});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return Scaffold(
      backgroundColor: AppThemeData.surface,
      appBar: AppBar(
        backgroundColor: themeChange.getThem() ? AppThemeData.grey900 : AppThemeData.grey50,
        centerTitle: false,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        leading: InkWell(
          splashColor: Colors.transparent,
          onTap: () {
            Get.back();
          },
          child: Icon(
            Icons.chevron_left_outlined,
            color: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey900,
          ),
        ),
        title: TranslatedText(
          type == "privacy" ? "Privacy Policy" : "Terms & Conditions",
          style: TextStyle(color: themeChange.getThem() ? AppThemeData.grey100 : AppThemeData.grey800, fontFamily: AppThemeData.bold, fontSize: 18),
        ),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: Container(
            color: themeChange.getThem() ? AppThemeData.grey700 : AppThemeData.grey200,
            height: 4.0,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        child: SingleChildScrollView(
          child: ValueListenableBuilder(
              valueListenable: TranslationNotifier.refresh,
              builder: (_, __, ___) {
                return Html(
                  shrinkWrap: true,
                  data: cleanHtml(
                    type == "privacy" ? Constant.privacyPolicy.tr : Constant.termsAndConditions.tr,
                  ),
                  style: {
                    "body": Style(
                      margin: Margins.zero,
                      padding: HtmlPaddings.zero,
                      color: AppThemeData.grey900,
                      fontSize: FontSize(14),
                      fontFamily: AppThemeData.medium,
                    ),
                    "p": Style(
                      color: AppThemeData.grey900,
                    ),
                    "li": Style(
                      color: AppThemeData.grey900,
                    ),
                    "h1": Style(
                      color: AppThemeData.grey900,
                    ),
                    "h2": Style(
                      color: AppThemeData.grey900,
                    ),
                    "h3": Style(
                      color: AppThemeData.grey900,
                    ),
                    "a": Style(
                      color: AppThemeData.primary300,
                    ),
                  },
                );
              }),
        ),
      ),
    );
  }
}

String cleanHtml(String html) {
  return html

      /// remove style tag
      .replaceAll(
        RegExp(r'<style[^>]*>[\s\S]*?<\/style>'),
        '',
      )

      /// remove script tag
      .replaceAll(
        RegExp(r'<script[^>]*>[\s\S]*?<\/script>'),
        '',
      )

      /// remove inline style=""
      .replaceAll(
        RegExp(r'style="[^"]*"'),
        '',
      )

      /// remove tailwind css variables text
      .replaceAll(
        RegExp(r'--tw-[^;]+;'),
        '',
      )

      /// remove extra font-family css text
      .replaceAll(
        RegExp(r'font-family:[^;]+;'),
        '',
      );
}
