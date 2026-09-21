import 'package:flutter/material.dart';

import 'localized_material_app.dart';

/// A full-screen overlay with a translucent black background, for overlays
/// shown above the game. [builder] receives a [BuildContext] that has the
/// app's localizations and theme.
class OverlayScaffold extends StatelessWidget {
  final double backgroundOpacity;
  final WidgetBuilder builder;

  const OverlayScaffold({
    required this.backgroundOpacity,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return LocalizedMaterialApp(
      (context) => Scaffold(
        backgroundColor: Colors.black.withValues(alpha: backgroundOpacity),
        body: builder(context),
      ),
    );
  }
}
