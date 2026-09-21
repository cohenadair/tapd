import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile/l10n/gen/strings.dart';
import 'package:mobile/tapd_world.dart';
import 'package:mobile/utils/text_utils.dart';
import 'package:mobile/widgets/overlay_scaffold.dart';

/// A "get ready" countdown shown while gameplay stays paused after a run is
/// continued. [TapdWorld] owns the countdown, and removes this overlay when it
/// finishes; this widget only displays the remaining time.
class ContinueCountdown extends StatelessWidget {
  static const _backgroundOpacity = 0.5;
  static const _countdownSize = 100.0;

  /// The seconds remaining in the countdown.
  final ValueListenable<int> secondsLeft;

  const ContinueCountdown(this.secondsLeft);

  @override
  Widget build(BuildContext context) {
    return OverlayScaffold(
      backgroundOpacity: _backgroundOpacity,
      builder: (context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTitle(context),
            _buildSeconds(),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return DisplayLargeText(Strings.of(context).continueCountdownTitle);
  }

  Widget _buildSeconds() {
    return ValueListenableBuilder<int>(
      valueListenable: secondsLeft,
      builder: (context, seconds, _) => Text(
        seconds.toString(),
        style: const TextStyle(fontSize: _countdownSize),
      ),
    );
  }
}
