import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/utils/color_vision.dart';
import 'package:mobile/widgets/color_clash_text.dart';

import '../test_utils/test_utils.dart';

void main() {
  testWidgets("Shows nothing without clashes", (tester) async {
    await pumpContext(tester, (_) => const ColorClashText([], summary: "S"));
    expect(find.text("S"), findsNothing);
  });

  testWidgets("Shows the summary in place of each clash", (tester) async {
    await pumpContext(
      tester,
      (_) => const ColorClashText(
        [
          ColorClash(0, 1, {ColorVision.normal}),
          ColorClash(2, 3, {ColorVision.normal}),
        ],
        summary: "Summary",
      ),
    );
    expect(find.text("Summary"), findsOneWidget);
    expect(find.textContaining("look alike"), findsNothing);
  });

  testWidgets("Normal vision clash is worded for everyone", (tester) async {
    await pumpContext(
      tester,
      (_) => const ColorClashText([
        ColorClash(0, 1, {ColorVision.normal, ColorVision.redGreen}),
      ]),
    );
    expect(find.text("Colours 1 and 2 look alike."), findsOneWidget);
  });

  testWidgets("Red-green clash", (tester) async {
    await pumpContext(
      tester,
      (_) => const ColorClashText([
        ColorClash(1, 3, {ColorVision.redGreen}),
      ]),
    );
    expect(
      find.text(
          "Colours 2 and 4 may look alike with red-green colour blindness."),
      findsOneWidget,
    );
  });

  testWidgets("Blue-yellow clash", (tester) async {
    await pumpContext(
      tester,
      (_) => const ColorClashText([
        ColorClash(3, 7, {ColorVision.blueYellow}),
      ]),
    );
    expect(
      find.text(
          "Colours 4 and 8 may look alike with blue-yellow colour blindness."),
      findsOneWidget,
    );
  });

  testWidgets("Red-green and blue-yellow clash", (tester) async {
    await pumpContext(
      tester,
      (_) => const ColorClashText([
        ColorClash(0, 1, {ColorVision.redGreen, ColorVision.blueYellow}),
      ]),
    );
    expect(
      find.text("Colours 1 and 2 may look alike with red-green and blue-yellow "
          "colour blindness."),
      findsOneWidget,
    );
  });

  testWidgets("Shows one line per clash", (tester) async {
    await pumpContext(
      tester,
      (_) => const ColorClashText([
        ColorClash(0, 1, {ColorVision.normal}),
        ColorClash(2, 3, {ColorVision.normal}),
      ]),
    );
    expect(find.textContaining("look alike"), findsNWidgets(2));
  });
}
