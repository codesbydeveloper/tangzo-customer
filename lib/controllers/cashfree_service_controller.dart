import 'dart:convert';

import 'package:customer/models/payment_model/cashfree_model.dart';
import 'package:customer/models/user_model.dart';
import 'package:flutter_cashfree_pg_sdk/api/cferrorresponse/cferrorresponse.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfwebcheckoutpayment.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpaymentgateway/cfpaymentgatewayservice.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfsession/cfsession.dart';
import 'package:flutter_cashfree_pg_sdk/api/cftheme/cftheme.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfenums.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfexceptions.dart';
import 'package:http/http.dart' as http;

class CashfreeService {
  final CFPaymentGatewayService _gateway = CFPaymentGatewayService();

  Future<Map<String, String>?> createOrder({
    required Cashfree cashfree,
    required UserModel userModel,
    required double amount,
    required String paymentDesc,
  }) async {
    try {
      final baseUrl = cashfree.isSandbox == true ? "https://sandbox.cashfree.com/pg/orders" : "https://api.cashfree.com/pg/orders";

      String phone = (userModel.phoneNumber ?? "").replaceAll(RegExp(r'[^0-9]'), '');
      if (phone.isEmpty) phone = "9999999999";
      if (phone.length > 10 && phone.startsWith('91')) {
        phone = phone.substring(phone.length - 10);
      }

      final customerId = (userModel.id ?? "guest").replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final orderId = "ord_${DateTime.now().millisecondsSinceEpoch}";

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          "x-client-id": cashfree.clientId ?? "",
          "x-client-secret": cashfree.clientSecret ?? "",
          "x-api-version": "2025-01-01",
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({
          "order_id": orderId,
          "order_amount": double.parse(amount.toStringAsFixed(2)),
          "order_currency": "INR",
          "order_note": paymentDesc,
          "customer_details": {
            "customer_id": customerId,
            "customer_email": userModel.email ?? "customer@example.com",
            "customer_name": userModel.fullName().isNotEmpty ? userModel.fullName() : "Customer",
            "customer_phone": phone,
          },
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          "order_id": data["order_id"]?.toString() ?? orderId,
          "payment_session_id": data["payment_session_id"]?.toString() ?? "",
        };
      }

      final error = jsonDecode(response.body);
      throw Exception(error["message"] ?? response.body);
    } catch (e) {
      print("Cashfree createOrder error: $e");
      return null;
    }
  }

  /// Opens Cashfree Web Checkout with all methods (UPI, card, net banking, wallet, etc.).
  /// UPI apps open only after the user selects UPI inside checkout.
  Future<bool> startCheckoutPayment({
    required Cashfree cashfree,
    required UserModel userModel,
    required double amount,
    required String paymentDesc,
    required void Function(String orderId) onSuccess,
    required void Function(String message) onError,
  }) async {
    try {
      if ((cashfree.clientId ?? "").isEmpty || (cashfree.clientSecret ?? "").isEmpty) {
        onError("Cashfree credentials missing. Please configure cashfree_settings in Firebase.");
        return false;
      }

      final order = await createOrder(
        cashfree: cashfree,
        userModel: userModel,
        amount: amount,
        paymentDesc: paymentDesc,
      );

      if (order == null || (order["payment_session_id"] ?? "").isEmpty) {
        onError("Unable to create Cashfree order. Please try again.");
        return false;
      }

      _gateway.setCallback(
        (String orderId) => onSuccess(orderId),
        (CFErrorResponse error, String orderId) => onError(error.getMessage() ?? "Payment failed"),
      );

      final session = CFSessionBuilder()
          .setEnvironment(cashfree.isSandbox == true ? CFEnvironment.SANDBOX : CFEnvironment.PRODUCTION)
          .setOrderId(order["order_id"]!)
          .setPaymentSessionId(order["payment_session_id"]!)
          .build();

      final theme = CFThemeBuilder()
          .setNavigationBarBackgroundColorColor("#FF6B00")
          .setNavigationBarTextColor("#FFFFFF")
          .build();

      final payment = CFWebCheckoutPaymentBuilder().setSession(session).setTheme(theme).build();
      _gateway.doPayment(payment);
      return true;
    } on CFException catch (e) {
      onError(e.message);
      return false;
    } catch (e) {
      onError(e.toString());
      return false;
    }
  }
}
