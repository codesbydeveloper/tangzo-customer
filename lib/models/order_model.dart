import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer/models/cart_product_model.dart';
import 'package:customer/models/cashbackModel.dart';
import 'package:customer/models/driver_cashback_model.dart';
import 'package:customer/models/tax_model.dart';
import 'package:customer/models/user_model.dart';
import 'package:customer/models/vendor_model.dart';

class OrderModel {
  ShippingAddress? address;
  String? status;
  String? couponId;
  String? vendorID;
  String? driverID;
  num? discount;
  String? authorID;
  String? estimatedTimeToPrepare;
  Timestamp? createdAt;
  Timestamp? triggerDelivery;
  List<TaxModel>? taxSetting;
  List<TaxModel>? driverDeliveryTax;
  List<TaxModel>? packagingTax;
  List<TaxModel>? platformTax;
  String? paymentMethod;
  /// e.g. PAID / COD — set after gateway verification for online payments.
  String? paymentStatus;
  /// Gateway order / payment reference (e.g. Cashfree order_id).
  String? paymentTransactionId;
  List<CartProductModel>? products;
  String? adminCommissionType;
  VendorModel? vendor;
  String? id;
  String? adminCommission;
  String? couponCode;
  Map<String, dynamic>? specialDiscount;
  String? deliveryCharge;
  Timestamp? scheduleTime;
  String? tipAmount;
  String? notes;
  UserModel? author;
  UserModel? driver;
  bool? takeAway;
  List<dynamic>? rejectedByDrivers;
  CashbackModel? cashback;
  DriverCashbackModel? driverCashback;
  bool? isFreeDelivery;
  bool? isPosOrder;
  String? taxScope;
  String? platformFee;
  /// e.g. shiprocket / shiprocket_pending
  String? deliveryPartner;
  ShiprocketInfo? shiprocket;
  OrderModel(
      {this.address,
      this.status,
      this.couponId,
      this.vendorID,
      this.driverID,
      this.discount,
      this.authorID,
      this.estimatedTimeToPrepare,
      this.createdAt,
      this.triggerDelivery,
      this.taxSetting,
      this.paymentMethod,
      this.paymentStatus,
      this.paymentTransactionId,
      this.products,
      this.adminCommissionType,
      this.vendor,
      this.id,
      this.adminCommission,
      this.couponCode,
      this.specialDiscount,
      this.deliveryCharge,
      this.scheduleTime,
      this.tipAmount,
      this.notes,
      this.author,
      this.driver,
      this.takeAway,
      this.rejectedByDrivers,
      this.cashback,
      this.driverCashback,
      this.isFreeDelivery,
      this.driverDeliveryTax,
      this.packagingTax,
      this.platformTax,
      this.taxScope,
      this.platformFee,
      this.isPosOrder,
      this.deliveryPartner,
      this.shiprocket});

  bool get isShiprocketPartner {
    final p = deliveryPartner ?? '';
    return p == 'shiprocket' || p == 'shiprocket_pending' || p.startsWith('shiprocket');
  }

