import 'package:customer/utils/fire_store_utils.dart';
import 'package:customer/utils/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class GlobalSettingController extends GetxController {
  @override
  void onInit() {
    notificationInit();
    getCurrentCurrency();
    super.onInit();
  }

  Future<void> getCurrentCurrency() async {
    await FireStoreUtils.getSettings();
  }

  NotificationService notificationService = NotificationService();

  void notificationInit() {
    notificationService.initInfo().then((value) async {
      // FCM token write is owned by SplashController (partial update only).
      // Avoid duplicate getUserProfile + full-document set() race on boot.
      if (FirebaseAuth.instance.currentUser == null) return;
      final token = await NotificationService.getToken();
      await FireStoreUtils.updateFcmTokenIfChanged(
        userId: FireStoreUtils.getCurrentUid(),
        token: token,
      );
    });
  }
}
