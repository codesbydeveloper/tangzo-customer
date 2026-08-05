import 'package:customer/constant/show_toast_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';

class ChangePasswordController extends GetxController {
  RxBool isLoading = false.obs;
  Rx<TextEditingController> emailEditingController = TextEditingController().obs;

  Future<void> forgotPassword() async {
    try {
      if (emailEditingController.value.text.isEmpty) {
        ShowToastDialog.showToast("Please enter valid email'id");
        return;
      }
      ShowToastDialog.showLoader("Please wait");
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: emailEditingController.value.text.trim(),
      );
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast('${'Reset Password link sent your'} ${emailEditingController.value.text} ${'email'}');
      Get.back();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        ShowToastDialog.showToast('No user found for that email.');
      } else {
        ShowToastDialog.showToast(e.message ?? 'An error occurred');
      }
      ShowToastDialog.closeLoader();
    }
  }
}
