import 'package:cloud_firestore/cloud_firestore.dart';

class ZoneModel {
  List<GeoPoint>? area;
  bool? publish;
  double? latitude;
  String? name;
  String? id;
  double? longitude;

  ZoneModel(
      {this.area,
      this.publish,
      this.latitude,
      this.name,
      this.id,
      this.longitude});

  ZoneModel.fromJson(Map<String, dynamic> json) {
    if (json['area'] != null) {
      area = <GeoPoint>[];
      for (final v in (json['area'] as List)) {
        final point = _toGeoPoint(v);
        if (point != null) {
          area!.add(point);
        }
      }
    }

    publish = json['publish'];
    latitude = _toDouble(json['latitude']);
    name = json['name']?.toString();
    id = json['id']?.toString();
    longitude = _toDouble(json['longitude']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (area != null) {
      data['area'] = area!.map((v) => v).toList();
    }
    data['publish'] = publish;
    data['latitude'] = latitude;
    data['name'] = name;
    data['id'] = id;
    data['longitude'] = longitude;
    return data;
  }

  /// Accepts Firestore [GeoPoint] or Redis/CF JSON maps
  /// (`{latitude, longitude}` / `{__type: geopoint, ...}`).
  static GeoPoint? _toGeoPoint(dynamic v) {
    if (v == null) return null;
    if (v is GeoPoint) return v;
    if (v is Map) {
      final lat = _toDouble(v['latitude'] ?? v['_latitude'] ?? v['lat']);
      final lng = _toDouble(v['longitude'] ?? v['_longitude'] ?? v['lng']);
      if (lat != null && lng != null) {
        return GeoPoint(lat, lng);
      }
    }
    return null;
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }
}
