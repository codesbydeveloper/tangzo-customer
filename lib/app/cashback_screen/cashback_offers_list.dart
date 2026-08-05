import 'package:customer/constant/constant.dart';
import 'package:customer/controllers/cashback_controller.dart';
import 'package:customer/themes/app_them_data.dart';
import 'package:customer/utils/dark_theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:customer/widget/translated_text.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class CashbackOffersListScreen extends StatelessWidget {
  const CashbackOffersListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX(
        init: CashbackController(),
        builder: (controller) {
          return Scaffold(
            appBar: AppBar(
              centerTitle: false,
              titleSpacing: 0,
              title: TranslatedText(
                "Cashback Offers",
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontFamily: AppThemeData.medium,
                  fontSize: 16,
                  color: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey900,
                ),
              ),
              backgroundColor: themeChange.getThem() ? AppThemeData.surfaceDark : AppThemeData.surface,
            ),
            body: controller.isLoading.value
                ? Constant.loader()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: controller.cashbackList.length,
                    itemBuilder: (BuildContext context, int index) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: themeChange.getThem() ? AppThemeData.grey900 : AppThemeData.grey50,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TranslatedText(controller.cashbackList[index].title ?? '',
                                      style: TextStyle(fontFamily: AppThemeData.semiBold, fontSize: 16, color: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey900)),
                                ),
                                TranslatedText(
                                  controller.cashbackList[index].cashbackType == 'Percent'
                                      ? "${controller.cashbackList[index].cashbackAmount}%"
                                      : Constant.amountShow(amount: "${controller.cashbackList[index].cashbackAmount}"),
                                  style: TextStyle(fontFamily: AppThemeData.semiBold, fontSize: 16, color: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey900),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            TranslatedText(
                              "${"Min spent"} ${Constant.amountShow(amount: "${controller.cashbackList[index].minimumPurchaseAmount ?? 0.0}")} | ${"Valid till"} ${Constant.timestampToDateTime2(controller.cashbackList[index].endDate!)}",
                              style: TextStyle(color: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey900, fontFamily: AppThemeData.regular, fontSize: 14),
                            ),
                            TranslatedText(
                              "${"Maximum cashback up to"} ${Constant.amountShow(amount: "${controller.cashbackList[index].maximumDiscount ?? 0.0}")}",
                              style: TextStyle(color: themeChange.getThem() ? AppThemeData.primary200 : AppThemeData.primary300, fontFamily: AppThemeData.regular, fontSize: 14),
                            ),
                          ],
                        ),
                      );
                    }),
          );
        });
  }
}
