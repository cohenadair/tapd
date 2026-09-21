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
import '../managers/time_manager.dart';
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
  static const _padding = 3.0;

  final TargetBoard _board;
  final SpriteComponent _targetSprite;

  var _isPassedBottom = false;
  var _wasHit = false;

  /// True if this target is the one that ended the current run, either by
  /// being tapped when it shouldn't have been, or by being missed.
  var _endedRun = false;
  var _color = TargetColor.random();

  TargetColor get color => _color;

  Target(
    Vector2 position,
    double radius,
    TargetBoard board, {
    super.key,
  })  : _board = board,
        _targetSprite = SpriteComponent(
          position: Vector2(
            radius + _padding / 2.0,
            radius + _padding / 2.0,
          ),
          size: Vector2(radius * 2 - _padding, radius * 2 - _padding),
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
    if (_isPassedBottom || absolutePosition.y - height <= game.size.y) {
      // Target is still on the screen, or passed the bottom, where it's no
      // longer relevant.
      return;
    } else {
      _isPassedBottom = true;
    }

    // Allow targets to be missed during the grace period.
    if (TimeManager.get.millisSinceEpoch <= (world.gracePeriod ?? -1)) {
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

  void pulse() => _handleIncorrectHit();
}
