import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/difficulty.dart';

import 'test_utils/test_utils.dart';

void main() {
  testWidgets("targetsPerRow for smaller devices", (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(599, 1000);
    expect(Difficulty.easy.targetsPerRow, 4);
  });

  testWidgets("targetsPerRow for smaller, high density devices",
      (tester) async {
    tester.view.devicePixelRatio = 3.0;
    tester.view.physicalSize = const Size(1797, 1000);
    expect(Difficulty.easy.targetsPerRow, 4);
  });

  testWidgets("targetsPerRow for larger devices", (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(600, 1000);
    expect(Difficulty.easy.targetsPerRow, 5);
  });

  testWidgets("targetsPerRow for larger, high density devices", (tester) async {
    tester.view.devicePixelRatio = 3.0;
    tester.view.physicalSize = const Size(1800, 1000);
    expect(Difficulty.easy.targetsPerRow, 5);
  });

  testWidgets("displayName returns correct values", (tester) async {
    var context = await pumpContext(tester, (_) => Container());
    expect(Difficulty.veryEasy.displayName(context), "Very Easy");
    expect(Difficulty.easy.displayName(context), "Easy");
    expect(Difficulty.normal.displayName(context), "Normal");
    expect(Difficulty.hard.displayName(context), "Hard");
    expect(Difficulty.expert.displayName(context), "Expert");
  });

  test("DifficultyStats fromJson()", () {
    var stats = DifficultyStats.fromJson(const {
      "difficultyIndex": 1,
      "highScore": 5,
      "gamesPlayed": 10,
    });
    expect(stats.difficultyIndex, 1);
    expect(stats.highScore, 5);
    expect(stats.gamesPlayed, 10);
  });

  test("DifficultyStats toJson()", () {
    var stats = const DifficultyStats(
      difficultyIndex: 1,
      highScore: 10,
      gamesPlayed: 5,
    );
    expect(stats.toJson(), const {
      "difficultyIndex": 1,
      "highScore": 10,
      "gamesPlayed": 5,
    });
  });

  test("DifficultyStats withIncedGamesPlayed()", () {
    var stats = const DifficultyStats(
      difficultyIndex: 1,
      highScore: 10,
      gamesPlayed: 5,
    );
    expect(stats.withIncedGamesPlayed().gamesPlayed, 6);
  });

  test("DifficultyStats withHighScore()", () {
    var stats = const DifficultyStats(
      difficultyIndex: 1,
      highScore: 10,
      gamesPlayed: 5,
    );
    expect(stats.withHighScore(15).highScore, 15);
  });
}
