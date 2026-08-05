// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'package:customer/constant/constant.dart';
import 'package:customer/models/notification_model.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

class SendNotification {
  static final _scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

  static Future getCharacters() {
    return http.get(Uri.parse(Constant.jsonNotificationFileURL.toString()));
  }

  static Future<String> getAccessToken() async {
    Map<String, dynamic> jsonData = {};

    await getCharacters().then((response) {
      jsonData = json.decode(response.body);
    });
    final serviceAccountCredentials = ServiceAccountCredentials.fromJson(jsonData);
    final client = await clientViaServiceAccount(serviceAccountCredentials, _scopes);
    return client.credentials.accessToken.data;
  }

  static Future<bool> sendFcmMessage(String type, String token, Map<String, dynamic>? payload) async {
    print(type);
    try {
      final String accessToken = await getAccessToken();
      debugPrint("accessToken=======>");
      debugPrint(accessToken);
      NotificationModel? notificationModel = await FireStoreUtils.getNotificationContent(type);

      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/v1/projects/${Constant.senderId}/messages:send'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(
          <String, dynamic>{
            'message': {
              'token': token,
              'notification': {'body': notificationModel?.message ?? '', 'title': notificationModel?.subject ?? ''},
              'data': payload,
            }
          },
        ),
      );

      debugPrint("Notification=======>");
      debugPrint(response.statusCode.toString());
      debugPrint(response.body);
      return true;
    } catch (e) {
      debugPrint(e.toString());
      return false;
    }
  }

  static Future<bool> sendOneNotification({required String token, required String title, required String body, required Map<String, dynamic> payload}) async {
    try {
      final String accessToken = await getAccessToken();
      debugPrint("accessToken=======>");
      debugPrint(accessToken);

      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/v1/projects/${Constant.senderId}/messages:send'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(
          <String, dynamic>{
            'message': {
              'token': token,
              'notification': {'body': body, 'title': title},
              'data': payload,
            }
          },
        ),
      );

      debugPrint("Notification=======>");
      debugPrint(response.statusCode.toString());
      debugPrint(response.body);
      return true;
    } catch (e) {
      debugPrint(e.toString());
      return false;
    }
  }

  static Future<bool> sendChatFcmMessage({
    required String title,
    required String message,
    required String token,
    Map<String, dynamic>? payload,
  }) async {
    try {
      final accessToken = await getAccessToken();

      final uri = Uri.parse(
        'https://fcm.googleapis.com/v1/projects/${Constant.senderId}/messages:send',
      );

      final body = {
        'message': {
          'token': token,
          'notification': {
            'title': title,
            'body': message,
          },
          if (payload != null && payload.isNotEmpty) 'data': payload.map((k, v) => MapEntry(k, v.toString())),
        }
      };

      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $accessToken',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));

      debugPrint('FCM Status Code: ${response.statusCode}');
      debugPrint('FCM Response: ${response.body}');

      return response.statusCode == 200;
    } catch (e, stack) {
      debugPrint('sendChatFcmMessage error: $e');
      debugPrintStack(stackTrace: stack);
      return false;
    }
  }
}
