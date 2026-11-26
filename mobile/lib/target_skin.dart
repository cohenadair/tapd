import 'package:material_ui/material_ui.dart';

import 'target_color.dart';
import 'target_symbol.dart';
import 'target_symbol_set.dart';

/// Draws targets. Everything that shows a target (the game, the scoreboard,
/// and settings) draws it through the player's current skin, from
/// `PreferenceManager.targetSkin`. A new kind of target look, such as a
/// sticker pack or a different target shape, is added as a new skin, without
/// changing the game or its widgets.
///
/// A skin only changes how a color slot looks. The game itself only deals in
/// slots ([TargetColor.index]), and taps are always detected within the
/// target's circle, whatever a skin draws there.
abstract class TargetSkin {
  /// True if [paintSymbol] draws anything.
  bool get hasSymbols;

  /// Draws the target for the color slot at [index], filling the circle at
  /// [center] with [radius]. [opacity] fades the whole target.
  void paint(
    Canvas canvas, {
    required int index,
    required Offset center,
    required double radius,
    double opacity = 1,
    bool includesSymbol = true,
  });

  /// Draws only the symbol for the color slot at [index], sized as it would
  /// be on a target with [radius], such as above the score on the
  /// scoreboard.
  void paintSymbol(
    Canvas canvas, {
    required int index,
    required Offset center,
    required double radius,
  });
}

/// Targets filled with a palette's [colors], with an optional [symbolSet]
/// drawn on top.
class PaletteSkin implements TargetSkin {
  final List<Color> colors;
  final TargetSymbolSet symbolSet;

  /// Paints shared by every target drawn with this skin, keyed by slot,
  /// radius, and opacity. Building a gradient shader is expensive, so each is
  /// built only once. Targets come in only a few sizes, so these stay small.
  final _fills = <(int, double, double), Paint>{};
  final _symbolPaints = <(int, double), Paint>{};

  PaletteSkin({
    required this.colors,
    required this.symbolSet,
  });

  @override
  bool get hasSymbols => symbolSet != TargetSymbolSet.none;

  @override
  void paint(
    Canvas canvas, {
    required int index,
    required Offset center,
    required double radius,
    double opacity = 1,
    bool includesSymbol = true,
  }) {
    // Drawn around the origin, so a fill's shader can be reused at any
    // position.
    canvas
      ..save()
      ..translate(center.dx, center.dy)
      ..drawCircle(Offset.zero, radius, _fill(index, radius, opacity));
    if (includesSymbol) {
      _drawSymbol(canvas, index, radius, opacity);
    }
    canvas.restore();
  }

  @override
  void paintSymbol(
    Canvas canvas, {
    required int index,
    required Offset center,
    required double radius,
  }) {
    canvas
      ..save()
      ..translate(center.dx, center.dy);
    _drawSymbol(canvas, index, radius, 1);
    canvas.restore();
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

  void _drawSymbol(Canvas canvas, int index, double radius, double opacity) {
    switch (symbolSet) {
      case TargetSymbolSet.none:
        return;
      case TargetSymbolSet.shapes:
        TargetSymbol.draw(
          canvas,
          index: index,
          center: Offset.zero,
          radius: radius,
          paint: _symbolPaints.putIfAbsent((index, opacity),
              () => TargetSymbol.paintOn(colors[index], opacity: opacity)),
        );
    }
  }
}
