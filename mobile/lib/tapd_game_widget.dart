import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:mobile/managers/orientation_manager.dart';
import 'package:mobile/tapd_game.dart';
import 'package:mobile/target_color.dart';

import 'log.dart';
import 'utils/overlay_utils.dart';

class TapdGameWidget extends StatefulWidget {
  final TapdGame game;

  const TapdGameWidget(this.game);

  @override
  State<TapdGameWidget> createState() => _TapdGameWidgetState();
}

class _TapdGameWidgetState extends State<TapdGameWidget> {
  static const _log = Log("TapdGameWidget");

  var _didCacheImages = false;

  @override
  Widget build(BuildContext context) {
    if (!_didCacheImages) {
      _log.d("Caching images...");
      for (var color in TargetColor.all()) {
        precacheImage(AssetImage(color.path), context);
        Flame.images.load(color.image);
      }
      _didCacheImages = true;
    }

    return OrientationBuilder(
      builder: (_, orientation) {
        OrientationManager.get.orientation = orientation;
        return GameWidget(
          game: widget.game,
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
