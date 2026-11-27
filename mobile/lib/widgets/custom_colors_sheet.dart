import 'package:adair_flutter_lib/res/dimen.dart';
import 'package:adair_flutter_lib/widgets/min_divider.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/l10n/gen/strings.dart';

import '../managers/audio_manager.dart';
import '../managers/preference_manager.dart';
import '../target_palette.dart';
import 'circle_grid.dart';
import 'color_circle.dart';
import 'selectable_circle.dart';
import 'target_appearance_builder.dart';
import 'target_circle.dart';

/// Edits the custom palette: the player picks one of its colors, then picks
/// a new color for it from [TargetPalette.swatches], seeing every other
/// color as they go.
class CustomColorsSheet extends StatefulWidget {
  const CustomColorsSheet();

  /// Shows a sheet for editing the custom palette's colors.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const CustomColorsSheet(),
    );
  }

  @override
  State<CustomColorsSheet> createState() => _CustomColorsSheetState();
}

class _CustomColorsSheetState extends State<CustomColorsSheet> {
  /// Slots and swatches share one grid layout, so every circle lines up
  /// and is evenly spaced.
  static const _columns = TargetPalette.colorCount;

  /// The color slot being edited.
  var _index = 0;

  @override
  Widget build(BuildContext context) {
    return TargetAppearanceBuilder(
      // Scrolls if the circles, which grow with the sheet's width, don't fit,
      // such as on a tablet in landscape.
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
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
    return CircleGrid(
      List.generate(TargetPalette.colorCount, _buildSlot),
      columns: _columns,
    );
  }

  /// Separates the slots from the swatches, which are also circles.
  Widget _buildDivider() {
    return const Padding(
      padding: insetsVerticalDefault,
      child: MinDivider(color: Colors.white10),
    );
  }

  Widget _buildSlot(int index) {
    return Semantics(
      button: true,
      label: Strings.of(context).targetColorTitle(index + 1),
      child: SelectableCircle(
        TargetCircle(index),
        isSelected: index == _index,
        onTap: AudioManager.get.onButtonPressed(() {
          setState(() => _index = index);
        }),
      ),
    );
  }

  Widget _buildSwatches() {
    var selected = PreferenceManager.get.targetColors[_index];
    return CircleGrid(
      TargetPalette.swatches
          .map((swatch) => _buildSwatch(swatch, isSelected: swatch == selected))
          .toList(),
      columns: _columns,
    );
  }

  Widget _buildSwatch(Color swatch, {required bool isSelected}) {
    return SelectableCircle(
      ColorCircle(swatch),
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
            child: Text(Strings.of(context).targetColorsDone),
          ),
        ],
      ),
    );
  }
}
