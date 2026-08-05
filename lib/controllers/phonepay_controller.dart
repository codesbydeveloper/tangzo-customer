import 'dart:convert';
import 'dart:developer';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/models/payment_model/phonepe_model.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:phonepe_payment_sdk/phonepe_payment_sdk.dart';

class PhonePePaymentService {
  static bool isSucess = false;

  static PhonePe phonePe = PhonePe();

  static const String appSchema = "poolmate";

  static String tokenUrl = phonePe.isSandbox == true ? "https://api-preprod.phonepe.com/apis/pg-sandbox/v1/oauth/token" : "https://api.phonepe.com/apis/identity-manager/v1/oauth/token";

  static String orderUrl = phonePe.isSandbox == true ? "https://api-preprod.phonepe.com/apis/pg-sandbox/checkout/v2/sdk/order" : "https://api.phonepe.com/apis/pg/checkout/v2/sdk/order";

  static String statusUrl = phonePe.isSandbox == true ? "https://api-preprod.phonepe.com/apis/pg-sandbox/checkout/v2/order/" : "https://api.phonepe.com/apis/pg/checkout/v2/order/";

  static String accessToken = "";
  static String merchantOrderId = "";
  static String orderId = "";
  static String orderToken = "";

  static double amount = 0.0;

  static Future<bool> initSDK() async {
    try {
      bool init = await PhonePePaymentSdk.init(
        phonePe.isSandbox == true ? "SANDBOX" : "PRODUCTION",
        phonePe.merchantId ?? '',
        phonePe.flowId ?? '',
        true,
      );

      log("✅ PhonePe SDK Initialized: $init");
      return init;
    } catch (e) {
      log("❌ SDK Init Error: $e");
      return false;
    }
  }

