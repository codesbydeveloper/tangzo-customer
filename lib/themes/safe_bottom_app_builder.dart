import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

/// Lifts every screen above the Android/iOS system navigation bar so
/// bottom buttons (View Cart, Checkout, Pickup, etc.) stay fully visible.
///
/// Top inset is left to AppBars. Existing SafeArea widgets will not
/// double-pad because this consumes the bottom MediaQuery padding.
TransitionBuilder safeBottomAppBuilder() {
  final TransitionBuilder easyLoading = EasyLoading.init();
  return (BuildContext context, Widget? child) {
    return easyLoading(
      context,
      _BottomSystemInset(
        child: child ?? const SizedBox.shrink(),
      ),
    );
  };
}

class _BottomSystemInset extends StatelessWidget {
  final Widget child;

  const _BottomSystemInset({required this.child});

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final double bottomInset = [
      mediaQuery.viewPadding.bottom,
      mediaQuery.padding.bottom,
    ].reduce((a, b) => a > b ? a : b);

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: MediaQuery(
        data: mediaQuery.copyWith(
          padding: mediaQuery.padding.copyWith(bottom: 0),
          viewPadding: mediaQuery.viewPadding.copyWith(bottom: 0),
        ),
        child: child,
      ),
    );
  }
}
