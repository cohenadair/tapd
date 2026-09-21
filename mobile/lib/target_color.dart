import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flame/palette.dart';

import 'managers/preference_manager.dart';

class TargetColor {
  /// Supported targets by [TargetColor]. The indexes of these colors should
  /// never change, as they may be persisted in the database.
  static const _images = [
    "target_red.png",
    "target_orange.png",
    "target_yellow.png",
    "target_green.png",
    "target_blue.png",
    "target_purple.png",
    "target_magenta.png",
    "target_cyan.png",
  ];

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

  static String _randomImage({
    TargetColor? exclude,
  }) {
    var images =
        PreferenceManager.get.difficulty.colors().map((e) => e._image).toList();

    if (exclude != null) {
      images.remove(exclude._image);
    }

    return images[Random().nextInt(images.length)];
  }

  static String? _preferenceImage() {
    var index = PreferenceManager.get.colorIndex;
    return index == null ? null : _images[index];
  }

  static List<TargetColor> all() =>
      _images.mapIndexed((index, _) => TargetColor.from(index: index)).toList();

  static List<TargetColor> veryEasy() {
    return [
      TargetColor.from(index: 0),
      TargetColor.from(index: 2),
      TargetColor.from(index: 3),
      TargetColor.from(index: 4),
    ];
  }

  final String _image;

  /// Returns a [TargetColor] instance of the user-selected color, or a random
  /// [TargetColor] if there isn't one selected.
  TargetColor.fromPreferences({TargetColor? exclude})
      : _image = _preferenceImage() ?? _randomImage(exclude: exclude);

  TargetColor.random({TargetColor? exclude})
      : _image = _randomImage(exclude: exclude);

  TargetColor.from({
    required int index,
  }) : _image = _images[index];

  String get image => _image;

  String get path => "assets/images/$_image";

  Color get color => _palettes[index].color;

  int get index => _images.indexOf(_image);

  @override
  bool operator ==(Object other) =>
      other is TargetColor && other._image == _image;

  @override
  int get hashCode => _image.hashCode;
}
