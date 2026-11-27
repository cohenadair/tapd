import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/managers/preference_manager.dart';
import 'package:mobile/pages/target_appearance_page.dart';
import 'package:mobile/target_palette.dart';
import 'package:mobile/target_type.dart';
import 'package:mobile/widgets/color_circle.dart';
import 'package:mobile/widgets/target_circle.dart';
import 'package:mobile/widgets/custom_colors_sheet.dart';
import 'package:mockito/mockito.dart';

import '../test_utils/stubbed_managers.dart';
import '../test_utils/test_utils.dart';

void main() {
  late StubbedManagers managers;

  const custom = [
    Color(0xFFFF0000),
    Color(0xFFD55E00),
    Color(0xFFFFFF00),
    Color(0xFF00FF00),
    Color(0xFF0000FF),
    Color(0xFFFF00FF),
    Color(0xFF00FFFF),
    Color(0xFFFFFFFF),
  ];

  setUp(() {
    managers = StubbedManagers();
  });

  // A tall view by default, so every row is built.
  Future<void> pumpPage(
    WidgetTester tester, {
    Size size = const Size(800, 2400),
  }) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = size;
    await pumpContext(tester, (_) => TargetAppearancePage());
  }

  Finder optionTile(String name) =>
      find.ancestor(of: find.text(name), matching: find.byType(ListTile));

  /// The "Colours" type tile.
  Finder colorsTypeTile() => find.byWidgetPredicate((widget) =>
      widget is ListTile && (widget.title as Text).data == "Colours");

  /// The colors shown in the palette tile called [name].
  List<Color> paletteColors(WidgetTester tester, String name) => tester
      .widgetList<ColorCircle>(find.descendant(
        of: optionTile(name),
        matching: find.byType(ColorCircle),
      ))
      .map((e) => e.color)
      .toList();

  testWidgets("Title matches the Settings row", (tester) async {
    await pumpPage(tester);
    expect(find.widgetWithText(AppBar, "Targets"), findsOneWidget);
  });

  testWidgets("Preview isn't padded by the bottom inset", (tester) async {
    tester.view.padding = const FakeViewPadding(bottom: 34);
    addTearDown(tester.view.resetPadding);
    await pumpPage(tester);
    expect(tester.widget<GridView>(find.byType(GridView)).padding,
        EdgeInsets.zero);
  });

  testWidgets("Shows every palette", (tester) async {
    await pumpPage(tester);
    expect(find.text("Default"), findsOneWidget);
    expect(find.text("Colour-Blind Friendly"), findsOneWidget);
    expect(find.text("Custom"), findsOneWidget);
  });

  testWidgets("Selected palette has a check", (tester) async {
    when(managers.preferenceManager.targetPalette)
        .thenReturn(TargetPalette.colorBlindFriendly);
    await pumpPage(tester);
    expect(
      find.descendant(
        of: optionTile("Colour-Blind Friendly"),
        matching: find.byIcon(Icons.check),
      ),
      findsOneWidget,
    );
    // One for the palette, one for the type.
    expect(find.byIcon(Icons.check), findsNWidgets(2));
  });

  testWidgets("Selected rows aren't highlighted, only checked", (tester) async {
    var context = await pumpContext(tester, (_) => const SizedBox());
    await pumpPage(tester);

    // Default and Colours are selected.
    for (var title in [
      find.text("Default"),
      find.descendant(of: colorsTypeTile(), matching: find.text("Colours")),
    ]) {
      expect(
        DefaultTextStyle.of(tester.element(title)).style.color,
        isNot(isSameColorAs(Theme.of(context).colorScheme.primary)),
      );
    }
    expect(
      tester
          .widgetList<Icon>(find.byIcon(Icons.check))
          .map((icon) => icon.color),
      everyElement(isSameColorAs(Theme.of(context).colorScheme.primary)),
    );
  });

  testWidgets("Tapping a palette selects it", (tester) async {
    await pumpPage(tester);
    await tapAndSettle(tester, find.text("Colour-Blind Friendly"));
    verify(managers.preferenceManager
            .selectTargetPalette(TargetPalette.colorBlindFriendly))
        .called(1);
  });

  testWidgets("Custom palette shows its colors", (tester) async {
    when(managers.preferenceManager.colorsFor(TargetPalette.custom))
        .thenReturn(custom);
    await pumpPage(tester);
    expect(paletteColors(tester, "Custom"), custom);
  });

  testWidgets("Reset resets the page", (tester) async {
    await pumpPage(tester);
    await tapAndSettle(tester, find.text("Reset"));
    verify(managers.preferenceManager.resetTargetAppearance()).called(1);
  });

  testWidgets("Reset is shown for shapes", (tester) async {
    when(managers.preferenceManager.targetType).thenReturn(TargetType.shapes);
    await pumpPage(tester);
    expect(find.widgetWithText(FilledButton, "Reset"), findsOneWidget);
  });

  testWidgets("Tapping Custom selects it and opens its colors", (tester) async {
    await pumpPage(tester);
    await tapAndSettle(tester, find.text("Custom"));
    verify(managers.preferenceManager.selectTargetPalette(TargetPalette.custom))
        .called(1);
    expect(find.byType(CustomColorsSheet), findsOneWidget);
  });

  testWidgets("Tapping a preset palette doesn't open the colors",
      (tester) async {
    await pumpPage(tester);
    await tapAndSettle(tester, find.text("Default"));
    expect(find.byType(CustomColorsSheet), findsNothing);
  });

  testWidgets("Reset is below the options, above the bottom inset",
      (tester) async {
    tester.view.padding = const FakeViewPadding(bottom: 34);
    addTearDown(tester.view.resetPadding);
    await pumpPage(tester);
    var reset = find.widgetWithText(FilledButton, "Reset");
    expect(
      tester.getTopLeft(reset).dy,
      greaterThan(tester.getBottomLeft(optionTile("Custom")).dy),
    );
    expect(tester.getBottomLeft(reset).dy, 2400 - 34 - 16);
  });

  testWidgets("Reset scrolls after the options on a short screen",
      (tester) async {
    await pumpPage(tester, size: const Size(800, 600));
    await tester.scrollUntilVisible(
      find.widgetWithText(FilledButton, "Reset"),
      100,
      scrollable: find
          .descendant(
            of: find.byType(CustomScrollView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(
      tester.getTopLeft(find.widgetWithText(FilledButton, "Reset")).dy,
      greaterThan(tester.getBottomLeft(optionTile("Custom")).dy),
    );
  });

  testWidgets("Shows every target type", (tester) async {
    await pumpPage(tester);
    expect(find.text("Type"), findsOneWidget);
    expect(colorsTypeTile(), findsOneWidget);
    expect(optionTile("Shapes"), findsOneWidget);
  });

  testWidgets("Selected target type is checked", (tester) async {
    when(managers.preferenceManager.targetType).thenReturn(TargetType.shapes);
    await pumpPage(tester);
    expect(
      find.descendant(
          of: optionTile("Shapes"), matching: find.byIcon(Icons.check)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: colorsTypeTile(), matching: find.byIcon(Icons.check)),
      findsNothing,
    );
  });

  testWidgets("Tapping a target type selects it", (tester) async {
    await pumpPage(tester);
    await tapAndSettle(tester, find.text("Shapes"));
    verify(managers.preferenceManager.targetType = TargetType.shapes).called(1);
  });

  testWidgets("Palettes are shown for colored targets", (tester) async {
    await pumpPage(tester);
    expect(find.text("Palette"), findsOneWidget);
    expect(find.text("Default"), findsOneWidget);
  });

  testWidgets("Colors are only shown in their sheet", (tester) async {
    when(managers.preferenceManager.targetPalette)
        .thenReturn(TargetPalette.custom);
    await pumpPage(tester);
    // Only the preview's targets.
    expect(find.byType(TargetCircle), findsNWidgets(12));
  });

  testWidgets("Palettes and colors are hidden for shapes", (tester) async {
    when(managers.preferenceManager.targetType).thenReturn(TargetType.shapes);
    await pumpPage(tester);
    expect(find.text("Palette"), findsNothing);
    expect(find.text("Default"), findsNothing);
    expect(find.text("Custom"), findsNothing);
  });

  testWidgets("Page updates when preferences change", (tester) async {
    var controller = StreamController<String>.broadcast();
    when(managers.preferenceManager.stream)
        .thenAnswer((_) => controller.stream);
    await pumpPage(tester);
    expect(
      find.descendant(
          of: optionTile("Custom"), matching: find.byIcon(Icons.check)),
      findsNothing,
    );

    when(managers.preferenceManager.targetPalette)
        .thenReturn(TargetPalette.custom);
    controller.add(PreferenceManager.keyTargetPalette);
    await tester.pumpAndSettle();
    expect(
      find.descendant(
          of: optionTile("Custom"), matching: find.byIcon(Icons.check)),
      findsOneWidget,
    );
    await controller.close();
  });
}
