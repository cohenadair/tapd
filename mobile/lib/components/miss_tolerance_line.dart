import 'dart:ui';

import 'package:flame/components.dart';

import '../managers/preference_manager.dart';
import '../target_color.dart';
import 'target.dart';

/// A full-width line, drawn in the current target's color, marking where that
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

  final TargetColor _color;

  MissToleranceLine({
    required TargetColor color,
    required double width,
    required double y,
  })  : _color = color,
        super(
          position: Vector2(0, y),
          size: Vector2(width, Target.padding),
          anchor: Anchor.centerLeft,
          priority: _priority,
          paint: Paint()..color = _colorOf(color),
        );

  /// Repaints the line after the player changes how targets look.
  void updateAppearance() => paint.color = _colorOf(_color);

  static Color _colorOf(TargetColor color) =>
      PreferenceManager.get.targetSkin.colorOf(color.index);

  @override
  void update(double dt) {
    super.update(dt);
    if (absolutePosition.y > game.size.y) {
      removeFromParent();
    }
  }
}
