import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/tapd_game.dart';
import 'package:mobile/tapd_world.dart';

import '../managers/audio_manager.dart';
import '../managers/preference_manager.dart';
import '../target_color.dart';
import 'target_board.dart';

class Target extends PositionComponent
    with HasGameRef<TapdGame>, HasWorldReference<TapdWorld>, TapCallbacks {
  static const _scaleDownBy = 0.20;
  static const _scaleDownDuration = 0.12; // Matches sound effect length.
  static const _scaleUpBy = 1.5;
  static const _scaleUpDuration = 0.3;

  /// The space between adjacent targets. Also used as the thickness of a
  /// [MissToleranceLine] so it fits exactly between two rows.
  static const padding = 3.0;

  /// The opacity of targets that match the current color but can be missed
  /// without ending the run.
  static const _missToleratedOpacity = 0.5;

  /// Paints shared by every target of the same color and opacity. Building a
  /// gradient shader is expensive, so each is built only once. Every target is
  /// the same size, so only paints for [_paintsRadius] are kept, and they're
  /// rebuilt when the size changes, such as after a rotation.
  static final _paints = <(TargetColor, bool), Paint>{};
  static double? _paintsRadius;

  final TargetBoard _board;

  /// The center of the painted circle, in local coordinates.
  final Offset _center;

  /// The radius of the painted circle, which leaves [padding] between it and
  /// adjacent targets.
  final double _circleRadius;

  late Paint _paint;

  /// The effect scaling this target down after a correct hit, if any.
  Effect? _hitEffect;

  var _isPassedBottom = false;
  var _wasHit = false;

  /// True if this target is the one that ended the current run, either by
  /// being tapped when it shouldn't have been, or by being missed.
  var _endedRun = false;
  var _color = TargetColor.random();

  /// True if this target can scroll off the screen without ending the run.
  /// Set when a [MissToleranceLine] is placed above this target.
  var _isMissTolerated = false;

  /// True if this target is currently faded to [_missToleratedOpacity].
  var _isFaded = false;

  TargetColor get color => _color;

  @visibleForTesting
  double get opacity => _isFaded ? _missToleratedOpacity : 1;

  @visibleForTesting
  Paint get paint => _paint;

  @visibleForTesting
  bool get endedRun => _endedRun;

  /// The absolute Y position of this target's center. Unlike
  /// [absolutePosition], this doesn't allocate, so it's cheap to use every
  /// frame. Only correct while neither the board nor its parent is
  /// transformed, which [onLoad] asserts.
  double get _absoluteY => _board.position.y + position.y;

  bool get _isAboveScreen => _absoluteY + height < 0;

  bool get _isBelowScreen => _absoluteY - height > game.size.y;

  Target(
    Vector2 position,
    double radius,
    TargetBoard board, {
    super.key,
  })  : _board = board,
        _center = Offset(radius, radius),
        _circleRadius = radius - padding / 2,
        super(
          position: position,
          size: Vector2(radius * 2, radius * 2),
          anchor: Anchor.center,
        );

  @override
  FutureOr<void> onLoad() {
    assert(
      _board.parent is! PositionComponent &&
          _board.anchor == Anchor.topLeft &&
          _board.scale == Vector2.all(1) &&
          _board.angle == 0,
      "_absoluteY doesn't account for the board's transform",
    );
    _updatePaint();
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

  /// Skips targets that have nothing to update, which is most of them, since
  /// each board is taller than the screen. Targets below the screen are still
  /// updated until they've passed the bottom, so misses are detected.
  @override
  void updateTree(double dt) {
    if (_isAboveScreen || (_isPassedBottom && _isBelowScreen)) {
      return;
    }
    super.updateTree(dt);
  }

  /// Skips targets that aren't visible. The margin, a full target height,
  /// leaves room for a target pulsing near the edge of the screen.
  @override
  void renderTree(Canvas canvas) {
    if (_isAboveScreen || _isBelowScreen) {
      return;
    }
    super.renderTree(canvas);
  }

  @override
  void update(double dt) {
    // Must happen before the on-screen check below, which returns early for
    // every on-screen target.
    _updateFade();

    if (_isPassedBottom || _absoluteY - height <= game.size.y) {
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

  @override
  void render(Canvas canvas) =>
      canvas.drawCircle(_center, _circleRadius, _paint);

  void _handleCorrectHit() {
    add(_hitEffect = ScaleEffect.by(
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
    _updatePaint();
  }

  void _updatePaint() {
    if (_circleRadius != _paintsRadius) {
      _paints.clear();
      _paintsRadius = _circleRadius;
    }

    _paint = _paints.putIfAbsent((_color, _isFaded), () {
      var bounds = Rect.fromCircle(center: _center, radius: _circleRadius);
      return Paint()
        ..shader = _color.gradient.createShader(bounds)
        // When a shader is set, only the color's opacity is used.
        ..color = Colors.black.withValues(alpha: opacity);
    });
  }

  void reset() {
    // A hit target is left scaled down. Setting the scale directly, rather
    // than with an effect, keeps resetting every target on a board cheap.
    // An unfinished hit effect is removed first, since it would otherwise
    // continue scaling the target once it's updated again. Other effects, such
    // as the incorrect hit pulse, are left to finish, since their completion
    // ends the run.
    _hitEffect?.removeFromParent();
    _hitEffect = null;
    scale.setValues(1, 1);

    _isPassedBottom = false;
    _wasHit = false;
    _endedRun = false;
    _isMissTolerated = false;
    _isFaded = false;
    _color = TargetColor.random();
    _updatePaint();
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
  void updateMissTolerance(double y) => _isMissTolerated = _absoluteY > y;

  void pulse() => _handleIncorrectHit();
}
