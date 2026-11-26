import 'package:material_ui/material_ui.dart';
import 'package:mobile/l10n/gen/strings.dart';

import 'target_skin.dart';

/// The kinds of targets players can choose from. Each is drawn by its own
/// [TargetSkin].
///
/// Note that the indexes are stored in preferences and should *not* be
/// changed.
enum TargetType {
  /// Circles in the selected palette's colors.
  colors,

  /// Plain shapes, one for each target slot, with no color.
  shapes;

  String displayName(BuildContext context) {
    switch (this) {
      case TargetType.colors:
        return Strings.of(context).targetTypeColors;
      case TargetType.shapes:
        return Strings.of(context).targetTypeShapes;
    }
  }
}
