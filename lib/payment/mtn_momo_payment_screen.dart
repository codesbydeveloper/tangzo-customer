import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/controllers/mtnmomo_controller.dart';
import 'package:customer/models/payment_model/mtnmomo_model.dart';
import 'package:customer/widget/translated_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum PaymentType { process, faild, succss }

class MtnPaymentScreen extends StatefulWidget {
  final MtnMomo mtnMomoSettingData;
  final double amount;
  final String? currency;

  const MtnPaymentScreen({super.key, required this.mtnMomoSettingData, required this.amount, required this.currency});

  @override
  State<MtnPaymentScreen> createState() => _MtnPaymentScreenState();
}

class _MtnPaymentScreenState extends State<MtnPaymentScreen> {
  final _formkey = GlobalKey<FormState>();
  var email = TextEditingController();
  var password = TextEditingController();
  var isLoading = false;
  var isTranLoading = false;
  var accessToken = 'false';
  Timer? time;
  PaymentType type = PaymentType.process;

  @override
  void initState() {
    super.initState();
    reset();
  }

  @override
  void dispose() {
    super.dispose();
    time?.cancel();
  }

  void reset() {
    email = TextEditingController();
    password = TextEditingController();
    isLoading = false;
    isTranLoading = false;
    accessToken = 'false';
    type = PaymentType.process;
  }

  void checkTransacationStatus() {
    // Get Payment Status
    time = Timer.periodic(const Duration(seconds: 3), (timer) async {
      String status = await MtnMomoController.getRequestToPayTransactionStatus();
      if (status == "SUCCESSFUL") {
        type = PaymentType.succss;
        setState(() {});
        callWait(check: true);
      } else {
        Future.delayed(Duration(seconds: int.parse(widget.mtnMomoSettingData.expiryTimeSeconds ?? '180')), () {
          type = PaymentType.faild;
          setState(() {});
          callWait(check: false);
        });
      }
    });
  }

