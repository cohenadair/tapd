import 'package:adair_flutter_lib/res/dimen.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/l10n/gen/strings.dart';

import '../managers/audio_manager.dart';
import '../managers/preference_manager.dart';
import '../target_palette.dart';
import 'color_circle.dart';
import 'selectable_circle.dart';
import 'target_appearance_builder.dart';
import 'target_circle.dart';

/// Edits the custom palette: the player picks one of its colors, then picks
/// a new color for it from [TargetPalette.swatches], seeing every other
/// color as they go.
class TargetColorSheet extends StatefulWidget {
  // Not const: preferences are read in build, so an identical const instance
  // would skip rebuilding when the player changes them.
  // ignore: prefer_const_constructors_in_immutables
  TargetColorSheet();

  /// Shows a sheet for editing the custom palette's colors.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => TargetColorSheet(),
    );
  }

  @override
  State<TargetColorSheet> createState() => _TargetColorSheetState();
}

class _TargetColorSheetState extends State<TargetColorSheet> {
  static const _slotSize = 36.0;
  static const _swatchSize = 36.0;

  /// The color slot being edited.
  var _index = 0;

  @override
  Widget build(BuildContext context) {
    return TargetAppearanceBuilder(
      builder: (context) => SafeArea(
        child: Padding(
          padding: insetsDefault,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildSlots(),
              _buildDivider(),
              _buildSwatches(),
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: insetsBottomDefault,
      child: Text(
        Strings.of(context).targetColorsTitle,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }

  Widget _buildSlots() {
    return SizedBox(
      // Full width, so the slots spread across it.
      width: double.infinity,
      child: Wrap(
        // All eight slots fit on one row on most phones, spread across it,
        // and wrap on narrower screens.
        alignment: WrapAlignment.spaceBetween,
        spacing: paddingTiny,
        runSpacing: paddingSmall,
        children: List.generate(TargetPalette.colorCount, _buildSlot),
      ),
    );
  }

  /// Separates the slots from the swatches, which are also circles.
  Widget _buildDivider() {
    return const Padding(
      padding: insetsVerticalSmall,
      child: Divider(color: Colors.white10),
    );
  }

  Widget _buildSlot(int index) {
    return Semantics(
      button: true,
      label: Strings.of(context).targetColorTitle(index + 1),
      child: SelectableCircle(
        TargetCircle(index),
        size: _slotSize,
        isSelected: index == _index,
        onTap: AudioManager.get.onButtonPressed(() {
          setState(() => _index = index);
        }),
      ),
    );
  }

  Widget _buildSwatches() {
    var selected = PreferenceManager.get.targetColors[_index];
    return Wrap(
      spacing: paddingSmall,
      runSpacing: paddingSmall,
      children: TargetPalette.swatches
          .map((swatch) => _buildSwatch(swatch, isSelected: swatch == selected))
          .toList(),
    );
  }

  Widget _buildSwatch(Color swatch, {required bool isSelected}) {
    return SelectableCircle(
      ColorCircle(swatch),
      size: _swatchSize,
      isSelected: isSelected,
      onTap: AudioManager.get.onButtonPressed(
          () => PreferenceManager.get.setCustomColor(_index, swatch)),
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: insetsTopDefault,
      child: Row(
        children: [
          TextButton(
            onPressed: AudioManager.get
                .onButtonPressed(PreferenceManager.get.useDefaultCustomColors),
            child: Text(Strings.of(context).targetColorsUseDefaults),
          ),
          const Spacer(),
          TextButton(
            onPressed: AudioManager.get
                .onButtonPressed(() => Navigator.of(context).pop()),
            child: Text(Strings.of(context).targetColorDone),
          ),
        ],
      ),
    );
  }
}
