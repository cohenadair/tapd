import 'package:flutter/material.dart';

import '../target_color.dart';

/// Paints a target the same way the game does, for use outside of the game,
/// such as in the scoreboard and settings.
class TargetCircle extends StatelessWidget {
  final TargetColor color;

  const TargetCircle(this.color);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: color.gradient,
      ),
    );
  }
}
