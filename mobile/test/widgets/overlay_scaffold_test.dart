import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/widgets/overlay_scaffold.dart';

import '../test_utils/stubbed_managers.dart';
import '../test_utils/test_utils.dart';

void main() {
  setUp(() {
    StubbedManagers();
  });

  testWidgets("Builder content is shown", (tester) async {
    await pumpContext(
      tester,
      (_) => OverlayScaffold(
        backgroundOpacity: 0.5,
        builder: (_) => const Text("Test content"),
      ),
    );

    expect(find.text("Test content"), findsOneWidget);
  });

  testWidgets("Background uses the given opacity", (tester) async {
    await pumpContext(
      tester,
      (_) => OverlayScaffold(
        backgroundOpacity: 0.5,
        builder: (_) => const SizedBox(),
      ),
    );

    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      Colors.black.withValues(alpha: 0.5),
    );
  });
}
