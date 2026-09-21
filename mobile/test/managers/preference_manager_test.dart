import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/difficulty.dart';
import 'package:mobile/managers/preference_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<void> stubValues(Map<String, Object> values) {
    SharedPreferences.setMockInitialValues(values);
    PreferenceManager.suicide();
    return PreferenceManager.get.init();
  }

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
