import 'package:flame/game.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/tapd_world.dart';

import 'utils/colors.dart';

class TapdGame extends FlameGame<TapdWorld> {
  TapdGame({
    super.world,
  });

  @override
  Color backgroundColor() => colorGame;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);

    // Set origin (0, 0) to top left of screen.
    camera.viewport.position = Vector2(
      -camera.viewport.size.x / 2,
      -camera.viewport.size.y / 2,
    );
  }
}
