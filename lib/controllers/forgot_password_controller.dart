import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/models/user_model.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ForgotPasswordController extends GetxController {
  Rx<TextEditingController> emailEditingController = TextEditingController().obs;

  Future<void> forgotPassword() async {
    final email = emailEditingController.value.text.trim().toLowerCase();
    if (email.isEmpty) {
      ShowToastDialog.showToast("Please enter a valid email.");
      return;
    }

    try {
      ShowToastDialog.showLoader("Please wait");

      UserModel? userModel = await FireStoreUtils.getUserByEmailRole(email);

      // Only block when we know this account uses Google/Apple (not email/password).
      if (userModel != null &&
          userModel.provider != null &&
          userModel.provider != 'email' &&
          userModel.provider!.isNotEmpty) {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast("This email address is not registered with an email and password.");
        return;
      }

      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast('${'Reset Password link sent your'} $email ${'email'}');
      Get.back();
    } on FirebaseAuthException catch (e) {
      ShowToastDialog.closeLoader();
      if (e.code == 'user-not-found') {
        ShowToastDialog.showToast('No user found for that email.');
      } else if (e.code == 'invalid-email') {
        ShowToastDialog.showToast('Invalid Email.');
      } else {
        ShowToastDialog.showToast(e.message ?? 'Something went wrong');
      }
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast('Something went wrong');
    }
  }
}
