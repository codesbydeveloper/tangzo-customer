import 'package:customer/models/payment_model/cashfree_model.dart';

import 'cashfree_secrets_stub.dart' if (dart.library.io) 'cashfree_payment_config.local.dart' as secrets;

class CashfreePaymentConfig {
  static Cashfree get model => Cashfree(
        clientId: secrets.cashfreeAppId,
        clientSecret: secrets.cashfreeSecretKey,
        name: 'Cashfree',
        enable: secrets.cashfreeAppId.isNotEmpty && secrets.cashfreeSecretKey.isNotEmpty,
        isSandbox: secrets.cashfreeIsSandbox,
      );
}
