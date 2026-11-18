import 'package:cloud_firestore/cloud_firestore.dart';

/// Embedded on orders for round-trip safety (customer app must not wipe this field).
class DriverCashbackModel {
  bool? allDrivers;
  bool? allPayment;
  double? cashbackAmount;
  String? cashbackType;
  List<String>? driverIds;
  Timestamp? endDate;
  String? id;
  bool? isEnabled;
  double? maximumDiscount;
  double? minimumPurchaseAmount;
  List<String>? paymentMethods;
  int? redeemLimit;
  Timestamp? startDate;
  String? title;
  double? cashbackValue;

  DriverCashbackModel({
    this.allDrivers,
    this.allPayment,
    this.cashbackAmount,
    this.cashbackValue,
    this.cashbackType,
    this.driverIds,
    this.endDate,
    this.id,
    this.isEnabled,
    this.maximumDiscount,
    this.minimumPurchaseAmount,
    this.paymentMethods,
    this.redeemLimit,
    this.startDate,
    this.title,
  });

  factory DriverCashbackModel.fromJson(Map<String, dynamic> json) {
    return DriverCashbackModel(
      allDrivers: json['allDrivers'],
      allPayment: json['allPayment'],
      cashbackAmount: (json['cashbackAmount'] != null) ? double.tryParse(json['cashbackAmount'].toString()) : null,
      cashbackValue: (json['cashbackValue'] != null) ? double.tryParse(json['cashbackValue'].toString()) : null,
      cashbackType: json['cashbackType'] ?? '',
      driverIds: json['driverIds'] != null ? List<String>.from(json['driverIds']) : null,
      endDate: json['endDate'] is Timestamp ? json['endDate'] as Timestamp : null,
      id: json['id'],
      isEnabled: json['isEnabled'],
      maximumDiscount: (json['maximumDiscount'] != null) ? double.tryParse(json['maximumDiscount'].toString()) : null,
      minimumPurchaseAmount: (json['minumumPurchaseAmount'] != null) ? double.tryParse(json['minumumPurchaseAmount'].toString()) : null,
      paymentMethods: json['paymentMethods'] != null ? List<String>.from(json['paymentMethods']) : null,
      redeemLimit: int.parse("${json['redeemLimit'] ?? 0}"),
      startDate: json['startDate'] is Timestamp ? json['startDate'] as Timestamp : null,
      title: json['title'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'allDrivers': allDrivers,
      'allPayment': allPayment,
      'cashbackAmount': cashbackAmount,
      if (cashbackValue != null) 'cashbackValue': cashbackValue,
      'cashbackType': cashbackType,
      'driverIds': driverIds,
      'endDate': endDate,
      'id': id,
      'isEnabled': isEnabled,
      'maximumDiscount': maximumDiscount,
      'minumumPurchaseAmount': minimumPurchaseAmount,
      'paymentMethods': paymentMethods,
      'redeemLimit': redeemLimit,
      'startDate': startDate,
      'title': title,
    };
  }
}
