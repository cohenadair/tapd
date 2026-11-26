import 'package:adair_flutter_lib/res/dimen.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/l10n/gen/strings.dart';

import '../managers/audio_manager.dart';
import '../managers/preference_manager.dart';
import '../target_palette.dart';
import '../target_symbol_set.dart';
import '../utils/color_vision.dart';
import '../utils/colors.dart';
import '../widgets/color_clash_text.dart';
import '../widgets/target_circle.dart';
import '../widgets/target_color_row.dart';
import '../widgets/target_color_sheet.dart';

/// Lets players choose a target palette, change individual target colors,
/// and choose symbols to draw on targets.
class TargetAppearancePage extends StatelessWidget {
  static const _previewTargetSize = 48.0;
  static const _paletteTargetSize = 20.0;
  static const _slotSize = 40.0;

  /// The color slots in the preview, arranged like a few rows of a game.
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
          var colors = PreferenceManager.get.targetColors;
          var clashes = findColorClashes(colors);
          return SafeArea(
            child: ListView(
              children: [
                _buildPreview(),
                _buildHeader(
                    context, Strings.of(context).targetAppearancePalette),
                ...TargetPalette.values
                    .map((palette) => _buildPalette(context, palette)),
                _buildColorsHeader(context),
                _buildSlots(context, colors, clashes),
                _buildClashes(context, clashes),
                _buildHeader(
                    context, Strings.of(context).targetAppearanceSymbols),
                ...TargetSymbolSet.values
                    .map((symbolSet) => _buildSymbolSet(context, symbolSet)),
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

  Widget _buildPalette(BuildContext context, TargetPalette palette) {
    var isSelected = PreferenceManager.get.targetPalette == palette;
    // Before any custom colors exist, Custom previews the current ones, which
    // is what selecting it would start from.
    var colors = palette.colors ??
        PreferenceManager.get.customColors ??
        PreferenceManager.get.targetColors;

    return ListTile(
      contentPadding: insetsHorizontalDefault,
      title: Text(palette.displayName(context)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(palette.description(context)),
          const SizedBox(height: paddingTiny),
          TargetColorRow(colors, size: _paletteTargetSize),
        ],
      ),
      trailing: _buildCheck(context, isSelected),
      onTap: AudioManager.get.onButtonPressed(
          () => PreferenceManager.get.selectTargetPalette(palette)),
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

  Widget _buildSlots(
    BuildContext context,
    List<Color> colors,
    List<ColorClash> clashes,
  ) {
    return Padding(
      padding: insetsHorizontalDefault,
      child: Wrap(
        // All eight slots fit on one row on most phones, spread across it,
        // and wrap on narrower screens.
        alignment: WrapAlignment.spaceBetween,
        spacing: paddingTiny,
        runSpacing: paddingSmall,
        children: List.generate(
          colors.length,
          (index) => _buildSlot(
            context,
            index,
            clashes: clashes.any((clash) => clash.involves(index)),
          ),
        ),
      ),
    );
  }

  Widget _buildSlot(
    BuildContext context,
    int index, {
    required bool clashes,
  }) {
    return Semantics(
      button: true,
      label: Strings.of(context).targetColorTitle(index + 1),
      child: GestureDetector(
        onTap: AudioManager.get
            .onButtonPressed(() => TargetColorSheet.show(context, index)),
        child: SizedBox(
          width: _slotSize,
          height: _slotSize,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: TargetCircle(index),
              ),
              _buildClashIcon(clashes),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClashIcon(bool clashes) {
    if (!clashes) {
      return const SizedBox();
    }
    return const Positioned(
      top: -paddingTiny,
      right: -paddingTiny,
      child: Icon(
        Icons.warning_amber,
        color: colorWarningText,
        size: iconSizeMedium,
      ),
    );
  }

  /// The standard palette gets a single suggestion rather than a line for
  /// each of its many color-blind clashes.
  Widget _buildClashes(BuildContext context, List<ColorClash> clashes) {
    return Padding(
      padding: insetsHorizontalDefaultTopDefault,
      child: ColorClashText(
        clashes,
        summary: PreferenceManager.get.targetPalette == TargetPalette.standard
            ? Strings.of(context).targetAppearanceStandardClash
            : null,
      ),
    );
  }

  Widget _buildSymbolSet(BuildContext context, TargetSymbolSet symbolSet) {
    var isSelected = PreferenceManager.get.targetSymbolSet == symbolSet;
    return ListTile(
      contentPadding: insetsHorizontalDefault,
      title: Text(symbolSet.displayName(context)),
      subtitle: Text(symbolSet.description(context)),
      trailing: _buildCheck(context, isSelected),
      onTap: AudioManager.get.onButtonPressed(
          () => PreferenceManager.get.targetSymbolSet = symbolSet),
    );
  }

  /// Only the checkmark marks the selected option; the row's text keeps its
  /// normal color.
  Widget? _buildCheck(BuildContext context, bool isSelected) {
    return isSelected
        ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
        : null;
  }
}
