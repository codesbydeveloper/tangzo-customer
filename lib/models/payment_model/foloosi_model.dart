class Foloosi {
  String? merchantKey;
  String? image;
  String? name;
  bool? enable;
  bool? isSandbox;

  Foloosi({this.merchantKey, this.image, this.name, this.enable, this.isSandbox});

  Foloosi.fromJson(Map<String, dynamic> json) {
    merchantKey = json['merchantKey'];
    image = json['image'];
    name = json['name'];
    enable = json['enable'];
    isSandbox = json['isSandbox'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['merchantKey'] = merchantKey;
    data['image'] = image;
    data['name'] = name;
    data['enable'] = enable;
    data['isSandbox'] = isSandbox;
    return data;
  }
}
