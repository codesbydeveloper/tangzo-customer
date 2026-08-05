import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:customer/constant/collection_name.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/models/order_model.dart';
import 'package:customer/models/user_model.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:flutter/material.dart';

import 'package:flutter_map/flutter_map.dart' as flutterMap;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' as location;

class LiveTrackingController extends GetxController {
  GoogleMapController? mapController;
  final flutterMap.MapController osmMapController = flutterMap.MapController();

  @override
  void onInit() {
    addMarkerSetup();
    getArgument();
    super.onInit();
  }

  @override
  void onClose() {
    // Clean up controllers and cancel any running animations.
    mapController = null;
    _cancelGoogleAnim();
    _cancelOsmAnim();
    super.onClose();
  }

  // ---------- existing reactive fields ----------
  Rx<OrderModel> orderModel = OrderModel().obs;
  Rx<UserModel> driverUserModel = UserModel().obs;
  RxBool isLoading = true.obs;

  Rx<location.LatLng> source = location.LatLng(21.1702, 72.8311).obs; // Start (e.g., Surat)
  Rx<location.LatLng> current = location.LatLng(21.1800, 72.8400).obs; // Moving marker
  Rx<location.LatLng> destination = location.LatLng(21.2000, 72.8600).obs; // Destination

  // ---------- animation helpers ----------
  LatLng? _oldGooglePos;
  location.LatLng? _oldOsmPos;

  // Keys to cancel previous animation loops
  int _googleAnimKey = 0;
  int _osmAnimKey = 0;

  // Anim timers / controllers
  Timer? _googleAnimTimer;
  Timer? _osmAnimTimer;

  // Camera follow throttle
  DateTime _lastCameraFollow = DateTime.fromMillisecondsSinceEpoch(0);
  final Duration cameraFollowThrottle = const Duration(milliseconds: 200);

  // Movement threshold (meters) below which we snap instead of animate
  final double snapThresholdMeters = 0.5;

  // ---------- initialization from arguments & Firestore listeners ----------
  Future<void> getArgument() async {
    dynamic argumentData = Get.arguments;
    if (argumentData != null) {
      orderModel.value = argumentData['orderModel'];
      // listen to order doc
      FireStoreUtils.fireStore.collection(CollectionName.restaurantOrders).doc(orderModel.value.id).snapshots().listen((event) {
        if (event.data() != null) {
          OrderModel orderModelStream = OrderModel.fromJson(event.data()!);
          orderModel.value = orderModelStream;

          // listen to driver doc inside order listener
          if (orderModel.value.driverID != null && orderModel.value.driverID!.isNotEmpty) {
            FireStoreUtils.fireStore.collection(CollectionName.users).doc(orderModel.value.driverID).snapshots().listen((event) {
              if (event.data() != null) {
                driverUserModel.value = UserModel.fromJson(event.data()!);

                // animate / fetch based on map type & order status
                if (Constant.selectedMapType != 'osm') {
                  if (orderModel.value.status == Constant.orderShipped) {
                    getPolyline(
                        sourceLatitude: driverUserModel.value.location!.latitude,
                        sourceLongitude: driverUserModel.value.location!.longitude,
                        destinationLatitude: orderModel.value.vendor!.latitude,
                        destinationLongitude: orderModel.value.vendor!.longitude);
                  } else if (orderModel.value.status == Constant.orderInTransit) {
                    getPolyline(
                        sourceLatitude: driverUserModel.value.location!.latitude,
                        sourceLongitude: driverUserModel.value.location!.longitude,
                        destinationLatitude: orderModel.value.address!.location!.latitude,
                        destinationLongitude: orderModel.value.address!.location!.longitude);
                  } else {
                    getPolyline(
                        sourceLatitude: orderModel.value.address!.location!.latitude,
                        sourceLongitude: orderModel.value.address!.location!.longitude,
                        destinationLatitude: orderModel.value.vendor!.latitude,
                        destinationLongitude: orderModel.value.vendor!.longitude);
                  }

                  // call animation for Google (non-blocking)
                } else {
                  // OSM flow
                  current.value = location.LatLng(driverUserModel.value.location!.latitude ?? 0.0, driverUserModel.value.location!.longitude ?? 0.0);

                  // set source/destination logically depending on status
                  if (orderModel.value.status == Constant.orderShipped) {
                    source.value = location.LatLng(orderModel.value.vendor!.latitude ?? 0.0, orderModel.value.vendor!.longitude ?? 0.0);
                    destination.value = location.LatLng(orderModel.value.address!.location!.latitude ?? 0.0, orderModel.value.address!.location!.longitude ?? 0.0);
                    awaitFetchRouteAndAnimateOSM(current.value, source.value);
                  } else if (orderModel.value.status == Constant.orderInTransit) {
                    source.value = location.LatLng(orderModel.value.vendor!.latitude ?? 0.0, orderModel.value.vendor!.longitude ?? 0.0);
                    destination.value = location.LatLng(orderModel.value.address!.location!.latitude ?? 0.0, orderModel.value.address!.location!.longitude ?? 0.0);
                    awaitFetchRouteAndAnimateOSM(current.value, destination.value);
                  } else {
                    source.value = location.LatLng(orderModel.value.vendor!.latitude ?? 0.0, orderModel.value.vendor!.longitude ?? 0.0);
                    destination.value = location.LatLng(orderModel.value.address!.location!.latitude ?? 0.0, orderModel.value.address!.location!.longitude ?? 0.0);
                    awaitFetchRouteAndAnimateOSM(current.value, source.value);
                  }
                }
                onDriverLocationUpdate(
                  lat: driverUserModel.value.location!.latitude,
                  lng: driverUserModel.value.location!.longitude,
                  rotation: double.tryParse(driverUserModel.value.rotation.toString()) ?? 0.0,
                );
              }
            });
          }

          if (orderModel.value.status == Constant.orderCompleted) {
            // ensure we cancel animations before popping
            _cancelGoogleAnim();
            _cancelOsmAnim();
            if (Get.isOverlaysOpen) {
              // just a gentle guard; your app may not need this
            }
            Get.back();
          }
        }
      });
    }

    isLoading.value = false;
    update();
  }

