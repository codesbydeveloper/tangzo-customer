import 'dart:math';
import 'package:customer/app/auth_screen/otp_screen.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/services/msg91_whatsapp_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PhoneNumberController extends GetxController {
  Rx<TextEditingController> phoneNUmberEditingController =
      TextEditingController().obs;
  Rx<TextEditingController> countryCodeEditingController =
      TextEditingController(text: Constant.defaultCountryCode).obs;
  Rx<TextEditingController> countryISOCodeEditingController =
      TextEditingController(text: Constant.defaultCountryCode).obs;

  // Generates a 6-digit OTP locally
  static String _generateOtp() {
    final rng = Random.secure();
    return (100000 + rng.nextInt(900000)).toString();
  }

  Future<void> sendCode() async {
    ShowToastDialog.showLoader("Please wait");

    // Strip leading + if present; MSG91 expects digits only (country code + number)
    final rawCountry =
        countryCodeEditingController.value.text.replaceAll('+', '');
    final rawPhone = phoneNUmberEditingController.value.text.trim();
    final fullNumber = '$rawCountry$rawPhone'; // e.g. 919876543210

    final otp = _generateOtp();

    final error = await Msg91WhatsappService.sendOtp(
      phoneNumber: fullNumber,
      otp: otp,
    );

    ShowToastDialog.closeLoader();

    if (error == null) {
      Get.to(const OtpScreen(), arguments: {
        "countryCode": countryCodeEditingController.value.text,
        "countryISOCode": countryISOCodeEditingController.value.text,
        "phoneNumber": rawPhone,
        "fullPhoneNumber": fullNumber,
        "otp": otp,
      });
    } else {
      ShowToastDialog.showToast(error);
    }
  }
}
