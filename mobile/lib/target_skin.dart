import 'package:material_ui/material_ui.dart';

import 'target_color.dart';
import 'target_shape.dart';
import 'utils/colors.dart';

/// Draws targets. Everything that shows a target (the game, the scoreboard,
/// and settings) draws it through the player's current skin, from
/// `PreferenceManager.targetSkin`. A new kind of target, such as a sticker
/// pack, is added as a new skin, without changing the game or its widgets.
///
/// A skin only changes how a target slot looks. The game itself only deals
/// in slots ([TargetColor.index]), and taps are always detected within the
/// target's circle, whatever a skin draws there.
abstract class TargetSkin {
  /// The main color of the target for the slot at [index], for things drawn
  /// to match it, such as a `MissToleranceLine`.
  Color colorOf(int index);

  /// Draws the target for the slot at [index] within the circle at [center]
  /// with [radius]. [opacity] fades the whole target.
  void paint(
    Canvas canvas, {
    required int index,
    required Offset center,
    required double radius,
    double opacity = 1,
  });
}

/// Circles filled with a palette's [colors].
class PaletteSkin implements TargetSkin {
  final List<Color> colors;

  /// The circle every fill is built for. Targets are scaled to their size
  /// when drawn, so one fill serves every size.
  static final _unitBounds = Rect.fromCircle(center: Offset.zero, radius: 1);

  /// Paints shared by every target drawn with this skin, keyed by slot and
  /// opacity. Building a gradient shader is expensive, so each is built only
  /// once.
  final _fills = <(int, double), Paint>{};

  PaletteSkin(this.colors);

  @override
  Color colorOf(int index) => colors[index];

  @override
  void paint(
    Canvas canvas, {
    required int index,
    required Offset center,
    required double radius,
    double opacity = 1,
  }) {
    // Drawn as a unit circle around the origin, so a fill's shader can be
    // reused at any position and size.
    canvas
      ..save()
      ..translate(center.dx, center.dy)
      ..scale(radius)
      ..drawCircle(Offset.zero, 1, _fill(index, opacity))
      ..restore();
  }

  Paint _fill(int index, double opacity) {
    return _fills.putIfAbsent((index, opacity), () {
      return Paint()
        ..shader =
            TargetColor.gradientFor(colors[index]).createShader(_unitBounds)
        // When a shader is set, only the color's opacity is used.
        ..color = Colors.black.withValues(alpha: opacity);
    });
  }
}

/// A different [TargetShape] for each slot, all in one light color, with no
/// circle behind them.
class ShapeSkin implements TargetSkin {
  static const _color = colorShape;

  /// Shapes are drawn a little smaller than their circle, so neighboring
  /// shapes don't touch.
  static const _sizeFactor = 0.85;

  /// Paints shared by every shape, keyed by opacity.
  final _paints = <double, Paint>{};

  @override
  Color colorOf(int _) => _color;

  @override
  void paint(
    Canvas canvas, {
    required int index,
    required Offset center,
    required double radius,
    double opacity = 1,
  }) {
    TargetShape.draw(
      canvas,
      index: index,
      center: center,
      radius: radius * _sizeFactor,
      paint: _paints.putIfAbsent(
          opacity, () => Paint()..color = _color.withValues(alpha: opacity)),
    );
  }
}
