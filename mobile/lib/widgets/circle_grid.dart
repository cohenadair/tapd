import 'package:adair_flutter_lib/res/dimen.dart';
import 'package:material_ui/material_ui.dart';

/// A non-scrolling grid of [circles] in [columns] columns, with the same space
/// between them across and down, such as targets or color swatches.
class CircleGrid extends StatelessWidget {
  static const _spacing = paddingSmall;

  final List<Widget> circles;
  final int columns;

  const CircleGrid(
    this.circles, {
    required this.columns,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: columns,
      mainAxisSpacing: _spacing,
      crossAxisSpacing: _spacing,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      // Without it, the grid pads itself with the screen's insets.
      padding: EdgeInsets.zero,
      children: circles,
    );
  }
}
