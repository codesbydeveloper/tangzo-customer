import 'package:customer/app/restaurant_details_screen/restaurant_details_screen.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/controllers/search_controller.dart';
import 'package:customer/models/product_model.dart';
import 'package:customer/models/vendor_model.dart';
import 'package:customer/themes/app_them_data.dart';
import 'package:customer/themes/responsive.dart';
import 'package:customer/themes/text_field_widget.dart';
import 'package:customer/utils/dark_theme_provider.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:customer/utils/network_image_widget.dart';
import 'package:customer/widget/restaurant_image_view.dart';
import 'package:flutter/material.dart';
import 'package:customer/widget/translated_text.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isRTL = Directionality.of(context) == TextDirection.rtl;
    return GetX(
        init: SearchScreenController(),
        builder: (controller) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: themeChange.getThem() ? AppThemeData.surfaceDark : AppThemeData.surface,
              centerTitle: false,
              titleSpacing: 0,
              title: TranslatedText(
                "Search Food & Restaurant",
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontFamily: AppThemeData.medium,
                  fontSize: 16,
                  color: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey900,
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(55),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextFieldWidget(
                    hintText: 'Search the dish, restaurant, food, meals',
                    prefix: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SvgPicture.asset(
                        "assets/icons/ic_search.svg",
                        width: 25,
                        height: 25,
                      ),
                    ),
                    controller: controller.searchTextController.value,
                    onchange: (value) {
                      controller.onSearchTextChanged(value);
                    },
                    suffix: IconButton(
                        onPressed: () {
                          controller.voiceSearch();
                        },
                        icon: Icon(Icons.mic)),
                  ),
                ),
              ),
            ),
            body: controller.isLoading.value
                ? Constant.loader()
                : controller.vendorSearchList.isEmpty && controller.productSearchList.isEmpty
                    ? Center(child: Constant.showEmptyView(message: "Not Found"))
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              controller.vendorSearchList.isEmpty
                                  ? const SizedBox()
                                  : Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        TranslatedText(
                                          "Restaurants",
                                          textAlign: TextAlign.start,
                                          style: TextStyle(
                                            fontFamily: AppThemeData.semiBold,
                                            fontSize: 16,
                                            color: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey900,
                                          ),
                                        ),
                                        const Padding(
                                          padding: EdgeInsets.symmetric(vertical: 10),
                                          child: Divider(),
                                        ),
                                      ],
                                    ),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: controller.vendorSearchList.length,
                                itemBuilder: (context, index) {
                                  VendorModel vendorModel = controller.vendorSearchList[index];
                                  bool isOpen = Constant.statusCheckOpenORClose(vendorModel: vendorModel);
                                  return InkWell(
                                    onTap: () {
                                      Get.to(const RestaurantDetailsScreen(), arguments: {"vendorModel": vendorModel});
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.only(bottom: 20),
                                      child: Container(
                                        decoration: ShapeDecoration(
                                          color: themeChange.getThem() ? AppThemeData.grey900 : AppThemeData.grey50,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Stack(
                                              children: [
                                                ClipRRect(
                                                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                                                  child: Stack(
                                                    children: [
                                                      ColorFiltered(
                                                        colorFilter: isOpen
                                                            ? const ColorFilter.mode(
                                                                Colors.transparent,
                                                                BlendMode.multiply,
                                                              )
                                                            : const ColorFilter.matrix(<double>[
                                                                0.2126,
                                                                0.7152,
                                                                0.0722,
                                                                0,
                                                                0,
                                                                0.2126,
                                                                0.7152,
                                                                0.0722,
                                                                0,
                                                                0,
                                                                0.2126,
                                                                0.7152,
                                                                0.0722,
                                                                0,
                                                                0,
                                                                0,
                                                                0,
                                                                0,
                                                                1,
                                                                0,
                                                              ]),
                                                        child: RestaurantImageView(
                                                          vendorModel: vendorModel,
                                                        ),
                                                      ),
                                                      Container(
                                                        height: Responsive.height(20, context),
                                                        width: Responsive.width(100, context),
                                                        decoration: BoxDecoration(
                                                          color: (isOpen) ? null : Colors.black38,
                                                          gradient: (isOpen)
                                                              ? LinearGradient(
                                                                  begin: const Alignment(-0.00, -1.00),
                                                                  end: const Alignment(0, 1),
                                                                  colors: [Colors.black.withOpacity(0), const Color(0xFF111827)],
                                                                )
                                                              : null,
                                                        ),
                                                        child: (isOpen)
                                                            ? SizedBox()
                                                            : Center(
                                                                child: Image.asset(
                                                                  "assets/images/closed.PNG",
                                                                  height: Responsive.height(16, context),
                                                                  fit: BoxFit.fill,
                                                                ),
                                                              ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Transform.translate(
                                                  offset: Offset(Responsive.width(isRTL == true ? 3 : -3, context), Responsive.height(17.5, context)),
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.end,
                                                    crossAxisAlignment: CrossAxisAlignment.end,
                                                    children: [
                                                      Visibility(
                                                        visible: (vendorModel.isSelfDelivery == true && Constant.isSelfDeliveryFeature == true),
                                                        child: Row(
                                                          children: [
                                                            Container(
                                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                                              decoration: BoxDecoration(
                                                                color: AppThemeData.lightGreen,
                                                                borderRadius: BorderRadius.circular(120), // Optional
                                                              ),
                                                              child: Row(
                                                                children: [
                                                                  SvgPicture.asset(
                                                                    "assets/icons/ic_free_delivery.svg",
                                                                  ),
                                                                  const SizedBox(
                                                                    width: 5,
                                                                  ),
                                                                  TranslatedText(
                                                                    "Free Delivery",
                                                                    style: TextStyle(
                                                                      fontSize: 14,
                                                                      color: AppThemeData.darkGreen,
                                                                      fontFamily: AppThemeData.semiBold,
                                                                      fontWeight: FontWeight.w600,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              width: 6,
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                                        decoration: ShapeDecoration(
                                                          color: themeChange.getThem() ? AppThemeData.primary600 : AppThemeData.primary50,
                                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(120)),
                                                        ),
                                                        child: Row(
                                                          children: [
                                                            SvgPicture.asset(
                                                              "assets/icons/ic_star.svg",
                                                              colorFilter: ColorFilter.mode(AppThemeData.primary300, BlendMode.srcIn),
                                                            ),
                                                            const SizedBox(
                                                              width: 5,
                                                            ),
                                                            Text(
                                                              "${Constant.calculateReview(reviewCount: vendorModel.reviewsCount!.toStringAsFixed(0), reviewSum: vendorModel.reviewsSum.toString())} (${vendorModel.reviewsCount!.toStringAsFixed(0)})",
                                                              style: TextStyle(
                                                                fontSize: 14,
                                                                color: themeChange.getThem() ? AppThemeData.primary300 : AppThemeData.primary300,
                                                                fontFamily: AppThemeData.semiBold,
                                                                fontWeight: FontWeight.w600,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        width: 6,
                                                      ),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                                        decoration: ShapeDecoration(
                                                          color: themeChange.getThem() ? AppThemeData.secondary600 : AppThemeData.secondary50,
                                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(120)),
                                                        ),
                                                        child: Row(
                                                          children: [
                                                            SvgPicture.asset(
                                                              "assets/icons/ic_map_distance.svg",
                                                              colorFilter: const ColorFilter.mode(AppThemeData.secondary300, BlendMode.srcIn),
                                                            ),
                                                            const SizedBox(
                                                              width: 5,
                                                            ),
                                                            TranslatedText(
                                                              "${Constant.getDistance(
                                                                lat1: vendorModel.latitude.toString(),
                                                                lng1: vendorModel.longitude.toString(),
                                                                lat2: Constant.selectedLocation.location!.latitude.toString(),
                                                                lng2: Constant.selectedLocation.location!.longitude.toString(),
                                                              )} ${Constant.distanceType}",
                                                              style: TextStyle(
                                                                fontSize: 14,
                                                                color: themeChange.getThem() ? AppThemeData.secondary300 : AppThemeData.secondary300,
                                                                fontFamily: AppThemeData.semiBold,
                                                                fontWeight: FontWeight.w600,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                )
                                              ],
                                            ),
                                            const SizedBox(
                                              height: 15,
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 16),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  TranslatedText(
                                                    vendorModel.title.toString(),
                                                    textAlign: TextAlign.start,
                                                    maxLines: 1,
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      overflow: TextOverflow.ellipsis,
                                                      fontFamily: AppThemeData.semiBold,
                                                      color: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey900,
                                                    ),
                                                  ),
                                                  TranslatedText(
                                                    vendorModel.location.toString(),
                                                    textAlign: TextAlign.start,
                                                    maxLines: 1,
                                                    style: TextStyle(
                                                      overflow: TextOverflow.ellipsis,
                                                      fontFamily: AppThemeData.medium,
                                                      fontWeight: FontWeight.w500,
                                                      color: themeChange.getThem() ? AppThemeData.grey400 : AppThemeData.grey400,
                                                    ),
                                                  ),
                                                  (isOpen == false)
                                                      ? Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            // DottedLine(
                                                            //   dashColor: AppThemeData.grey400,
                                                            //   dashLength: 6,   // dash ni lambai
                                                            //   dashGapLength: 4, // gap vachche
                                                            //   lineThickness: 1,
                                                            // ),

                                                            TranslatedText(
                                                              Constant.getNextOpeningTime(vendorModel, DateTime.now()),
                                                              maxLines: 1,
                                                              overflow: TextOverflow.ellipsis,
                                                              style: TextStyle(color: AppThemeData.danger300, fontFamily: AppThemeData.medium),
                                                            )
                                                          ],
                                                        )
                                                      : SizedBox()
                                                ],
                                              ),
                                            ),
                                            const SizedBox(
                                              height: 10,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              controller.productSearchList.isEmpty
                                  ? const SizedBox()
                                  : Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        TranslatedText(
                                          "Foods",
                                          textAlign: TextAlign.start,
                                          style: TextStyle(
                                            fontFamily: AppThemeData.semiBold,
                                            fontSize: 16,
                                            color: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey900,
                                          ),
                                        ),
                                        const Padding(
                                          padding: EdgeInsets.symmetric(vertical: 10),
                                          child: Divider(),
                                        ),
                                      ],
                                    ),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: controller.productSearchList.length,
                                itemBuilder: (context, index) {
                                  ProductModel productModel = controller.productSearchList[index];
                                  return FutureBuilder(
                                      future: getPrice(productModel),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                          return Constant.loader();
                                        } else {
                                          if (snapshot.hasError) {
                                            return Center(child: TranslatedText('Error: ${snapshot.error}'));
                                          } else if (snapshot.data == null) {
                                            return const SizedBox();
                                          } else {
                                            Map<String, dynamic> map = snapshot.data!;
                                            String price = map['price'];
                                            String disPrice = map['disPrice'];
                                            return InkWell(
                                              onTap: () async {
                                                await FireStoreUtils.getVendorById(productModel.vendorID.toString()).then(
                                                  (value) {
                                                    if (value != null) {
                                                      Get.to(const RestaurantDetailsScreen(), arguments: {"vendorModel": value});
                                                    }
                                                  },
                                                );
                                              },
                                              child: Padding(
                                                padding: const EdgeInsets.only(bottom: 20),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.start,
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Expanded(
                                                      child: Column(
                                                        mainAxisAlignment: MainAxisAlignment.start,
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Row(
                                                            children: [
                                                              productModel.nonveg == true ? SvgPicture.asset("assets/icons/ic_nonveg.svg") : SvgPicture.asset("assets/icons/ic_veg.svg"),
                                                              const SizedBox(
                                                                width: 5,
                                                              ),
                                                              TranslatedText(
                                                                productModel.nonveg == true ? "Non Veg." : "Pure veg.",
                                                                style: TextStyle(
                                                                  color: productModel.nonveg == true ? AppThemeData.danger300 : AppThemeData.success400,
                                                                  fontFamily: AppThemeData.semiBold,
                                                                  fontWeight: FontWeight.w600,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          const SizedBox(
                                                            height: 5,
                                                          ),
                                                          TranslatedText(
                                                            productModel.name.toString(),
                                                            style: TextStyle(
                                                              fontSize: 18,
                                                              color: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey900,
                                                              fontFamily: AppThemeData.semiBold,
                                                              fontWeight: FontWeight.w600,
                                                            ),
                                                          ),
                                                          double.parse(disPrice) <= 0
                                                              ? Text(
                                                                  Constant.amountShow(amount: price),
                                                                  style: TextStyle(
                                                                    fontSize: 16,
                                                                    color: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey900,
                                                                    fontFamily: AppThemeData.semiBold,
                                                                    fontWeight: FontWeight.w600,
                                                                  ),
                                                                )
                                                              : Row(
                                                                  children: [
                                                                    Text(
                                                                      Constant.amountShow(amount: disPrice),
                                                                      style: TextStyle(
                                                                        fontSize: 16,
                                                                        color: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey900,
                                                                        fontFamily: AppThemeData.semiBold,
                                                                        fontWeight: FontWeight.w600,
                                                                      ),
                                                                    ),
                                                                    const SizedBox(
                                                                      width: 5,
                                                                    ),
                                                                    Text(
                                                                      Constant.amountShow(amount: price),
                                                                      style: TextStyle(
                                                                        fontSize: 14,
                                                                        decoration: TextDecoration.lineThrough,
                                                                        decorationColor: themeChange.getThem() ? AppThemeData.grey500 : AppThemeData.grey400,
                                                                        color: themeChange.getThem() ? AppThemeData.grey500 : AppThemeData.grey400,
                                                                        fontFamily: AppThemeData.semiBold,
                                                                        fontWeight: FontWeight.w600,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                          Row(
                                                            children: [
                                                              SvgPicture.asset(
                                                                "assets/icons/ic_star.svg",
                                                                colorFilter: const ColorFilter.mode(AppThemeData.warning300, BlendMode.srcIn),
                                                              ),
                                                              const SizedBox(
                                                                width: 5,
                                                              ),
                                                              Text(
                                                                "${Constant.calculateReview(reviewCount: productModel.reviewsCount!.toStringAsFixed(0), reviewSum: productModel.reviewsSum.toString())} (${productModel.reviewsCount!.toStringAsFixed(0)})",
                                                                style: TextStyle(
                                                                  color: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey900,
                                                                  fontFamily: AppThemeData.regular,
                                                                  fontWeight: FontWeight.w500,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          TranslatedText(
                                                            "${productModel.description}",
                                                            maxLines: 2,
                                                            style: TextStyle(
                                                              overflow: TextOverflow.ellipsis,
                                                              color: themeChange.getThem() ? AppThemeData.grey50 : AppThemeData.grey900,
                                                              fontFamily: AppThemeData.regular,
                                                              fontWeight: FontWeight.w400,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    ClipRRect(
                                                      borderRadius: const BorderRadius.all(Radius.circular(16)),
                                                      child: Stack(
                                                        children: [
                                                          NetworkImageWidget(
                                                            imageUrl: productModel.photo.toString(),
                                                            fit: BoxFit.cover,
                                                            height: Responsive.height(16, context),
                                                            width: Responsive.width(34, context),
                                                          ),
                                                          Container(
                                                            height: Responsive.height(16, context),
                                                            width: Responsive.width(34, context),
                                                            decoration: BoxDecoration(
                                                              gradient: LinearGradient(
                                                                begin: const Alignment(-0.00, -1.00),
                                                                end: const Alignment(0, 1),
                                                                colors: [Colors.black.withOpacity(0), const Color(0xFF111827)],
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    )
                                                  ],
                                                ),
                                              ),
                                            );
                                          }
                                        }
                                      });
                                },
                              )
                            ],
                          ),
                        ),
                      ),
          );
        });
  }

  Future<Map<String, dynamic>> getPrice(ProductModel productModel) async {
    String price = "0.0";
    String disPrice = "0.0";
    List<String> selectedVariants = [];
    List<String> selectedIndexVariants = [];
    List<String> selectedIndexArray = [];

    print("=======>");
    print(productModel.price);
    print(productModel.disPrice);

    VendorModel? vendorModel = await FireStoreUtils.getVendorById(productModel.vendorID.toString());
    if (productModel.itemAttribute != null) {
      if (productModel.itemAttribute!.attributes!.isNotEmpty) {
        for (var element in productModel.itemAttribute!.attributes!) {
          if (element.attributeOptions!.isNotEmpty) {
            selectedVariants.add(productModel.itemAttribute!.attributes![productModel.itemAttribute!.attributes!.indexOf(element)].attributeOptions![0].toString());
            selectedIndexVariants.add('${productModel.itemAttribute!.attributes!.indexOf(element)} _${productModel.itemAttribute!.attributes![0].attributeOptions![0].toString()}');
            selectedIndexArray.add('${productModel.itemAttribute!.attributes!.indexOf(element)}_0');
          }
        }
      }
      if (productModel.itemAttribute!.variants!.where((element) => element.variantSku == selectedVariants.join('-')).isNotEmpty) {
        price = Constant.productCommissionPrice(vendorModel!, productModel.itemAttribute!.variants!.where((element) => element.variantSku == selectedVariants.join('-')).first.variantPrice ?? '0');
        disPrice = Constant.productCommissionPrice(vendorModel, '0');
      }
    } else {
      price = Constant.productCommissionPrice(vendorModel!, productModel.price.toString());
      disPrice = Constant.productCommissionPrice(vendorModel, productModel.disPrice.toString());
    }

    return {'price': price, 'disPrice': disPrice};
  }
}
