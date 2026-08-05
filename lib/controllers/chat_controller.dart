import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer/constant/send_notification.dart';
import 'package:customer/models/conversation_model.dart';
import 'package:customer/models/inbox_model.dart';
import 'package:customer/models/user_model.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class ChatController extends GetxController {
  Rx<TextEditingController> messageController = TextEditingController().obs;

  Rx<ScrollController> scrollController = ScrollController().obs;

  @override
  void onInit() {
    // TODO: implement onInit

    getArgument();
    super.onInit();
  }

  RxBool isLoading = true.obs;
  RxString orderId = "".obs;
  RxString senderId = "".obs;
  RxString senderName = "".obs;
  RxString senderProfileUrl = "".obs;
  RxString receivedId = "".obs;
  RxString receivedName = "".obs;
  RxString receivedProfileUrl = "".obs;
  RxString token = "".obs;
  RxString chatType = "".obs;
  UserModel? receiverUser;

  Future<void> getArgument() async {
    dynamic argumentData = Get.arguments;
    if (argumentData != null) {
      orderId.value = argumentData['orderId'] ?? '';
      senderId.value = argumentData['senderId'] ?? '';
      senderName.value = argumentData['senderName'] ?? '';
      senderProfileUrl.value = argumentData['senderProfileUrl'] ?? "";
      receivedId.value = argumentData['receivedId'] ?? '';
      receivedName.value = argumentData['receivedName'] ?? '';
      receivedProfileUrl.value = argumentData['receivedProfileUrl'] ?? "";
      token.value = argumentData['token'] ?? '';
      chatType.value = argumentData['chatType'] ?? "";
      receiverUser = await FireStoreUtils.getUserProfile(receivedId.value);
    }

    setSeen();
    isLoading.value = false;
  }

  Future<void> setSeen() async {
    FireStoreUtils.setSeenChatForOrder(orderId: orderId.value);
  }

  Future<void> sendMessage(String message, Url? url, String videoThumbnail, String messageType, ChatController controller) async {
    List<String> senderReceiverId = [controller.senderId.value, controller.receivedId.value];
    InboxModel inboxModel = InboxModel(
        chatType: controller.chatType.value,
        senderReceiverId: senderReceiverId,
        lastSenderId: senderId.value,
        senderId: senderId.value,
        receiverId: receivedId.value,
        createdAt: Timestamp.now(),
        orderId: orderId.value,
        lastMessage: messageController.value.text,
        lastMessageType: messageType,
        type: 'orderChat');

    await FireStoreUtils.addInbox(inboxModel);

    ConversationModel conversationModel = ConversationModel(
        id: const Uuid().v4(),
        message: message,
        senderId: FireStoreUtils.getCurrentUid(),
        receiverId: receivedId.value,
        createdAt: Timestamp.now(),
        url: url,
        orderId: orderId.value,
        messageType: messageType,
        videoThumbnail: videoThumbnail,
        seen: false);

    if (url != null) {
      if (url.mime.contains('image')) {
        conversationModel.message = "sent a message".tr;
      } else if (url.mime.contains('video')) {
        conversationModel.message = "Sent a video".tr;
      } else if (url.mime.contains('audio')) {
        conversationModel.message = "Sent a audio".tr;
      }
    }

    await FireStoreUtils.addChat(conversationModel);
    print("sendChatFcmMessage ::11:: ${receivedName.value} :: ${conversationModel.message} :: ${receiverUser?.fcmToken}");
    print("sendChatFcmMessage ::22:: ${inboxModel.type} :: ${inboxModel.chatType} :: $orderId :: ${conversationModel.senderId}");
    await SendNotification.sendChatFcmMessage(
        title: receivedName.value,
        message: conversationModel.message.toString(),
        token: receiverUser?.fcmToken ?? '',
        payload: {'type': inboxModel.type, 'chatType': inboxModel.chatType, 'orderId': orderId, 'senderId': conversationModel.senderId});
  }

  final ImagePicker imagePicker = ImagePicker();

// Future pickFile({required ImageSource source}) async {
//   try {
//     XFile? image = await imagePicker.pickImage(source: source);
//     if (image == null) return;
//     Url url = await FireStoreUtils.uploadChatImageToFireStorage(File(image.path), Get.context!);
//     sendMessage('', url, '', 'image');
//     Get.back();
//   } on PlatformException catch (e) {
//     ShowToastDialog.showToast("${"failed_to_pick"} : \n $e");
//   }
// }
}
