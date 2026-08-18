import 'dart:math';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/services/msg91_whatsapp_service.dart';
import 'package:get/get.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class OtpController extends GetxController {
  Rx<PinInputController> otpController = PinInputController().obs;

  RxString countryCode = "".obs;
  RxString countryISOCode = "".obs;
  RxString phoneNumber = "".obs;
  RxString fullPhoneNumber = "".obs;
  RxString expectedOtp = "".obs;
  RxBool isLoading = true.obs;

  @override
  void onInit() {
    getArgument();
    super.onInit();
  }

  void getArgument() {
    final dynamic args = Get.arguments;
    if (args != null) {
      countryCode.value = args['countryCode'] ?? '';
      countryISOCode.value = args['countryISOCode'] ?? '';
      phoneNumber.value = args['phoneNumber'] ?? '';
      fullPhoneNumber.value = args['fullPhoneNumber'] ?? '';
      expectedOtp.value = args['otp'] ?? '';
    }
    isLoading.value = false;
    update();
  }

  // Returns true if entered OTP matches the one we generated and sent
  bool verifyOtp(String entered) => entered.trim() == expectedOtp.value;

  // Resend: generate new OTP and send again via MSG91
  Future<void> sendOTP() async {
    ShowToastDialog.showLoader("Sending OTP…");
    final newOtp = _generateOtp();
    final error = await Msg91WhatsappService.sendOtp(
      phoneNumber: fullPhoneNumber.value,
      otp: newOtp,
    );
    ShowToastDialog.closeLoader();
    if (error == null) {
      expectedOtp.value = newOtp;
      ShowToastDialog.showToast("OTP sent to your WhatsApp");
    } else {
      ShowToastDialog.showToast(error);
    }
  }

  static String _generateOtp() {
    final rng = Random.secure();
    return (100000 + rng.nextInt(900000)).toString();
  }
}