  Future<void> awaitFetchRouteAndAnimateOSM(location.LatLng cur, location.LatLng dest) async {
    await fetchRoute(cur, dest);
  }

  // ---------- route fetching (OSRM) ----------
  RxList<location.LatLng> routePoints = <location.LatLng>[].obs;

  Future<void> fetchRoute(location.LatLng source, location.LatLng destination) async {
    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/${source.longitude},${source.latitude};${destination.longitude},${destination.latitude}?overview=full&geometries=geojson',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final geometry = decoded['routes'][0]['geometry']['coordinates'];

      routePoints.clear();
      for (var coord in geometry) {
        final lon = coord[0];
        final lat = coord[1];
        routePoints.add(location.LatLng(lat, lon));
      }
      update();
    } else {
      print("Failed to get route: ${response.body}");
    }
  }

  // ---------- icons & marker setup ----------
  BitmapDescriptor? departureIcon;
  BitmapDescriptor? destinationIcon;
  BitmapDescriptor? driverIcon;

  void addMarkerSetup() async {
    if (Constant.selectedMapType != 'osm') {
      final Uint8List departure = await Constant().getBytesFromAsset('assets/images/pickup.png', 100);
      final Uint8List destination = await Constant().getBytesFromAsset('assets/images/dropoff.png', 100);
      final Uint8List driver = await Constant().getBytesFromAsset('assets/images/food_delivery.png', 100);
      departureIcon = BitmapDescriptor.fromBytes(departure);
      destinationIcon = BitmapDescriptor.fromBytes(destination);
      driverIcon = BitmapDescriptor.fromBytes(driver);
    } else {
      // OSM: we use Image.asset inside marker builder (no extra setup required)
    }
  }

  // ---------- polyline & map state for Google ----------
  RxMap<MarkerId, Marker> markers = <MarkerId, Marker>{}.obs;
  RxMap<PolylineId, Polyline> polyLines = <PolylineId, Polyline>{}.obs;
  PolylinePoints polylinePoints = PolylinePoints(apiKey: Constant.mapAPIKey);

  void _addPolyLine(List<LatLng> polylineCoordinates) {
    PolylineId id = const PolylineId("poly");
    Polyline polyline = Polyline(
      polylineId: id,
      points: polylineCoordinates,
      consumeTapEvents: true,
      startCap: Cap.roundCap,
      width: 6,
    );
    polyLines[id] = polyline;
    // updateCameraLocation();
    update();
  }

  void getPolyline({required double? sourceLatitude, required double? sourceLongitude, required double? destinationLatitude, required double? destinationLongitude}) async {
    if (sourceLatitude != null && sourceLongitude != null && destinationLatitude != null && destinationLongitude != null) {
      List<LatLng> polylineCoordinates = [];
      PolylineRequest polylineRequest = PolylineRequest(
        origin: PointLatLng(sourceLatitude, sourceLongitude),
        destination: PointLatLng(destinationLatitude, destinationLongitude),
        mode: TravelMode.driving,
      );

      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(request: polylineRequest);
      if (result.points.isNotEmpty) {
        for (var point in result.points) {
          polylineCoordinates.add(LatLng(point.latitude, point.longitude));
        }
      } else {
        print(result.errorMessage.toString());
      }

      // Set markers depending on order status
      if (orderModel.value.status == Constant.orderShipped) {
        _setOrUpdateMarker(
          id: 'Driver',
          position: LatLng(driverUserModel.value.location!.latitude!, driverUserModel.value.location!.longitude!),
          descriptor: driverIcon,
          rotation: double.tryParse(driverUserModel.value.rotation.toString()) ?? 0.0,
        );
        _setOrUpdateMarker(
          id: 'Departure',
          position: LatLng(orderModel.value.vendor!.latitude!, orderModel.value.vendor!.longitude!),
          descriptor: departureIcon,
          rotation: 0.0,
        );
      } else if (orderModel.value.status == Constant.orderInTransit) {
        _setOrUpdateMarker(
          id: 'Driver',
          position: LatLng(driverUserModel.value.location!.latitude!, driverUserModel.value.location!.longitude!),
          descriptor: driverIcon,
          rotation: double.tryParse(driverUserModel.value.rotation.toString()) ?? 0.0,
        );
        _setOrUpdateMarker(
          id: 'Destination',
          position: LatLng(orderModel.value.address!.location!.latitude!, orderModel.value.address!.location!.longitude!),
          descriptor: destinationIcon,
          rotation: 0.0,
        );
      } else {
        _setOrUpdateMarker(
          id: 'Departure',
          position: LatLng(orderModel.value.vendor!.latitude!, orderModel.value.vendor!.longitude!),
          descriptor: departureIcon,
          rotation: 0.0,
        );
        _setOrUpdateMarker(
          id: 'Destination',
          position: LatLng(orderModel.value.address!.location!.latitude!, orderModel.value.address!.location!.longitude!),
          descriptor: destinationIcon,
          rotation: 0.0,
        );
      }
      if (polylineCoordinates.isNotEmpty) {
        _addPolyLine(polylineCoordinates);
        update();
      }
    }
  }

  // ---------- Google: add / update marker (small helper) ----------
  void _setOrUpdateMarker({required String id, required LatLng position, BitmapDescriptor? descriptor, double rotation = 0.0}) {
    final markerId = MarkerId(id);

    // Create a marker with rotation; set flat: true so icon rotates smoothly
    final marker = Marker(
      markerId: markerId,
      position: position,
      icon: descriptor ?? BitmapDescriptor.defaultMarker,
      rotation: rotation,
      anchor: const Offset(0.5, 0.5),
      flat: true,
      zIndex: 10,
    );

    markers[markerId] = marker;
    update();
  }

  // ---------- Camera utilities ----------
  Future<void> updateCameraLocation() async {
    if (mapController == null) return;
    try {
      await mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: LatLng(driverUserModel.value.location!.latitude!, driverUserModel.value.location!.longitude!), zoom: 15, bearing: double.parse('${driverUserModel.value.rotation!}')),
        ),
      );
    } catch (_) {}
  }

  Future<void> checkCameraLocation(CameraUpdate cameraUpdate, GoogleMapController mapController) async {
    mapController.animateCamera(cameraUpdate);
    LatLngBounds l1 = await mapController.getVisibleRegion();
    LatLngBounds l2 = await mapController.getVisibleRegion();

    if (l1.southwest.latitude == -90 || l2.southwest.latitude == -90) {
      return checkCameraLocation(cameraUpdate, mapController);
    }
  }

  // ---------- OSM markers ----------
  RxList<flutterMap.Marker> osmMarkers = <flutterMap.Marker>[].obs;

  void setOsmMarkers() {
    osmMarkers.value = [
      flutterMap.Marker(
        point: current.value,
        width: 45,
        height: 45,
        rotate: true,
        child: Transform.rotate(
          angle: (double.tryParse(driverUserModel.value.rotation.toString()) ?? 0.0) * (math.pi / 180),
          child: Image.asset('assets/images/food_delivery.png'),
        ),
      ),
      flutterMap.Marker(
        point: source.value,
        width: 40,
        height: 40,
        child: Image.asset('assets/images/pickup.png'),
      ),
      flutterMap.Marker(
        point: destination.value,
        width: 40,
        height: 40,
        child: Image.asset('assets/images/dropoff.png'),
      ),
    ];
    update();
  }

  // ---------- Interpolation helpers ----------
  LatLng _lerpLatLng(LatLng a, LatLng b, double t) {
    return LatLng(
      a.latitude + (b.latitude - a.latitude) * t,
      a.longitude + (b.longitude - a.longitude) * t,
    );
  }

  location.LatLng _lerpOsm(location.LatLng a, location.LatLng b, double t) {
    return location.LatLng(
      a.latitude + (b.latitude - a.latitude) * t,
      a.longitude + (b.longitude - a.longitude) * t,
    );
  }

  double _interpolateRotation(double start, double end, double t) {
    double diff = (end - start) % 360;
    if (diff < -180) diff += 360;
    if (diff > 180) diff -= 360;
    return (start + diff * t) % 360;
  }

  double _deg2rad(double deg) => deg * (math.pi / 180);

  double _calculateDistanceMeters(double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371000; // meters
    final double dLat = _deg2rad(lat2 - lat1);
    final double dLon = _deg2rad(lon2 - lon1);
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) + math.cos(_deg2rad(lat1)) * math.cos(_deg2rad(lat2)) * math.sin(dLon / 2) * math.sin(dLon / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  // ---------- Smooth animation for Google Marker ----------
  Future<void> animateDriverMarkerGoogle(
    LatLng newPos, {
    double? newRotation,
    Duration duration = const Duration(milliseconds: 900),
    bool followCamera = true,
  }) async {
    _cancelGoogleAnim();
    final int myKey = ++_googleAnimKey;

    final LatLng from = _oldGooglePos ?? newPos;
    final double startRot = double.tryParse(driverUserModel.value.rotation.toString()) ?? 0.0;
    final double targetRot = newRotation ?? startRot;

    final double distanceMeters = _calculateDistanceMeters(from.latitude, from.longitude, newPos.latitude, newPos.longitude);

    // If movement is extremely small, snap to new position (prevents jitter)
    if (distanceMeters <= snapThresholdMeters) {
      _setOrUpdateMarker(id: 'Driver', position: newPos, descriptor: driverIcon, rotation: targetRot);
      _oldGooglePos = newPos;
      driverUserModel.value.rotation = targetRot;
      if (followCamera && DateTime.now().difference(_lastCameraFollow) > cameraFollowThrottle) {
        _lastCameraFollow = DateTime.now();
        try {
          mapController?.animateCamera(CameraUpdate.newLatLng(newPos));
        } catch (_) {}
      }
      return;
    }

    final int fps = 60;
    final int totalFrames = math.max(1, ((duration.inMilliseconds / (1000 / fps))).round());
    int frame = 0;

    // animation timer
    _googleAnimTimer = Timer.periodic(Duration(milliseconds: (1000 / fps).round()), (timer) {
      if (myKey != _googleAnimKey) {
        timer.cancel();
        return;
      }

      final double tRaw = (frame / totalFrames).clamp(0.0, 1.0);
      final double t = Curves.easeInOut.transform(tRaw);
      final LatLng interpolated = _lerpLatLng(from, newPos, t);
      final double rot = _interpolateRotation(startRot, targetRot, t);

      // update marker with rotation; marker is flat so rotation looks good
      final markerId = MarkerId('Driver');
      final marker = Marker(
        markerId: markerId,
        position: interpolated,
        icon: driverIcon ?? BitmapDescriptor.defaultMarker,
        rotation: rot,
        anchor: const Offset(0.5, 0.5),
        flat: true,
        zIndex: 10,
      );
      markers[markerId] = marker;
      update();

      // throttle camera updates
      if (followCamera && DateTime.now().difference(_lastCameraFollow) > cameraFollowThrottle) {
        _lastCameraFollow = DateTime.now();
        try {
          mapController?.animateCamera(CameraUpdate.newLatLng(interpolated));
        } catch (_) {}
      }

      frame++;
      if (frame > totalFrames) {
        // final snap and finish
        timer.cancel();
        if (myKey == _googleAnimKey) {
          markers[markerId] = Marker(
            markerId: markerId,
            position: newPos,
            icon: driverIcon ?? BitmapDescriptor.defaultMarker,
            rotation: targetRot,
            anchor: const Offset(0.5, 0.5),
            flat: true,
            zIndex: 10,
          );
          _oldGooglePos = newPos;
          driverUserModel.value.rotation = targetRot;
          update();
        }
      }
    });
  }

  void _cancelGoogleAnim() {
    _googleAnimKey++;
    try {
      _googleAnimTimer?.cancel();
    } catch (_) {}
    _googleAnimTimer = null;
  }

  // ---------- Smooth animation for OSM marker ----------
  Future<void> animateDriverMarkerOsm(
    location.LatLng newPos, {
    double? newRotation,
    Duration duration = const Duration(milliseconds: 1000),
    double osmZoom = 14.0,
    bool followCamera = true,
    int cameraUpdateEveryNthFrame = 3,
  }) async {
    _cancelOsmAnim();
    final int myKey = ++_osmAnimKey;

    final location.LatLng from = _oldOsmPos ?? newPos;

    final double startRot = double.tryParse(driverUserModel.value.rotation.toString()) ?? 0.0;
    final double targetRot = newRotation ?? startRot;

    final double distanceMeters = _calculateDistanceMeters(from.latitude, from.longitude, newPos.latitude, newPos.longitude);
    if (distanceMeters <= snapThresholdMeters) {
      current.value = newPos;
      driverUserModel.value.rotation = targetRot;
      setOsmMarkers();

      if (followCamera && DateTime.now().difference(_lastCameraFollow) > cameraFollowThrottle) {
        _lastCameraFollow = DateTime.now();
        try {
          osmMapController.move(newPos, osmZoom);
        } catch (_) {}
      }

      _oldOsmPos = newPos;
      update();
      return;
    }

    final int fps = 60;
    final int totalFrames = math.max(1, ((duration.inMilliseconds / (1000 / fps))).round());
    int frame = 0;

    _osmAnimTimer = Timer.periodic(
      Duration(milliseconds: (1000 / fps).round()),
      (timer) async {
        if (myKey != _osmAnimKey) {
          timer.cancel();
          return;
        }

        final double tRaw = (frame / totalFrames).clamp(0.0, 1.0);
        final double t = Curves.easeInOut.transform(tRaw);

        final location.LatLng interpolated = _lerpOsm(from, newPos, t);
        final double rot = _interpolateRotation(startRot, targetRot, t);

        current.value = interpolated;
        driverUserModel.value.rotation = rot;

        setOsmMarkers();

        // camera update throttling
        if (followCamera && frame % cameraUpdateEveryNthFrame == 0 && DateTime.now().difference(_lastCameraFollow) > cameraFollowThrottle) {
          _lastCameraFollow = DateTime.now();
          try {
            osmMapController.move(interpolated, osmZoom);
          } catch (_) {}
        }

        frame++;
        if (frame > totalFrames) {
          timer.cancel();
          if (myKey == _osmAnimKey) {
            current.value = newPos;
            driverUserModel.value.rotation = targetRot;
            _oldOsmPos = newPos;
            setOsmMarkers();
          }
        }
      },
    );
  }

  void _cancelOsmAnim() {
    _osmAnimKey++;
    try {
      _osmAnimTimer?.cancel();
    } catch (_) {}
    _osmAnimTimer = null;
  }

  // ---------- public wrapper: call this when driver location updates ----------
  Future<void> onDriverLocationUpdate({double? lat, double? lng, double? rotation}) async {
    if (lat == null || lng == null) return;

    final LatLng googlePos = LatLng(lat, lng);
    final location.LatLng osmPos = location.LatLng(lat, lng);

    if (Constant.selectedMapType != 'osm') {
      await animateDriverMarkerGoogle(googlePos, newRotation: rotation ?? (double.tryParse(driverUserModel.value.rotation.toString()) ?? 0.0));
    } else {
      await animateDriverMarkerOsm(osmPos, newRotation: rotation ?? (double.tryParse(driverUserModel.value.rotation.toString()) ?? 0.0));
    }
  }
}
