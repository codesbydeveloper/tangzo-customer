class Instamojo {
  String? clientId;
  String? clientSecret;
  String? image;
  String? name;
  bool? enable;
  bool? isSandbox;

  Instamojo({this.clientId, this.clientSecret, this.image, this.name, this.enable, this.isSandbox});

  Instamojo.fromJson(Map<String, dynamic> json) {
    clientId = json['clientId'];
    clientSecret = json['clientSecret'];
    image = json['image'];
    name = json['name'];
    enable = json['enable'];
    isSandbox = json['isSandbox'];
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


