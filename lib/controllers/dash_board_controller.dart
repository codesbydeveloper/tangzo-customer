import 'package:customer/app/favourite_screens/favourite_screen.dart';
import 'package:customer/app/home_screen/home_screen.dart';
import 'package:customer/app/home_screen/home_screen_two.dart';
import 'package:customer/app/order_list_screen/order_screen.dart';
import 'package:customer/app/profile_screen/profile_screen.dart';
import 'package:customer/app/wallet_screen/wallet_screen.dart';
import 'package:customer/constant/constant.dart';
import 'package:get/get.dart';

class DashBoardController extends GetxController {
  RxInt selectedIndex = 0.obs;

  RxList pageList = [].obs;

  @override
  void onInit() {
    // TODO: implement onInit

    super.onInit();
    getInit();
  }

  Future<void> getInit() async {
    if (Constant.theme == "theme_2") {
      if (Constant.walletSetting == false) {
        pageList.value = [
          const HomeScreen(),
          const FavouriteScreen(),
          const OrderScreen(),
          const ProfileScreen(),
        ];
      } else {
        pageList.value = [
          const HomeScreen(),
          const FavouriteScreen(),
          const WalletScreen(),
          const OrderScreen(),
          const ProfileScreen(),
        ];
      }
    } else {
      if (Constant.walletSetting == false) {
        pageList.value = [
          const HomeScreenTwo(),
          const FavouriteScreen(),
          const OrderScreen(),
          const ProfileScreen(),
        ];
      } else {
        pageList.value = [
          const HomeScreenTwo(),
          const FavouriteScreen(),
          const WalletScreen(),
          const OrderScreen(),
          const ProfileScreen(),
        ];
      }
    }
  }

  DateTime? currentBackPressTime;
  RxBool canPopNow = false.obs;
}
