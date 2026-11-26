import 'dart:math';

import 'package:material_ui/material_ui.dart';

/// Shapes drawn on targets so players can tell colors apart without relying
/// on color alone. Each color slot always has the same shape, whatever the
/// palette.
class TargetSymbol {
  /// The symbol's size relative to its target's radius.
  static const _sizeFactor = 0.55;

  /// Above this luminance, a target is light enough for a dark symbol.
  static const _lightLuminance = 0.3;
  static const _darkSymbolOpacity = 0.62;
  static const _lightSymbolOpacity = 0.85;

  static const _squareHalfSize = 0.8;
  static const _triangleBase = 0.8;
  static const _ringOuterRadius = 0.9;
  static const _starPoints = 5;
  static const _starInnerRadius = 0.42;
  static const _armHalfWidth = 0.24;
  static const _ringInnerRadius = 0.55;
  static const _crescentOffset = 0.42;
  static const _crescentInnerRadius = 0.82;

  /// One shape per color slot, in a unit square centered on the origin
  /// (from -1 to 1 on each axis). Built once, since they never change.
  static final _paths = List<Path>.unmodifiable([
    _square(),
    _star(),
    _triangle(),
    _ring(),
    _diamond(),
    _plus(),
    _cross(),
    _crescent(),
  ]);

  /// Draws the symbol for the color at [index], centered at [center], on a
  /// target with the given [radius]. [paint] comes from [paintOn], and can be
  /// reused for every target of the same color.
  static void draw(
    Canvas canvas, {
    required int index,
    required Offset center,
    required double radius,
    required Paint paint,
  }) {
    canvas
      ..save()
      ..translate(center.dx, center.dy)
      ..scale(radius * _sizeFactor)
      ..drawPath(_paths[index], paint)
      ..restore();
  }

  /// The paint for a symbol on a target of [color]: dark on light targets,
  /// light on dark ones. [opacity] fades the symbol along with its target.
  static Paint paintOn(Color color, {double opacity = 1}) => Paint()
    ..color = color.computeLuminance() > _lightLuminance
        ? Colors.black.withValues(alpha: _darkSymbolOpacity * opacity)
        : Colors.white.withValues(alpha: _lightSymbolOpacity * opacity);

  @visibleForTesting
  static int get count => _paths.length;

  static Path _square() => Path()
    ..addRect(const Rect.fromLTRB(
      -_squareHalfSize,
      -_squareHalfSize,
      _squareHalfSize,
      _squareHalfSize,
    ));

  static Path _star() {
    var path = Path();
    for (var i = 0; i < _starPoints * 2; i++) {
      var radius = i.isEven ? 1.0 : _starInnerRadius;
      var angle = -pi / 2 + i * pi / _starPoints;
      var point = Offset(cos(angle) * radius, sin(angle) * radius);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path..close();
  }

  static Path _triangle() => Path()
    ..moveTo(0, -1)
    ..lineTo(1, _triangleBase)
    ..lineTo(-1, _triangleBase)
    ..close();

  static Path _ring() => Path()
    ..fillType = PathFillType.evenOdd
    ..addOval(Rect.fromCircle(center: Offset.zero, radius: _ringOuterRadius))
    ..addOval(Rect.fromCircle(center: Offset.zero, radius: _ringInnerRadius));

  static Path _diamond() => Path()
    ..moveTo(0, -1)
    ..lineTo(1, 0)
    ..lineTo(0, 1)
    ..lineTo(-1, 0)
    ..close();

  static Path _plus() => Path.combine(
        PathOperation.union,
        Path()
          ..addRect(const Rect.fromLTRB(-_armHalfWidth, -1, _armHalfWidth, 1)),
        Path()
          ..addRect(const Rect.fromLTRB(-1, -_armHalfWidth, 1, _armHalfWidth)),
      );

  static Path _cross() => _plus().transform(Matrix4.rotationZ(pi / 4).storage);

  static Path _crescent() => Path.combine(
        PathOperation.difference,
        Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: 1)),
        Path()
          ..addOval(Rect.fromCircle(
            center: const Offset(_crescentOffset, -_crescentOffset / 2),
            radius: _crescentInnerRadius,
          )),
      );
}
