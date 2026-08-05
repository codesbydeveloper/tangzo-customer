import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';

class ShowToastDialog {
  static Future<void> showToast(String? message, {EasyLoadingToastPosition position = EasyLoadingToastPosition.top}) async {
    // String translated = await DynamicTranslator.translate(message ?? '');
    EasyLoading.showToast((message ?? '').tr, toastPosition: position);
  }

  static Future<void> showLoader(String message) async {
    EasyLoading.instance
      ..userInteractions = false
      ..dismissOnTap = false;
    // String translated = await DynamicTranslator.translate(message);
    EasyLoading.show(
      status: message.tr,
      maskType: EasyLoadingMaskType.black,
    );
  }

  static void closeLoader() {
    EasyLoading.dismiss();
  }
}
