import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;

class Msg91WhatsappService {
  static const String _baseUrl = 'https://control.msg91.com/api/v5/whatsapp/whatsapp-outbound-message/bulk/';

  // Replace with your MSG91 auth key — store in gitignored secrets or Firestore
  static const String authKey = '561409Ap2sdju76a82bc30P1';

  // The WhatsApp business number integrated in your MSG91 account
  static const String integratedNumber = '15553575042';

  // Template name configured in MSG91
  static const String templateName = 'authentication';

  // Sends the WhatsApp OTP to [phoneNumber] (e.g. "919876543210" — country code + number, no +)
  // [otp] is the 6-digit code you generate locally before calling this method.
  static Future<String?> sendOtp({required String phoneNumber, required String otp}) async {
    try {
      final body = jsonEncode({
        "integrated_number": integratedNumber,
        "content_type": "template",
        "payload": {
          "messaging_product": "whatsapp",
          "type": "template",
          "template": {
            "name": templateName,
            "language": {"code": "en", "policy": "deterministic"},
            "namespace": null,
            "to_and_components": [
              {
                "to": [phoneNumber],
                "components": {
                  "body_1": {"type": "text", "value": otp},
                  "button_1": {"subtype": "url", "type": "text", "value": otp}
                }
              }
            ]
          }
        }
      });

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
          'authkey': authKey,
        },
        body: body,
      );

      log('MSG91 WhatsApp sendOtp status: ${response.statusCode}');
      log('MSG91 WhatsApp sendOtp body: ${response.body}');

      final json = jsonDecode(response.body);
      if (response.statusCode == 200 && json['type'] != 'error') {
        return null;
      }
      return json['message']?.toString() ?? json['error']?.toString() ?? response.body;
    } catch (e) {
      log('MSG91 WhatsApp sendOtp error: $e');
      return e.toString();
    }
  }
}
