import 'dart:math';

import 'package:adair_flutter_lib/res/dimen.dart';
import 'package:flame/components.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';
import 'package:mobile/difficulty.dart';
import 'package:mobile/managers/orientation_manager.dart';
import 'package:mobile/managers/preference_manager.dart';
import 'package:mobile/managers/stats_manager.dart';
import 'package:mobile/screenshot_scene.dart';
import 'package:mobile/utils/keys.dart';
import 'package:adair_flutter_lib/wrappers/analytics_wrapper.dart';

import 'components/miss_tolerance_line.dart';
import 'components/target.dart';
import 'components/target_board.dart';
import 'effects/target_board_rewind_effect.dart';
import 'managers/audio_manager.dart';
import 'target_color.dart';
import 'utils/overlay_utils.dart';

class TapdWorld extends World with HasGameRef, Notifier {
  static const _fpsPriority = 1;
  static const _fpsVerticalOffset = 150.0;
  static const _fpsFontSize = 20.0;

  /// The length of the "get ready" countdown shown after a run is continued.
  static const _continueCountdownSeconds = 5;

  /// How often, in seconds, the continue countdown decrements.
  static const _continueTickSeconds = 1.0;

  /// Scales [Difficulty.missToleranceFactor] for the line placed when a run is
  /// continued. The countdown gives the player time to prepare, so the line is
  /// placed closer to the bottom of the screen.
  static const _continueMissToleranceScale = 0.5;

  /// Matching targets above this fraction of the screen's height aren't
  /// tapped yet by the [ScreenshotScene] bot.
  static const _botTapFactor = 0.3;

  /// The [ScreenshotScene] bot ends its run by tapping an incorrect target
  /// below this fraction of the screen's height, so it's easy to see.
  static const _botWrongTapFactor = 0.4;

  /// The shortest pause, in seconds, between [ScreenshotScene] bot taps.
  static const _botMinTapSeconds = 0.08;

  /// The most random time, in seconds, added to [_botMinTapSeconds].
  static const _botTapJitter = 0.1;

  /// The shortest pause, in seconds, before the [ScreenshotScene] bot taps
  /// the new color after the target changes.
  static const _botColorChangeSeconds = 1.2;

  /// The most random time, in seconds, added to [_botColorChangeSeconds].
  static const _botColorChangeJitter = 0.5;

  static final _botRandom = Random(ScreenshotScene.randomSeed);

  final _board1Key = ComponentKey.unique();
  final _board2Key = ComponentKey.unique();

  final _fpsComponent = FpsTextComponent(
    priority: _fpsPriority,
    position: Vector2(paddingDefault, _fpsVerticalOffset),
    textRenderer: TextPaint(
      style: const TextStyle(
        color: Colors.green,
        fontSize: _fpsFontSize,
      ),
    ),
  );

  late double _speed;
  late int _colorResetMod;
  late TargetColor _color;

  var _score = 0;
  var _scrollingPaused = true;
  var shouldShowNewHighScore =
      ScreenshotScene.current?.showNewHighScore ?? false;

  /// True until the active [ScreenshotScene], if any, has been staged.
  var _isScreenshotPending = ScreenshotScene.current != null;

  /// Seconds until the [ScreenshotScene] bot can tap again.
  var _botCooldown = 0.0;

  /// True once the [ScreenshotScene] bot has ended its run.
  var _isBotDone = false;

  /// If set, marks where the current color "starts". Targets below it when it
  /// was placed are allowed to be missed. This prevents an immediate loss
  /// after a color change (or continue) due to the current color already
  /// being near the bottom of the screen.
  MissToleranceLine? _missToleranceLine;

  /// True once the current run has been continued. Each run can only be
  /// continued once. Reset when a new game starts.
  var _hasUsedContinue = false;

  /// Ticks the continue countdown. This is driven by [update] rather than the
  /// wall clock, so it doesn't run while the game is paused, such as when the
  /// app is in the background.
  Timer? _continueTimer;

