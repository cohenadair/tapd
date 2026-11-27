import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/difficulty.dart';
import 'package:mobile/managers/preference_manager.dart';
import 'package:mobile/target_palette.dart';
import 'package:mobile/target_skin.dart';
import 'package:mobile/target_type.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<void> stubValues(Map<String, Object> values) {
    SharedPreferences.setMockInitialValues(values);
    PreferenceManager.suicide();
    return PreferenceManager.get.init();
  }

  const custom = [
    Color(0xFF000001),
    Color(0xFF000002),
    Color(0xFF000003),
    Color(0xFF000004),
    Color(0xFF000005),
    Color(0xFF000006),
    Color(0xFF000007),
    Color(0xFF000008),
  ];
  var customValues = custom.map((e) => e.toARGB32().toString()).toList();

  test("targetPalette default value", () async {
    await stubValues({});
    expect(PreferenceManager.get.targetPalette, TargetPalette.standard);
  });

  test("targetPalette falls back to standard for an unknown index", () async {
    await stubValues({"target_palette": TargetPalette.values.length});
    expect(PreferenceManager.get.targetPalette, TargetPalette.standard);
  });

  test("targetPalette falls back to standard for a negative index", () async {
    await stubValues({"target_palette": -1});
    expect(PreferenceManager.get.targetPalette, TargetPalette.standard);
  });

  test("customColors is null when not saved", () async {
    await stubValues({});
    expect(PreferenceManager.get.customColors, isNull);
  });

  test("customColors is null when the wrong number are saved", () async {
    await stubValues({"custom_colors": customValues.sublist(1)});
    expect(PreferenceManager.get.customColors, isNull);
  });

  test("customColors is null when a saved value is invalid", () async {
    await stubValues({
      "custom_colors": [...customValues.sublist(1), "not a color"],
    });
    expect(PreferenceManager.get.customColors, isNull);
  });

  test("customColors returns saved value", () async {
    await stubValues({"custom_colors": customValues});
    expect(PreferenceManager.get.customColors, custom);
  });

  test("targetColors returns a preset palette's colors", () async {
    await stubValues({
      "target_palette": TargetPalette.colorBlindFriendly.index,
      "custom_colors": customValues,
    });
    expect(PreferenceManager.get.targetColors,
        TargetPalette.colorBlindFriendly.colors);
  });

  test("targetColors returns custom colors", () async {
    await stubValues({
      "target_palette": TargetPalette.custom.index,
      "custom_colors": customValues,
    });
    expect(PreferenceManager.get.targetColors, custom);
  });

  test("targetColors falls back to standard without custom colors", () async {
    await stubValues({"target_palette": TargetPalette.custom.index});
    expect(PreferenceManager.get.targetColors, TargetPalette.standard.colors);
  });

  test("targetColors is cached until the palette changes", () async {
    await stubValues({});
    var colors = PreferenceManager.get.targetColors;
    expect(PreferenceManager.get.targetColors, same(colors));

    PreferenceManager.get.selectTargetPalette(TargetPalette.colorBlindFriendly);
    expect(PreferenceManager.get.targetColors,
        TargetPalette.colorBlindFriendly.colors);
  });

  test("colorsFor returns a preset palette's colors", () async {
    await stubValues({"custom_colors": customValues});
    expect(PreferenceManager.get.colorsFor(TargetPalette.colorBlindFriendly),
        TargetPalette.colorBlindFriendly.colors);
  });

  test("colorsFor custom returns saved custom colors", () async {
    await stubValues({"custom_colors": customValues});
    expect(PreferenceManager.get.colorsFor(TargetPalette.custom), custom);
  });

  test("colorsFor custom returns current colors when none are saved", () async {
    await stubValues({
      "target_palette": TargetPalette.colorBlindFriendly.index,
    });
    expect(PreferenceManager.get.colorsFor(TargetPalette.custom),
        TargetPalette.colorBlindFriendly.colors);
  });

  test("targetColors cache is kept when other preferences change", () async {
    await stubValues({});
    var colors = PreferenceManager.get.targetColors;
    PreferenceManager.get.isMusicOn = false;
    expect(PreferenceManager.get.targetColors, same(colors));
  });

  test("Target appearance changes notify listeners once", () async {
    await stubValues({});
    var keys = <String>[];
    var sub = PreferenceManager.get.stream.listen(keys.add);

    PreferenceManager.get.setCustomColor(0, const Color(0xFF123456));
    PreferenceManager.get.selectTargetPalette(TargetPalette.colorBlindFriendly);
    PreferenceManager.get.useDefaultCustomColors();
    PreferenceManager.get.resetTargetAppearance();
    await Future.delayed(Duration.zero);

    expect(keys, List.filled(4, PreferenceManager.keyTargetPalette));
    await sub.cancel();
  });

  test("selectTargetPalette starts custom colors from the current ones",
      () async {
    await stubValues({
      "target_palette": TargetPalette.colorBlindFriendly.index,
    });
    PreferenceManager.get.selectTargetPalette(TargetPalette.custom);
    expect(PreferenceManager.get.targetPalette, TargetPalette.custom);
    expect(PreferenceManager.get.customColors,
        TargetPalette.colorBlindFriendly.colors);
  });

  test("selectTargetPalette keeps existing custom colors", () async {
    await stubValues({"custom_colors": customValues});
    PreferenceManager.get.selectTargetPalette(TargetPalette.custom);
    expect(PreferenceManager.get.customColors, custom);
  });

  test("selectTargetPalette does nothing when already selected", () async {
    await stubValues({});
    var keys = <String>[];
    var sub = PreferenceManager.get.stream.listen(keys.add);

    PreferenceManager.get.selectTargetPalette(TargetPalette.standard);
    await Future.delayed(Duration.zero);

    expect(keys, isEmpty);
    await sub.cancel();
  });

  test("selectTargetPalette keeps custom colors when choosing a preset",
      () async {
    await stubValues({
      "target_palette": TargetPalette.custom.index,
      "custom_colors": customValues,
    });
    PreferenceManager.get.selectTargetPalette(TargetPalette.standard);
    expect(PreferenceManager.get.targetPalette, TargetPalette.standard);
    expect(PreferenceManager.get.customColors, custom);
  });

  test("selectTargetPalette selects a preset palette", () async {
    await stubValues({});
    PreferenceManager.get.selectTargetPalette(TargetPalette.colorBlindFriendly);
    expect(
        PreferenceManager.get.targetPalette, TargetPalette.colorBlindFriendly);
    expect(PreferenceManager.get.customColors, isNull);
  });

  test("setCustomColor changes one color and selects custom", () async {
    await stubValues({});
    PreferenceManager.get.setCustomColor(2, const Color(0xFF123456));
    expect(PreferenceManager.get.targetPalette, TargetPalette.custom);
    expect(
      PreferenceManager.get.targetColors,
      List.of(TargetPalette.standard.colors!)..[2] = const Color(0xFF123456),
    );
  });

  test("setCustomColor does nothing when the color is unchanged", () async {
    await stubValues({});
    var keys = <String>[];
    var sub = PreferenceManager.get.stream.listen(keys.add);

    PreferenceManager.get.setCustomColor(2, TargetPalette.standard.colors![2]);
    await Future.delayed(Duration.zero);

    expect(PreferenceManager.get.targetPalette, TargetPalette.standard);
    expect(keys, isEmpty);
    await sub.cancel();
  });

  test("resetTargetAppearance resets type, palette and custom colors",
      () async {
    await stubValues({
      "target_type": TargetType.shapes.index,
      "target_palette": TargetPalette.custom.index,
      "custom_colors": customValues,
    });
    PreferenceManager.get.resetTargetAppearance();
    expect(PreferenceManager.get.targetType, TargetType.colors);
    expect(PreferenceManager.get.targetPalette, TargetPalette.standard);
    expect(PreferenceManager.get.customColors, isNull);
    expect(PreferenceManager.get.targetSkin, isA<PaletteSkin>());
  });

  test("useDefaultCustomColors keeps custom with the standard colors",
      () async {
    await stubValues({
      "target_palette": TargetPalette.custom.index,
      "custom_colors": customValues,
    });
    PreferenceManager.get.useDefaultCustomColors();
    expect(PreferenceManager.get.targetPalette, TargetPalette.custom);
    expect(PreferenceManager.get.customColors, TargetPalette.standard.colors);
    expect(PreferenceManager.get.targetColors, TargetPalette.standard.colors);
  });

  test("useDefaultCustomColors does nothing if they're already standard",
      () async {
    await stubValues({
      "target_palette": TargetPalette.custom.index,
      "custom_colors": TargetPalette.standard.colors!
          .map((e) => e.toARGB32().toString())
          .toList(),
    });
    var keys = <String>[];
    var sub = PreferenceManager.get.stream.listen(keys.add);

    PreferenceManager.get.useDefaultCustomColors();
    await Future.delayed(Duration.zero);

    expect(keys, isEmpty);
    await sub.cancel();
  });

  test("useDefaultCustomColors selects custom from another palette", () async {
    await stubValues({
      "target_palette": TargetPalette.standard.index,
      "custom_colors": TargetPalette.standard.colors!
          .map((e) => e.toARGB32().toString())
          .toList(),
    });
    PreferenceManager.get.useDefaultCustomColors();
    expect(PreferenceManager.get.targetPalette, TargetPalette.custom);
  });

  test("targetType default value", () async {
    await stubValues({});
    expect(PreferenceManager.get.targetType, TargetType.colors);
  });

  test("targetType falls back to colors for an unknown index", () async {
    await stubValues({"target_type": 99});
    expect(PreferenceManager.get.targetType, TargetType.colors);
  });

  test("targetType is set", () async {
    await stubValues({});
    PreferenceManager.get.targetType = TargetType.shapes;
    expect(PreferenceManager.get.targetType, TargetType.shapes);
  });

  test("targetType does nothing when unchanged", () async {
    await stubValues({});
    var keys = <String>[];
    var sub = PreferenceManager.get.stream.listen(keys.add);

    PreferenceManager.get.targetType = TargetType.colors;
    await Future.delayed(Duration.zero);

    expect(keys, isEmpty);
    await sub.cancel();
  });

  test("targetSkin uses the palette colors for colored targets", () async {
    await stubValues({
      "target_palette": TargetPalette.colorBlindFriendly.index,
      "target_type": TargetType.colors.index,
    });
    var skin = PreferenceManager.get.targetSkin as PaletteSkin;
    expect(skin.colors, TargetPalette.colorBlindFriendly.colors);
  });

  test("targetSkin draws shapes for shape targets", () async {
    await stubValues({"target_type": TargetType.shapes.index});
    expect(PreferenceManager.get.targetSkin, isA<ShapeSkin>());
  });

  test("targetSkin is cached until how targets look changes", () async {
    await stubValues({});
    var skin = PreferenceManager.get.targetSkin;
    expect(PreferenceManager.get.targetSkin, same(skin));

    PreferenceManager.get.isMusicOn = false;
    expect(PreferenceManager.get.targetSkin, same(skin));

    PreferenceManager.get.targetType = TargetType.shapes;
    expect(PreferenceManager.get.targetSkin, isNot(same(skin)));
  });

  test("isTargetAppearanceKey is true for appearance keys", () {
    expect(
        PreferenceManager.isTargetAppearanceKey(
            PreferenceManager.keyTargetPalette),
        isTrue);
    expect(
        PreferenceManager.isTargetAppearanceKey(
            PreferenceManager.keyCustomColors),
        isTrue);
    expect(
        PreferenceManager.isTargetAppearanceKey(
            PreferenceManager.keyTargetType),
        isTrue);
  });

  test("isTargetAppearanceKey is false for other keys", () {
    expect(
        PreferenceManager.isTargetAppearanceKey(PreferenceManager.keyMusicOn),
        isFalse);
  });

  test("difficulty returns saved value", () async {
    await stubValues({"difficulty": Difficulty.hard.index});
    expect(PreferenceManager.get.difficulty, Difficulty.hard);
  });

  test("difficulty default value", () async {
    await stubValues({});
    expect(PreferenceManager.get.difficulty, Difficulty.normal);
  });

  test("difficulty is set", () async {
    await stubValues({});
    PreferenceManager.get.difficulty = Difficulty.expert;
    expect(PreferenceManager.get.difficulty, Difficulty.expert);
  });

  test("colorIndex returns saved value", () async {
    await stubValues({"color_index": 1});
    expect(PreferenceManager.get.colorIndex, 1);
  });

  test("colorIndex is set", () async {
    await stubValues({});

    PreferenceManager.get.colorIndex = 1;
    expect(PreferenceManager.get.colorIndex, 1);

    PreferenceManager.get.colorIndex = null;
    expect(PreferenceManager.get.colorIndex, null);
  });

  test("difficultyStats returns empty map", () async {
    await stubValues({});
    var stats = PreferenceManager.get.difficultyStats;
    expect(stats, isEmpty);
  });

  test("difficultyStats is written and read correctly", () async {
    await stubValues({});

    // Write.
    PreferenceManager.get.difficultyStats = {
      1: const DifficultyStats(
        difficultyIndex: 1,
        highScore: 5,
        gamesPlayed: 6,
      ),
    };

    // Read back.
    var stats = PreferenceManager.get.difficultyStats;
    expect(stats.length, 1);
    expect(stats[1]!.difficultyIndex, 1);
    expect(stats[1]!.highScore, 5);
    expect(stats[1]!.gamesPlayed, 6);
  });

  test("init removes legacy lives value", () async {
    await stubValues({"lives": 3});

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey("lives"), isFalse);
  });
}
