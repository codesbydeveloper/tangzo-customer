class Cashfree {
  String? clientId;
  String? clientSecret;
  String? image;
  String? name;
  bool? enable;
  bool? isSandbox;

  Cashfree({this.clientId, this.clientSecret, this.image, this.name, this.enable, this.isSandbox});

  Cashfree.fromJson(Map<String, dynamic> json) {
    clientId = json['clientId'] ?? json['appId'] ?? json['appID'];
    clientSecret = json['clientSecret'] ?? json['secretKey'] ?? json['secret'];
    image = json['image'];
    name = json['name'];
    enable = json['enable'] ?? json['isEnabled'] ?? json['isEnable'];
    isSandbox = json['isSandbox'] ?? json['sandbox'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['clientId'] = clientId;
    data['clientSecret'] = clientSecret;
    data['image'] = image;
    data['name'] = name;
    data['enable'] = enable;
    data['isSandbox'] = isSandbox;
    return data;
  }
}
