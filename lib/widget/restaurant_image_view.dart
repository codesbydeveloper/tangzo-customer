import 'dart:async';

import 'package:customer/models/vendor_model.dart';
import 'package:customer/themes/responsive.dart';
import 'package:customer/utils/network_image_widget.dart';
import 'package:flutter/material.dart';

class RestaurantImageView extends StatefulWidget {
  final VendorModel vendorModel;

  const RestaurantImageView({super.key, required this.vendorModel});

  @override
  State<RestaurantImageView> createState() => _RestaurantImageViewState();
}

class _RestaurantImageViewState extends State<RestaurantImageView> {
  int currentPage = 0;
  PageController pageController = PageController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    animateSlider();
  }

  void animateSlider() {
    final photos = widget.vendorModel.photos;
    if (photos == null || photos.length <= 1) return;

    _timer = Timer.periodic(const Duration(seconds: 2), (Timer timer) {
      if (!mounted || !pageController.hasClients) return;
      if (currentPage < photos.length - 1) {
        currentPage++;
      } else {
        currentPage = 0;
      }
      pageController.animateToPage(
        currentPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imageHeight = Responsive.height(20, context).clamp(140.0, 220.0);
    return SizedBox(
      height: imageHeight,
      width: double.infinity,
      child: widget.vendorModel.photos == null || widget.vendorModel.photos!.isEmpty
          ? NetworkImageWidget(
              imageUrl: widget.vendorModel.photo.toString(),
              fit: BoxFit.cover,
              height: imageHeight,
              width: double.infinity,
            )
          : PageView.builder(
              physics: const BouncingScrollPhysics(),
              controller: pageController,
              scrollDirection: Axis.horizontal,
              allowImplicitScrolling: true,
              itemCount: widget.vendorModel.photos!.length,
              padEnds: false,
              pageSnapping: true,
              itemBuilder: (BuildContext context, int index) {
                String image = widget.vendorModel.photos![index];
                return NetworkImageWidget(
                  imageUrl: image.toString(),
                  fit: BoxFit.cover,
                  height: imageHeight,
                  width: double.infinity,
                );
              },
            ),
    );
  }
}
