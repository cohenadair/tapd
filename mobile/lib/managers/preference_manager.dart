import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile/difficulty.dart';
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

  /// The key previously used to store the number of lives a player had. It is
  /// only referenced to clear stale values left over from before lives were
  /// removed, and can be deleted once enough releases have shipped.
  static const _legacyKeyLives = "lives";

  late final SharedPreferences _prefs;

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

  void _remove(String key) {
    _prefs.remove(key);
    _notify(key);
  }

  void _notify(String key) => _controller.add(key);
}
