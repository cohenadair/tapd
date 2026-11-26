import 'package:adair_flutter_lib/res/dimen.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/l10n/gen/strings.dart';

import '../managers/audio_manager.dart';
import '../managers/preference_manager.dart';
import '../target_palette.dart';
import '../target_type.dart';
import '../utils/colors.dart';
import '../widgets/color_circle.dart';
import '../widgets/target_circle.dart';
import '../widgets/target_color_sheet.dart';
import '../widgets/target_row.dart';

/// Lets players choose the type of targets and, for colored targets, a
/// palette and individual colors.
class TargetAppearancePage extends StatelessWidget {
  static const _previewTargetSize = 48.0;
  static const _paletteTargetSize = 20.0;
  static const _slotSize = 40.0;

  /// The target slots in the preview, arranged like a few rows of a game.
  static const _previewSlots = [0, 3, 5, 1, 6, 2, 7, 4, 2, 0, 4, 6];
  static const _previewColumns = 4;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Strings.of(context).targetAppearanceTitle),
      ),
      // The stream only signals changes and has no initial value, which
      // AsyncBuilder would show as loading.
      body: StreamBuilder(
        stream: PreferenceManager.get.stream,
        builder: (context, _) {
          return SafeArea(
            child: ListView(
              children: [
                _buildPreview(),
                _buildHeader(context, Strings.of(context).targetAppearanceType),
                ...TargetType.values.map((type) => _buildType(context, type)),
                _buildColorOptions(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPreview() {
    return Card(
      color: colorCard,
      elevation: 0,
      margin: insetsDefault,
      child: Padding(
        padding: insetsDefault,
        child: GridView.count(
          crossAxisCount: _previewColumns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: paddingSmall,
          crossAxisSpacing: paddingSmall,
          children: _previewSlots
              .map((slot) => Center(
                    child: SizedBox(
                      width: _previewTargetSize,
                      height: _previewTargetSize,
                      child: TargetCircle(slot),
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String title) {
    return Padding(
      padding: insetsHorizontalDefaultTopSmall,
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }

  Widget _buildType(BuildContext context, TargetType type) {
    return _buildOption(
      context,
      title: type.displayName(context),
      isSelected: PreferenceManager.get.targetType == type,
      onTap: () => PreferenceManager.get.targetType = type,
    );
  }

  /// Palettes and colors only apply to colored targets.
  Widget _buildColorOptions(BuildContext context) {
    if (PreferenceManager.get.targetType != TargetType.colors) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context, Strings.of(context).targetAppearancePalette),
        ...TargetPalette.values
            .map((palette) => _buildPalette(context, palette)),
        _buildColorsHeader(context),
        _buildSlots(context),
      ],
    );
  }

  Widget _buildPalette(BuildContext context, TargetPalette palette) {
    // Before any custom colors exist, Custom previews the current ones, which
    // is what selecting it would start from.
    var colors = palette.colors ??
        PreferenceManager.get.customColors ??
        PreferenceManager.get.targetColors;

    return _buildOption(
      context,
      title: palette.displayName(context),
      subtitle: Padding(
        padding: insetsTopSmall,
        child: TargetRow(
          colors.map(ColorCircle.new).toList(),
          size: _paletteTargetSize,
        ),
      ),
      isSelected: PreferenceManager.get.targetPalette == palette,
      onTap: () => PreferenceManager.get.selectTargetPalette(palette),
    );
  }

  /// Only the checkmark marks the selected option; the row's text keeps its
  /// normal color.
  Widget _buildOption(
    BuildContext context, {
    required String title,
    Widget? subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: insetsHorizontalDefault,
      title: Text(title),
      subtitle: subtitle,
      trailing: isSelected
          ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
          : null,
      onTap: AudioManager.get.onButtonPressed(onTap),
    );
  }

  Widget _buildColorsHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child:
              _buildHeader(context, Strings.of(context).targetAppearanceColors),
        ),
        Padding(
          padding: insetsHorizontalSmall,
          child: TextButton(
            onPressed: AudioManager.get
                .onButtonPressed(PreferenceManager.get.resetTargetColors),
            child: Text(Strings.of(context).targetAppearanceReset),
          ),
        ),
      ],
    );
  }

  Widget _buildSlots(BuildContext context) {
    return Padding(
      padding: insetsHorizontalDefaultBottomDefault,
      child: Wrap(
        // All eight slots fit on one row on most phones, spread across it,
        // and wrap on narrower screens.
        alignment: WrapAlignment.spaceBetween,
        spacing: paddingTiny,
        runSpacing: paddingSmall,
        children: List.generate(
          TargetPalette.colorCount,
          (index) => _buildSlot(context, index),
        ),
      ),
    );
  }

  Widget _buildSlot(BuildContext context, int index) {
    return Semantics(
      button: true,
      label: Strings.of(context).targetColorTitle(index + 1),
      child: GestureDetector(
        onTap: AudioManager.get
            .onButtonPressed(() => TargetColorSheet.show(context, index)),
        child: SizedBox(
          width: _slotSize,
          height: _slotSize,
          child: TargetCircle(index),
        ),
      ),
    );
  }
}
