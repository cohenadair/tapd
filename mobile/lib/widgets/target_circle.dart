import 'package:material_ui/material_ui.dart';

import '../managers/preference_manager.dart';
import '../target_skin.dart';

/// Paints the target for a color slot with the player's [TargetSkin], the
/// same way the game does, for use outside of the game, such as in the
/// scoreboard and settings. Fills its parent.
class TargetCircle extends StatelessWidget {
  /// The color slot to paint.
  final int index;

  /// False to leave out the skin's symbol, such as when it's drawn elsewhere.
  final bool includesSymbol;

  // Not const: the skin is read in build, so an identical const instance
  // would skip rebuilding when the player changes it.
  // ignore: prefer_const_constructors_in_immutables
  TargetCircle(
    this.index, {
    this.includesSymbol = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: CustomPaint(
        painter: _TargetPainter(
          PreferenceManager.get.targetSkin,
          index,
          includesSymbol: includesSymbol,
        ),
      ),
    );
  }
}

class _TargetPainter extends CustomPainter {
  final TargetSkin skin;
  final int index;
  final bool includesSymbol;

  _TargetPainter(
    this.skin,
    this.index, {
    required this.includesSymbol,
  });

  @override
  void paint(Canvas canvas, Size size) {
    skin.paint(
      canvas,
      index: index,
      center: size.center(Offset.zero),
      radius: size.shortestSide / 2,
      includesSymbol: includesSymbol,
    );
  }

  @override
  bool shouldRepaint(_TargetPainter oldDelegate) =>
      oldDelegate.skin != skin ||
      oldDelegate.index != index ||
      oldDelegate.includesSymbol != includesSymbol;
}
