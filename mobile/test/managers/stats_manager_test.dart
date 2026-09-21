import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/difficulty.dart';
import 'package:mobile/managers/stats_manager.dart';
import 'package:mockito/mockito.dart';

import '../test_utils/stubbed_managers.dart';

void main() {
  late StubbedManagers managers;

  setUp(() async {
    managers = StubbedManagers();

    when(managers.preferenceManager.difficultyStats).thenReturn({});
    when(managers.preferenceManager.difficultyStats = any).thenAnswer((_) {});
    when(managers.preferenceManager.difficulty).thenReturn(Difficulty.normal);

    StatsManager.suicide();
    await StatsManager.get.init();
  });

  test("Stats default to empty values", () {
    when(managers.preferenceManager.difficultyStats).thenReturn({});

    var stats = StatsManager.get.currentDifficultyStats;
    expect(stats.difficultyIndex, Difficulty.normal.index);
    expect(stats.highScore, 0);
    expect(stats.gamesPlayed, 0);
  });

  test("gamesPlayed", () async {
    when(managers.preferenceManager.difficultyStats).thenReturn({
      Difficulty.veryEasy.index: DifficultyStats(
        difficultyIndex: Difficulty.veryEasy.index,
        highScore: 5,
        gamesPlayed: 3,
      ),
      Difficulty.easy.index: DifficultyStats(
        difficultyIndex: Difficulty.easy.index,
        highScore: 10,
        gamesPlayed: 15,
      ),
      Difficulty.normal.index: DifficultyStats(
        difficultyIndex: Difficulty.normal.index,
        highScore: 50,
        gamesPlayed: 300,
      ),
    });

    StatsManager.suicide();
    await StatsManager.get.init();
    expect(StatsManager.get.gamesPlayed, 318);
  });

  test("incCurrentGamesPlayed", () {
    expect(StatsManager.get.currentGamesPlayed, 0);
    StatsManager.get.incCurrentGamesPlayed();
    expect(StatsManager.get.currentGamesPlayed, 1);
  });

  test("updateCurrentHighScore", () {
    expect(StatsManager.get.currentHighScore, 0);

    // New high score.
    StatsManager.get.updateCurrentHighScore(50);
    expect(StatsManager.get.currentHighScore, 50);
    verify(managers.preferenceManager.difficultyStats = any).called(1);

    // Not high enough.
    StatsManager.get.updateCurrentHighScore(40);
    expect(StatsManager.get.currentHighScore, 50);
    verifyNever(managers.preferenceManager.difficultyStats = any);
  });

  test("reset", () {
    // Set some value.
    StatsManager.get.updateCurrentHighScore(50);
    expect(StatsManager.get.currentHighScore, 50);
    verify(managers.preferenceManager.difficultyStats = any).called(1);

    // Clear and verify.
    StatsManager.get.reset();
    expect(StatsManager.get.currentHighScore, 0);
    verify(managers.preferenceManager.difficultyStats = any).called(1);
  });
}
