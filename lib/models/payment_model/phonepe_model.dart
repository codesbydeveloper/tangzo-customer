class PhonePe {
  String? merchantId;
  String? saltKey;
  String? flowId;
  String? clientId;
  String? clientSecret;
  String? image;
  String? name;
  bool? enable;
  bool? isSandbox;

  PhonePe({this.merchantId, this.saltKey, this.flowId, this.clientId, this.clientSecret, this.image, this.name, this.enable, this.isSandbox});

  PhonePe.fromJson(Map<String, dynamic> json) {
    merchantId = json['merchantId'];
    flowId = json['flowId'];
    clientId = json['clientId'];
    clientSecret = json['clientSecret'];
    saltKey = json['saltKey'];
    image = json['image'];
    name = json['name'];
    enable = json['enable'];
    isSandbox = json['isSandbox'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['merchantId'] = merchantId;
    data['flowId'] = flowId;
    data['clientId'] = clientId;
    data['clientSecret'] = clientSecret;
    data['saltKey'] = saltKey;
    data['image'] = image;
    data['name'] = name;
    data['enable'] = enable;
    data['isSandbox'] = isSandbox;
    return data;
  }
}
