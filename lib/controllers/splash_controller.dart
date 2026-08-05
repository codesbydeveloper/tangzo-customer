import 'dart:async';
import 'dart:developer';
import 'package:customer/app/auth_screen/login_screen.dart';
import 'package:customer/app/dash_board_screens/dash_board_screen.dart';
import 'package:customer/app/help_support_screen/help_support_screen.dart';
import 'package:customer/app/location_permission_screen/location_permission_screen.dart';
import 'package:customer/app/maintenance_mode_screen/maintenance_mode_screen.dart';
import 'package:customer/app/on_boarding_screen.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/models/user_model.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:customer/utils/notification_service.dart';
import 'package:customer/utils/preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';

class SplashController extends GetxController {
  @override
  void onInit() {
    Timer(const Duration(seconds: 3), () => redirectScreen());
    super.onInit();
  }

  Future<void> redirectScreen() async {
    if (await FireStoreUtils.isMaintenanceMode() == true) {
      Get.offAll(() => MaintenanceModeScreen());
      return;
    } else {
      if (Preferences.getBoolean(Preferences.isClickOnNotification) != true) {
        if (Preferences.getBoolean(Preferences.isFinishOnBoardingKey) == false) {
          Get.offAll(const OnBoardingScreen());
        } else {
          bool isLogin = await FireStoreUtils.isLogin();
          if (isLogin == true) {
            await FireStoreUtils.getUserProfile(FireStoreUtils.getCurrentUid()).then((value) async {
              if (value != null) {
                UserModel userModel = value;
                // userModel.shippingAddress?[0].location = UserLocation(latitude: 23.8500, longitude: 72.1210);
                log(userModel.toJson().toString());
                if (userModel.role == Constant.userRoleCustomer) {
                  if (userModel.active == true) {
                    userModel.fcmToken = await NotificationService.getToken();
                    await FireStoreUtils.updateUser(userModel);
                    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
                    if (initialMessage != null && initialMessage.data['type'] != null) {
                    } else if (userModel.shippingAddress != null && userModel.shippingAddress!.isNotEmpty) {
                      if (userModel.shippingAddress!.where((element) => element.isDefault == true).isNotEmpty) {
                        Constant.selectedLocation = userModel.shippingAddress!.where((element) => element.isDefault == true).single;
                      } else {
                        Constant.selectedLocation = userModel.shippingAddress!.first;
                      }
                      Get.offAll(const DashBoardScreen());
                    } else {
                      Get.offAll(const LocationPermissionScreen());
                    }
                  } else {
                    await FirebaseAuth.instance.signOut();
                    Get.offAll(const LoginScreen());
                  }
                } else {
                  await FirebaseAuth.instance.signOut();
                  Get.offAll(const LoginScreen());
                }
              }
            });
          } else {
            await FirebaseAuth.instance.signOut();
            Get.offAll(const LoginScreen());
          }
        }
      } else {
        Get.to(HelpSupportScreen(isNavigateViaNotification: true));
      }
    }
  }

  // Future<void> handleMessageClick({required String type, required String role, required bool isBgApp}) async {
  //   final String uid = FireStoreUtils.getCurrentUid();
  //   if (type == 'admin_chat' && uid.isNotEmpty) {
  //     await Preferences.setBoolean(Preferences.isClickOnNotification, true);
  //     if (isBgApp == false) {
  //       Get.offAll(HelpSupportScreen(isNavigateViaNotification: true));
  //     }
  //   } else if (type == 'orderChat') {
  //     DashBoardController dashBoardScreen = Get.put(DashBoardController());
  //     dashBoardScreen.selectedIndex.value = 4;
  //     Get.offAll(DashBoardScreen());
  //     if (role == Constant.userRoleVendor) {
  //       Get.to(RestaurantInboxScreen());
  //     } else {
  //       Get.to(DriverInboxScreen());
  //     }
  //   }
  // }
}
