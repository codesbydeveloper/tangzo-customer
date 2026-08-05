import 'dart:convert';
import 'dart:developer';

import 'package:customer/app/chat_screens/driver_inbox_screen.dart';
import 'package:customer/app/chat_screens/restaurant_inbox_screen.dart';
import 'package:customer/app/dash_board_screens/dash_board_screen.dart';
import 'package:customer/app/help_support_screen/help_support_screen.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/controllers/dash_board_controller.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:customer/utils/preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

Future<void> firebaseMessageBackgroundHandle(RemoteMessage message) async {
  log("BackGround Message :: ${message.messageId}");
}

class NotificationService {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> initInfo() async {
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    var request = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (request.authorizationStatus == AuthorizationStatus.authorized || request.authorizationStatus == AuthorizationStatus.provisional) {
      const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
      var iosInitializationSettings = const DarwinInitializationSettings();
      final InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid, iOS: iosInitializationSettings);
      await flutterLocalNotificationsPlugin.initialize(
          settings: initializationSettings,
          onDidReceiveNotificationResponse: (response) {
            if (response.payload != null) {
              final data = jsonDecode(response.payload!);
              final String type = data['type'] ?? '';
              final String role = data['chatType'] ?? '';
              handleMessageClick(type: type, role: role, isBgApp: false);
            }
          });
      setupInteractedMessage();
    }
  }

  Future<void> setupInteractedMessage() async {
    // RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    // if (initialMessage != null) {
    //   FirebaseMessaging.onBackgroundMessage((message) => firebaseMessageBackgroundHandle(message));
    // }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log("::::::::::::onMessage:::::::::::::::::");
      if (message.notification != null) {
        log(message.notification.toString());
        display(message);
      }
    });
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage? message) {
      log("::::::::::::onMessageOpenedApp:::::::::::::::::");
      if (message != null) {
        final String type = message.data['type'] ?? '';
        final String role = message.data['chatType'] ?? '';
        handleMessageClick(type: type, role: role, isBgApp: true);
      }
    });
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      log("::::::::::::getInitialMessage:::::::::::::::::");
      if (message != null) {
        final String type = message.data['type'] ?? '';
        final String role = message.data['chatType'] ?? '';
        handleMessageClick(type: type, role: role, isBgApp: true);
      }
    });
    log("::::::::::::Permission authorized:::::::::::::::::");
    await FirebaseMessaging.instance.subscribeToTopic("customer");
  }

  static Future<String?> getToken() async {
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      return "";
    }
  }

  Future<void> handleMessageClick({required String type, required String role, required bool isBgApp}) async {
    final String uid = FireStoreUtils.getCurrentUid();
    if (type == 'admin_chat' && uid.isNotEmpty) {
      await Preferences.setBoolean(Preferences.isClickOnNotification, true);
      if (isBgApp == false) {
        Get.offAll(HelpSupportScreen(isNavigateViaNotification: true));
      }
    } else if (type == 'orderChat') {
      DashBoardController dashBoardScreen = Get.put(DashBoardController());
      dashBoardScreen.selectedIndex.value = 4;
      Get.offAll(DashBoardScreen());
      if (role == Constant.userRoleVendor) {
        Get.to(RestaurantInboxScreen());
      } else {
        Get.to(DriverInboxScreen());
      }
    }
  }

  void display(RemoteMessage message) async {
    log('Got a message whilst in the foreground!');
    log('Message data: ${message.notification!.body.toString()}');
    try {
      AndroidNotificationChannel channel = const AndroidNotificationChannel(
        '0',
        'foodie-customer',
        description: 'Show QuickLAI Notification',
        importance: Importance.max,
      );
      AndroidNotificationDetails notificationDetails =
          AndroidNotificationDetails(channel.id, channel.name, channelDescription: 'your channel Description', importance: Importance.high, priority: Priority.high, ticker: 'ticker');
      const DarwinNotificationDetails darwinNotificationDetails = DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true);
      NotificationDetails notificationDetailsBoth = NotificationDetails(android: notificationDetails, iOS: darwinNotificationDetails);
      await FlutterLocalNotificationsPlugin().show(
        id: 0,
        title: message.notification!.title,
        body: message.notification!.body,
        notificationDetails: notificationDetailsBoth,
        payload: jsonEncode(message.data),
      );
    } on Exception catch (e) {
      log(e.toString());
    }
  }
}
