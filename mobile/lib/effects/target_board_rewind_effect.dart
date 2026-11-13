import 'package:flame/effects.dart';
import 'package:flame/game.dart';

import '../utils/target_utils.dart';

class TargetBoardRewindEffect extends MoveByEffect {
  static const _duration = 0.3;

  TargetBoardRewindEffect({
    required Game game,
    super.onComplete,
  }) : super(
          Vector2(0, -targetScrollBackDistance(game.size.y)),
          EffectController(duration: _duration),
        );
}
