// Flutter Packages
import 'package:flutter/material.dart';
import 'package:customer/widget/translated_text.dart';

/// A [Widget] to show when there is no data to display.
class EmptyScreen extends StatelessWidget {
  /// Creates a [Widget] to show when there is no data to display.
  const EmptyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TranslatedText('Nothing found here...'),
    );
  }
}
