import 'dart:developer';

import 'package:get/get.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceSearchController extends GetxController {
  Rx<stt.SpeechToText> speech = stt.SpeechToText().obs;
  RxString recognizedText = "Listening...".obs;
  RxDouble micSize = 100.0.obs;
  RxString status = ''.obs;

  @override
  void onInit() {
    startListening();
    super.onInit();
  }

  Future<void> startListening() async {
    bool available = await speech.value.initialize(
      onError: (val) => print("Speech error: $val"),
      finalTimeout: Duration(seconds: 3),
      onStatus: (value) async {
        status.value = value;
        if (status.value == 'done') {
          speech.value.stop();
          await speech.value.cancel();
          speech.value = stt.SpeechToText();
        }
        log("onStatus :: ${status.value}");
      },
    );
    if (available) {
      speech.value.listen(
        onResult: (val) {
          if (val.finalResult == true) {
            if (val.recognizedWords != '') {
              String result = val.recognizedWords.trim();
              recognizedText.value = result;
              stopListening(duration: 1);
            }
          }
        },
        localeId: 'en_IN',
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.confirmation,
          cancelOnError: true,
          partialResults: true,
        ),
      );
    }
  }

  void stopListening({required int duration}) {
    Future.delayed(Duration(seconds: duration), () async {
      speech.value.stop();
      await speech.value.cancel();
      speech.value = stt.SpeechToText();
      Get.back(result: recognizedText.value == "Listening..." || recognizedText.value.isEmpty ? '' : recognizedText.value);
    });
  }

  @override
  void onClose() {
    speech.value.stop();
    speech.value = stt.SpeechToText();
    super.onClose();
  }
}
