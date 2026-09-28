import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:mobile/tapd_game.dart';
import 'package:mobile/tapd_world.dart';
import 'package:mobile/wrappers/flame_wrapper.dart';

import '../managers/audio_manager.dart';
import '../managers/preference_manager.dart';
import '../target_color.dart';
import 'target_board.dart';

class Target extends RectangleComponent
    with HasGameRef<TapdGame>, HasWorldReference<TapdWorld>, TapCallbacks {
  static const _scaleDownBy = 0.20;
  static const _scaleDownDuration = 0.12; // Matches sound effect length.
  static const _scaleUpBy = 1.5;
  static const _scaleUpDuration = 0.3;
  static const _scaleResetBy = 1 / _scaleDownBy;
  static const _scaleResetDuration = 0.0;

  /// The space between adjacent targets. Also used as the thickness of a
  /// [MissToleranceLine] so it fits exactly between two rows.
  static const padding = 3.0;

  /// The opacity of targets that match the current color but can be missed
  /// without ending the run.
  static const _missToleratedOpacity = 0.5;

  final TargetBoard _board;
  final SpriteComponent _targetSprite;

  var _isPassedBottom = false;
  var _wasHit = false;

  /// True if this target is the one that ended the current run, either by
  /// being tapped when it shouldn't have been, or by being missed.
  var _endedRun = false;
  var _color = TargetColor.random();

  /// True if this target can scroll off the screen without ending the run.
  /// Set when a [MissToleranceLine] is placed above this target.
  var _isMissTolerated = false;

  /// True if [_targetSprite] is currently faded to [_missToleratedOpacity].
  var _isFaded = false;

  TargetColor get color => _color;

  Target(
    Vector2 position,
    double radius,
    TargetBoard board, {
    super.key,
  })  : _board = board,
        _targetSprite = SpriteComponent(
          position: Vector2(radius, radius),
          size: Vector2(radius * 2 - padding, radius * 2 - padding),
          anchor: Anchor.center,
        ),
        super(
          position: position,
          size: Vector2(radius * 2, radius * 2),
          anchor: Anchor.center,
          paint: Paint()..color = Colors.transparent,
        );

  @override
  FutureOr<void> onLoad() async {
    await _updateSpriteColor();
    add(_targetSprite);
    return super.onLoad();
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (world.scrollingPaused || _wasHit || !PreferenceManager.get.didOnboard) {
      return;
    }

    if (_color == world.color) {
      _handleCorrectHit();
      _wasHit = true;
    } else {
      _handleIncorrectHit();
    }
  }

  @override
  void update(double dt) {
    // Must happen before the on-screen check below, which returns early for
    // every on-screen target.
    _updateFade();

    if (_isPassedBottom || absolutePosition.y - height <= game.size.y) {
      // Target is still on the screen, or passed the bottom, where it's no
      // longer relevant.
      return;
    } else {
      _isPassedBottom = true;
    }

    if (PreferenceManager.get.difficulty.canMissTargets) {
      return;
    }

    if (_isMissTolerated) {
      return;
    }

    if (color == world.color && !_wasHit && !world.scrollingPaused) {
      world.handleTargetMissed(this, _board);
    }
  }

  void _handleCorrectHit() {
    add(ScaleEffect.by(
      Vector2.all(_scaleDownBy),
      EffectController(duration: _scaleDownDuration),
    ));

    world.handleTargetHit(isCorrect: true);
  }

  void _handleIncorrectHit() {
    AudioManager.get.playIncorrectHit();
    _endedRun = true;

    // Pulse the target 3 times so the user knows what they did wrong.
    add(ScaleEffect.by(
      Vector2.all(_scaleUpBy),
      SequenceEffectController([
        LinearEffectController(_scaleUpDuration),
        ReverseLinearEffectController(_scaleUpDuration),
        LinearEffectController(_scaleUpDuration),
        ReverseLinearEffectController(_scaleUpDuration),
        LinearEffectController(_scaleUpDuration),
        ReverseLinearEffectController(_scaleUpDuration),
      ]),
      onComplete: () {
        priority = 0;
        _board.priority = priority;
        world.handleTargetHit(isCorrect: false);
      },
    ));
    priority = 1;
    _board.priority = priority;
    world.scrollingPaused = true;
  }

  /// Fades miss-tolerated targets that match the current color, so players can
  /// see which matching targets they don't have to tap. Tolerated targets of
  /// other colors stay opaque, since tapping them still ends the run.
  void _updateFade() {
    var isFaded = _isMissTolerated && _color == world.color;
    if (isFaded == _isFaded) {
      return;
    }

    _isFaded = isFaded;
    _targetSprite.opacity = isFaded ? _missToleratedOpacity : 1;
  }

  Future<void> _updateSpriteColor() async {
    _targetSprite.sprite = await FlameWrapper.get.loadSprite(_color.image);
  }

  void reset() {
    if (_wasHit) {
      add(ScaleEffect.by(
        Vector2.all(_scaleResetBy),
        EffectController(duration: _scaleResetDuration),
      ));
    }

    _isPassedBottom = false;
    _wasHit = false;
    _endedRun = false;
    _isMissTolerated = false;
    _isFaded = false;
    _targetSprite.opacity = 1;
    _color = TargetColor.random();
    _updateSpriteColor();
  }

  /// Puts this target back in a fresh, untapped state if it's the one that
  /// ended the run. Used when a run is continued, so the target doesn't end
  /// the run again as soon as gameplay resumes.
  void resetIfEndedRun() {
    if (_endedRun) {
      reset();
    }
  }

  /// Allows this target to scroll off the screen without ending the run if
  /// it's below the absolute [y] position of a newly placed
  /// [MissToleranceLine], and revokes that allowance otherwise. Targets only
  /// end up above a new line after a rewind moves them back up.
  void updateMissTolerance(double y) =>
      _isMissTolerated = absolutePosition.y > y;

  void pulse() => _handleIncorrectHit();
}
