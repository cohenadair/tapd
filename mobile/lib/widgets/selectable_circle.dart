import 'package:material_ui/material_ui.dart';

/// A circle the player can tap to select, outlined while selected, such as a
/// `TargetCircle` or `ColorCircle`.
class SelectableCircle extends StatelessWidget {
  static const _selectedBorderSize = 2.0;

  final Widget circle;
  final double size;
  final bool isSelected;

  /// Called when tapped; null when the circle can't be selected.
  final VoidCallback? onTap;

  const SelectableCircle(
    this.circle, {
    required this.size,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            width: _selectedBorderSize,
          ),
        ),
        child: circle,
      ),
    );
  }
}
