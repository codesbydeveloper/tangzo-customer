class PayMongo {
  String? secretKey;
  String? image;
  String? name;
  bool? enable;
  bool? isSandbox;

  PayMongo({this.secretKey, this.image, this.name, this.enable, this.isSandbox});

  PayMongo.fromJson(Map<String, dynamic> json) {
    secretKey = json['secretKey'];
    image = json['image'];
    name = json['name'];
    enable = json['enable'];
    isSandbox = json['isSandbox'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['secretKey'] = secretKey;
    data['image'] = image;
    data['name'] = name;
    data['enable'] = enable;
    data['isSandbox'] = isSandbox;
    return data;
  }
}
