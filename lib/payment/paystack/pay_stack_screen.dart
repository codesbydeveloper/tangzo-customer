import 'dart:async';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/payment/paystack/paystack_url_genrater.dart';
import 'package:customer/themes/app_them_data.dart';
import 'package:flutter/material.dart';
import 'package:customer/widget/translated_text.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PayStackScreen extends StatefulWidget {
  final String initialURl;
  final String reference;
  final String amount;
  final String secretKey;
  final String callBackUrl;

  const PayStackScreen({super.key, required this.initialURl, required this.reference, required this.amount, required this.secretKey, required this.callBackUrl});

  @override
  State<PayStackScreen> createState() => _PayStackScreenState();
}

class _PayStackScreenState extends State<PayStackScreen> {
  WebViewController controller = WebViewController();

  @override
  void initState() {
    initController();
    super.initState();
  }

  void initController() {
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {},
          onPageStarted: (String url) {
            ShowToastDialog.closeLoader();
          },
          onPageFinished: (String url) {},
          onWebResourceError: (WebResourceError error) {},
          onNavigationRequest: (NavigationRequest navigation) async {
            debugPrint("--->2${navigation.url}");
            debugPrint("--->2" "${widget.callBackUrl}?trxref=${widget.reference}&reference=${widget.reference}");
            if (navigation.url == 'https://foodieweb.siswebapp.com/success?trxref=${widget.reference}&reference=${widget.reference}' ||
                (navigation.url == '${widget.callBackUrl}?trxref=${widget.reference}&reference=${widget.reference}') ||
                (navigation.url == "https://hello.pstk.xyz/callback") ||
                (navigation.url == 'https://standard.paystack.co/close') ||
                (navigation.url == 'https://talazo.app/login')) {
              final isDone = await PayStackURLGen.verifyTransaction(secretKey: widget.secretKey, reference: widget.reference, amount: widget.amount);
              Get.back(result: isDone);
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.initialURl));
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _showMyDialog();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
            backgroundColor: AppThemeData.grey50,
            title: TranslatedText("Payment"),
            centerTitle: false,
            leading: GestureDetector(
              onTap: () {
                _showMyDialog();
              },
              child: const Icon(
                Icons.arrow_back,
              ),
            )),
        body: WebViewWidget(controller: controller),
      ),
    );
  }

  Future<void> _showMyDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const TranslatedText('Cancel Payment'),
          content: const SingleChildScrollView(
            child: TranslatedText("Cancel Payment?"),
          ),
          actions: <Widget>[
            TextButton(
              child: const TranslatedText(
                'Cancel',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const TranslatedText(
                'Continue',
                style: TextStyle(color: Colors.green),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
