import 'package:material_ui/material_ui.dart';

import '../target_symbol.dart';

/// Paints the [TargetSymbol] for the color slot at [index], sized as it would
/// be on a target that fills this widget. [color] is the color of the target
/// the symbol is drawn on, which decides whether the symbol is dark or light.
class TargetSymbolIcon extends StatelessWidget {
  final int index;
  final Color color;

  const TargetSymbolIcon({
    required this.index,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: CustomPaint(painter: _TargetSymbolPainter(index, color)),
    );
  }
}

class _TargetSymbolPainter extends CustomPainter {
  final int index;
  final Color color;

  _TargetSymbolPainter(this.index, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    TargetSymbol.draw(
      canvas,
      index: index,
      center: size.center(Offset.zero),
      radius: size.shortestSide / 2,
      paint: TargetSymbol.paintOn(color),
    );
  }

  @override
  bool shouldRepaint(_TargetSymbolPainter oldDelegate) =>
      oldDelegate.index != index || oldDelegate.color != color;
}
