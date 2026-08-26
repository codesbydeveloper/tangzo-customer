import 'package:cached_network_image/cached_network_image.dart';
import 'package:customer/constant/constant.dart';
import 'package:flutter/material.dart';

class NetworkImageWidget extends StatelessWidget {
  final String imageUrl;
  final double? height;
  final double? width;
  final Widget? errorWidget;
  final BoxFit? fit;
  final double? borderRadius;
  final Color? color;

  const NetworkImageWidget({
    super.key,
    this.height,
    this.width,
    this.fit,
    required this.imageUrl,
    this.borderRadius,
    this.errorWidget,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final url = imageUrl.trim();
    final hasUrl = url.isNotEmpty && url != 'null';

    Widget placeholder = Image.asset(
      "assets/images/simmer_gif.gif",
      height: height,
      width: width,
      fit: BoxFit.cover,
    );

    Widget fallback = errorWidget ??
        (Constant.placeholderImage.isNotEmpty
            ? Image.network(
                Constant.placeholderImage,
                fit: fit ?? BoxFit.cover,
                height: height,
                width: width,
                errorBuilder: (_, __, ___) => Container(
                  height: height,
                  width: width,
                  color: Colors.grey.shade300,
                ),
              )
            : Container(
                height: height,
                width: width,
                color: Colors.grey.shade300,
              ));

    if (!hasUrl) {
      return SizedBox(height: height, width: width, child: fallback);
    }

    return CachedNetworkImage(
      imageUrl: url,
      fit: fit ?? BoxFit.cover,
      height: height,
      width: width,
      color: color,
      progressIndicatorBuilder: (context, url, downloadProgress) => placeholder,
      errorWidget: (context, url, error) => fallback,
    );
  }
}
