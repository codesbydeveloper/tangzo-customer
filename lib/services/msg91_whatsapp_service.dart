/// DEPRECATED (Phase 5): WhatsApp OTP is sent by Cloud Functions only.
/// Do not call this from the Flutter apps — credentials must not ship in clients.
/// Kept as a stub so accidental imports fail loudly.
class Msg91WhatsappService {
  static Future<String?> sendOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    throw UnsupportedError(
      'Client MSG91 OTP is disabled. Use OtpApi → Cloud Functions sendWhatsAppOtp.',
    );
  }
}
