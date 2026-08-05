class FreeDeliveryByAdminModel {
  num? freeDeliveryDistance;
  num? freeDeliveryOver;
  bool? isEnableFreeDelivery;

  FreeDeliveryByAdminModel({
    this.freeDeliveryDistance,
    this.freeDeliveryOver,
    this.isEnableFreeDelivery,
  });

  factory FreeDeliveryByAdminModel.fromJson(Map<String, dynamic> json) {
    return FreeDeliveryByAdminModel(
      freeDeliveryDistance: double.tryParse("${json['freeDeliveryDistance'] ?? '0.0'}"),
      freeDeliveryOver: double.tryParse("${json['freeDeliveryOver'] ?? '0.0'}"),
      isEnableFreeDelivery: json['isEnableFreeDelivery'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'freeDeliveryDistance': freeDeliveryDistance ?? 0.0,
      'freeDeliveryOver': freeDeliveryOver ?? 0.0,
      'isEnableFreeDelivery': isEnableFreeDelivery ?? false,
    };
  }
}
