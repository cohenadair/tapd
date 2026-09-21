import 'package:adair_flutter_lib/res/style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/utils/text_utils.dart';

import '../test_utils/stubbed_managers.dart';
import '../test_utils/test_utils.dart';

void main() {
  setUp(() {
    StubbedManagers();
  });

  testWidgets("DisplayLargeText is centered", (tester) async {
    await pumpContext(tester, (_) => const DisplayLargeText("Test"));

    expect(tester.widget<Text>(find.text("Test")).textAlign, TextAlign.center);
  });

  testWidgets("DisplayLargeText uses the default weight", (tester) async {
    await pumpContext(tester, (_) => const DisplayLargeText("Test"));

    final displayLarge =
        Theme.of(tester.element(find.text("Test"))).textTheme.displayLarge;
    expect(
      tester.widget<Text>(find.text("Test")).style?.fontWeight,
      displayLarge?.fontWeight,
    );
  });

  testWidgets("DisplayLargeText is bold if requested", (tester) async {
    await pumpContext(
      tester,
      (_) => const DisplayLargeText("Test", isBold: true),
    );

    expect(
      tester.widget<Text>(find.text("Test")).style?.fontWeight,
      fontWeightBold,
    );
  });
}
