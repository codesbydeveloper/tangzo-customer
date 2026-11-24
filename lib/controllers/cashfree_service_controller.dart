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

  String _ordersBaseUrl(Cashfree cashfree) {
    return cashfree.isSandbox == true
        ? "https://sandbox.cashfree.com/pg/orders"
        : "https://api.cashfree.com/pg/orders";
  }

  Map<String, String> _authHeaders(Cashfree cashfree) {
    return {
      "x-client-id": cashfree.clientId ?? "",
      "x-client-secret": cashfree.clientSecret ?? "",
      "x-api-version": "2025-01-01",
      "Content-Type": "application/json",
      "Accept": "application/json",
    };
  }

  Future<Map<String, String>?> createOrder({
    required Cashfree cashfree,
    required UserModel userModel,
    required double amount,
    required String paymentDesc,
  }) async {
    try {
      final baseUrl = _ordersBaseUrl(cashfree);

      String phone = (userModel.phoneNumber ?? "").replaceAll(RegExp(r'[^0-9]'), '');
      if (phone.isEmpty) phone = "9999999999";
      if (phone.length > 10 && phone.startsWith('91')) {
        phone = phone.substring(phone.length - 10);
      }

      final customerId = (userModel.id ?? "guest").replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final orderId = "ord_${DateTime.now().millisecondsSinceEpoch}";

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: _authHeaders(cashfree),
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

  /// Confirms money actually captured. SDK success callback alone is NOT enough.
  /// Returns true only when Cashfree reports order_status == PAID.
  Future<bool> verifyOrderPaid({
    required Cashfree cashfree,
    required String orderId,
    int maxAttempts = 6,
  }) async {
    if (orderId.trim().isEmpty) return false;
    final url = "${_ordersBaseUrl(cashfree)}/${Uri.encodeComponent(orderId.trim())}";

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        final response = await http.get(Uri.parse(url), headers: _authHeaders(cashfree));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final status = (data["order_status"] ?? "").toString().toUpperCase();
          print("Cashfree verify attempt ${attempt + 1}: order=$orderId status=$status");
          if (status == "PAID") return true;
          // Terminal failure states — stop early.
          if (status == "EXPIRED" ||
              status == "TERMINATED" ||
              status == "CANCELLED" ||
              status == "FAILED") {
            return false;
          }
        } else {
          print("Cashfree verify HTTP ${response.statusCode}: ${response.body}");
        }
      } catch (e) {
        print("Cashfree verifyOrderPaid error: $e");
      }
      // ACTIVE / PENDING may settle shortly after SDK callback.
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    return false;
  }

  /// Opens Cashfree Web Checkout. Calls [onSuccess] only after Get Order == PAID.
  Future<bool> startCheckoutPayment({
    required Cashfree cashfree,
    required UserModel userModel,
    required double amount,
    required String paymentDesc,
    required void Function(String orderId) onSuccess,
    required void Function(String message) onError,
    void Function()? onVerifying,
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
        (String orderId) {
          // SDK callback ≠ paid. Verify with Cashfree before fulfilling.
          Future<void>(() async {
            onVerifying?.call();
            final paid = await verifyOrderPaid(cashfree: cashfree, orderId: orderId);
            if (paid) {
              onSuccess(orderId);
            } else {
              onError(
                "Payment not confirmed by Cashfree. If money was deducted it will reflect after bank confirmation — please do not retry immediately.",
              );
            }
          });
        },
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