  static Future<bool> generateAccessToken() async {
    try {
      final response = await http.post(
        Uri.parse(tokenUrl),
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: {
          "client_id": phonePe.clientId,
          "client_secret": phonePe.clientSecret,
          "grant_type": "client_credentials",
          "client_version": "1",
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data["access_token"] != null) {
        accessToken = data["access_token"];

        log("✅ Access Token Generated Successfully");
        return true;
      }

      log("❌ Token Failed: ${response.body}");
      return false;
    } catch (e) {
      log("⚠ Token Exception: $e");
      return false;
    }
  }

  static Future<bool> createOrder({required int amountInPaise}) async {
    try {
      amount = amountInPaise / 100;

      merchantOrderId = "TXN_${DateTime.now().millisecondsSinceEpoch}";

      final body = {
        "merchantOrderId": merchantOrderId,
        "amount": amountInPaise,

        // ✅ Required Field (Must be >= 300)
        "expireAfter": 600,

        "paymentFlow": {
          "type": "PG_CHECKOUT",
        }
      };

      log("📌 Order Create Body: ${jsonEncode(body)}");

      final response = await http.post(
        Uri.parse(orderUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "O-Bearer $accessToken",
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        orderId = data["orderId"];
        orderToken = data["token"];

        log("✅ Order Created Successfully");
        log("OrderId: $orderId");
        return true;
      }

      log("❌ Order Creation Failed: ${data["message"]}");
      return false;
    } catch (e) {
      log("⚠ Order Exception: $e");
      return false;
    }
  }

  static Future<void> startPayment() async {
    try {
      final paymentRequest = {
        "orderId": orderId,
        "merchantId": phonePe.merchantId,
        "token": orderToken,
        "paymentMode": {"type": "PAY_PAGE"},
      };

      log("💳 Payment Request: ${jsonEncode(paymentRequest)}");

      final response = await PhonePePaymentSdk.startTransaction(
        jsonEncode(paymentRequest),
        appSchema,
      );

      log("📌 Payment Response: $response");

      _handlePaymentResponse(response);
    } catch (e) {
      log("❌ Payment Exception: $e");
    }
  }

  static void _handlePaymentResponse(dynamic response) {
    if (response == null) {
      ShowToastDialog.showToast("Payment Cancelled");
      return;
    }

    final status = response["status"];

    switch (status) {
      case "SUCCESS":
        ShowToastDialog.showToast("Payment Successful 🎉");
        isSucess = true;
        Get.back(result: {
          "amount": amount.toString(),
          "paymentType": phonePe.name,
        });
        break;

      case "FAILURE":
        ShowToastDialog.showToast("Payment Failed ❌");
        isSucess = false;
        Get.back(result: false);
        break;

      default:
        ShowToastDialog.showToast("Payment Pending ⏳");
        isSucess = false;
        getOrderStatus();
        break;
    }
  }

  static Future<void> getOrderStatus() async {
    try {
      final url = Uri.parse(
        "$statusUrl$merchantOrderId/status?details=true",
      );

      log("🔍 Checking Status: $url");

      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "O-Bearer $accessToken",
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data["success"] == true) {
        final state = data["data"]["state"];

        log("✅ Payment State: $state");

        if (state == "COMPLETED") {
          ShowToastDialog.showToast("Payment Completed Successfully ✅");
        } else if (state == "FAILED") {
          ShowToastDialog.showToast("Payment Failed ❌");
        } else {
          ShowToastDialog.showToast("Payment Pending: $state ⏳");
        }
      } else {
        log("❌ Status Check Failed: ${data["message"]}");
      }
    } catch (e) {
      log("⚠ Status Exception: $e");
    }
  }

  static Future<void> payNow({required int amountInPaise}) async {
    isSucess = false;

    ShowToastDialog.showToast("Initializing Payment...");

    final init = await initSDK();
    if (!init) return;

    final tokenOk = await generateAccessToken();
    if (!tokenOk) return;

    final orderOk = await createOrder(amountInPaise: amountInPaise);
    log("orderOk ::11:: $orderOk");
    if (!orderOk) return;
    log("orderOk ::22:: $orderOk");
    await startPayment();
  }
}

// import 'dart:convert';
// import 'dart:developer';
// import 'package:http/http.dart' as http;
// import 'package:phonepe_payment_sdk/phonepe_payment_sdk.dart';
// import 'package:poolmate/model/payment_method_model.dart';

// class PhonePeSandboxPaymentService {
//   /// ✅ Sandbox Merchant Credentials
//   static PhonePe phonePe = PhonePe();

//   /// ✅ App schema (must match AndroidManifest.xml)
//   static const String appSchema = "poolmate";

//   /// ✅ API URLs
//   static String tokenUrl = phonePe.isSandbox == true ? "https://api-preprod.phonepe.com/apis/pg-sandbox/v1/oauth/token" : 'https://api.phonepe.com/apis/identity-manager/v1/oauth/token';
//   static String orderUrl = phonePe.isSandbox == true ? "https://api-preprod.phonepe.com/apis/pg-sandbox/checkout/v2/sdk/order" : 'https://api.phonepe.com/apis/pg/checkout/v2/sdk/order';
//   static String checkStatus = phonePe.isSandbox == true ? "https://api-preprod.phonepe.com/apis/pg-sandbox/checkout/v2/order/" : 'https://api.phonepe.com/apis/pg/checkout/v2/order/';

//   /// Runtime variables
//   static String accessToken = "";
//   static String orderId = "";
//   static String orderToken = "";
//   static String merchantOrderId = "";

//   // ------------------------------------------------------------
//   // ✅ Initialize PhonePe SDK
//   // ------------------------------------------------------------
//   static Future<bool> initSDK() async {
//     try {
//       accessToken = '';
//       orderId = '';
//       orderToken = '';
//       merchantOrderId = '';
//       bool init = await PhonePePaymentSdk.init(
//         phonePe.isSandbox == true ? 'SANDBOX' : 'PRODUCTION',
//         phonePe.merchantId!,
//         phonePe.flowId!,
//         true, // enable logs
//       );
//       print("✅ SDK Initialized: $init");
//       return init;
//     } catch (e) {
//       print("❌ SDK Init Error: $e");
//       return false;
//     }
//   }

//   // ------------------------------------------------------------
//   // ✅ Generate Access Token (must be fresh)
//   // ------------------------------------------------------------
//   static Future<bool> generateAccessToken() async {
//     try {
//       final response = await http.post(
//         Uri.parse(tokenUrl),
//         headers: {"Content-Type": "application/x-www-form-urlencoded"},
//         body: {
//           "client_id": phonePe.clientId,
//           "client_secret": phonePe.clientSecret,
//           "grant_type": "client_credentials",
//           "client_version": "1",
//         },
//       );

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         accessToken = data["access_token"];
//         print("✅ Access Token Generated: $accessToken");
//         return true;
//       }

//       print("❌ Access Token Failed: ${response.body}");
//       return false;
//     } catch (e) {
//       print("⚠ Token Exception: $e");
//       return false;
//     }
//   }

//   // ------------------------------------------------------------
//   // ✅ Create Order (Sandbox)
//   // ------------------------------------------------------------
//   static Future<bool> createOrder({int amountInPaise = 1000}) async {
//     try {
//       merchantOrderId = "TXN_${DateTime.now().millisecondsSinceEpoch}";
//       final body = {
//         "merchantOrderId": merchantOrderId,
//         "amount": amountInPaise, // ₹10 = 1000 paise
//         "expireAfter": phonePe.expiryTimeMinutes, // 20 minutes
//         "paymentFlow": {"type": "PG_CHECKOUT"}
//       };

//       final response = await http.post(
//         Uri.parse(orderUrl),
//         headers: {
//           "Content-Type": "application/json",
//           "Authorization": "O-Bearer $accessToken",
//         },
//         body: jsonEncode(body),
//       );

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         orderId = data["orderId"];
//         orderToken = data["token"];
//         print("✅ Order Created: $orderId, Token: $orderToken");
//         return true;
//       }

//       print("❌ Order Creation Failed: ${response.body}");
//       return false;
//     } catch (e) {
//       print("⚠ Order Exception: $e");
//       return false;
//     }
//   }

//   // ------------------------------------------------------------
//   // ✅ Start Payment (Sandbox PAY_PAGE)
//   // ------------------------------------------------------------
//   static Future<void> startPayment() async {
//     try {
//       final paymentRequest = {
//         "orderId": orderId,
//         "merchantId": phonePe.merchantId,
//         "token": orderToken,
//         "paymentMode": {"type": "PAY_PAGE"}
//       };

//       log("💳 Payment Request: ${jsonEncode(paymentRequest)}");

//       final response = await PhonePePaymentSdk.startTransaction(
//         jsonEncode(paymentRequest),
//         appSchema, // must match AndroidManifest.xml
//       );

//       log("📌 Payment Response: $response");

//       _handleResponse(response);
//     } catch (e) {
//       print("❌ Payment Exception: $e");
//     }
//   }

//   // ------------------------------------------------------------
//   // ✅ Handle Payment Response
//   // ------------------------------------------------------------
//   static void _handleResponse(dynamic response) {
//     if (response == null) {
//       print("⚠ Payment Cancelled by User");
//       return;
//     }

//     final status = response["status"];

//     if (status == "SUCCESS") {
//       print("✅ Payment Successful");
//     } else if (status == "FAILURE") {
//       print("❌ Payment Failed");
//     } else {
//       print("⏳ Payment Pending");
//     }
//   }

//   // ------------------------------------------------------------
//   // ✅  Complete Payment Flow (All Steps)
//   // ------------------------------------------------------------
//   static Future<void> payNow({int amountInPaise = 1000}) async {
//     final init = await initSDK();
//     if (!init) return;

//     final tokenGenerated = await generateAccessToken();
//     if (!tokenGenerated) return;

//     final orderCreated = await createOrder(amountInPaise: amountInPaise);
//     if (!orderCreated) return;

//     await startPayment();
//   }

//   // ------------------------------------------------------------
//   // ✅  Complete Payment Flow (All Status)
//   // ------------------------------------------------------------
//   static Future<void> getOrderStatus() async {
//     final url = Uri.parse('$checkStatus/$merchantOrderId/status?details=false');

//     try {
//       final response = await http.get(
//         url,
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': "O-Bearer $accessToken",
//         },
//       );

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         print('Order Status: $data');
//       } else {
//         print('Failed to fetch status: ${response.statusCode}');
//         print('Response: ${response.body}');
//       }
//     } catch (e) {
//       print('Error calling PhonePe API: $e');
//     }
//   }
// }
