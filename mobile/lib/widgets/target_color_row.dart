import 'package:adair_flutter_lib/res/dimen.dart';
import 'package:material_ui/material_ui.dart';

import 'target_circle.dart';

/// A compact row of target [colors], such as a preview of a palette.
class TargetColorRow extends StatelessWidget {
  final List<Color> colors;
  final double size;

  const TargetColorRow(
    this.colors, {
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: paddingTiny,
      runSpacing: paddingTiny,
      children: colors
          .map((color) => SizedBox(
                width: size,
                height: size,
                child: TargetCircle.raw(color),
              ))
          .toList(),
    );
  }
}
