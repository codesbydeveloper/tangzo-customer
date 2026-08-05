import 'dart:convert';
import 'dart:developer';

import 'package:crypto/crypto.dart';
import 'package:customer/app/auth_screen/signup_screen.dart';
import 'package:customer/app/dash_board_screens/dash_board_screen.dart';
import 'package:customer/app/location_permission_screen/location_permission_screen.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/models/user_model.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:customer/utils/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class LoginController extends GetxController {
  Rx<TextEditingController> emailEditingController = TextEditingController().obs;
  Rx<TextEditingController> passwordEditingController = TextEditingController().obs;

  RxBool passwordVisible = true.obs;

  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
  }

  Future<void> loginWithEmailAndPassword() async {
    ShowToastDialog.showLoader("Please wait");
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailEditingController.value.text.trim(),
        password: passwordEditingController.value.text.trim(),
      );
      UserModel? userModel = await FireStoreUtils.getUserProfile(credential.user!.uid);
      log("Login :: ${userModel?.toJson()}");
      if (userModel?.role == Constant.userRoleCustomer) {
        if (userModel?.active == true) {
          userModel?.fcmToken = await NotificationService.getToken();
          await FireStoreUtils.updateUser(userModel!);
          if (userModel.shippingAddress != null && userModel.shippingAddress!.isNotEmpty) {
            if (userModel.shippingAddress!.where((element) => element.isDefault == true).isNotEmpty) {
              Constant.selectedLocation = userModel.shippingAddress!.where((element) => element.isDefault == true).single;
            } else {
              Constant.selectedLocation = userModel.shippingAddress!.first;
            }
            Get.offAll(const DashBoardScreen());
          } else {
            Get.offAll(const LocationPermissionScreen());
          }
        } else {
          await FirebaseAuth.instance.signOut();
          ShowToastDialog.showToast("This user is disable please contact to administrator");
        }
      } else {
        await FirebaseAuth.instance.signOut();
        ShowToastDialog.showToast("This user is not created in customer application.");
      }
    } on FirebaseAuthException catch (e) {
      print(e.code);
      if (e.code == 'user-not-found') {
        ShowToastDialog.showToast("No user found for that email.");
      } else if (e.code == 'wrong-password') {
        ShowToastDialog.showToast("Wrong password provided for that user.");
      } else if (e.code == 'invalid-email') {
        ShowToastDialog.showToast("Invalid Email.");
      }
    }
    ShowToastDialog.closeLoader();
  }

  Future<void> loginWithGoogle() async {
    ShowToastDialog.showLoader("please wait...");
    await signInWithGoogle().then((value) async {
      ShowToastDialog.closeLoader();
      if (value != null) {
        if (value.additionalUserInfo!.isNewUser) {
          UserModel userModel = UserModel();
          userModel.id = value.user!.uid;
          userModel.email = value.user!.email;
          userModel.firstName = value.user!.displayName?.split(' ').first;
          userModel.lastName = value.user!.displayName?.split(' ').last;
          userModel.provider = 'google';

          ShowToastDialog.closeLoader();
          Get.off(const SignupScreen(), arguments: {
            "userModel": userModel,
            "type": "google",
          });
        } else {
          await FireStoreUtils.userExistOrNot(value.user!.uid).then((userExit) async {
            ShowToastDialog.closeLoader();
            if (userExit == true) {
              UserModel? userModel = await FireStoreUtils.getUserProfile(value.user!.uid);
              if (userModel!.role == Constant.userRoleCustomer) {
                if (userModel.active == true) {
                  userModel.fcmToken = await NotificationService.getToken();
                  await FireStoreUtils.updateUser(userModel);
                  if (userModel.shippingAddress != null && userModel.shippingAddress!.isNotEmpty) {
                    if (userModel.shippingAddress!.where((element) => element.isDefault == true).isNotEmpty) {
                      Constant.selectedLocation = userModel.shippingAddress!.where((element) => element.isDefault == true).single;
                    } else {
                      Constant.selectedLocation = userModel.shippingAddress!.first;
                    }
                    Get.offAll(const DashBoardScreen());
                  } else {
                    Get.offAll(const LocationPermissionScreen());
                  }
                } else {
                  await FirebaseAuth.instance.signOut();
                  ShowToastDialog.showToast("This user is disable please contact to administrator");
                }
              } else {
                await FirebaseAuth.instance.signOut();
                // ShowToastDialog.showToast("This user is disable please contact to administrator");
              }
            } else {
              UserModel userModel = UserModel();
              userModel.id = value.user!.uid;
              userModel.email = value.user!.email;
              userModel.firstName = value.user!.displayName?.split(' ').first;
              userModel.lastName = value.user!.displayName?.split(' ').last;
              userModel.provider = 'google';

              Get.off(const SignupScreen(), arguments: {
                "userModel": userModel,
                "type": "google",
              });
            }
          });
        }
      }
    });
  }

  Future<void> loginWithApple() async {
    ShowToastDialog.showLoader("please wait...");
    await signInWithApple().then((value) async {
      ShowToastDialog.closeLoader();
      if (value != null) {
        Map<String, dynamic> map = value;
        AuthorizationCredentialAppleID appleCredential = map['appleCredential'];
        UserCredential userCredential = map['userCredential'];
        if (userCredential.additionalUserInfo!.isNewUser) {
          UserModel userModel = UserModel();
          userModel.id = userCredential.user!.uid;
          userModel.email = appleCredential.email;
          userModel.firstName = appleCredential.givenName;
          userModel.lastName = appleCredential.familyName;
          userModel.provider = 'apple';

          ShowToastDialog.closeLoader();
          Get.off(const SignupScreen(), arguments: {
            "userModel": userModel,
            "type": "apple",
          });
        } else {
          await FireStoreUtils.userExistOrNot(userCredential.user!.uid).then((userExit) async {
            ShowToastDialog.closeLoader();
            if (userExit == true) {
              UserModel? userModel = await FireStoreUtils.getUserProfile(userCredential.user!.uid);
              if (userModel!.role == Constant.userRoleCustomer) {
                if (userModel.active == true) {
                  userModel.fcmToken = await NotificationService.getToken();
                  await FireStoreUtils.updateUser(userModel);
                  if (userModel.shippingAddress != null && userModel.shippingAddress!.isNotEmpty) {
                    if (userModel.shippingAddress!.where((element) => element.isDefault == true).isNotEmpty) {
                      Constant.selectedLocation = userModel.shippingAddress!.where((element) => element.isDefault == true).single;
                    } else {
                      Constant.selectedLocation = userModel.shippingAddress!.first;
                    }
                    Get.offAll(const DashBoardScreen());
                  } else {
                    Get.offAll(const LocationPermissionScreen());
                  }
                } else {
                  await FirebaseAuth.instance.signOut();
                  ShowToastDialog.showToast("This user is disable please contact to administrator");
                }
              } else {
                await FirebaseAuth.instance.signOut();
                // ShowToastDialog.showToast("This user is disable please contact to administrator");
              }
            } else {
              UserModel userModel = UserModel();
              userModel.id = userCredential.user!.uid;
              userModel.email = appleCredential.email;
              userModel.firstName = appleCredential.givenName;
              userModel.lastName = appleCredential.familyName;
              userModel.provider = 'apple';

              Get.off(const SignupScreen(), arguments: {
                "userModel": userModel,
                "type": "apple",
              });
            }
          });
        }
      }
    });
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn.instance;

      await googleSignIn.initialize();

      final GoogleSignInAccount googleUser = await googleSignIn.authenticate();
      if (googleUser.id.isEmpty) return null;

      UserModel? userModel = await FireStoreUtils.getUserByEmail(googleUser.email);

      if (userModel?.provider != "google" && userModel?.provider != "apple" && userModel?.provider != null) {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast("The account already exists for that email.");
        return null;
      }

      if ((userModel?.provider == "google" || userModel?.provider == "apple") && userModel?.role != "customer") {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast("The account already exists for that email.");
        return null;
      }

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

      return userCredential;
    } catch (e) {
      print("Google Sign-In Error: $e");
      return null;
    }
  }

  String sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<Map<String, dynamic>?> signInWithApple() async {
    try {
      final rawNonce = generateNonce();
      final nonce = sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final email = appleCredential.email;

      if (email != null) {
        UserModel? userModel = await FireStoreUtils.getUserByEmail(email);

        if (userModel?.provider != "google" && userModel?.provider != "apple" && userModel?.provider != null) {
          ShowToastDialog.closeLoader();
          ShowToastDialog.showToast("The account already exists for that email.");
          return null;
        }

        if ((userModel?.provider == "google" || userModel?.provider == "apple") && userModel?.role != Constant.userRoleCustomer) {
          ShowToastDialog.closeLoader();
          ShowToastDialog.showToast("The account already exists for that email.");
          return null;
        }
      }

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(oauthCredential);
      return {
        "appleCredential": appleCredential,
        "userCredential": userCredential,
      };
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        debugPrint("User cancelled Apple Sign-In");
        // You can return a specific value or null here
      } else {
        debugPrint("Apple Sign-In failed: ${e.code} - ${e.message}");
      }
    } catch (e) {
      debugPrint("Unexpected error during Apple Sign-In: $e");
    }
    return null;
  }
}
