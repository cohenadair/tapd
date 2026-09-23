import 'dart:async' as async;
import 'dart:math';

import 'package:adair_flutter_lib/res/dimen.dart';
import 'package:flame/components.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';
import 'package:mobile/difficulty.dart';
import 'package:mobile/managers/orientation_manager.dart';
import 'package:mobile/managers/preference_manager.dart';
import 'package:mobile/managers/stats_manager.dart';
import 'package:mobile/utils/keys.dart';
import 'package:adair_flutter_lib/wrappers/analytics_wrapper.dart';

import 'components/target.dart';
import 'components/target_board.dart';
import 'effects/target_board_rewind_effect.dart';
import 'managers/audio_manager.dart';
import 'managers/time_manager.dart';
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

  /// How long, in milliseconds, players are allowed to miss targets after a
  /// run is continued. Targets near the bottom of the screen when gameplay
  /// resumes shouldn't be unfairly counted as missed.
  static const _continueGracePeriodMs = 3000;

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
  var shouldShowNewHighScore = false;

  /// If set, a "grace period" is active, where users are allowed to miss
  /// targets. This is to prevent immediate loss after a color change due
  /// to the new colour already being at the bottom of the screen.
  int? _gracePeriod;
  async.Timer? _gracePeriodTimer;

  /// True once the current run has been continued. Each run can only be
  /// continued once. Reset when a new game starts.
  var _hasUsedContinue = false;

  /// Ticks the continue countdown. Unlike [_gracePeriodTimer], this is driven
  /// by [update] rather than the wall clock, so it doesn't run while the game
  /// is paused, such as when the app is in the background.
  Timer? _continueTimer;

  /// The seconds remaining in the "get ready" countdown shown after a run is
  /// continued.
  final continueSecondsLeft = ValueNotifier<int>(_continueCountdownSeconds);

  double? instructionsY;

  double get speed => _speed;

  TargetColor get color => _color;

  int get score => _score;

  int? get gracePeriod => _gracePeriod;

  Difficulty get _difficulty => PreferenceManager.get.difficulty;

  /// A run can be continued once. The Very Easy difficulty doesn't offer a
  /// continue at all. Players who have purchased "Remove Ads" are still offered
  /// a continue; it just doesn't involve an ad.
  bool get _canOfferContinue =>
      _difficulty != Difficulty.veryEasy && !_hasUsedContinue;

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
        _startGracePeriod(_difficulty.colorChangeGracePeriodMs);
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
  /// [play], the score, speed, color, and board are left untouched. Gameplay
  /// resumes after a countdown, at which point a grace period starts.
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
    _startGracePeriod(_continueGracePeriodMs);
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

  void _startGracePeriod(int durationMs) {
    _gracePeriod = TimeManager.get.millisSinceEpoch + durationMs;

    _gracePeriodTimer?.cancel();
    _gracePeriodTimer = async.Timer(
      Duration(milliseconds: durationMs),
      () => _gracePeriod = null,
    );
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
    _gracePeriod = null;
    _hasUsedContinue = false;
    _continueTimer = null;
    _updateColorResetMod();
  }
}
