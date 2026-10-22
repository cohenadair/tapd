import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'difficulty.dart';
import 'managers/preference_manager.dart';
import 'target_color.dart';

/// Hard-coded game states used to capture App Store and Google Play
/// screenshots without having to play the game first. A scene is chosen at
/// build time with `--dart-define=SCREENSHOT_SCENE=<name>`, where `<name>` is
/// one of the enum value names below. See the "tapd screenshot" launch
/// configurations in `workspace.code-workspace`.
///
/// When a scene is active, preferences are kept in memory only, so the
/// device's real stats and settings are never read or overwritten. Ads are
/// also hidden, as if "Remove Ads" was purchased.
enum ScreenshotScene {
  /// 01: Normal difficulty, mid-run.
  game(
    difficulty: Difficulty.normal,
    targetColorIndex: 3, // Green.
    autoPlay: true,
    score: 34,
  ),

  /// 02: The first-run instructions overlay, on the step explaining that the
  /// current target changes. The run plays normally until the instructions
  /// are shown.
  instructions(
    difficulty: Difficulty.normal,
    didOnboard: false,
    targetColorIndex: 2, // Yellow.
    autoPlay: true,
  ),

  /// 03: Expert difficulty, mid-run.
  expert(
    difficulty: Difficulty.expert,
    targetColorIndex: 6, // Magenta.
    autoPlay: true,
    score: 47,
  ),

  /// 04: Very Easy difficulty, mid-run, with a single color chosen.
  veryEasy(
    difficulty: Difficulty.veryEasy,
    targetColorIndex: 4, // Blue.
    autoPlay: true,
    score: 25,
  ),

  /// 05: The New High Score page, shown on launch.
  highScore(
    difficulty: Difficulty.normal,
    showNewHighScore: true,
  ),

  /// 06: The main menu with stats filled in.
  stats(
    difficulty: Difficulty.normal,
  ),

  /// Store preview video: a Normal run, played by a bot, that changes
  /// target color twice, then ends on the New High Score page once
  /// [botEndScore] beats [seededHighScore].
  video(
    difficulty: Difficulty.normal,
    autoPlay: true,
    isBotPlayed: true,
    botEndScore: 22,
    seededHighScore: 21,
  );

  /// Must stay `const`, otherwise the dart-define is silently ignored.
  static const _name = String.fromEnvironment("SCREENSHOT_SCENE");

  /// The active scene, or null if the app is running normally.
  static final current = ScreenshotScene.values.asNameMap()[_name];

  /// Seeds the random target colors, so a scene's board is the same on every
  /// launch of the same device.
  static const randomSeed = 116;

  /// Targets of the current color below this fraction of the screen's height
  /// are shown as already tapped, so frozen runs look like they're in
  /// progress.
  static const hitBelowFactor = 0.55;

  /// Stats shown on the menu and the New High Score page, for every scene.
  /// The total games played intentionally isn't a multiple of 15, which would
  /// show the in-app review dialog on the menu.
  static const _stats = [
    DifficultyStats(
      difficultyIndex: 0, // Very Easy.
      highScore: 64,
      gamesPlayed: 9,
    ),
    DifficultyStats(
      difficultyIndex: 1, // Easy.
      highScore: 48,
      gamesPlayed: 14,
    ),
    DifficultyStats(
      difficultyIndex: 2, // Normal.
      highScore: 63,
      gamesPlayed: 37,
    ),
    DifficultyStats(
      difficultyIndex: 3, // Hard.
      highScore: 41,
      gamesPlayed: 22,
    ),
    DifficultyStats(
      difficultyIndex: 4, // Expert.
      highScore: 52,
      gamesPlayed: 18,
    ),
  ];

  final Difficulty difficulty;

  final bool didOnboard;

  /// The [TargetColor] index of the current target in an auto-played run.
  /// When [Difficulty.canChooseColor] is true, this is also the color chosen
  /// in Settings.
  final int? targetColorIndex;

  /// True if a run is started on launch, instead of showing the menu.
  final bool autoPlay;

  /// If set, an auto-played run is frozen on a full board, with this score.
  /// Otherwise, the run plays normally.
  final int? score;

  /// True if the New High Score page is shown on launch.
  final bool showNewHighScore;

  /// True if an auto-played run is played by a bot that taps matching
  /// targets, for recording store preview videos. Continues aren't offered.
  final bool isBotPlayed;

  /// If set, the bot taps an incorrect target, ending the run, once the score
  /// reaches this value. Otherwise, the bot plays indefinitely.
  final int? botEndScore;

  /// If set, replaces the seeded high score of [difficulty].
  final int? seededHighScore;

  const ScreenshotScene({
    required this.difficulty,
    this.didOnboard = true,
    this.targetColorIndex,
    this.autoPlay = false,
    this.score,
    this.showNewHighScore = false,
    this.isBotPlayed = false,
    this.botEndScore,
    this.seededHighScore,
  });

  /// Replaces the device's preferences with this scene's in-memory values.
  /// Must be called before [PreferenceManager.init].
  void mockPreferences() {
    final colorIndex = difficulty.canChooseColor ? targetColorIndex : null;
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({
      PreferenceManager.keyDifficulty: difficulty.index,
      PreferenceManager.keyDidOnboard: didOnboard,
      PreferenceManager.keyFpsOn: false,
      PreferenceManager.keyDifficultyStats: jsonEncode({
        for (var stats in _stats)
          stats.difficultyIndex.toString(): _withHighScore(stats).toJson(),
      }),
      if (colorIndex != null) PreferenceManager.keyColorIndex: colorIndex,
    });
  }

  DifficultyStats _withHighScore(DifficultyStats stats) {
    final highScore = seededHighScore;
    return highScore == null || stats.difficultyIndex != difficulty.index
        ? stats
        : stats.withHighScore(highScore);
  }
}
