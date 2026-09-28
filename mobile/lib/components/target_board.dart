import 'dart:async';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:mobile/managers/orientation_manager.dart';
import 'package:mobile/tapd_world.dart';
import 'package:mobile/utils/keys.dart';
import 'package:mobile/utils/target_utils.dart';

import '../managers/preference_manager.dart';
import 'miss_tolerance_line.dart';
import 'target.dart';

class TargetBoard extends PositionComponent
    with HasGameRef, HasWorldReference<TapdWorld> {
  late final StreamSubscription _preferenceManagerSub;
  late final StreamSubscription _orientationManagerSub;

  final ComponentKey otherBoardKey;
  final double verticalStartFactor;
  final Color? backgroundColor;

  /// When false, the `update()` method exits early, otherwise this and the
  /// board associated with [otherBoardKey] are both updated.
  ///
  /// Only one [TargetBoard] should do the updating. This is to ensure each
  /// board's position is in sync with the other, otherwise gaps between boards
  /// appear when their position is reset while animating.
  ///
  /// TODO: There may be a better way to do this (for example, a coordinating
  ///   component that includes both boards as children).
  final bool isUpdater;

  final _targets = <Target>[];
  TargetBoard? _otherBoard;

  TargetBoard({
    required this.otherBoardKey,
    required this.verticalStartFactor,
    required this.isUpdater,
    this.backgroundColor,
    super.key,
  });

  @override
  FutureOr<void> onLoad() {
    _preferenceManagerSub = PreferenceManager.get.stream.listen((key) {
      if (key != PreferenceManager.keyDifficulty) {
        return;
      }
      _resetForNewDifficulty();
    });

    _orientationManagerSub =
        OrientationManager.get.stream.listen((_) => _resetForNewDifficulty());

    _resetForNewDifficulty();
    return super.onLoad();
  }

  @override
  void onRemove() {
    super.onRemove();
    _preferenceManagerSub.cancel();
    _orientationManagerSub.cancel();
  }

  @override
  void update(double dt) {
    if (world.scrollingPaused || !isUpdater) {
      return;
    }

    _otherBoard ??= game.findByKey(otherBoardKey) as TargetBoard;
    if (_otherBoard == null) {
      return;
    }

    // Update both boards' position. This must be done before moving a board to
    // the top of the game so the new position is exactly correct.
    //
    // Calculate the change in position relative to 60 FPS, but account for
    // variable frame rates.
    var delta = world.speed / (1 / 60 / dt);
    position.y += delta;
    _otherBoard!.position.y += delta;

    // Reset boards.
    _moveToTopIfNeeded(_otherBoard);
    _otherBoard?._moveToTopIfNeeded(this);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (backgroundColor != null) {
      canvas.drawRect(Rect.fromLTWH(0, 0, width, height),
          Paint()..color = backgroundColor!);
    }
  }

  void resetForNewGame() {
    _resetPos();
    _resetTargets();
    _removeMissToleranceLines();
  }

  /// Returns the absolute Y of the nearest row boundary at or above
  /// [absoluteY], or null if [absoluteY] is outside this board.
  double? rowBoundaryAbove(double absoluteY) {
    var top = absolutePosition.y;
    if (absoluteY < top || absoluteY >= top + size.y) {
      return null;
    }

    var diameter = targetDiameterForRect(size.toRect());
    return top + (absoluteY - top) ~/ diameter * diameter;
  }

  void _resetForNewDifficulty() {
    size = targetBoardSize(game.size);
    _resetPos();
    _clearAndAddTargets();
    _removeMissToleranceLines();
  }

  void _removeMissToleranceLines() =>
      removeWhere((component) => component is MissToleranceLine);

  void _resetPos() {
    position.y = -verticalStartFactor * size.y;
  }

  void _resetTargets() {
    for (var target in _targets) {
      target.reset();
    }
  }

  void _clearAndAddTargets() {
    removeAll(_targets);
    _targets.clear();

    var bounds = size.toRect();
    var diameter = targetDiameterForRect(bounds);

    var numColumns = (bounds.width / diameter).floorToDouble();
    var numRows = (bounds.height / diameter).floorToDouble();

    for (var r = 0; r < numRows; r++) {
      for (var c = 0; c < numColumns; c++) {
        _targets.add(Target(
          Vector2(
            c * diameter + diameter / 2,
            r * diameter + diameter / 2,
          ),
          diameter / 2,
          this,
          // Mark a target to be used in the game instructions.
          key: r == numRows - 2 && // Second to last row.
                  c == numColumns - 1 &&
                  verticalStartFactor == 1 // First board.
              ? keyInstructionsTarget
              : null,
        ));
      }
    }

    addAll(_targets);
  }

  void _moveToTopIfNeeded(TargetBoard? otherBoard) {
    if (position.y < size.y || otherBoard == null) {
      return;
    }

    position.y = otherBoard.position.y - size.y;
    _resetTargets();
    _removeMissToleranceLines();
  }
}
