import 'package:material_ui/material_ui.dart';
import 'package:mobile/l10n/gen/strings.dart';

/// The sets of colors targets can be painted with.
///
/// Note that the palette indexes are stored in preferences and should *not*
/// be changed.
enum TargetPalette {
  standard(
    colors: [
      Color(0xFFFF0000),
      Color(0xFFFFA500),
      Color(0xFFFFFF00),
      Color(0xFF00FF00),
      Color(0xFF0000FF),
      Color(0xFF800080),
      Color(0xFFFF00FF),
      Color(0xFF00FFFF),
    ],
  ),

  /// Based on the Okabe-Ito palette, tuned so every pair of colors stays
  /// distinct on the game's dark background with protanopia, deuteranopia,
  /// and tritanopia, as well as normal color vision.
  colorBlindFriendly(
    colors: [
      Color(0xFFA56608),
      Color(0xFFD6A708),
      Color(0xFFD8FF8A),
      Color(0xFF309E73),
      Color(0xFF285AEF),
      Color(0xFF9C89AF),
      Color(0xFF9EE4FF),
      Color(0xFFEFE7DF),
    ],
  ),

  /// The player's own colors. Has no preset [colors]; they're stored in
  /// preferences.
  custom(colors: null);

  /// The number of colors in every palette, and so the number of distinct
  /// target colors in the game.
  static const colorCount = 8;

  /// Colors a player can choose from when customizing a palette. Each stands
  /// out against the game's background, including with color vision
  /// deficiencies.
  static const swatches = [
    Color(0xFFFF0000),
    Color(0xFFD55E00),
    Color(0xFFFF7F50),
    Color(0xFFFFA500),
    Color(0xFFE69F00),
    Color(0xFFD6A708),
    Color(0xFFA56608),
    Color(0xFFFFFF00),
    Color(0xFFF0E442),
    Color(0xFFD8FF8A),
    Color(0xFF7CFC00),
    Color(0xFF00FF00),
    Color(0xFF309E73),
    Color(0xFF009E73),
    Color(0xFF00FFFF),
    Color(0xFF9EE4FF),
    Color(0xFF56B4E9),
    Color(0xFF4477FF),
    Color(0xFF285AEF),
    Color(0xFF0000FF),
    Color(0xFFAA44EE),
    Color(0xFF800080),
    Color(0xFF9C89AF),
    Color(0xFFFF00FF),
    Color(0xFFCC79A7),
    Color(0xFFFF69B4),
    Color(0xFFFFB6C1),
    Color(0xFFEFE7DF),
    Color(0xFFFFFFFF),
    Color(0xFFBBBBBB),
  ];

  /// The palette's preset colors, or null for [custom].
  final List<Color>? colors;

  const TargetPalette({required this.colors});

  String displayName(BuildContext context) {
    switch (this) {
      case TargetPalette.standard:
        return Strings.of(context).targetPaletteStandard;
      case TargetPalette.colorBlindFriendly:
        return Strings.of(context).targetPaletteColorBlindFriendly;
      case TargetPalette.custom:
        return Strings.of(context).targetPaletteCustom;
    }
  }
}