  void callWait({check}) {
    time?.cancel();
    Future.delayed(const Duration(seconds: 4), () {
      Get.back(result: check);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: accessToken == "false"
          ? Form(
              key: _formkey,
              child: SafeArea(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () {
                          FocusScope.of(context).unfocus();
                          Get.back(result: false);
                        },
                        child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                            child: Icon(
                              Icons.arrow_back_outlined,
                            )),
                      ),
                      const SizedBox(height: 80),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Image.asset(
                          'assets/images/mtnmom.png',
                          width: 140,
                          height: 90,
                          fit: BoxFit.fitWidth,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TranslatedText(
                          'Enter your MTN Momo number'.tr,
                          style: const TextStyle(color: Color(0xff2e2e2e), fontSize: 18, fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TranslatedText(
                          'You will receive a payment prompt on your phone.'.tr,
                          style: const TextStyle(color: Color(0xff2e2e2e), fontSize: 14, fontWeight: FontWeight.w400),
                        ),
                      ),
                      const SizedBox(height: 10),
                      textFieldAvaria(
                          hintText: 'eg. 25677XXXXXXX',
                          label: 'Phone Number (MSISDN)'.tr,
                          controller: email,
                          validation: (value) {
                            if (value == null || value.isEmpty) {
                              return 'This field is required.'.tr;
                            }
                            return null;
                          }),
                      const SizedBox(height: 60),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: isLoading ? 120 : 100,
                              height: 45,
                              decoration: BoxDecoration(color: const Color(0xff204a6a), borderRadius: BorderRadius.circular(5)),
                              child: InkWell(
                                onTap: () async {
                                  FocusScope.of(context).unfocus();
                                  if (_formkey.currentState!.validate()) {
                                    setState(() {
                                      isLoading = true;
                                    });
                                    await MtnMomoController.requesttopayAPI(partyId: email.value.text, amount: widget.amount.toString()).then((v) {
                                      if (v == false) {
                                        ShowToastDialog.showToast("Please Enter Valid Momo Money Number".tr);
                                        setState(() {
                                          isLoading = false;
                                        });
                                      } else {
                                        checkTransacationStatus();
                                      }
                                      accessToken = '$v';
                                      setState(() {
                                        isLoading = false;
                                      });
                                    });
                                  }
                                },
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    TranslatedText(
                                      "Next".tr,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
                                    ),
                                    if (isLoading) const SizedBox(width: 10),
                                    if (isLoading)
                                      const SizedBox(
                                        height: 25,
                                        width: 25,
                                        child: Center(child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color>(Colors.white))),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : SingleChildScrollView(
              child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SizedBox(height: 80),
                Image.asset(
                  'assets/images/mtnmom.png',
                  width: 140,
                  height: 90,
                  fit: BoxFit.fitWidth,
                ),
                // CachedNetworkImage(
                //   width: 90,
                //   height: 90,
                //   imageUrl: widget.mtnMomoSettingData.image ?? '',
                //   fit: BoxFit.cover,
                //   placeholder: (context, url) => Constant.loader(),
                //   errorWidget: (context, url, error) => Image.network(Constant.userPlaceHolder),
                // ),
                const SizedBox(height: 60),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [BoxShadow(color: const Color.fromRGBO(0, 0, 0, 0.1).withOpacity(.05), offset: const Offset(0.1, 0), blurRadius: 10, spreadRadius: 3)],
                      borderRadius: BorderRadius.circular(10)),
                  child: Column(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, children: [
                    type == PaymentType.process
                        ? TranslatedText(
                            'Request has been sent to your MTN app'.tr,
                            style: const TextStyle(fontSize: 22, letterSpacing: 0.8, fontWeight: FontWeight.w600, color: Colors.black),
                          )
                        : TranslatedText(
                            type == PaymentType.succss ? 'Thank You!'.tr : 'Payment Failed!'.tr,
                            style: const TextStyle(fontSize: 24, letterSpacing: 0.8, fontWeight: FontWeight.w600, color: Colors.black),
                          ),
                    const SizedBox(height: 30),
                    type == PaymentType.process
                        ? TranslatedText(
                            'Please open your MTN Momo app, accept the payment request'.tr,
                            style: const TextStyle(height: 1.8, fontSize: 20, letterSpacing: 1, fontWeight: FontWeight.w400, color: Colors.black),
                          )
                        : TranslatedText(
                            type == PaymentType.succss ? 'Your payment request has been successfully completed'.tr : '',
                            style: const TextStyle(height: 1.8, fontSize: 20, letterSpacing: 1, fontWeight: FontWeight.w400, color: Colors.black),
                          ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TranslatedText('${widget.currency} ${widget.amount.toStringAsFixed(Constant.currencyModel!.decimalDigits!)}',
                          style: const TextStyle(fontSize: 22, letterSpacing: 0.1, fontWeight: FontWeight.w600, color: Colors.black)),
                    ),
                    const SizedBox(height: 50),
                    type == PaymentType.process
                        ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xff204a6a))))
                        : type == PaymentType.succss
                            ? Center(
                                child: CachedNetworkImage(
                                    height: 100,
                                    width: 160,
                                    fit: BoxFit.fill,
                                    imageUrl:
                                        'https://firebasestorage.googleapis.com/v0/b/yaadou-b0626.appspot.com/o/images%2FAnimation%20-%201705665100240.gif?alt=media&token=f1fc0be7-9572-4db4-967f-211db58dd86d'))
                            : Center(
                                child: CachedNetworkImage(
                                    height: 100,
                                    width: 120,
                                    fit: BoxFit.fill,
                                    imageUrl:
                                        'https://firebasestorage.googleapis.com/v0/b/yaadou-b0626.appspot.com/o/images%2FAnimation%20-%201705665369816.gif?alt=media&token=53846944-1c0f-4261-ae60-034ae4f8b36d')),
                    const SizedBox(height: 10),
                    Visibility(
                      visible: type == PaymentType.process,
                      child: Align(
                        alignment: Alignment.center,
                        child: TranslatedText("Payment is Being process".tr, style: const TextStyle(fontSize: 16, letterSpacing: 0.1, fontWeight: FontWeight.w400, color: Colors.black)),
                      ),
                    ),
                    const SizedBox(height: 50),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: TranslatedText("Do not cancel or close your application".tr, style: const TextStyle(fontSize: 16, letterSpacing: 0.1, fontWeight: FontWeight.w600, color: Colors.black)),
                    ),
                  ]),
                ),
              ]),
            )),
    );
  }
}

Widget textFieldAvaria({required String label, required String hintText, required TextEditingController controller, bool obscureText = false, required Function(String?) validation}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TranslatedText(
          label.tr,
          style: const TextStyle(color: Color(0xff2e2e2e), fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 10),
        TextFormField(
          obscureText: obscureText,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: (v) => validation(v),
          cursorColor: const Color(0xff204a6a),
          style: const TextStyle(color: Colors.black),
          decoration: InputDecoration(
              contentPadding: const EdgeInsets.all(12),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                  borderSide: const BorderSide(
                    color: Color(0xff204a6a),
                  )),
              disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(5), borderSide: const BorderSide(color: Color(0xffdcdcdc))),
              errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(5), borderSide: const BorderSide(color: Color(0xff204a6a))),
              focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(5), borderSide: const BorderSide(color: Color(0xff204a6a))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(5), borderSide: const BorderSide(color: Color(0xff204a6a))),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(5), borderSide: const BorderSide(color: Color(0xff204a6a))),
              hintText: hintText.tr,
              hintStyle: const TextStyle(color: Color.fromARGB(255, 151, 150, 150), fontSize: 15)),
          controller: controller,
        ),
      ],
    ),
  );
}
