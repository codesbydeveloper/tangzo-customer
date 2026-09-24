import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/services/otp_api.dart';
import 'package:get/get.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class OtpController extends GetxController {
  Rx<PinInputController> otpController = PinInputController().obs;

  RxString countryCode = "".obs;
  RxString countryISOCode = "".obs;
  RxString phoneNumber = "".obs;
  RxString fullPhoneNumber = "".obs;
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
    }
    isLoading.value = false;
    update();
  }

  Future<bool> verifyOtp(String entered) async {
    return OtpApi.verifyOtp(
      phoneNumber: fullPhoneNumber.value,
      otp: entered.trim(),
    );
  }

  Future<void> sendOTP() async {
    ShowToastDialog.showLoader("Sending OTP…");
    final error = await OtpApi.sendOtp(phoneNumber: fullPhoneNumber.value);
    ShowToastDialog.closeLoader();
    if (error == null) {
      ShowToastDialog.showToast("OTP sent to your WhatsApp");
    } else {
      ShowToastDialog.showToast(error);
    }
  }
}
