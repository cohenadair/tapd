import 'package:material_ui/material_ui.dart';

import '../managers/preference_manager.dart';
import '../target_color.dart';
import 'target_symbol_icon.dart';

/// Paints a target the same way the game does, for use outside of the game,
/// such as in the scoreboard and settings.
class TargetCircle extends StatelessWidget {
  final Color color;

  /// The color slot whose symbol is drawn on the target, or null to draw no
  /// symbol.
  final int? symbolIndex;

  /// A target of [targetColor], in the selected palette.
  TargetCircle(
    TargetColor targetColor, {
    bool showsSymbol = false,
  })  : color = targetColor.color,
        symbolIndex = showsSymbol ? targetColor.index : null;

  /// A target of [color] in the color slot at [index], with the slot's
  /// symbol if the player has turned symbols on. For colors that aren't in
  /// the selected palette yet, such as while choosing one.
  TargetCircle.slot(int index, this.color)
      : symbolIndex = PreferenceManager.get.isSymbolsOn ? index : null;

  /// A target of any [color], such as one the player hasn't chosen yet.
  const TargetCircle.raw(
    this.color, {
    this.symbolIndex,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: TargetColor.gradientFor(color),
      ),
      child: _buildSymbol(),
    );
  }

  Widget _buildSymbol() {
    if (symbolIndex == null) {
      return const SizedBox();
    }
    return TargetSymbolIcon(index: symbolIndex!, color: color);
  }
}
