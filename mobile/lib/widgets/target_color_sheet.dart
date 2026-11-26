import 'package:adair_flutter_lib/res/dimen.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/l10n/gen/strings.dart';

import '../managers/audio_manager.dart';
import '../managers/preference_manager.dart';
import '../target_palette.dart';
import 'color_circle.dart';
import 'selectable_target_circle.dart';
import 'target_circle.dart';

class TargetColorSheet extends StatelessWidget {
  static const _previewSize = 48.0;
  static const _swatchSize = 36.0;

  /// The color slot being edited.
  final int index;

  const TargetColorSheet(this.index);

  /// Shows a sheet for choosing the color at [index] from
  /// [TargetPalette.swatches].
  static Future<void> show(BuildContext context, int index) {
    return showModalBottomSheet(
      context: context,
      builder: (_) => TargetColorSheet(index),
    );
  }

  @override
  Widget build(BuildContext context) {
    // The stream only signals changes and has no initial value, which
    // AsyncBuilder would show as loading.
    return StreamBuilder(
      stream: PreferenceManager.get.stream,
      builder: (context, _) {
        var colors = PreferenceManager.get.targetColors;
        return SafeArea(
          child: Padding(
            padding: insetsDefault,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                _buildSwatches(colors[index]),
                _buildActions(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: insetsBottomDefault,
      child: Row(
        children: [
          SizedBox(
            width: _previewSize,
            height: _previewSize,
            child: TargetCircle(index),
          ),
          const SizedBox(width: paddingDefault),
          Text(
            Strings.of(context).targetColorTitle(index + 1),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildSwatches(Color selected) {
    return Wrap(
      spacing: paddingSmall,
      runSpacing: paddingSmall,
      children: TargetPalette.swatches
          .map((swatch) => _buildSwatch(swatch, isSelected: swatch == selected))
          .toList(),
    );
  }

  Widget _buildSwatch(Color swatch, {required bool isSelected}) {
    return SelectableTargetCircle(
      ColorCircle(swatch),
      size: _swatchSize,
      isSelected: isSelected,
      onTap: AudioManager.get.onButtonPressed(
          () => PreferenceManager.get.setCustomColor(index, swatch)),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      children: [
        TextButton(
          onPressed: AudioManager.get.onButtonPressed(() => PreferenceManager
              .get
              .setCustomColor(index, TargetPalette.standard.colors![index])),
          child: Text(Strings.of(context).targetColorUseDefault),
        ),
        const Spacer(),
        TextButton(
          onPressed: AudioManager.get
              .onButtonPressed(() => Navigator.of(context).pop()),
          child: Text(Strings.of(context).targetColorDone),
        ),
      ],
    );
  }
}
