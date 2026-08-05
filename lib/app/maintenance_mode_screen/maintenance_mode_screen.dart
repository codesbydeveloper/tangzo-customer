import 'package:customer/themes/app_them_data.dart';
import 'package:customer/utils/dark_theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:customer/widget/translated_text.dart';
import 'package:provider/provider.dart';

class MaintenanceModeScreen extends StatelessWidget {
  const MaintenanceModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return Scaffold(
      backgroundColor: themeChange.getThem() ? AppThemeData.surfaceDark : AppThemeData.surface,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(child: Image.asset('assets/images/maintenance.png', height: 200, width: 200)),
          const SizedBox(height: 20),
          TranslatedText("We'll be back soon!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: themeChange.getThem() ? AppThemeData.grey100 : AppThemeData.grey800)),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: TranslatedText(
              "Sorry for the inconvenience but we're performing some maintenance at the moment. We'll be back online shortly!",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: themeChange.getThem() ? AppThemeData.grey100 : AppThemeData.grey800),
            ),
          ),
        ],
      ),
    );
  }
}
