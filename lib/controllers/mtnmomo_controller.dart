// ignore_for_file: prefer_interpolation_to_compose_strings

import 'dart:convert';
import 'dart:developer';
import 'package:customer/constant/constant.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/models/payment_model/mtnmomo_model.dart';
import 'package:http/http.dart' as http;

class MtnMomoController {
  static MtnMomo? mtnMomoData;
  static String? xReferenceId;
  static String? authorization;
  static String? apiKey;
  static String? accessToken;

  static String? xReferenceIdPay;

  static Future apiuserAPI({required MtnMomo mtnMomo}) async {
    mtnMomoData = mtnMomo;
    log("mtnMomoData :: ${mtnMomoData?.primaryKey} :: ${mtnMomoData?.secondaryKey}");
    xReferenceId = Constant.getUuid();

    var url = mtnMomoData?.isSandbox == true ? '$baseUrl/v1_0/apiuser' : '$baseUrl/v1_0/apiuser';
    Map<String, String> headers = {
      'X-Reference-Id': xReferenceId ?? '',
      'Ocp-Apim-Subscription-Key': mtnMomoData?.primaryKey ?? '',
      'Content-Type': 'application/json',
    };

    final data = {'providerCallbackHost': mtnMomoData?.callbackUrl};

    final response = await http.post(Uri.parse(url), headers: headers, body: jsonEncode(data));

    log("MtnMomo :: apiuserAPI :: ${response.statusCode}");
    if (response.statusCode == 201) {
      return await getAPIKey();
    } else {
      return false;
    }
  }

  static Future getAPIKey() async {
    final url = '$baseUrl/v1_0/apiuser/$xReferenceId/apikey';
    final headers = {'Ocp-Apim-Subscription-Key': mtnMomoData?.primaryKey ?? ''};

    final response = await http.post(Uri.parse(url), headers: headers);

    log("MtnMomo :: getAPIKey :: ${response.body}");
    if (response.statusCode == 201) {
      Map<String, dynamic> responseData = json.decode(response.body);
      apiKey = responseData['apiKey'];
      return await generatingAPIToken();
    } else {
      return '';
    }
  }

  static Future generatingAPIToken() async {
    var url = '$baseUrl/collection/token/';
    final basicAuth = 'Basic ${base64Encode(utf8.encode('$xReferenceId:$apiKey'))}';
    final headers = {'Ocp-Apim-Subscription-Key': mtnMomoData?.primaryKey ?? '', 'Authorization': basicAuth};

    final response = await http.post(Uri.parse(url), headers: headers);

    log("MtnMomo :: generatingAPIToken :: ${response.body}");

    if (response.statusCode == 200) {
      // Convert the JSON string to a Dart map
      Map<String, dynamic> responseData = json.decode(response.body);
      if (responseData['access_token'] != '') {
        accessToken = responseData['access_token'];
        return responseData['access_token'];
      } else {
        return '';
      }
    } else {
      return '';
    }
  }

  static Future<bool> requesttopayAPI({required String partyId, required String amount}) async {
    xReferenceIdPay = Constant.getUuid();
    var url = '$baseUrl/collection/v1_0/requesttopay';
    Map<String, String> headers = {
      'X-Reference-Id': xReferenceIdPay ?? '',
      "X-Target-Environment": targetEnv,
      'Ocp-Apim-Subscription-Key': mtnMomoData?.primaryKey ?? '',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    };

    final data = {
      "amount": amount,
      "currency": "EUR",
      "externalId": xReferenceId,
      "payer": {"partyIdType": "MSISDN", "partyId": partyId},
      "payerMessage": "Pay for TopUp",
      "payeeNote": "Pay for TopUp"
    };

    final response = await http.post(Uri.parse(url), headers: headers, body: jsonEncode(data));

    log("MtnMomo :: requesttopayAPI :: ${response.statusCode}");

    if (response.statusCode == 202) {
      return true;
    } else {
      return false;
    }
  }

  static Future getRequestToPayTransactionStatus() async {
    final url = '$baseUrl/collection/v1_0/requesttopay/$xReferenceIdPay';
    Map<String, String> headers = {
      'Ocp-Apim-Subscription-Key': mtnMomoData?.primaryKey ?? '',
      "X-Target-Environment": targetEnv,
      'Authorization': 'Bearer $accessToken',
    };

    final response = await http.get(Uri.parse(url), headers: headers);

    log("MtnMomo :: getRequestToPayTransactionStatus :: ${response.statusCode}");

    if (response.statusCode == 200) {
      Map<String, dynamic> responseData = json.decode(response.body);
      return responseData['status'];
    } else {
      ShowToastDialog.showToast('Your Transaction is FAILED');
      return 'FAILED';
    }
  }

  static String get baseUrl {
    return mtnMomoData?.isSandbox == true ? "https://sandbox.momodeveloper.mtn.com" : "https://proxy.momoapi.mtn.com";
  }

  /// ✅ Target Environment
  static String get targetEnv {
    return mtnMomoData?.isSandbox == true ? "sandbox" : mtnMomoData?.targetEnvironment ?? "mtnuganda";
  }
}
