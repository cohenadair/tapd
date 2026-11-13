import 'package:flame/game.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/managers/orientation_manager.dart';
import 'package:mobile/tapd_game.dart';

import 'utils/overlay_utils.dart';

class TapdGameWidget extends StatelessWidget {
  final TapdGame game;

  const TapdGameWidget(this.game);

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (_, orientation) {
        OrientationManager.get.orientation = orientation;
        return GameWidget(
          game: game,
          overlayBuilderMap: const {
            overlayIdMainMenu: buildMainMenu,
            overlayIdGameOver: buildGameOver,
            overlayIdScoreboard: buildScoreboard,
            overlayIdInstructions: buildInstructions,
            overlayIdContinueOffer: buildContinueOffer,
            overlayIdContinueCountdown: buildContinueCountdown,
          },
        );
      },
    );
  }
}
