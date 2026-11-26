import 'package:material_ui/material_ui.dart';

import '../target_color.dart';

/// A circle of any [color], shaded like a target but with no symbol, such as
/// a swatch the player can choose from. Use [TargetCircle] for a target in
/// the player's colors.
class ColorCircle extends StatelessWidget {
  final Color color;

  const ColorCircle(this.color);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: TargetColor.gradientFor(color),
      ),
    );
  }
}