  /// The seconds remaining in the "get ready" countdown shown after a run is
  /// continued.
  final continueSecondsLeft = ValueNotifier<int>(_continueCountdownSeconds);

  double? instructionsY;

  double get speed => _speed;

  TargetColor get color => _color;

  int get score => _score;

  Difficulty get _difficulty => PreferenceManager.get.difficulty;

  /// A run can be continued once. The Very Easy difficulty doesn't offer a
  /// continue at all. Players who have purchased "Remove Ads" are still offered
  /// a continue; it just doesn't involve an ad.
  bool get _canOfferContinue =>
      _difficulty != Difficulty.veryEasy &&
      !_hasUsedContinue &&
      !(ScreenshotScene.current?.isBotPlayed ?? false);

  bool get scrollingPaused => _scrollingPaused;

  set scrollingPaused(bool paused) {
    _scrollingPaused = paused;
    if (_scrollingPaused) {
      AudioManager.get.pauseMusic();
    } else {
      AudioManager.get.resumeMusic();
    }

    // Lets listeners, such as the scoreboard's pause button, stay in sync.
    notifyListeners();
  }

  @override
  void onLoad() {
    scrollingPaused = true;
    _resetForNewGame();

    game.overlays.add(overlayIdScoreboard);
    game.overlays.add(overlayIdMainMenu);
    AudioManager.get.playMenuBackground();

    add(TargetBoard(
      verticalStartFactor: 2,
      otherBoardKey: _board2Key,
      key: _board1Key,
      isUpdater: true,
    ));
    add(TargetBoard(
      verticalStartFactor: 1,
      otherBoardKey: _board1Key,
      key: _board2Key,
      isUpdater: false,
    ));

    // FPS counter.
    if (PreferenceManager.get.isFpsOn) {
      add(_fpsComponent);
    }

    PreferenceManager.get.stream.listen((_) {
      if (PreferenceManager.get.isFpsOn && !_fpsComponent.isMounted) {
        add(_fpsComponent);
      } else if (!PreferenceManager.get.isFpsOn && _fpsComponent.isMounted) {
        remove(_fpsComponent);
      }
    });
  }

  @override
  void update(double dt) {
    _stageScreenshotIfNeeded();
    _updateBot(dt);
    _showInstructionsIfNeeded();
    _continueTimer?.update(dt);
  }

  void handleTargetHit({required bool isCorrect}) {
    if (isCorrect) {
      // The amount of speed added after each touch is dependent on the screen
      // size to narrow the difficulty gap between different devices.
      _speed += game.size.y * _difficulty.incSpeedBy;
      _score++;

      if (PreferenceManager.get.colorIndex == null &&
          _score % _colorResetMod == 0) {
        // Ensure color always changes.
        _color = TargetColor.random(exclude: _color);
        _placeMissToleranceLine(_difficulty.missToleranceFactor);
        _updateColorResetMod();
        AudioManager.get.playSwitchTarget();
      } else {
        AudioManager.get.playCorrectHit();
      }
    } else if (_canOfferContinue) {
      // The run isn't over until the player declines the continue, or fails to
      // watch its ad. Scrolling must stay paused while the offer is shown, in
      // case the player resumed it while the incorrect target was pulsing.
      scrollingPaused = true;
      AnalyticsWrapper.get.logEvent(name: "continue_offered");
      game.overlays.add(overlayIdContinueOffer);
    } else {
      scrollingPaused = true;
      _endRun();
    }

    notifyListeners();
  }

  void handleTargetMissed(Target target, TargetBoard board) {
    scrollingPaused = true;

    board.add(TargetBoardRewindEffect(
      game: game,
      onComplete: () => target.pulse(),
    ));
    _targetBoard(board.otherBoardKey).add(TargetBoardRewindEffect(game: game));
  }

  void play() {
    AudioManager.get.playGameBackground();
    AnalyticsWrapper.get.logEvent(name: "game_played");
    OrientationManager.get.lockCurrent();

    _targetBoard(_board1Key).resetForNewGame();
    _targetBoard(_board2Key).resetForNewGame();

    scrollingPaused = false;
    _resetForNewGame(exclude: _color);
    notifyListeners();

    game.overlays.removeAll([overlayIdMainMenu, overlayIdGameOver]);
  }

