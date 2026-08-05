import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/models/user_model.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';

class ForgotPasswordController extends GetxController {
  Rx<TextEditingController> emailEditingController = TextEditingController().obs;

  Future<void> forgotPassword() async {
    try {
      if (emailEditingController.value.text.isEmpty) {
        ShowToastDialog.showToast("Please enter a valid email.");
        return;
      }
      ShowToastDialog.showLoader("Please wait");
      UserModel? userModel = await FireStoreUtils.getUserByEmailRole(emailEditingController.value.text);
      if (userModel?.provider != 'email') {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast("This email address is not registered with an email and password.");
        return;
      }

      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: emailEditingController.value.text.trim(),
      );
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast('${'Reset Password link sent your'} ${emailEditingController.value.text} ${'email'}');
      Get.back();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        ShowToastDialog.showToast('No user found for that email.');
      }
    }
  }
}
