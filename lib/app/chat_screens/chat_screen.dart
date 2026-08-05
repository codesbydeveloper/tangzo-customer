import 'dart:async';
import 'dart:io';
import 'package:customer/app/chat_screens/full_screen_image_viewer.dart';
import 'package:customer/app/chat_screens/full_screen_video_viewer.dart';
import 'package:customer/constant/collection_name.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/controllers/chat_controller.dart';
import 'package:customer/models/conversation_model.dart';
import 'package:customer/themes/app_them_data.dart';
import 'package:customer/utils/dark_theme_provider.dart';
import 'package:customer/utils/dynamic_traslator.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:customer/utils/network_image_widget.dart';
import 'package:customer/utils/translation_notifier.dart';
import 'package:customer/widget/firebase_pagination/src/firestore_pagination.dart';
import 'package:customer/widget/firebase_pagination/src/models/view_type.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:customer/widget/translated_text.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'ChatVideoContainer.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX(
        init: ChatController(),
        builder: (controller) {
          return Scaffold(
            appBar: AppBar(
                backgroundColor: themeChange.getThem() ? AppThemeData.surfaceDark : AppThemeData.surface,
                centerTitle: false,
                titleSpacing: 0,
                title: TranslatedText(
                  controller.receivedName.value,
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    fontFamily: AppThemeData.medium,
                    fontSize: 16,
                    color: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey900,
                  ),
                ),
                bottom: PreferredSize(
                    preferredSize: Size.fromHeight(10), // height of the bottom section
                    child: Padding(
                      padding: const EdgeInsets.only(left: 55, bottom: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: TranslatedText(
                          "${"Order"} ${Constant.orderId(orderId: controller.orderId.value.toString())}",
                          style: TextStyle(
                            fontFamily: AppThemeData.medium,
                            fontSize: 14,
                            color: themeChange.getThem() ? AppThemeData.grey200 : AppThemeData.grey700,
                          ),
                        ),
                      ),
                    ))),
            body: Column(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      FocusScope.of(context).unfocus();
                    },
                    child: FirestorePagination(
                      reverse: true,
                      controller: controller.scrollController.value,
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, documentSnapshots, index) {
                        ConversationModel inboxModel = ConversationModel.fromJson(documentSnapshots[index].data() as Map<String, dynamic>);
                        return chatItemView(themeChange, context, inboxModel.senderId == FireStoreUtils.getCurrentUid(), inboxModel);
                      },
                      onEmpty: Constant.showEmptyView(message: "No Conversion found"),
                      // orderBy is compulsory to enable pagination
                      query: FireStoreUtils.fireStore.collection(CollectionName.chat).doc(controller.orderId.value).collection("thread").orderBy('createdAt', descending: true),
                      isLive: true,
                      viewType: ViewType.list,
                    ),
                  ),
                ),
                Container(
                  color: themeChange.getThem() ? AppThemeData.grey900 : AppThemeData.grey50,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            InkWell(
                                onTap: () {
                                  onCameraClick(themeChange, context, controller);
                                },
                                child: SvgPicture.asset("assets/icons/ic_picture_one.svg")),
                            Flexible(
                                child: Padding(
                              padding: const EdgeInsets.only(left: 10),
                              child: ValueListenableBuilder(
                                  valueListenable: TranslationNotifier.refresh,
                                  builder: (_, __, ___) {
                                    return TextField(
                                      textInputAction: TextInputAction.send,
                                      keyboardType: TextInputType.text,
                                      textCapitalization: TextCapitalization.sentences,
                                      controller: controller.messageController.value,
                                      decoration: InputDecoration(
                                        contentPadding: const EdgeInsets.only(top: 3, left: 10),
                                        focusedBorder: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        hintText: 'Type message here....'.tr,
                                      ),
                                      onSubmitted: (value) async {
                                        if (controller.messageController.value.text.isNotEmpty) {
                                          controller.sendMessage(controller.messageController.value.text, null, '', 'text', controller);
                                          Timer(const Duration(milliseconds: 500), () => controller.scrollController.value.jumpTo(controller.scrollController.value.position.minScrollExtent));
                                          controller.messageController.value.clear();
                                        }
                                      },
                                    );
                                  }),
                            )),
                            InkWell(
                              onTap: () {
                                if (controller.messageController.value.text.isNotEmpty) {
                                  controller.sendMessage(controller.messageController.value.text, null, '', 'text', controller);
                                  Timer(const Duration(milliseconds: 500), () => controller.scrollController.value.jumpTo(controller.scrollController.value.position.minScrollExtent));
                                  controller.messageController.value.clear();
                                }
                              },
                              child: Container(
                                margin: const EdgeInsets.only(left: 10),
                                decoration: BoxDecoration(
                                  color: themeChange.getThem() ? AppThemeData.grey700 : AppThemeData.grey200,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: SvgPicture.asset("assets/icons/ic_send.svg"),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        });
  }

  Widget chatItemView(themeChange, context, bool isMe, ConversationModel data) {
    return Container(
      padding: EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 10),
      child: isMe
          ? Align(
              alignment: Alignment.topRight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.end, crossAxisAlignment: CrossAxisAlignment.end, children: [
                    data.messageType == "text"
                        ? Container(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.75, // prevent overflow
                            ),
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12), bottomLeft: Radius.circular(12)),
                              color: AppThemeData.primary300,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            child: TranslatedText(
                              data.message.toString(),
                              style: const TextStyle(
                                fontFamily: AppThemeData.medium,
                                fontSize: 16,
                                color: AppThemeData.grey50,
                              ),
                            ),
                          )
                        : data.messageType == "image"
                            ? ClipRRect(
                                borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12), bottomLeft: Radius.circular(12)),
                                child: Stack(alignment: Alignment.center, children: [
                                  GestureDetector(
                                    onTap: () {
                                      Get.to(FullScreenImageViewer(imageUrl: data.url!.url));
                                    },
                                    child: Hero(
                                      tag: data.url!.url,
                                      child: NetworkImageWidget(
                                        imageUrl: data.url!.url,
                                        height: 100,
                                        width: 100,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ]),
                              )
                            : FloatingActionButton(
                                mini: true,
                                heroTag: data.id,
                                backgroundColor: AppThemeData.primary300,
                                onPressed: () {
                                  Get.to(FullScreenVideoViewer(heroTag: data.id.toString(), videoUrl: data.url!.url));
                                },
                                child: const Icon(
                                  Icons.play_arrow,
                                  color: Colors.white,
                                ),
                              ),
                  ]),
                  const SizedBox(height: 5),
                  TranslatedText(DateFormat('MMM d, yyyy hh:mm aa').format(DateTime.fromMillisecondsSinceEpoch(data.createdAt!.millisecondsSinceEpoch)),
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            )
          : Align(
              alignment: Alignment.topLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, children: [
                    data.messageType == "text"
                        ? Container(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.75, // prevent overflow
                            ),
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12), bottomRight: Radius.circular(12)),
                              color: themeChange.getThem() ? AppThemeData.grey700 : AppThemeData.grey200,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            child: TranslatedText(
                              data.message.toString(),
                              style: TextStyle(
                                fontFamily: AppThemeData.medium,
                                fontSize: 16,
                                color: themeChange.getThem() ? AppThemeData.grey100 : AppThemeData.grey800,
                              ),
                            ),
                          )
                        : data.messageType == "image"
                            ? ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minWidth: 50,
                                  maxWidth: 200,
                                ),
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12), bottomRight: Radius.circular(12)),
                                  child: Stack(alignment: Alignment.center, children: [
                                    GestureDetector(
                                      onTap: () {
                                        Get.to(FullScreenImageViewer(imageUrl: data.url!.url));
                                      },
                                      child: Hero(
                                        tag: data.url!.url,
                                        child: NetworkImageWidget(
                                          imageUrl: data.url!.url,
                                        ),
                                      ),
                                    ),
                                  ]),
                                ))
                            : FloatingActionButton(
                                mini: true,
                                heroTag: data.id,
                                backgroundColor: AppThemeData.primary300,
                                onPressed: () {
                                  Get.to(FullScreenVideoViewer(heroTag: data.id.toString(), videoUrl: data.url!.url));
                                },
                                child: const Icon(
                                  Icons.play_arrow,
                                  color: Colors.white,
                                ),
                              ),
                  ]),
                  const SizedBox(height: 5),
                  TranslatedText(DateFormat('MMM d, yyyy hh:mm aa').format(DateTime.fromMillisecondsSinceEpoch(data.createdAt!.millisecondsSinceEpoch)),
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
    );
  }

  void onCameraClick(DarkThemeProvider themeChange, BuildContext context, ChatController controller) {
    final action = CupertinoActionSheet(
      message: TranslatedText(
        'Send Media',
        style: TextStyle(
          fontSize: 18.0,
          color: themeChange.getThem() ? AppThemeData.grey100 : AppThemeData.grey800,
        ),
      ),
      actions: <Widget>[
        CupertinoActionSheetAction(
          isDefaultAction: false,
          onPressed: () async {
            Get.back();
            try {
              XFile? image = await controller.imagePicker.pickImage(source: ImageSource.gallery);
              if (image != null) {
                Url url = await FireStoreUtils.uploadChatImageToFireStorage(File(image.path), context);
                controller.sendMessage(controller.messageController.value.text, url, '', 'image', controller);
                Timer(const Duration(milliseconds: 500), () => controller.scrollController.value.jumpTo(controller.scrollController.value.position.minScrollExtent));
              }
            } catch (e) {
              ShowToastDialog.showToast("Storage permission is not enabled. Please allow it.");
            }
          },
          child: TranslatedText("Choose image from gallery"),
        ),
        CupertinoActionSheetAction(
          isDefaultAction: false,
          onPressed: () async {
            Get.back();
            XFile? galleryVideo = await controller.imagePicker.pickVideo(source: ImageSource.gallery);
            if (galleryVideo != null) {
              ChatVideoContainer? videoContainer = await FireStoreUtils.uploadChatVideoToFireStorage(context, File(galleryVideo.path));
              if (videoContainer != null) {
                controller.sendMessage(controller.messageController.value.text, videoContainer.videoUrl, videoContainer.thumbnailUrl, 'video', controller);
              }
            }
          },
          child: TranslatedText("Choose video from gallery"),
        ),
        CupertinoActionSheetAction(
          isDestructiveAction: false,
          onPressed: () async {
            Get.back();
            try {
              XFile? image = await controller.imagePicker.pickImage(source: ImageSource.camera);
              if (image != null) {
                Url url = await FireStoreUtils.uploadChatImageToFireStorage(File(image.path), context);
                controller.sendMessage(controller.messageController.value.text, url, '', 'image', controller);
                Timer(const Duration(milliseconds: 500), () => controller.scrollController.value.jumpTo(controller.scrollController.value.position.minScrollExtent));
              }
            } catch (e) {
              ShowToastDialog.showToast("Camera access is not enabled. Please allow camera permission.");
            }
          },
          child: TranslatedText("Take a picture"),
        ),
        // CupertinoActionSheetAction(
        //   isDestructiveAction: false,
        //   onPressed: () async {
        //     Get.back();
        //     XFile? recordedVideo = await controller.imagePicker.pickVideo(source: ImageSource.camera);
        //     if (recordedVideo != null) {
        //       ChatVideoContainer videoContainer = await FireStoreUtils.uploadChatVideoToFireStorage(File(recordedVideo.path), context);
        //       controller.sendMessage('', videoContainer.videoUrl, videoContainer.thumbnailUrl, 'video');
        //     }
        //   },
        //   child: TranslatedText("Record video"),
        // )
      ],
      cancelButton: CupertinoActionSheetAction(
        child: TranslatedText(
          'Cancel',
        ),
        onPressed: () {
          Get.back();
        },
      ),
    );
    showCupertinoModalPopup(context: context, builder: (context) => action);
  }
}
