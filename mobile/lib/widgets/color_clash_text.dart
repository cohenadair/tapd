import 'package:adair_flutter_lib/res/dimen.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/l10n/gen/strings.dart';

import '../utils/color_vision.dart';
import '../utils/colors.dart';

/// Warns the player about target colors that look alike, one line per pair.
/// Shows nothing when there are no [clashes].
class ColorClashText extends StatelessWidget {
  final List<ColorClash> clashes;

  /// Shown in place of the per-pair lines when not null.
  final String? summary;

  const ColorClashText(
    this.clashes, {
    this.summary,
  });

  @override
  Widget build(BuildContext context) {
    if (clashes.isEmpty) {
      return const SizedBox();
    }

    var lines = summary == null
        ? clashes.map((clash) => _message(context, clash)).toList()
        : [summary!];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) => _buildLine(context, line)).toList(),
    );
  }

  Widget _buildLine(BuildContext context, String line) {
    var style = Theme.of(context)
        .textTheme
        .bodySmall
        ?.copyWith(color: colorWarningText);

    return Padding(
      padding: insetsBottomSmall,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber,
            color: colorWarningText,
            size: style?.fontSize,
          ),
          const SizedBox(width: paddingTiny),
          Expanded(child: Text(line, style: style)),
        ],
      ),
    );
  }

  /// Colors are numbered from 1 for players, and a clash for everyone is
  /// worded as one, whatever else it affects.
  String _message(BuildContext context, ColorClash clash) {
    var strings = Strings.of(context);
    var first = clash.first + 1;
    var second = clash.second + 1;

    if (clash.visions.contains(ColorVision.normal)) {
      return strings.targetAppearanceClash(first, second);
    }

    var isRedGreen = clash.visions.contains(ColorVision.redGreen);
    var isBlueYellow = clash.visions.contains(ColorVision.blueYellow);
    if (isRedGreen && isBlueYellow) {
      return strings.targetAppearanceClashColorBlind(first, second);
    }
    return isRedGreen
        ? strings.targetAppearanceClashRedGreen(first, second)
        : strings.targetAppearanceClashBlueYellow(first, second);
  }
}
