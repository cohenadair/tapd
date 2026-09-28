import 'dart:ui';

import 'package:flame/components.dart';

import '../target_color.dart';
import 'target.dart';

/// A full-width line, drawn in the current target color, marking where that
/// color "starts" after a color change (or after a run is continued). Targets
/// below the line when it was placed can scroll off the screen without ending
/// the run.
///
/// Added as a child of a [TargetBoard] so it scrolls, and rewinds, with the
/// targets. Removes itself once it scrolls off the bottom of the screen.
class MissToleranceLine extends RectangleComponent with HasGameRef {
  /// Draws below every target on its board, including a pulsing target, which
  /// sets its own priority to 1. A pulsing target on the other board is also
  /// drawn above the line, since its board's priority is raised to 1.
  static const _priority = -1;

  MissToleranceLine({
    required TargetColor color,
    required double width,
    required double y,
  }) : super(
          position: Vector2(0, y),
          size: Vector2(width, Target.padding),
          anchor: Anchor.centerLeft,
          priority: _priority,
          paint: Paint()..color = color.color,
        );

  @override
  void update(double dt) {
    super.update(dt);
    if (absolutePosition.y > game.size.y) {
      removeFromParent();
    }
  }
}
