class PlatformFeeModel {
  String? amount;
  bool? enable;

  PlatformFeeModel({this.amount, this.enable});

  PlatformFeeModel.fromJson(Map<String, dynamic> json) {
    amount = json['amount'].toString();
    enable = json['enable'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['amount'] = amount;
    data['enable'] = enable;
    return data;
  }
}
