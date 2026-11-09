import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flame/palette.dart';
import 'package:flutter/painting.dart';

import 'managers/preference_manager.dart';

class TargetColor {
  /// Supported targets by [TargetColor]. The indexes of these colors should
  /// never change, as they may be persisted in the database.
  static const _palettes = [
    BasicPalette.red,
    BasicPalette.orange,
    BasicPalette.yellow,
    BasicPalette.green,
    BasicPalette.blue,
    BasicPalette.purple,
    BasicPalette.magenta,
    BasicPalette.cyan,
  ];

  /// How much darker a target's edge is than its center.
  static const _edgeDarkening = 0.243;

  /// Where along a target's radius its gradient colors are placed. The
  /// gradient darkens with the square of the distance from the center, so
  /// targets look slightly rounded.
  static const _gradientStops = [0.0, 0.25, 0.5, 0.75, 1.0];

  static final _gradients = _palettes.map((palette) {
    var color = palette.color;
    return RadialGradient(
      colors: _gradientStops.map((stop) {
        var factor = 1 - _edgeDarkening * stop * stop;
        return Color.from(
          alpha: color.a,
          red: color.r * factor,
          green: color.g * factor,
          blue: color.b * factor,
        );
      }).toList(),
      stops: _gradientStops,
    );
  }).toList();

  static int _randomIndex({
    TargetColor? exclude,
  }) {
    var indexes =
        PreferenceManager.get.difficulty.colors().map((e) => e.index).toList();

    if (exclude != null) {
      indexes.remove(exclude.index);
    }

    return indexes[Random().nextInt(indexes.length)];
  }

  static List<TargetColor> all() => _palettes
      .mapIndexed((index, _) => TargetColor.from(index: index))
      .toList();

  static List<TargetColor> veryEasy() {
    return [
      TargetColor.from(index: 0),
      TargetColor.from(index: 2),
      TargetColor.from(index: 3),
      TargetColor.from(index: 4),
    ];
  }

  final int index;

  /// Returns a [TargetColor] instance of the user-selected color, or a random
  /// [TargetColor] if there isn't one selected, or the selected one is no
  /// longer valid.
  TargetColor.fromPreferences({TargetColor? exclude})
      : index = _preferenceIndex() ?? _randomIndex(exclude: exclude);

  TargetColor.random({TargetColor? exclude})
      : index = _randomIndex(exclude: exclude);

  TargetColor.from({
    required int index,
  }) : index = RangeError.checkValidIndex(index, _palettes);

  static int? _preferenceIndex() {
    var index = PreferenceManager.get.colorIndex;
    return index != null && index >= 0 && index < _palettes.length
        ? index
        : null;
  }

  Color get color => _palettes[index].color;

  /// The gradient targets of this color are painted with.
  RadialGradient get gradient => _gradients[index];

  @override
  bool operator ==(Object other) =>
      other is TargetColor && other.index == index;

  @override
  int get hashCode => index.hashCode;
}
