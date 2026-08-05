import 'package:customer/constant/constant.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/themes/app_them_data.dart';
import 'package:customer/utils/dark_theme_provider.dart';
import 'package:customer/widget/translated_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebUrlServiceScreen extends StatefulWidget {
  final String initialURl;

  const WebUrlServiceScreen({
    super.key,
    required this.initialURl,
  });

  @override
  State<WebUrlServiceScreen> createState() => _WebUrlServiceScreenState();
}

class _WebUrlServiceScreenState extends State<WebUrlServiceScreen> {
  WebViewController controller = WebViewController();

  @override
  void initState() {
    initController();
    ShowToastDialog.closeLoader();
    super.initState();
  }

  void initController() {
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {},
          onPageStarted: (v) {},
          onPageFinished: (String url) {},
          onWebResourceError: (WebResourceError error) {},
          onNavigationRequest: (NavigationRequest navigation) async {
            debugPrint("--->2 ${navigation.url}");
            //Instamojo
            if (navigation.url.contains('payment_status=Credit') ||
                navigation.url.contains('payment_status=Credit') ||
                navigation.url.contains('/devstudio/thankyou') ||
                navigation.url.contains("${Constant.globalUrl}payment/success")) {
              Get.back(result: true);
            } else if (navigation.url.contains("${Constant.globalUrl}payment/failure") || navigation.url.contains("${Constant.globalUrl}payment/pending")) {
              Get.back(result: false);
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.initialURl));
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return WillPopScope(
      onWillPop: () async {
        _showMyDialog();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
            title: TranslatedText("Payment"),
            centerTitle: false,
            leading: GestureDetector(
              onTap: () {
                _showMyDialog();
              },
              child: Icon(
                Icons.arrow_back,
                color: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey800,
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
                Navigator.of(context).pop();
                Get.back(result: false);
              },
            ),
            TextButton(
              child: TranslatedText(
                'Continue',
                style: const TextStyle(color: Colors.green),
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
