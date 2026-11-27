import 'package:adair_flutter_lib/res/dimen.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/l10n/gen/strings.dart';

import '../managers/audio_manager.dart';
import '../managers/preference_manager.dart';
import '../target_palette.dart';
import '../target_type.dart';
import '../utils/colors.dart';
import '../widgets/circle_grid.dart';
import '../widgets/color_circle.dart';
import '../widgets/target_appearance_builder.dart';
import '../widgets/target_circle.dart';
import '../widgets/custom_colors_sheet.dart';
import '../widgets/target_row.dart';

/// Lets players choose the type of targets and, for colored targets, a
/// palette and, for the custom palette, individual colors.
class TargetAppearancePage extends StatelessWidget {
  static const _previewTargetSize = 48.0;
  static const _paletteTargetSize = 20.0;
  static const _previewElevation = 0.0;

  /// The target slots in the preview, arranged like a few rows of a game.
  static const _previewSlots = [0, 3, 5, 1, 6, 2, 7, 4, 2, 0, 4, 6];
  static const _previewColumns = 4;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Strings.of(context).targetsTitle),
      ),
      body: TargetAppearanceBuilder(
        builder: (context) {
          // Only the sides are inset: the page scrolls under the bottom inset,
          // and the reset button's padding keeps it above the inset.
          return SafeArea(
            bottom: false,
            child: CustomScrollView(
              slivers: [
                SliverList.list(
                  children: [
                    _buildPreview(),
                    _buildHeader(
                        context, Strings.of(context).targetAppearanceType),
                    ...TargetType.values
                        .map((type) => _buildType(context, type)),
                    _buildColorOptions(context),
                  ],
                ),
                _buildResetButton(context),
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
      elevation: _previewElevation,
      margin: insetsDefault,
      child: Padding(
        padding: insetsDefault,
        child: CircleGrid(
          _previewSlots
              .map((slot) => Center(
                    child: TargetCircle(slot, size: _previewTargetSize),
                  ))
              .toList(),
          columns: _previewColumns,
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
      ],
    );
  }

  Widget _buildPalette(BuildContext context, TargetPalette palette) {
    return _buildOption(
      context,
      title: palette.displayName(context),
      subtitle: Padding(
        padding: insetsTopSmall,
        child: TargetRow(
          PreferenceManager.get
              .colorsFor(palette)
              .map(ColorCircle.new)
              .toList(),
          size: _paletteTargetSize,
        ),
      ),
      isSelected: PreferenceManager.get.targetPalette == palette,
      onTap: () => _onPaletteTapped(context, palette),
    );
  }

  /// Individual colors can only be changed in the custom palette, so tapping
  /// it also opens them.
  void _onPaletteTapped(BuildContext context, TargetPalette palette) {
    PreferenceManager.get.selectTargetPalette(palette);
    if (palette == TargetPalette.custom) {
      CustomColorsSheet.show(context);
    }
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

  /// Resets everything on the page, so it's at the bottom of the page rather
  /// than in one of its sections: after the options, or at the bottom of the
  /// screen when they don't fill it.
  Widget _buildResetButton(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: insetsDefault.copyWith(
            bottom: paddingDefault + MediaQuery.of(context).padding.bottom,
          ),
          child: FilledButton(
            onPressed: AudioManager.get
                .onButtonPressed(PreferenceManager.get.resetTargetAppearance),
            child: Text(Strings.of(context).targetAppearanceReset),
          ),
        ),
      ),
    );
  }
}
