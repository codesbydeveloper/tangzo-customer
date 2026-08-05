import 'package:customer/utils/dynamic_traslator.dart';
import 'package:customer/utils/translation_notifier.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TranslatedText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final bool softWrap;
  final TextOverflow? overflow;

  const TranslatedText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.softWrap = true, // ✅ default true
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: TranslationNotifier.refresh,
      builder: (_, __, ___) {
        return Text(
          text.tr,
          style: style,
          textAlign: textAlign,
          maxLines: maxLines,
          softWrap: softWrap,
          overflow: overflow,
        );
      },
    );
  }
}
