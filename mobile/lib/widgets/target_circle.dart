import 'package:material_ui/material_ui.dart';

import '../managers/preference_manager.dart';
import '../target_skin.dart';

/// Paints the target for a slot with the player's [TargetSkin], the same way
/// the game does, for use outside of the game, such as in the scoreboard and
/// settings.
class TargetCircle extends StatelessWidget {
  /// The target slot to paint.
  final int index;

  /// The width and height of the target; null to fill its parent.
  final double? size;

  // Not const: the skin is read in build, so an identical const instance
  // would skip rebuilding when the player changes it.
  // ignore: prefer_const_constructors_in_immutables
  TargetCircle(this.index, {super.key, this.size});

  @override
  Widget build(BuildContext context) {
    var paint = CustomPaint(
      painter: _TargetPainter(PreferenceManager.get.targetSkin, index),
    );
    return size == null
        ? SizedBox.expand(child: paint)
        : SizedBox.square(dimension: size, child: paint);
  }
}

class _TargetPainter extends CustomPainter {
  final TargetSkin skin;
  final int index;

  _TargetPainter(this.skin, this.index);

  @override
  void paint(Canvas canvas, Size size) {
    skin.paint(
      canvas,
      index: index,
      center: size.center(Offset.zero),
      radius: size.shortestSide / 2,
    );
  }

  @override
  bool shouldRepaint(_TargetPainter oldDelegate) =>
      oldDelegate.skin != skin || oldDelegate.index != index;
}
