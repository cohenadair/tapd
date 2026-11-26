import 'package:material_ui/material_ui.dart';

import '../managers/preference_manager.dart';
import '../target_skin.dart';

/// Paints only the player's [TargetSkin] symbol for the color slot at
/// [index], sized as it would be on a target that fills this widget.
class TargetSymbolIcon extends StatelessWidget {
  final int index;

  // Not const: the skin is read in build, so an identical const instance
  // would skip rebuilding when the player changes it.
  // ignore: prefer_const_constructors_in_immutables
  TargetSymbolIcon(this.index);

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: CustomPaint(
        painter: _TargetSymbolPainter(PreferenceManager.get.targetSkin, index),
      ),
    );
  }
}

class _TargetSymbolPainter extends CustomPainter {
  final TargetSkin skin;
  final int index;

  _TargetSymbolPainter(this.skin, this.index);

  @override
  void paint(Canvas canvas, Size size) {
    skin.paintSymbol(
      canvas,
      index: index,
      center: size.center(Offset.zero),
      radius: size.shortestSide / 2,
    );
  }

  @override
  bool shouldRepaint(_TargetSymbolPainter oldDelegate) =>
      oldDelegate.skin != skin || oldDelegate.index != index;
}
