import 'package:flutter/foundation.dart';

class TranslationNotifier {
  static final ValueNotifier<int> refresh = ValueNotifier(0);

  static void notify() {
    refresh.value++;
  }
}
