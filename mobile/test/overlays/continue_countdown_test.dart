import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/overlays/continue_countdown.dart';

import '../test_utils/stubbed_managers.dart';
import '../test_utils/test_utils.dart';

void main() {
  setUp(() {
    StubbedManagers();
  });

  testWidgets("Title and seconds are shown", (tester) async {
    await pumpContext(
      tester,
      (_) => ContinueCountdown(ValueNotifier(5)),
    );

    expect(find.text("Get Ready!"), findsOneWidget);
    expect(find.text("5"), findsOneWidget);
  });

  testWidgets("Seconds are updated", (tester) async {
    final secondsLeft = ValueNotifier(5);
    await pumpContext(tester, (_) => ContinueCountdown(secondsLeft));

    secondsLeft.value = 4;
    await tester.pump();

    expect(find.text("4"), findsOneWidget);
    expect(find.text("5"), findsNothing);
  });
}
