import 'dart:convert';
import 'dart:async';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/models/payment_model/instamojo_model.dart';
import 'package:http/http.dart' as http;

class InstamojoService {
  static Future<String?> getAccessToken({
    required Instamojo instamojoModel,
  }) async {
    try {
      final url = Uri.parse('https://api.instamojo.com/oauth2/token/');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'grant_type': 'client_credentials',
          'client_id': instamojoModel.clientId ?? '',
          'client_secret': instamojoModel.clientSecret ?? '',
        },
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['access_token'];
      } else {
        throw Exception('Failed to get access token. Status: ${response.statusCode}, Body: ${response.body}');
      }
    } on TimeoutException {
      throw Exception('Request timed out. Please try again.');
    } on http.ClientException {
      throw Exception('Network error. Please check your internet connection.');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  static Future<String?> createPaymentRequest({
    required String accessToken,
    required String amount,
    required String purpose,
  }) async {
    try {
      final url = Uri.parse('https://api.instamojo.com/v2/payment_requests/');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'amount': amount,
          'purpose': purpose,
          'allow_repeated_payments': 'false',
          'send_email': 'false',
        },
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['redirect_url'];
      } else {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast("Unable to initialize payment, credentials are invalid or not authorized. Please check credentials, environment (sandbox/live), and account region.");
      }
    } on TimeoutException {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Unable to initialize payment, credentials are invalid or not authorized. Please check credentials, environment (sandbox/live), and account region.");
      throw Exception('Payment request timed out.');
    } on http.ClientException {
      ShowToastDialog.closeLoader();
      throw Exception('Network error while creating payment.');
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Unable to initialize payment, credentials are invalid or not authorized. Please check credentials, environment (sandbox/live), and account region.");
      throw Exception('Unexpected payment error: $e');
    }
    return null;
  }
}
