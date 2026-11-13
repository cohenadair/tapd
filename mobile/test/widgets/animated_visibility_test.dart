import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/widgets/animated_visibility.dart';

import '../test_utils/test_utils.dart';

void main() {
  testWidgets("Is visible", (tester) async {
    await pumpContext(
      tester,
      (_) => const AnimatedVisibility(
        isVisible: true,
        child: Text("Test"),
      ),
    );
    expect(
      (tester.firstWidget(find.byType(AnimatedOpacity)) as AnimatedOpacity)
          .opacity,
      1.0,
    );
  });

  testWidgets("Is not visible", (tester) async {
    await pumpContext(
      tester,
      (_) => const AnimatedVisibility(
        isVisible: false,
        child: Text("Test"),
      ),
    );
    expect(
      (tester.firstWidget(find.byType(AnimatedOpacity)) as AnimatedOpacity)
          .opacity,
      0.0,
    );
  });
}
