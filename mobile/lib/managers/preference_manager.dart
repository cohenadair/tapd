import 'dart:async';
import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:mobile/difficulty.dart';
import 'package:mobile/target_palette.dart';
import 'package:mobile/target_skin.dart';
import 'package:mobile/target_type.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferenceManager {
  static var _instance = PreferenceManager._();

  static PreferenceManager get get => _instance;

  @visibleForTesting
  static void set(PreferenceManager manager) => _instance = manager;

  @visibleForTesting
  static void suicide() => _instance = PreferenceManager._();

  PreferenceManager._();

  static const keyDifficulty = "difficulty";
  static const keyColorIndex = "color_index";
  static const keyUserName = "user_name";
  static const keyUserEmail = "user_email";
  static const keyMusicOn = "is_music_on";
  static const keySoundOn = "is_sound_on";
  static const keyFpsOn = "is_fps_on";
  static const keyDifficultyStats = "difficulty_stats";
  static const keyDidOnboard = "did_onboard_user";
  static const keyTargetPalette = "target_palette";
  static const keyCustomColors = "custom_colors";
  static const keyTargetType = "target_type";

  /// The key previously used to store the number of lives a player had. It is
  /// only referenced to clear stale values left over from before lives were
  /// removed, and can be deleted once enough releases have shipped.
  static const _legacyKeyLives = "lives";

  late final SharedPreferences _prefs;

  /// Cached [targetColors] and [targetSkin]; null until read, and after
  /// they change.
  List<Color>? _targetColors;
  TargetSkin? _targetSkin;

  final _controller = StreamController<String>.broadcast();

  Stream<String> get stream => _controller.stream;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _prefs.remove(_legacyKeyLives);
  }

  Difficulty get difficulty => Difficulty
      .values[_prefs.getInt(keyDifficulty) ?? Difficulty.normal.index];

  set difficulty(Difficulty value) => _setInt(keyDifficulty, value.index);

  int? get colorIndex => _prefs.getInt(keyColorIndex);

  set colorIndex(int? value) {
    if (value == null) {
      _remove(keyColorIndex);
    } else {
      _setInt(keyColorIndex, value);
    }
  }

  TargetPalette get targetPalette => _enumValue(
      keyTargetPalette, TargetPalette.values, TargetPalette.standard);

  set targetPalette(TargetPalette value) =>
      _setInt(keyTargetPalette, value.index);

  /// The player's custom target colors, or null if they haven't made any, or
  /// the stored colors are invalid.
  List<Color>? get customColors {
    var values = _prefs.getStringList(keyCustomColors);
    if (values == null || values.length != TargetPalette.colorCount) {
      return null;
    }

    var colors = values.map(int.tryParse).toList();
    return colors.contains(null)
        ? null
        : colors.map((value) => Color(value!)).toList();
  }

  set customColors(List<Color>? value) {
    _writeCustomColors(value);
    _notify(keyCustomColors);
  }

  /// The colors targets are painted with, from the selected palette. Read for
  /// every target the game paints, so it's cached until the palette or
  /// custom colors change.
  ///
  /// Falls back to the standard colors if the custom palette is selected but
  /// its stored colors are missing or invalid.
  List<Color> get targetColors => _targetColors ??= List.unmodifiable(
      targetPalette.colors ?? customColors ?? TargetPalette.standard.colors!);

  /// Selects [palette]. Selecting [TargetPalette.custom] before any custom
  /// colors exist starts them from the current colors.
  void selectTargetPalette(TargetPalette palette) {
    _setTargetAppearance(
      palette,
      palette == TargetPalette.custom && customColors == null
          ? targetColors
          : customColors,
    );
  }

  /// Changes the color at [index] and switches to the custom palette, which
  /// starts from the current colors. Does nothing if [index] already has
  /// [color].
  void setCustomColor(int index, Color color) {
    if (targetColors[index] == color) {
      return;
    }
    _setTargetAppearance(
      TargetPalette.custom,
      List.of(targetColors)..[index] = color,
    );
  }

  /// Goes back to the standard palette, and forgets any custom colors.
  void resetTargetColors() =>
      _setTargetAppearance(TargetPalette.standard, null);

  TargetType get targetType =>
      _enumValue(keyTargetType, TargetType.values, TargetType.colors);

  set targetType(TargetType value) => _setInt(keyTargetType, value.index);

  /// Draws targets the way the player has chosen. Cached, like
  /// [targetColors], until how targets look changes.
  TargetSkin get targetSkin => _targetSkin ??= _buildTargetSkin();

  /// True if a key changes how targets look.
  static bool isTargetAppearanceKey(String key) =>
      key == keyTargetPalette || key == keyCustomColors || key == keyTargetType;

  set userName(String? value) => _setString(keyUserName, value ?? "");

  String? get userName => _prefs.getString(keyUserName);

  set userEmail(String? value) => _setString(keyUserEmail, value ?? "");

  String? get userEmail => _prefs.getString(keyUserEmail);

  bool get isSoundOn => _prefs.getBool(keySoundOn) ?? true;

  set isSoundOn(bool value) => _setBool(keySoundOn, value);

  bool get isMusicOn => _prefs.getBool(keyMusicOn) ?? true;

  set isMusicOn(bool value) => _setBool(keyMusicOn, value);

  bool get isFpsOn => _prefs.getBool(keyFpsOn) ?? false;

  set isFpsOn(bool value) => _setBool(keyFpsOn, value);

  Map<int, DifficultyStats> get difficultyStats =>
      _jsonMap(keyDifficultyStats).map((key, value) =>
          MapEntry(int.parse(key), DifficultyStats.fromJson(value)));

  set difficultyStats(Map<int, DifficultyStats> value) => _setJsonMap(
      keyDifficultyStats,
      value.map((key, stats) => MapEntry(key.toString(), stats.toJson())));

  bool get didOnboard => _prefs.getBool(keyDidOnboard) ?? false;

  set didOnboard(bool value) => _setBool(keyDidOnboard, value);

  void _setInt(String key, int value) {
    _prefs.setInt(key, value);
    _notify(key);
  }

  void _setString(String key, String value) {
    _prefs.setString(key, value);
    _notify(key);
  }

  void _setBool(String key, bool value) {
    _prefs.setBool(key, value);
    _notify(key);
  }

  void _setJsonMap(String key, Map<String, Map<String, dynamic>> json) {
    _prefs.setString(key, jsonEncode(json));
    _notify(key);
  }

  Map<String, Map<String, dynamic>> _jsonMap(String key) {
    return (jsonDecode(_prefs.getString(key) ?? "{}") as Map<String, dynamic>)
        .map((key, value) => MapEntry(key, value as Map<String, dynamic>));
  }

  TargetSkin _buildTargetSkin() {
    switch (targetType) {
      case TargetType.colors:
        return PaletteSkin(targetColors);
      case TargetType.shapes:
        return ShapeSkin();
    }
  }

  /// The value of [values] stored at [key]. A missing or unknown index, such
  /// as one saved by a newer version, falls back to [fallback] rather than
  /// crashing the game.
  T _enumValue<T extends Enum>(String key, List<T> values, T fallback) {
    var index = _prefs.getInt(key);
    return index == null || index < 0 || index >= values.length
        ? fallback
        : values[index];
  }

  void _remove(String key) {
    _prefs.remove(key);
    _notify(key);
  }

  /// Writes the palette and custom colors together, notifying listeners once,
  /// so they never see one changed without the other.
  void _setTargetAppearance(TargetPalette palette, List<Color>? colors) {
    _writeCustomColors(colors);
    _prefs.setInt(keyTargetPalette, palette.index);
    _notify(keyTargetPalette);
  }

  void _writeCustomColors(List<Color>? value) {
    if (value == null) {
      _prefs.remove(keyCustomColors);
    } else {
      _prefs.setStringList(
          keyCustomColors, value.map((e) => e.toARGB32().toString()).toList());
    }
  }

  void _notify(String key) {
    if (isTargetAppearanceKey(key)) {
      _targetColors = null;
      _targetSkin = null;
    }
    _controller.add(key);
  }
}
