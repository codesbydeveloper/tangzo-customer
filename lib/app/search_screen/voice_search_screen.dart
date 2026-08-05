import 'package:customer/controllers/voice_search_controller.dart';
import 'package:customer/themes/app_them_data.dart';
import 'package:customer/utils/dark_theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:customer/widget/translated_text.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class VoiceSearchScreen extends StatelessWidget {
  const VoiceSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX(
        init: VoiceSearchController(),
        builder: (controller) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  controller.status.value == 'done'
                      ? TranslatedText(
                          "Tap the mic to start voice recognition",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            color: themeChange.getThem() ? AppThemeData.surface : AppThemeData.surfaceDark,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      : TranslatedText(
                          "Speak now",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            color: themeChange.getThem() ? AppThemeData.surface : AppThemeData.surfaceDark,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                  const SizedBox(height: 20),
                  controller.status.value == 'done'
                      ? InkWell(
                          onTap: () {
                            controller.startListening();
                          },
                          child: Container(
                            height: controller.micSize.value + 40.0,
                            width: controller.micSize.value + 40,
                            decoration: BoxDecoration(
                              color: AppThemeData.grey400.withOpacity(0.8),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppThemeData.grey400.withOpacity(0.6),
                                  blurRadius: 30,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.mic,
                              size: 50,
                            ),
                          ),
                        )
                      : InkWell(
                          onTap: () {
                            controller.stopListening(duration: 1);
                          },
                          child: Container(
                            height: controller.micSize.value + 40.0,
                            width: controller.micSize.value + 40,
                            decoration: BoxDecoration(
                              color: AppThemeData.primary300.withOpacity(0.8),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppThemeData.primary300.withOpacity(0.6),
                                  blurRadius: 30,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.mic,
                              size: 50,
                            ),
                          ),
                        ),
                  const SizedBox(height: 30),
                  const SizedBox(height: 40),
                  if (controller.status.value != 'done')
                    Image.asset(
                      'assets/images/voice_wave.gif',
                      height: 100,
                    ),
                  const SizedBox(height: 20),
                  if (controller.status.value == 'listening' || controller.recognizedText.value != 'Listening...')
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: TranslatedText(
                        controller.recognizedText.value,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  const SizedBox(height: 30),
                  InkWell(
                    onTap: () {
                      controller.stopListening(duration: 0);
                    },
                    child: TranslatedText(
                      "Click to Back",
                      style: TextStyle(
                        fontSize: 20,
                        color: AppThemeData.primary300,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }
}
