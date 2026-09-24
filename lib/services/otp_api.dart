import 'dart:convert';

import 'package:customer/firebase_options.dart';
import 'package:http/http.dart' as http;

/// Server-side WhatsApp OTP via Cloud Functions (Redis + MSG91).
/// OTP is never returned to the client.
class OtpApi {
  OtpApi._();

  static Uri _callableUri(String functionName) {
    final projectId = DefaultFirebaseOptions.currentPlatform.projectId;
    return Uri.parse(
      'https://us-central1-$projectId.cloudfunctions.net/$functionName',
    );
  }

  static Future<_CallableResult> _call(
    String functionName,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http
          .post(
            _callableUri(functionName),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'data': data}),
          )
          .timeout(const Duration(seconds: 20));

      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['error'] != null) {
        final err = decoded['error'];
        final message = err is Map
            ? (err['message']?.toString() ?? 'Request failed')
            : err.toString();
        return _CallableResult(ok: false, message: message);
      }
      if (response.statusCode != 200) {
        return _CallableResult(ok: false, message: 'Request failed (${response.statusCode})');
      }
      final result = decoded is Map ? decoded['result'] : null;
      if (result is Map && result['ok'] == true) {
        return _CallableResult(ok: true);
      }
      return _CallableResult(ok: false, message: 'Unexpected response');
    } catch (e) {
      return _CallableResult(ok: false, message: e.toString());
    }
  }

  /// Returns null on success, or an error message (never includes OTP).
  static Future<String?> sendOtp({required String phoneNumber}) async {
    final result = await _call('sendWhatsAppOtp', {'phoneNumber': phoneNumber});
    return result.ok ? null : (result.message ?? 'Failed to send OTP');
  }

  static Future<bool> verifyOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    final result = await _call('verifyWhatsAppOtp', {
      'phoneNumber': phoneNumber,
      'otp': otp,
    });
    return result.ok;
  }
}

class _CallableResult {
  final bool ok;
  final String? message;
  _CallableResult({required this.ok, this.message});
}
