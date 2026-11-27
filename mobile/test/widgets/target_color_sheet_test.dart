import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/target_palette.dart';
import 'package:mobile/widgets/color_circle.dart';
import 'package:mobile/widgets/target_circle.dart';
import 'package:mobile/widgets/target_color_sheet.dart';
import 'package:mockito/mockito.dart';

import '../test_utils/stubbed_managers.dart';
import '../test_utils/test_utils.dart';

void main() {
  late StubbedManagers managers;

  setUp(() {
    managers = StubbedManagers();
  });

  Future<void> pumpSheet(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(800, 1200);
    await pumpContext(tester, (_) => Material(child: TargetColorSheet()));
  }

  Finder slot(int number) => find.bySemanticsLabel("Colour $number");

  /// The border color of the slot called "Colour [number]".
  Color slotBorder(WidgetTester tester, int number) {
    var container = tester.widget<Container>(find
        .descendant(of: slot(number), matching: find.byType(Container))
        .first);
    return (container.decoration as BoxDecoration).border!.top.color;
  }

  Color primary(WidgetTester tester) =>
      Theme.of(tester.element(find.byType(TargetColorSheet)))
          .colorScheme
          .primary;

  /// The swatch of [color].
  Finder swatch(Color color) => find.byWidgetPredicate(
      (widget) => widget is ColorCircle && widget.color == color);

  /// The border color of the swatch of [color].
  Color swatchBorder(WidgetTester tester, Color color) {
    var container = tester.widget<Container>(find
        .ancestor(of: swatch(color), matching: find.byType(Container))
        .first);
    return (container.decoration as BoxDecoration).border!.top.color;
  }

  testWidgets("Shows the title", (tester) async {
    await pumpSheet(tester);
    expect(find.text("Custom Colours"), findsOneWidget);
  });

  testWidgets("Shows every slot's target", (tester) async {
    await pumpSheet(tester);
    expect(
      tester
          .widgetList<TargetCircle>(find.byType(TargetCircle))
          .map((e) => e.index),
      [0, 1, 2, 3, 4, 5, 6, 7],
    );
  });

  testWidgets("First slot is selected at first", (tester) async {
    await pumpSheet(tester);
    expect(slotBorder(tester, 1), isSameColorAs(primary(tester)));
    expect(slotBorder(tester, 2), isSameColorAs(Colors.transparent));
  });

  testWidgets("Tapping a slot selects it", (tester) async {
    await pumpSheet(tester);
    await tapAndSettle(tester, slot(3));
    expect(slotBorder(tester, 3), isSameColorAs(primary(tester)));
    expect(slotBorder(tester, 1), isSameColorAs(Colors.transparent));
  });

  testWidgets("Swatches follow the selected slot", (tester) async {
    await pumpSheet(tester);
    await tapAndSettle(tester, slot(3));
    expect(
      swatchBorder(tester, TargetPalette.standard.colors![2]),
      isSameColorAs(primary(tester)),
    );
  });

  testWidgets("Shows every swatch", (tester) async {
    await pumpSheet(tester);
    for (var color in TargetPalette.swatches) {
      expect(swatch(color), findsWidgets);
    }
  });

  testWidgets("Selected swatch has a border", (tester) async {
    await pumpSheet(tester);
    expect(
      swatchBorder(tester, TargetPalette.standard.colors![0]),
      isSameColorAs(primary(tester)),
    );
  });

  testWidgets("Unselected swatch has a transparent border", (tester) async {
    await pumpSheet(tester);
    expect(swatchBorder(tester, TargetPalette.standard.colors![1]),
        isSameColorAs(Colors.transparent));
  });

  testWidgets("Tapping a swatch sets the selected slot's color",
      (tester) async {
    await pumpSheet(tester);
    await tapAndSettle(tester, slot(5));
    await tapAndSettle(tester, swatch(const Color(0xFF285AEF)));
    verify(managers.preferenceManager
            .setCustomColor(4, const Color(0xFF285AEF)))
        .called(1);
  });

  testWidgets("Use defaults sets every standard color", (tester) async {
    await pumpSheet(tester);
    await tapAndSettle(tester, find.text("Use Defaults"));
    verify(managers.preferenceManager.useDefaultCustomColors()).called(1);
  });

  testWidgets("Buttons are spaced away from the swatches", (tester) async {
    await pumpSheet(tester);
    var swatchesBottom = tester.getBottomLeft(find.byType(Wrap).last).dy;
    var buttonsTop = tester.getTopLeft(find.text("Use Defaults")).dy;
    expect(buttonsTop - swatchesBottom, greaterThanOrEqualTo(16));
  });

  testWidgets("show opens the sheet and Done closes it", (tester) async {
    await pumpContext(
      tester,
      (context) => TextButton(
        onPressed: () => TargetColorSheet.show(context),
        child: const Text("Open"),
      ),
    );
    await tapAndSettle(tester, find.text("Open"));
    expect(find.byType(TargetColorSheet), findsOneWidget);

    await tapAndSettle(tester, find.text("Done"));
    expect(find.byType(TargetColorSheet), findsNothing);
  });
}
