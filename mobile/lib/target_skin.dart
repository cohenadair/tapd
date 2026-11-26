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
  /// True if every target fills its whole circle, so other things, such as
  /// the score, can be drawn on top of it.
  bool get fillsCircle;

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

  /// Paints shared by every target drawn with this skin, keyed by slot,
  /// radius, and opacity. Building a gradient shader is expensive, so each is
  /// built only once. Targets come in only a few sizes, so this stays small.
  final _fills = <(int, double, double), Paint>{};

  PaletteSkin(this.colors);

  @override
  bool get fillsCircle => true;

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
    // Drawn around the origin, so a fill's shader can be reused at any
    // position.
    canvas
      ..save()
      ..translate(center.dx, center.dy)
      ..drawCircle(Offset.zero, radius, _fill(index, radius, opacity))
      ..restore();
  }

  Paint _fill(int index, double radius, double opacity) {
    return _fills.putIfAbsent((index, radius, opacity), () {
      var bounds = Rect.fromCircle(center: Offset.zero, radius: radius);
      return Paint()
        ..shader = TargetColor.gradientFor(colors[index]).createShader(bounds)
        // When a shader is set, only the color's opacity is used.
        ..color = Colors.black.withValues(alpha: opacity);
    });
  }
}

/// A different [TargetShape] for each slot, all in one light color, with no
/// circle behind them.
class ShapeSkin implements TargetSkin {
  static const _color = colorLightText;

  /// Shapes are drawn a little smaller than their circle, so neighboring
  /// shapes don't touch.
  static const _sizeFactor = 0.85;

  /// Paints shared by every shape, keyed by opacity.
  final _paints = <double, Paint>{};

  @override
  bool get fillsCircle => false;

  @override
  Color colorOf(int index) => _color;

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
