import 'dart:convert';
import 'package:customer/models/payment_model/cashfree_model.dart';
import 'package:customer/models/user_model.dart';
import 'package:http/http.dart' as http;

class CashfreeService {
  Future<String?> createPaymentLink({required Cashfree cashfree, required UserModel userModel, required double amount, required String paymentDesc}) async {
    try {
      String baseUrl = cashfree.isSandbox == true ? "https://sandbox.cashfree.com/pg/links" : "https://api.cashfree.com/pg/links";
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          "x-client-id": cashfree.clientId!,
          "x-client-secret": cashfree.clientSecret!,
          "x-api-version": "2025-01-01",
          "Content-Type": "application/json",
          "Accept": "application/json",
          "x-request-id": DateTime.now().millisecondsSinceEpoch.toString(),
          "x-idempotency-key": DateTime.now().millisecondsSinceEpoch.toString(),
        },
        body: jsonEncode({
          "customer_details": {"customer_email": userModel.email, "customer_name": userModel.fullName(), "customer_phone": userModel.phoneNumber},
          "link_amount": amount,
          "link_currency": "INR",
          "link_id": "my_test_link_${DateTime.now().millisecondsSinceEpoch}",
          "link_purpose": paymentDesc, //"Payment for PlayStation 11",
          "link_notify": {"send_email": true, "send_sms": false},
          "link_meta": {"return_url": "https://www.cashfree.com/devstudio/thankyou", "notify_url": "https://webhook.site/test"}
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("Payment Link Created Successfully");
        print(data);
        return data["link_url"]; // Open this in WebView
      } else {
        final error = jsonDecode(response.body);
        throw Exception(
          "Cashfree Error: ${error["message"] ?? response.body}",
        );
      }
    } catch (e) {
      print("Exception while creating payment link: $e");
      return null;
    }
  }
}
