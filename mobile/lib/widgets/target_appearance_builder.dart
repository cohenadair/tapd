import 'package:material_ui/material_ui.dart';

import '../managers/preference_manager.dart';

/// Rebuilds with [builder] whenever how targets look changes, such as the
/// target type or palette, but not for other preferences.
class TargetAppearanceBuilder extends StatefulWidget {
  final WidgetBuilder builder;

  const TargetAppearanceBuilder({required this.builder});

  @override
  State<TargetAppearanceBuilder> createState() =>
      _TargetAppearanceBuilderState();
}

class _TargetAppearanceBuilderState extends State<TargetAppearanceBuilder> {
  /// Filtered once, so rebuilding doesn't resubscribe to a new stream.
  late final Stream<String> _stream;

  @override
  void initState() {
    super.initState();
    _stream = PreferenceManager.get.stream
        .where(PreferenceManager.isTargetAppearanceKey);
  }

  @override
  Widget build(BuildContext context) {
    // The stream only signals changes and has no initial value, which
    // AsyncBuilder would show as loading.
    return StreamBuilder(
      stream: _stream,
      builder: (context, _) => widget.builder(context),
    );
  }
}