  /// Ends the run after the player declined the continue offered by
  /// [handleTargetHit], or was unable to watch the ad it requires.
  void declineContinue() {
    if (!game.overlays.isActive(overlayIdContinueOffer)) {
      return;
    }

    game.overlays.remove(overlayIdContinueOffer);
    _endRun();
  }

  /// Resumes the current run, from exactly where it ended, after the player
  /// watched an ad (or immediately, if they purchased "Remove Ads"). Unlike
  /// [play], the score, speed, color, and board are left untouched. A
  /// [MissToleranceLine] is placed immediately, and gameplay resumes after a
  /// countdown.
  void continueRun() {
    if (!game.overlays.isActive(overlayIdContinueOffer)) {
      return;
    }

    AnalyticsWrapper.get.logEvent(name: "continue_used");
    _hasUsedContinue = true;

    for (var target in game.descendants().whereType<Target>()) {
      target.resetIfEndedRun();
    }

    continueSecondsLeft.value = _continueCountdownSeconds;

    game.overlays.remove(overlayIdContinueOffer);
    game.overlays.add(overlayIdContinueCountdown);
    _placeMissToleranceLine(
        _difficulty.missToleranceFactor * _continueMissToleranceScale);

    _continueTimer = Timer(
      _continueTickSeconds,
      repeat: true,
      onTick: _onContinueTick,
    );
  }

  void hideInstructions() {
    game.overlays.remove(overlayIdInstructions);
    PreferenceManager.get.didOnboard = true;
  }

  void _showInstructionsIfNeeded() {
    if (PreferenceManager.get.didOnboard ||
        scrollingPaused ||
        instructionsY == null) {
      return;
    }

    var target = game.findByKey(keyInstructionsTarget);
    if (target == null) {
      return;
    }

    if ((target as Target).absoluteTopLeftPosition.y >= instructionsY!) {
      scrollingPaused = true;
      game.overlays.add(overlayIdInstructions);
    }
  }

  /// Starts, and optionally freezes, a run as described by the active
  /// [ScreenshotScene]. Waits until both boards and all their targets have
  /// loaded; otherwise, a target's initial sprite can finish loading after
  /// [play] resets its color, leaving it drawn in the wrong color.
  void _stageScreenshotIfNeeded() {
    var scene = ScreenshotScene.current;
    if (scene == null ||
        !_isScreenshotPending ||
        game.findByKey(_board1Key) == null ||
        game.findByKey(_board2Key) == null) {
      return;
    }

    var targets = game.descendants().whereType<Target>();
    if (targets.isEmpty || targets.any((target) => !target.isLoaded)) {
      return;
    }
    _isScreenshotPending = false;

    if (!scene.autoPlay) {
      return;
    }
    play();

    var targetColorIndex = scene.targetColorIndex;
    if (targetColorIndex != null) {
      _color = TargetColor.from(index: targetColorIndex);
      notifyListeners();
    }

    var score = scene.score;
    if (score == null) {
      return;
    }

    // Freeze the run, with the screen filled by targets. The upper board sits
    // directly above the lower board, whose bottom edge is at the bottom of
    // the screen, so no targets have scrolled off.
    _score = score;
    _speed = 0;

    var hitBelowY = game.size.y * ScreenshotScene.hitBelowFactor;
    var random = Random(ScreenshotScene.randomSeed);
    var lowerBoard = _targetBoard(_board2Key);
    lowerBoard.stageForScreenshot(
      bottomY: game.size.y,
      color: _color,
      hitBelowY: hitBelowY,
      random: random,
    );
    _targetBoard(_board1Key).stageForScreenshot(
      bottomY: lowerBoard.position.y,
      color: _color,
      hitBelowY: hitBelowY,
      random: random,
    );

    notifyListeners();
  }

