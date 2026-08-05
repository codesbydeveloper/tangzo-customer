class MtnMomo {
  String? callbackUrl;
  bool? enable;
  bool? isSandbox;
  String? name;
  String? image;
  String? primaryKey;
  String? secondaryKey;
  String? expiryTimeSeconds;
  String? targetEnvironment;

  MtnMomo({this.callbackUrl, this.enable, this.isSandbox, this.name, this.image, this.primaryKey, this.secondaryKey, this.expiryTimeSeconds, this.targetEnvironment});

  MtnMomo.fromJson(Map<String, dynamic> json) {
    callbackUrl = json['callbackUrl'];
    enable = json['enable'];
    enable = json['enable'];
    isSandbox = json['isSandbox'];
    name = json['name'];
    image = json['image'];
    primaryKey = json['primaryKey'];
    secondaryKey = json['secondaryKey'];
    expiryTimeSeconds = json['expiryTimeSeconds'];
    targetEnvironment = json['targetEnvironment'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['callbackUrl'] = callbackUrl;
    data['enable'] = enable;
    data['isSandbox'] = isSandbox;
    data['name'] = name;
    data['image'] = image;
    data['primaryKey'] = primaryKey;
    data['secondaryKey'] = secondaryKey;
    data['expiryTimeSeconds'] = expiryTimeSeconds;
    data['targetEnvironment'] = targetEnvironment;
    return data;
  }
}
