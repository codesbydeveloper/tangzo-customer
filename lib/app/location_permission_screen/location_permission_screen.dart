import 'package:customer/app/address_screens/address_list_screen.dart';
import 'package:customer/app/dash_board_screens/dash_board_screen.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/controllers/location_permission_controller.dart';
import 'package:customer/models/user_model.dart';
import 'package:customer/themes/app_them_data.dart';
import 'package:customer/themes/responsive.dart';
import 'package:customer/themes/round_button_fill.dart';
import 'package:customer/utils/dark_theme_provider.dart';
import 'package:customer/widget/osm_map/map_picker_page.dart';
import 'package:customer/widget/place_picker/location_picker_screen.dart';
import 'package:customer/widget/place_picker/selected_location_model.dart';
import 'package:flutter/material.dart';
import 'package:customer/widget/translated_text.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class LocationPermissionScreen extends StatelessWidget {
  const LocationPermissionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetBuilder(
      init: LocationPermissionController(),
      builder: (controller) {
        return Scaffold(
          body: Container(
            height: Responsive.height(100, context),
            width: Responsive.width(100, context),
            decoration:
                BoxDecoration(image: DecorationImage(image: themeChange.getThem() ? AssetImage("assets/images/location_bg_dark.png") : AssetImage("assets/images/location_bg.png"), fit: BoxFit.cover)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 35),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TranslatedText(
                    "Enable Location Services 📍",
                    style: TextStyle(color: themeChange.getThem() ? AppThemeData.grey200 : AppThemeData.grey900, fontSize: 22, fontFamily: AppThemeData.semiBold),
                  ),
                  TranslatedText(
                    "To provide the best dining experience, allow Foodie to access your location.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: themeChange.getThem() ? AppThemeData.grey200 : AppThemeData.grey900, fontSize: 16, fontFamily: AppThemeData.bold),
                  ),
                  const SizedBox(
                    height: 32,
                  ),
                  RoundedButtonFill(
                    title: "Use Current Location",
                    color: AppThemeData.primary300,
                    textColor: AppThemeData.grey50,
                    onPress: () async {
                      Constant.checkPermission(
                        context: context,
                        onTap: () async {
                          ShowToastDialog.showLoader("Please wait");
                          ShippingAddress addressModel = ShippingAddress();
                          try {
                            await Geolocator.requestPermission();
                            Position newLocalData = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

                            await placemarkFromCoordinates(newLocalData.latitude, newLocalData.longitude).then((valuePlaceMaker) {
                              Placemark placeMark = valuePlaceMaker[0];
                              addressModel.addressAs = "Home";
                              addressModel.location = UserLocation(latitude: newLocalData.latitude, longitude: newLocalData.longitude);
                              String currentLocation =
                                  "${placeMark.name}, ${placeMark.subLocality}, ${placeMark.locality}, ${placeMark.administrativeArea}, ${placeMark.postalCode}, ${placeMark.country}";
                              addressModel.locality = currentLocation;
                            });

                            Constant.selectedLocation = addressModel;
                            ShowToastDialog.closeLoader();

                            Get.offAll(const DashBoardScreen());
                          } catch (e) {
                            await placemarkFromCoordinates(19.228825, 72.854118).then((valuePlaceMaker) {
                              Placemark placeMark = valuePlaceMaker[0];
                              addressModel.addressAs = "Home";
                              addressModel.location = UserLocation(latitude: 19.228825, longitude: 72.854118);
                              String currentLocation =
                                  "${placeMark.name}, ${placeMark.subLocality}, ${placeMark.locality}, ${placeMark.administrativeArea}, ${placeMark.postalCode}, ${placeMark.country}";
                              addressModel.locality = currentLocation;
                            });

                            Constant.selectedLocation = addressModel;
                            ShowToastDialog.closeLoader();

                            Get.offAll(const DashBoardScreen());
                          }
                        },
                      );
                    },
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  RoundedButtonFill(
                    title: "Set From Map",
                    color: AppThemeData.primary300,
                    textColor: AppThemeData.grey50,
                    icon: Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: SvgPicture.asset(
                        "assets/icons/ic_location_pin.svg",
                        colorFilter: const ColorFilter.mode(AppThemeData.grey50, BlendMode.srcIn),
                      ),
                    ),
                    isRight: false,
                    onPress: () async {
                      Constant.checkPermission(
                        context: context,
                        onTap: () async {
                          ShowToastDialog.showLoader("Please wait");
                          ShippingAddress addressModel = ShippingAddress();
                          try {
                            await Geolocator.requestPermission();
                            await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
                            ShowToastDialog.closeLoader();
                            if (Constant.selectedMapType == 'osm') {
                              final result = await Get.to(() => MapPickerPage());
                              if (result != null) {
                                final firstPlace = result;
                                final lat = firstPlace.coordinates.latitude;
                                final lng = firstPlace.coordinates.longitude;
                                final address = firstPlace.address;

                                addressModel.addressAs = "Home";
                                addressModel.locality = address.toString();
                                addressModel.location = UserLocation(latitude: lat, longitude: lng);
                                Constant.selectedLocation = addressModel;

                                Get.offAll(const DashBoardScreen());
                              }
                            } else {
                              Get.to(LocationPickerScreen())!.then((value) async {
                                if (value != null) {
                                  SelectedLocationModel selectedLocationModel = value;

                                  ShippingAddress addressModel = ShippingAddress();
                                  addressModel.addressAs = "Home";
                                  addressModel.locality = Constant.formatAddress(selectedLocation: selectedLocationModel);
                                  addressModel.location = UserLocation(latitude: selectedLocationModel.latLng!.latitude, longitude: selectedLocationModel.latLng!.longitude);
                                  Constant.selectedLocation = addressModel;

                                  Get.offAll(const DashBoardScreen());
                                }
                              });
                            }
                          } catch (e) {
                            await placemarkFromCoordinates(19.228825, 72.854118).then((valuePlaceMaker) {
                              Placemark placeMark = valuePlaceMaker[0];
                              addressModel.addressAs = "Home";
                              addressModel.location = UserLocation(latitude: 19.228825, longitude: 72.854118);
                              String currentLocation =
                                  "${placeMark.name}, ${placeMark.subLocality}, ${placeMark.locality}, ${placeMark.administrativeArea}, ${placeMark.postalCode}, ${placeMark.country}";
                              addressModel.locality = currentLocation;
                            });

                            Constant.selectedLocation = addressModel;
                            ShowToastDialog.closeLoader();

                            Get.offAll(const DashBoardScreen());
                          }
                        },
                      );
                    },
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Constant.userModel == null
                      ? const SizedBox()
                      : RoundedButtonFill(
                          title: "Enter Manually location",
                          color: AppThemeData.primary300,
                          textColor: AppThemeData.grey50,
                          isRight: false,
                          onPress: () async {
                            Get.to(const AddressListScreen())!.then(
                              (value) {
                                if (value != null) {
                                  ShippingAddress addressModel = value;
                                  Constant.selectedLocation = addressModel;

                                  Get.offAll(const DashBoardScreen());
                                }
                              },
                            );
                          },
                        ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
