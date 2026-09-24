import 'dart:convert';

import 'package:customer/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class DriverLiveLocation {
  final double latitude;
  final double longitude;
  final double heading;
  final int timestamp;

  const DriverLiveLocation({
    required this.latitude,
    required this.longitude,
    required this.heading,
    required this.timestamp,
  });
}

/// Authenticated client for Redis-backed driver location (Cloud Functions).
/// Never connects to Redis directly.
class DriverTrackingApi {
  DriverTrackingApi._();

  static Uri _callableUri(String functionName) {
    final projectId = DefaultFirebaseOptions.currentPlatform.projectId;
    return Uri.parse(
      'https://us-central1-$projectId.cloudfunctions.net/$functionName',
    );
  }

  /// Returns null when Redis has no live location (TTL expired / offline).
  /// [orderId] is required for authorization when reading another driver's location.
  static Future<DriverLiveLocation?> getDriverLocation({
    required String driverId,
    required String orderId,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return null;
      }

      final idToken = await user.getIdToken();
      final response = await http
          .post(
            _callableUri('getDriverLocation'),
            headers: {
              'Authorization': 'Bearer $idToken',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'data': {
                'driverId': driverId,
                'orderId': orderId,
              },
            }),
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) {
        print('getDriverLocation HTTP ${response.statusCode}: ${response.body}');
        return null;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['error'] != null) {
        print('getDriverLocation callable error: ${decoded['error']}');
        return null;
      }

      final result = decoded is Map ? decoded['result'] : null;
      if (result is! Map || result['ok'] != true) {
        return null;
      }

      final location = result['location'];
      if (location == null) {
        return null;
      }
      if (location is! Map) {
        return null;
      }

      final lat = (location['latitude'] as num?)?.toDouble();
      final lng = (location['longitude'] as num?)?.toDouble();
      if (lat == null || lng == null) {
        return null;
      }

      return DriverLiveLocation(
        latitude: lat,
        longitude: lng,
        heading: (location['heading'] as num?)?.toDouble() ?? 0.0,
        timestamp: (location['timestamp'] as num?)?.toInt() ?? 0,
      );
    } catch (e) {
      print('getDriverLocation failed: $e');
      return null;
    }
  }
}