  /// Plays the run of a bot-played [ScreenshotScene], like a fast player:
  /// matching targets are tapped once they're partway down the screen, with
  /// a short, random pause between taps, and a longer one after the target
  /// changes color. Targets that can be missed are ignored.
  void _updateBot(double dt) {
    var scene = ScreenshotScene.current;
    if (scene == null ||
        !scene.isBotPlayed ||
        _isBotDone ||
        _isScreenshotPending ||
        scrollingPaused) {
      return;
    }

    _botCooldown -= dt;
    if (_botCooldown > 0) {
      return;
    }

    var visible = game
        .descendants()
        .whereType<Target>()
        .where((target) =>
            !target.wasHit &&
            target.absolutePosition.y > 0 &&
            target.absolutePosition.y < game.size.y)
        .toList();

    var endScore = scene.botEndScore;
    if (endScore != null && _score >= endScore) {
      var wrong = visible.where((target) =>
          target.color != _color &&
          target.absolutePosition.y > game.size.y * _botWrongTapFactor);
      if (wrong.isNotEmpty) {
        _isBotDone = true;
        wrong.first.tap();
      }
      return;
    }

    var matches = visible
        .where((target) =>
            target.color == _color &&
            !target.isMissTolerated &&
            target.absolutePosition.y > game.size.y * _botTapFactor)
        .toList()
      ..sort((a, b) => b.absolutePosition.y.compareTo(a.absolutePosition.y));
    if (matches.isEmpty) {
      return;
    }

    var color = _color;
    matches.first.tap();
    _botCooldown = color == _color
        ? _botMinTapSeconds + _botRandom.nextDouble() * _botTapJitter
        : _botColorChangeSeconds +
            _botRandom.nextDouble() * _botColorChangeJitter;
  }

  TargetBoard _targetBoard(ComponentKey key) =>
      game.findByKey(key) as TargetBoard;

  void _onContinueTick() {
    continueSecondsLeft.value--;
    if (continueSecondsLeft.value > 0) {
      return;
    }

    _continueTimer = null;
    _resumeAfterContinue();
  }

  void _resumeAfterContinue() {
    game.overlays.remove(overlayIdContinueCountdown);
    scrollingPaused = false;
    notifyListeners();
  }

  void _endRun() {
    game.overlays.add(overlayIdGameOver);
    StatsManager.get.incCurrentGamesPlayed();
    AudioManager.get.playMenuBackground();
    OrientationManager.get.reset();
    shouldShowNewHighScore = StatsManager.get.updateCurrentHighScore(score);
  }

  /// Places a [MissToleranceLine], in the current color, [factor] of the
  /// screen height up from the bottom, snapped to the row boundary above it.
  /// Targets below the line can be missed without ending the run.
  void _placeMissToleranceLine(double factor) {
    if (_difficulty.canMissTargets) {
      return;
    }

    _removeMissToleranceLine();

    var y = game.size.y * (1 - factor);
    for (var board in children.whereType<TargetBoard>()) {
      var rowY = board.rowBoundaryAbove(y);
      if (rowY == null) {
        continue;
      }

      for (var target in game.descendants().whereType<Target>()) {
        target.updateMissTolerance(rowY);
      }

      _missToleranceLine = MissToleranceLine(
        color: _color,
        width: board.size.x,
        y: rowY - board.absolutePosition.y,
      );
      board.add(_missToleranceLine!);
      return;
    }
  }

  void _removeMissToleranceLine() {
    _missToleranceLine?.removeFromParent();
    _missToleranceLine = null;
  }

  void _updateColorResetMod() {
    var min = _difficulty.colorChangeFrequencyRange.$1;
    var max = _difficulty.colorChangeFrequencyRange.$2;
    _colorResetMod = min == max ? min : min + Random().nextInt(max - min);
  }

  void _resetForNewGame({TargetColor? exclude}) {
    _speed = _difficulty.startSpeed;
    _color = TargetColor.fromPreferences(exclude: exclude);
    _score = 0;
    _removeMissToleranceLine();
    _hasUsedContinue = false;
    _continueTimer = null;
    _updateColorResetMod();
  }
}
