import 'package:adair_flutter_lib/res/dimen.dart';
import 'package:material_ui/material_ui.dart';

/// A compact row of [targets], each in a square of [size], such as a
/// preview of a palette.
class TargetRow extends StatelessWidget {
  final List<Widget> targets;
  final double size;

  const TargetRow(
    this.targets, {
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: paddingTiny,
      runSpacing: paddingTiny,
      children: targets
          .map((target) => SizedBox(width: size, height: size, child: target))
          .toList(),
    );
  }
}
