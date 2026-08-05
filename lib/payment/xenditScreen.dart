import 'dart:async';
import 'dart:convert';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/payment/xenditModel.dart';
import 'package:flutter/material.dart';
import 'package:customer/widget/translated_text.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';

// class XenditScreen extends StatefulWidget {
//   final String initialURl;
//   final String transId;
//   final String apiKey;

//   const XenditScreen({super.key, required this.initialURl, required this.transId, required this.apiKey});

//   @override
//   State<XenditScreen> createState() => _XenditScreenState();
// }

// class _XenditScreenState extends State<XenditScreen> {
//   WebViewController controller = WebViewController();
//   bool isLoading = true;

//   @override
//   void initState() {
//     controller.clearCache();
//     initController();
//     callTransaction();
//     super.initState();
//   }

//   void callTransaction() {
//     Timer? timer;
//     timer = Timer.periodic(const Duration(seconds: 4), (Timer t) async {
//       if (!mounted) {
//         timer?.cancel();
//         return;
//       }
//       await Future.delayed(const Duration(seconds: 5)).then((v) async {
//         final value = await checkStatus(paymentId: widget.transId);
//         if (!mounted) {
//           timer?.cancel();
//           return;
//         }
//         if (value.status == 'PAID' || value.status == 'SETTLED') {
//           if (mounted) {
//             timer?.cancel();
//             Get.back(result: true);
//           }
//         } else if (value.status == 'FAILED') {
//           if (mounted) {
//             timer?.cancel();
//             Get.back(result: false);
//           }
//         }
//       });
//     });
//   }

//   @override
//   void dispose() {
//     super.dispose();
//   }

//   void initController() {
//     controller = WebViewController()
//       ..setJavaScriptMode(JavaScriptMode.unrestricted)
//       ..setBackgroundColor(const Color(0x00000000))
//       ..setNavigationDelegate(
//         NavigationDelegate(
//           onPageFinished: ((url) {
//             if (mounted) {
//               setState(() {
//                 isLoading = false;
//               });
//             }
//           }),
//           onPageStarted: (String url) {
//             ShowToastDialog.closeLoader();
//           },
//           onWebResourceError: (WebResourceError error) {},
//           onNavigationRequest: (NavigationRequest navigation) async {
//             return NavigationDecision.navigate;
//           },
//         ),
//       )
//       ..loadRequest(Uri.parse(widget.initialURl));
//   }

//   @override
//   Widget build(BuildContext context) {
//     // ignore: deprecated_member_use
//     return WillPopScope(
//         onWillPop: () async {
//           _showMyDialog();
//           return false;
//         },
//         child: Scaffold(
//             appBar: AppBar(
//                 backgroundColor: Colors.black,
//                 centerTitle: false,
//                 leading: GestureDetector(
//                   onTap: () {
//                     _showMyDialog();
//                   },
//                   child: const Icon(
//                     Icons.arrow_back,
//                     color: Colors.white,
//                   ),
//                 )),
//             body: Stack(alignment: Alignment.center, children: [WebViewWidget(controller: controller), Visibility(visible: isLoading, child: const Center(child: CircularProgressIndicator()))])));
//   }

//   Future<void> _showMyDialog() async {
//     return showDialog<void>(
//       context: context,
//       barrierDismissible: true, // user must tap button!
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: TranslatedText('Cancel Payment'),
//           content: SingleChildScrollView(
//             child: TranslatedText("cancel Payment?"),
//           ),
//           actions: <Widget>[
//             TextButton(
//               child: TranslatedText(
//                 'Cancel',
//                 style: const TextStyle(color: Colors.red),
//               ),
//               onPressed: () {
//                 Navigator.of(context).pop(false);
//                 Navigator.of(context).pop(false);
//               },
//             ),
//             TextButton(
//               child: TranslatedText(
//                 'Continue',
//                 style: const TextStyle(color: Colors.green),
//               ),
//               onPressed: () {
//                 Navigator.of(context).pop(false);
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }

//   Future<XenditModel> checkStatus({required String paymentId}) async {
//     // API endpoint
//     var url = Uri.parse('https://api.xendit.co/v2/invoices/$paymentId');

//     // Headers
//     var headers = {
//       'Content-Type': 'application/json',
//       'Authorization': generateBasicAuthHeader(widget.apiKey.toString()),
//     };

//     // Making the POST request
//     var response = await http.get(url, headers: headers);

//     // Checking the response status
//     if (response.statusCode == 200) {
//       XenditModel model = XenditModel.fromJson(jsonDecode(response.body));
//       return model;
//     } else {
//       return XenditModel();
//     }
//   }

//   String generateBasicAuthHeader(String apiKey) {
//     String credentials = '$apiKey:';
//     String base64Encoded = base64Encode(utf8.encode(credentials));
//     return 'Basic $base64Encoded';
//   }
// }
class XenditScreen extends StatefulWidget {
  final String initialUrl;
  final String transId;
  final String apiKey;

  const XenditScreen({
    super.key,
    required this.initialUrl,
    required this.transId,
    required this.apiKey,
  });

  @override
  State<XenditScreen> createState() => _XenditScreenState();
}

class _XenditScreenState extends State<XenditScreen> {
  late final WebViewController controller;
  Timer? _timer;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initController();
    _startTransactionPolling();
  }

  /// ---------------- WEBVIEW ----------------
  void _initController() {
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            ShowToastDialog.closeLoader();
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.initialUrl));
  }

  /// ---------------- PAYMENT STATUS POLLING ----------------
  void _startTransactionPolling() {
    _timer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!mounted) return;

      final response = await checkStatus(paymentId: widget.transId);

      if (!mounted) return;

      switch (response.status) {
        case 'PAID':
        case 'SETTLED':
          _timer?.cancel();
          Get.back(result: true);
          break;

        case 'FAILED':
        case 'EXPIRED':
          _timer?.cancel();
          Get.back(result: false);
          break;

        default:
          break;
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// ---------------- CANCEL DIALOG ----------------
  Future<void> _showCancelDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: TranslatedText('Cancel Payment'),
        content: TranslatedText('CancelPayment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: TranslatedText('Cancel', style: const TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: TranslatedText('Continue', style: const TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );

    if (result == true) {
      _timer?.cancel();
      Get.back(result: false);
    }
  }

  /// ---------------- API CALL ----------------
  Future<XenditModel> checkStatus({required String paymentId}) async {
    final url = Uri.parse('https://api.xendit.co/v2/invoices/$paymentId');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': _generateBasicAuthHeader(widget.apiKey),
    };

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        return XenditModel.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint("Xendit status error: $e");
    }

    return XenditModel();
  }

  String _generateBasicAuthHeader(String apiKey) {
    final credentials = '$apiKey:';
    final base64Encoded = base64Encode(utf8.encode(credentials));
    return 'Basic $base64Encoded';
  }

  /// ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _showCancelDialog();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: _showCancelDialog,
          ),
        ),
        body: Stack(
          alignment: Alignment.center,
          children: [
            WebViewWidget(controller: controller),
          ],
        ),
      ),
    );
  }
}
