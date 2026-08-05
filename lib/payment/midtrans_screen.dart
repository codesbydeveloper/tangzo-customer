import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:customer/constant/show_toast_dialog.dart';
import 'package:flutter/material.dart';
import 'package:customer/widget/translated_text.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MidtransScreen extends StatefulWidget {
  final String initialURl;

  const MidtransScreen({super.key, required this.initialURl});

  @override
  State<MidtransScreen> createState() => _MidtransScreenState();
}

class _MidtransScreenState extends State<MidtransScreen> {
  WebViewController controller = WebViewController();
  bool isLoading = true;

  @override
  void initState() {
    controller.clearCache();
    initController();
    super.initState();
  }

  void initController() {
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            ShowToastDialog.closeLoader();
          },
          onNavigationRequest: (NavigationRequest navigation) async {
            log("Midtrans :: ${navigation.url}");
            if (Platform.isIOS) {
              if (navigation.url.contains('/success')) {
                Get.back(result: true);
              } else if (navigation.url.contains('/failed')) {
                Get.back(result: false);
              }
            } else {
              String? orderId = Uri.parse(navigation.url).queryParameters['merchant_order_id'];
              if (orderId != null) {
                Get.back(result: true);
              } else {
                Get.back(result: false);
              }
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.initialURl));
  }

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
        onWillPop: () async {
          _showMyDialog();
          return false;
        },
        child: Scaffold(
            appBar: AppBar(
                backgroundColor: Colors.black,
                centerTitle: false,
                leading: GestureDetector(
                  onTap: () {
                    _showMyDialog();
                  },
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                  ),
                )),
            body: Stack(alignment: Alignment.center, children: [WebViewWidget(controller: controller)])));
  }

  Future<void> _showMyDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: TranslatedText('Cancel Payment'),
          content: SingleChildScrollView(
            child: TranslatedText("Cancel Payment?"),
          ),
          actions: <Widget>[
            TextButton(
              child: TranslatedText(
                'Cancel',
                style: const TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Get.back(result: false);
                Get.back(result: false);
              },
            ),
            TextButton(
              child: TranslatedText(
                'Continue',
                style: const TextStyle(color: Colors.green),
              ),
              onPressed: () {
                Get.back(result: false);
              },
            ),
          ],
        );
      },
    );
  }
}
