import 'package:material_ui/material_ui.dart';
import 'package:mobile/l10n/gen/strings.dart';

import 'target_skin.dart';

/// The sets of symbols that can be drawn on targets, so players can tell
/// colors apart without relying on color alone. A [TargetSkin] decides how
/// each set is drawn.
///
/// Note that the indexes are stored in preferences and should *not* be
/// changed.
enum TargetSymbolSet {
  none,

  /// A different shape for each color slot, drawn by `TargetSymbol`.
  shapes;

  String displayName(BuildContext context) {
    switch (this) {
      case TargetSymbolSet.none:
        return Strings.of(context).targetSymbolSetNone;
      case TargetSymbolSet.shapes:
        return Strings.of(context).targetSymbolSetShapes;
    }
  }

  String description(BuildContext context) {
    switch (this) {
      case TargetSymbolSet.none:
        return Strings.of(context).targetSymbolSetNoneDescription;
      case TargetSymbolSet.shapes:
        return Strings.of(context).targetSymbolSetShapesDescription;
    }
  }
}
