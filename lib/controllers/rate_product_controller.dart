import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart' hide Constant;
import 'package:customer/constant/constant.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/models/order_model.dart';
import 'package:customer/models/product_model.dart';
import 'package:customer/models/rating_model.dart';
import 'package:customer/models/review_attribute_model.dart';
import 'package:customer/models/vendor_category_model.dart';
import 'package:customer/models/vendor_model.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class RateProductController extends GetxController {
  RxBool isLoading = true.obs;

  @override
  void onInit() {
    // TODO: implement onInit
    getArgument();
    super.onInit();
  }

  Rx<TextEditingController> commentController = TextEditingController().obs;

  Rx<OrderModel> orderModel = OrderModel().obs;
  RxString productId = "".obs;
  Rx<RatingModel> ratingModel = RatingModel().obs;
  Rx<ProductModel> productModel = ProductModel().obs;
  Rx<VendorModel> vendorModel = VendorModel().obs;
  Rx<VendorCategoryModel> vendorCategoryModel = VendorCategoryModel().obs;

  RxList<ReviewAttributeModel> reviewAttributeList = <ReviewAttributeModel>[].obs;

  RxDouble ratings = 0.0.obs;

  RxMap<String, dynamic> reviewAttribute = <String, dynamic>{}.obs;
  RxMap<String, dynamic> reviewProductAttributes = <String, dynamic>{}.obs;

  RxDouble vendorReviewSum = 0.0.obs;
  RxDouble vendorReviewCount = 0.0.obs;

  RxDouble productReviewSum = 0.0.obs;
  RxDouble productReviewCount = 0.0.obs;

  getArgument() async {
    dynamic argumentData = Get.arguments;
    if (argumentData != null) {
      orderModel.value = argumentData['orderModel'];
      productId.value = argumentData['productId'];

      await FireStoreUtils.getOrderReviewsByID(orderModel.value.id.toString(), productId.value).then(
        (value) {
          if (value != null) {
            ratingModel.value = value;
            ratings.value = value.rating ?? 0.0;
            commentController.value.text = value.comment.toString();
            reviewAttribute.value = value.reviewAttributes!;
            images.addAll(value.photos ?? []);
          }
        },
      );

      await FireStoreUtils.getProductById(productId.value.split('~').first).then(
        (value) {
          if (value != null) {
            productModel.value = value;
            if (ratingModel.value.id != null) {
              productReviewCount.value = ((value.reviewsCount ?? 0.0) - 1.0);
              productReviewSum.value = ((value.reviewsSum ?? 0.0) - ratings.value);

              if (value.reviewAttributes != null) {
                value.reviewAttributes!.forEach((key, value) {
                  ReviewsAttribute reviewsAttributeModel = ReviewsAttribute.fromJson(value);
                  reviewsAttributeModel.reviewsCount = ((reviewsAttributeModel.reviewsCount ?? 0.0) - 1);
                  reviewsAttributeModel.reviewsSum = reviewsAttributeModel.reviewsSum! - reviewAttribute[key];
                  reviewProductAttributes.addEntries([MapEntry(key, reviewsAttributeModel.toJson())]);
                });
              }
            } else {
              productReviewCount.value = double.parse(value.reviewsCount.toString());
              productReviewSum.value = double.parse(value.reviewsSum.toString());
              if (value.reviewAttributes != null) {
                reviewProductAttributes.value = value.reviewAttributes!;
              }
            }
          }
        },
      );

      await FireStoreUtils.getVendorById(productModel.value.vendorID.toString()).then(
        (value) {
          if (value != null) {
            vendorModel.value = value;
            if (ratingModel.value.id != null) {
              vendorReviewCount.value = ((value.reviewsCount ?? 0.0) - 1.0);
              vendorReviewSum.value = ((value.reviewsSum ?? 0.0) - ratings.value);
            } else {
              vendorReviewCount.value = double.parse(value.reviewsCount.toString());
              vendorReviewSum.value = double.parse(value.reviewsSum.toString());
            }
          }
        },
      );

      await FireStoreUtils.getVendorCategoryByCategoryId(productModel.value.categoryID.toString()).then((value) async {
        if (value != null) {
          vendorCategoryModel.value = value;
          for (var element in vendorCategoryModel.value.reviewAttributes!) {
            await FireStoreUtils.getVendorReviewAttribute(element).then((value) {
              reviewAttributeList.add(value!);
            });
          }
        }
      });
    }

    isLoading.value = false;
  }

  Future<void> saveRating() async {
    if (ratings.value != 0.0) {
      ShowToastDialog.showLoader("Please wait");
      log("reviewsCount :11:: ${productReviewCount.value}+1.0 :: ${((productReviewCount.value) + 1.0)}");
      productModel.value.reviewsCount = ((productReviewCount.value) + 1.0);
      log("reviewsCount :22:: ${productReviewSum.value}+${ratings.value} :: ${(productReviewSum.value + ratings.value)}");
      productModel.value.reviewsSum = (productReviewSum.value + ratings.value);
      log("reviewsCount :33:: ${reviewProductAttributes}");
      productModel.value.reviewAttributes = reviewProductAttributes;

      log("reviewsCount :44:: ${vendorReviewCount.value}+1.0 :: ${((vendorReviewCount.value) + 1.0)}");
      vendorModel.value.reviewsCount = ((vendorReviewCount.value) + 1.0);
      log("reviewsCount :55:: ${vendorReviewSum.value}+${ratings.value} :: ${vendorReviewSum.value + ratings.value}");
      vendorModel.value.reviewsSum = vendorReviewSum.value + ratings.value;

      if (reviewProductAttributes.isEmpty) {
        reviewAttribute.forEach((key, value) {
          ReviewsAttribute reviewsAttributeModel = ReviewsAttribute(reviewsCount: 1, reviewsSum: value);
          reviewProductAttributes.addEntries([MapEntry(key, reviewsAttributeModel.toJson())]);
        });
      } else {
        reviewProductAttributes.forEach((key, value) {
          ReviewsAttribute reviewsAttributeModel = ReviewsAttribute.fromJson(value);
          reviewsAttributeModel.reviewsCount = ((reviewsAttributeModel.reviewsCount ?? 0.0) + 1.0);
          reviewsAttributeModel.reviewsSum = ((reviewsAttributeModel.reviewsSum ?? 0.0) + reviewAttribute[key]);
          reviewProductAttributes.addEntries([MapEntry(key, reviewsAttributeModel.toJson())]);
        });
      }

      for (int i = 0; i < images.length; i++) {
        if (images[i].runtimeType == XFile) {
          String url = await Constant.uploadUserImageToFireStorage(
            File(images[i].path),
            "profileImage/${FireStoreUtils.getCurrentUid()}",
            File(images[i].path).path.split('/').last,
          );
          images.removeAt(i);
          images.insert(i, url);
        }
      }

      RatingModel ratingProduct = RatingModel(
        productId: productId.value,
        comment: commentController.value.text,
        photos: images,
        rating: ratings.value,
        customerId: FireStoreUtils.getCurrentUid(),
        id: ratingModel.value.id != null && ratingModel.value.id!.isNotEmpty ? ratingModel.value.id : Constant.getUuid(),
        orderId: orderModel.value.id,
        vendorId: productModel.value.vendorID,
        createdAt: Timestamp.now(),
        uname: Constant.userModel!.fullName(),
        profile: Constant.userModel!.profilePictureURL,
        reviewAttributes: reviewAttribute,
      );

      await FireStoreUtils.setRatingModel(ratingProduct);
      await FireStoreUtils.updateVendor(vendorModel.value);
      await FireStoreUtils.setProduct(productModel.value);
      ShowToastDialog.closeLoader();
      Get.back();
      ShowToastDialog.showToast("Review submitted successfully");
    } else {
      ShowToastDialog.showToast("Please add rate for food item.");
      ShowToastDialog.closeLoader();
    }
  }

  final ImagePicker _imagePicker = ImagePicker();
  RxList images = <dynamic>[].obs;

  Future pickFile({required ImageSource source}) async {
    try {
      XFile? image = await _imagePicker.pickImage(source: source);
      if (image == null) return;
      images.add(image);
      Get.back();
    } catch (e) {
      if (source == ImageSource.camera) {
        ShowToastDialog.showToast("Camera access is not enabled. Please allow camera permission.");
      } else {
        ShowToastDialog.showToast("Storage permission is not enabled. Please allow it.");
      }
    }
  }
}
