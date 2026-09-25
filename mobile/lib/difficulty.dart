import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:mobile/l10n/gen/strings.dart';

import 'target_color.dart';

/// The various difficulties of the game.
///
/// Note that the difficulty indexes are stored in preferences and should *not*
/// be changed.
enum Difficulty {
  veryEasy(
    minTargetsPerRow: 3,
    canChooseColor: true,
    canMissTargets: true,
    startSpeed: 3.0,
    incSpeedBy: 0,
    colorChangeGracePeriodMs: -1,
    colorChangeFrequencyRange: (1000000, 1000000),
    // Never change.
    colors: TargetColor.veryEasy,
  ),
  easy(
    minTargetsPerRow: 4,
    canChooseColor: false,
    canMissTargets: false,
    startSpeed: 3.5,
    incSpeedBy: 0,
    colorChangeGracePeriodMs: 2500,
    colorChangeFrequencyRange: (10, 10),
    colors: TargetColor.all,
  ),
  normal(
    minTargetsPerRow: 4,
    canChooseColor: false,
    canMissTargets: false,
    startSpeed: 4.0,
    incSpeedBy: 0.00005,
    colorChangeGracePeriodMs: 2000,
    colorChangeFrequencyRange: (10, 10),
    colors: TargetColor.all,
  ),
  hard(
    minTargetsPerRow: 5,
    canChooseColor: false,
    canMissTargets: false,
    startSpeed: 4.25,
    incSpeedBy: 0.0001,
    colorChangeGracePeriodMs: 1500,
    colorChangeFrequencyRange: (10, 10),
    colors: TargetColor.all,
  ),
  expert(
    minTargetsPerRow: 5,
    canChooseColor: false,
    canMissTargets: false,
    startSpeed: 6.0,
    incSpeedBy: 0.00015,
    colorChangeGracePeriodMs: 1250,
    colorChangeFrequencyRange: (7, 15),
    // Arbitrary numbers.
    colors: TargetColor.all,
  );

  /// If the screen's width is >= this value, the number of targets per row is
  /// increased by [_incTargetsPerRowBy].
  final int _incTargetsPerRowThreshold = 600;
  final int _incTargetsPerRowBy = 1;

  /// The minimum targets per row. This value may be added to depending on the
  /// type of device (tablet/iPad/phone) being used.
  final int minTargetsPerRow;

  /// True if the user can choose a constant color for the targets. When true,
  /// targets never change color.
  final bool canChooseColor;

  /// True if matching targets can scroll off the screen without ending the
  /// run. When true, only tapping an incorrect target ends the run.
  final bool canMissTargets;

  /// The speed at which the game starts.
  final double startSpeed;

  /// The factor at which the speed is increased after each successful target
  /// tap.
  final double incSpeedBy;

  /// How long, in milliseconds, to allow for the current target to scroll off
  /// the screen after a color switch.
  final int colorChangeGracePeriodMs;

  /// The range in which the target's color will change. Defaults to every 10
  /// successful taps.
  final (int, int) colorChangeFrequencyRange;

  /// The list of colors supported by the difficulty.
  final List<TargetColor> Function() colors;

  const Difficulty({
    required this.minTargetsPerRow,
    required this.canChooseColor,
    required this.canMissTargets,
    required this.startSpeed,
    required this.incSpeedBy,
    required this.colorChangeGracePeriodMs,
    required this.colorChangeFrequencyRange,
    required this.colors,
  });

  /// Returns the number of targets per row for this difficulty. For larger
  /// screens, a larger value is returned.
  int get targetsPerRow {
    FlutterView view = WidgetsBinding.instance.platformDispatcher.views.first;
    Size size = view.physicalSize / view.devicePixelRatio; // Size in dp.
    return size.width >= _incTargetsPerRowThreshold
        ? minTargetsPerRow + _incTargetsPerRowBy
        : minTargetsPerRow;
  }

  String displayName(BuildContext context) {
    switch (this) {
      case Difficulty.veryEasy:
        return Strings.of(context).difficultyVeryEasy;
      case Difficulty.easy:
        return Strings.of(context).difficultyEasy;
      case Difficulty.normal:
        return Strings.of(context).difficultyNormal;
      case Difficulty.hard:
        return Strings.of(context).difficultyHard;
      case Difficulty.expert:
        return Strings.of(context).difficultyExpert;
    }
  }
}

@immutable
class DifficultyStats {
  static const _keyDifficultyIndex = "difficultyIndex";
  static const _keyHighScore = "highScore";
  static const _keyGamesPlayed = "gamesPlayed";

  final int difficultyIndex;
  final int highScore;
  final int gamesPlayed;

  const DifficultyStats({
    required this.difficultyIndex,
    this.highScore = 0,
    this.gamesPlayed = 0,
  });

  DifficultyStats.fromJson(Map<String, dynamic> json)
      : difficultyIndex = json[_keyDifficultyIndex] as int,
        highScore = json[_keyHighScore] as int,
        gamesPlayed = json[_keyGamesPlayed] as int;

  Map<String, dynamic> toJson() {
    return {
      _keyDifficultyIndex: difficultyIndex,
      _keyHighScore: highScore,
      _keyGamesPlayed: gamesPlayed,
    };
  }

  DifficultyStats withIncedGamesPlayed() {
    return DifficultyStats(
      difficultyIndex: difficultyIndex,
      highScore: highScore,
      gamesPlayed: gamesPlayed + 1,
    );
  }

  DifficultyStats withHighScore(int newHighScore) {
    return DifficultyStats(
      difficultyIndex: difficultyIndex,
      highScore: newHighScore,
      gamesPlayed: gamesPlayed,
    );
  }
}
