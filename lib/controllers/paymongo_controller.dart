import 'dart:convert';
import 'package:customer/models/user_model.dart';
import 'package:http/http.dart' as http;

class PayMongoService {
  String secretKey = "";

  String authKey() {
    return base64Encode(utf8.encode("$secretKey:"));
  }

  Future<Map<String, dynamic>> createPaymentIntent({required String amount}) async {
    final response = await http.post(
      Uri.parse("https://api.paymongo.com/v1/payment_intents"),
      headers: {
        "accept": "application/json",
        "content-type": "application/json",
        "authorization": "Basic ${authKey()}",
      },
      body: jsonEncode({
        "data": {
          "attributes": {
            "amount": double.parse(amount),
            "currency": "PHP",
            "payment_method_allowed": ["gcash", "grab_pay"],
            "capture_type": "automatic"
          }
        }
      }),
    );

    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> createPaymentMethodGCash({required UserModel userModel}) async {
    final response = await http.post(
      Uri.parse("https://api.paymongo.com/v1/payment_methods"),
      headers: {
        "accept": "application/json",
        "content-type": "application/json",
        "authorization": "Basic ${authKey()}",
      },
      body: jsonEncode({
        "data": {
          "attributes": {
            "type": "gcash",
            "billing": {"name": userModel.fullName(), "email": userModel.email}
          }
        }
      }),
    );

    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> attachPaymentMethod({
    required String intentId,
    required String paymentMethodId,
    required String clientKey,
  }) async {
    final response = await http.post(
      Uri.parse(
        "https://api.paymongo.com/v1/payment_intents/$intentId/attach",
      ),
      headers: {
        "accept": "application/json",
        "content-type": "application/json",
        "authorization": "Basic ${authKey()}",
      },
      body: jsonEncode({
        "data": {
          "attributes": {"payment_method": paymentMethodId, "client_key": clientKey}
        }
      }),
    );

    return jsonDecode(response.body);
  }

  Future<void> checkPaymentStatus(String intentId) async {
    final response = await http.get(
      Uri.parse("https://api.paymongo.com/v1/payment_intents/$intentId"),
      headers: {
        "accept": "application/json",
        "authorization": "Basic ${authKey()}",
      },
    );

    final data = jsonDecode(response.body);

    print("Payment Status: ${data["data"]["attributes"]["status"]}");
  }
}
