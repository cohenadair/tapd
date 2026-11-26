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

  Future<void> pumpSheet(WidgetTester tester, int index) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(800, 1200);
    await pumpContext(tester, (_) => Material(child: TargetColorSheet(index)));
  }

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

  testWidgets("Shows the slot's number", (tester) async {
    await pumpSheet(tester, 2);
    expect(find.text("Colour 3"), findsOneWidget);
  });

  testWidgets("Preview shows the slot's target", (tester) async {
    await pumpSheet(tester, 2);
    expect(tester.widget<TargetCircle>(find.byType(TargetCircle)).index, 2);
  });

  testWidgets("Shows every swatch", (tester) async {
    await pumpSheet(tester, 0);
    for (var color in TargetPalette.swatches) {
      expect(swatch(color), findsWidgets);
    }
  });

  testWidgets("Selected swatch has a border", (tester) async {
    await pumpSheet(tester, 0);
    expect(
      swatchBorder(tester, TargetPalette.standard.colors![0]),
      Theme.of(tester.element(find.byType(TargetColorSheet)))
          .colorScheme
          .primary,
    );
  });

  testWidgets("Unselected swatch has a transparent border", (tester) async {
    await pumpSheet(tester, 0);
    expect(swatchBorder(tester, TargetPalette.standard.colors![1]),
        Colors.transparent);
  });

  testWidgets("Tapping a swatch sets the slot's color", (tester) async {
    await pumpSheet(tester, 4);
    await tapAndSettle(tester, swatch(const Color(0xFF285AEF)));
    verify(managers.preferenceManager
            .setCustomColor(4, const Color(0xFF285AEF)))
        .called(1);
  });

  testWidgets("Use default sets the slot's standard color", (tester) async {
    await pumpSheet(tester, 4);
    await tapAndSettle(tester, find.text("Use Default"));
    verify(managers.preferenceManager
            .setCustomColor(4, TargetPalette.standard.colors![4]))
        .called(1);
  });

  testWidgets("Buttons are spaced away from the swatches", (tester) async {
    await pumpSheet(tester, 0);
    var swatchesBottom = tester.getBottomLeft(find.byType(Wrap)).dy;
    var buttonsTop = tester.getTopLeft(find.text("Use Default")).dy;
    expect(buttonsTop - swatchesBottom, greaterThanOrEqualTo(16));
  });

  testWidgets("show opens the sheet and Done closes it", (tester) async {
    await pumpContext(
      tester,
      (context) => TextButton(
        onPressed: () => TargetColorSheet.show(context, 0),
        child: const Text("Open"),
      ),
    );
    await tapAndSettle(tester, find.text("Open"));
    expect(find.byType(TargetColorSheet), findsOneWidget);

    await tapAndSettle(tester, find.text("Done"));
    expect(find.byType(TargetColorSheet), findsNothing);
  });
}
