import 'dart:math';

import 'package:flutter/painting.dart';

import 'managers/preference_manager.dart';
import 'target_palette.dart';

class TargetColor {
  /// How much darker a target's edge is than its center.
  static const _edgeDarkening = 0.243;

  /// Where along a target's radius its gradient colors are placed. The
  /// gradient darkens with the square of the distance from the center, so
  /// targets look slightly rounded.
  static const _gradientStops = [0.0, 0.25, 0.5, 0.75, 1.0];

  /// Returns the gradient a target of [color] is painted with.
  static RadialGradient gradientFor(Color color) {
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
  }

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

  static List<TargetColor> all() => List.generate(
      TargetPalette.colorCount, (index) => TargetColor.from(index: index));

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
  }) : index = RangeError.checkValueInInterval(
            index, 0, TargetPalette.colorCount - 1, "index");

  static int? _preferenceIndex() {
    var index = PreferenceManager.get.colorIndex;
    return index == null || index < 0 || index >= TargetPalette.colorCount
        ? null
        : index;
  }

  /// This color in the selected palette. Each index is a color "slot", so a
  /// selected color and the game's logic carry over when the palette changes.
  Color get color => PreferenceManager.get.targetColors[index];

  @override
  bool operator ==(Object other) =>
      other is TargetColor && other.index == index;

  @override
  int get hashCode => index.hashCode;
}