  OrderModel.fromJson(Map<String, dynamic> json) {
    address = json['address'] != null ? ShippingAddress.fromJson(json['address']) : null;
    status = json['status'];
    couponId = json['couponId'];
    vendorID = json['vendorID'];
    driverID = json['driverID'];
    discount = json['discount'];
    authorID = json['authorID'];
    estimatedTimeToPrepare = json['estimatedTimeToPrepare'];
    createdAt = json['createdAt'];
    triggerDelivery = json['triggerDelevery'] ?? Timestamp.now();
    paymentMethod = json['payment_method'];
    paymentStatus = json['paymentStatus']?.toString();
    paymentTransactionId = json['paymentTransactionId']?.toString();
    if (json['products'] != null) {
      products = <CartProductModel>[];
      json['products'].forEach((v) {
        products!.add(CartProductModel.fromJson(v));
      });
    }
    adminCommissionType = json['adminCommissionType'];
    vendor = json['vendor'] != null ? VendorModel.fromJson(json['vendor']) : null;
    id = json['id'];
    adminCommission = json['adminCommission'];
    couponCode = json['couponCode'];
    specialDiscount = json['specialDiscount'];
    deliveryCharge = json['deliveryCharge'].toString().isEmpty ? "0.0" : json['deliveryCharge'] ?? '0.0';
    scheduleTime = json['scheduleTime'];
    tipAmount = json['tip_amount'].toString().isEmpty ? "0.0" : json['tip_amount'] ?? "0.0";
    notes = json['notes'];
    author = json['author'] != null ? UserModel.fromJson(json['author']) : null;
    driver = json['driver'] != null ? UserModel.fromJson(json['driver']) : null;
    takeAway = json['takeAway'];
    rejectedByDrivers = json['rejectedByDrivers'] ?? [];
    cashback = json['cashback'] != null ? CashbackModel.fromJson(json['cashback']) : null;
    driverCashback = json['driverCashback'] != null ? DriverCashbackModel.fromJson(json['driverCashback']) : null;
    isFreeDelivery = json['isFreeDelivery'] ?? false;
    if (json['taxSetting'] != null) {
      taxSetting = <TaxModel>[];
      json['taxSetting'].forEach((v) {
        taxSetting!.add(TaxModel.fromJson(v));
      });
    }
    if (json['platformTax'] != null) {
      platformTax = <TaxModel>[];
      json['platformTax'].forEach((v) {
        platformTax!.add(TaxModel.fromJson(v));
      });
    }
    if (json['packagingTax'] != null) {
      packagingTax = <TaxModel>[];
      json['packagingTax'].forEach((v) {
        packagingTax!.add(TaxModel.fromJson(v));
      });
    }

    if (json['driverDeliveryTax'] != null) {
      driverDeliveryTax = <TaxModel>[];
      json['driverDeliveryTax'].forEach((v) {
        driverDeliveryTax!.add(TaxModel.fromJson(v));
      });
    }
    taxScope = json['taxScope'];
    platformFee = json['platformFee'];
    isPosOrder = json['isPosOrder'] ?? false;
    deliveryPartner = json['deliveryPartner']?.toString();
    shiprocket = json['shiprocket'] != null ? ShiprocketInfo.fromJson(Map<String, dynamic>.from(json['shiprocket'] as Map)) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (address != null) {
      data['address'] = address!.toJson();
    }
    data['status'] = status;
    data['couponId'] = couponId;
    data['vendorID'] = vendorID;
    data['driverID'] = driverID;
    data['discount'] = discount;
    data['authorID'] = authorID;
    data['estimatedTimeToPrepare'] = estimatedTimeToPrepare;
    data['createdAt'] = createdAt;
    data['triggerDelivery'] = triggerDelivery;
    data['payment_method'] = paymentMethod;
    data['paymentStatus'] = paymentStatus;
    data['paymentTransactionId'] = paymentTransactionId;
    if (products != null) {
      data['products'] = products!.map((v) => v.toJson()).toList();
    }
    data['adminCommissionType'] = adminCommissionType;
    if (vendor != null) {
      data['vendor'] = vendor!.toJson();
    }
    data['id'] = id;
    data['adminCommission'] = adminCommission;
    data['couponCode'] = couponCode;
    data['specialDiscount'] = specialDiscount;
    data['deliveryCharge'] = deliveryCharge;
    data['scheduleTime'] = scheduleTime;
    data['tip_amount'] = tipAmount;
    data['notes'] = notes;
    if (author != null) {
      data['author'] = author!.toJson();
    }
    if (driver != null) {
      data['driver'] = driver!.toJson();
    }
    data['takeAway'] = takeAway;
    data['rejectedByDrivers'] = rejectedByDrivers;
    data['cashback'] = cashback?.toJson();
    data['driverCashback'] = driverCashback?.toJson();
    data['isFreeDelivery'] = isFreeDelivery ?? false;
    if (taxSetting != null) {
      data['taxSetting'] = taxSetting!.map((v) => v.toJson()).toList();
    }
    if (platformTax != null) {
      data['platformTax'] = platformTax!.map((v) => v.toJson()).toList();
    }
    if (packagingTax != null) {
      data['packagingTax'] = packagingTax!.map((v) => v.toJson()).toList();
    }
    if (driverDeliveryTax != null) {
      data['driverDeliveryTax'] = driverDeliveryTax!.map((v) => v.toJson()).toList();
    }
    data['taxScope'] = taxScope;
    data['platformFee'] = platformFee;
    data['isPosOrder'] = isPosOrder ?? false;
    data['deliveryPartner'] = deliveryPartner;
    if (shiprocket != null) {
      data['shiprocket'] = shiprocket!.toJson();
    }
    return data;
  }
}

class ShiprocketInfo {
  String? status;
  String? mode;
  dynamic shipmentId;
  dynamic srOrderId;
  String? awb;
  String? trackingUrl;
  String? pickupOtp;
  String? dropOtp;
  String? currentStatus;
  String? courierHint;
  ShiprocketRider? rider;

  ShiprocketInfo({
    this.status,
    this.mode,
    this.shipmentId,
    this.srOrderId,
    this.awb,
    this.trackingUrl,
    this.pickupOtp,
    this.dropOtp,
    this.currentStatus,
    this.courierHint,
    this.rider,
  });

  factory ShiprocketInfo.fromJson(Map<String, dynamic> json) {
    return ShiprocketInfo(
      status: json['status']?.toString(),
      mode: json['mode']?.toString(),
      shipmentId: json['shipmentId'],
      srOrderId: json['srOrderId'],
      awb: json['awb']?.toString(),
      trackingUrl: json['trackingUrl']?.toString() ?? json['tracking_url']?.toString(),
      pickupOtp: json['pickupOtp']?.toString() ?? json['pickup_otp']?.toString(),
      dropOtp: json['dropOtp']?.toString() ?? json['drop_otp']?.toString(),
      currentStatus: json['currentStatus']?.toString() ?? json['current_status']?.toString(),
      courierHint: json['courierHint']?.toString() ?? json['courierName']?.toString(),
      rider: json['rider'] != null ? ShiprocketRider.fromJson(Map<String, dynamic>.from(json['rider'] as Map)) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'mode': mode,
      'shipmentId': shipmentId,
      'srOrderId': srOrderId,
      'awb': awb,
      'trackingUrl': trackingUrl,
      'pickupOtp': pickupOtp,
      'dropOtp': dropOtp,
      'currentStatus': currentStatus,
      'courierHint': courierHint,
      if (rider != null) 'rider': rider!.toJson(),
    };
  }
}

class ShiprocketRider {
  String? name;
  String? phone;
  double? lat;
  double? lng;
  String? vehicleNumber;

  ShiprocketRider({this.name, this.phone, this.lat, this.lng, this.vehicleNumber});

  factory ShiprocketRider.fromJson(Map<String, dynamic> json) {
    return ShiprocketRider(
      name: json['name']?.toString(),
      phone: json['phone']?.toString(),
      lat: json['lat'] != null ? double.tryParse(json['lat'].toString()) : null,
      lng: json['lng'] != null ? double.tryParse(json['lng'].toString()) : null,
      vehicleNumber: json['vehicleNumber']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'lat': lat,
      'lng': lng,
      'vehicleNumber': vehicleNumber,
    };
  }
}
