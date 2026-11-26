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

  /// The skin that draws this type of target, using [colors] for types that
  /// are colored.
  TargetSkin skin(List<Color> colors) {
    switch (this) {
      case TargetType.colors:
        return PaletteSkin(colors);
      case TargetType.shapes:
        return ShapeSkin();
    }
  }

  String displayName(BuildContext context) {
    switch (this) {
      case TargetType.colors:
        return Strings.of(context).targetTypeColors;
      case TargetType.shapes:
        return Strings.of(context).targetTypeShapes;
    }
  }

  /// The title of the setting that picks one target to always use.
  String chooseTitle(BuildContext context) {
    switch (this) {
      case TargetType.colors:
        return Strings.of(context).settingsChooseColorTitle;
      case TargetType.shapes:
        return Strings.of(context).settingsChooseShapeTitle;
    }
  }

  /// Explains the setting that picks one target to always use.
  String chooseMessage(BuildContext context) {
    switch (this) {
      case TargetType.colors:
        return Strings.of(context).settingsChooseColorMessage;
      case TargetType.shapes:
        return Strings.of(context).settingsChooseShapeMessage;
    }
  }
}
