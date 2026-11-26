import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/managers/preference_manager.dart';
import 'package:mobile/pages/target_appearance_page.dart';
import 'package:mobile/target_palette.dart';
import 'package:mobile/widgets/color_clash_text.dart';
import 'package:mobile/widgets/target_circle.dart';
import 'package:mobile/widgets/target_color_sheet.dart';
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

  // A tall view so every row is built.
  Future<void> pumpPage(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(800, 2400);
    await pumpContext(tester, (_) => TargetAppearancePage());
  }

  Finder paletteTile(String name) =>
      find.ancestor(of: find.text(name), matching: find.byType(ListTile));

  /// The colors shown in the palette tile called [name].
  List<Color> paletteColors(WidgetTester tester, String name) => tester
      .widgetList<TargetCircle>(find.descendant(
        of: paletteTile(name),
        matching: find.byType(TargetCircle),
      ))
      .map((e) => e.color)
      .toList();

  Finder slot(int number) => find.bySemanticsLabel("Colour $number");

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
        of: paletteTile("Colour-Blind Friendly"),
        matching: find.byIcon(Icons.check),
      ),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets("Tapping a palette selects it", (tester) async {
    await pumpPage(tester);
    await tapAndSettle(tester, find.text("Colour-Blind Friendly"));
    verify(managers.preferenceManager
            .selectTargetPalette(TargetPalette.colorBlindFriendly))
        .called(1);
  });

  testWidgets("Custom palette shows saved custom colors", (tester) async {
    when(managers.preferenceManager.customColors).thenReturn(custom);
    await pumpPage(tester);
    expect(paletteColors(tester, "Custom"), custom);
  });

  testWidgets("Custom palette shows current colors when none are saved",
      (tester) async {
    await pumpPage(tester);
    expect(paletteColors(tester, "Custom"), TargetPalette.standard.colors);
  });

  testWidgets("Reset resets the colors", (tester) async {
    await pumpPage(tester);
    await tapAndSettle(tester, find.text("Reset"));
    verify(managers.preferenceManager.resetTargetColors()).called(1);
  });

  testWidgets("Tapping a color opens its sheet", (tester) async {
    await pumpPage(tester);
    await tapAndSettle(tester, slot(3));
    expect(
      tester.widget<TargetColorSheet>(find.byType(TargetColorSheet)).index,
      2,
    );
  });

  testWidgets("Clashing colors have a warning icon", (tester) async {
    // Standard clashes involve colours 2, 3, 4, and 8.
    await pumpPage(tester);
    for (var number in [2, 3, 4, 8]) {
      expect(
        find.descendant(
            of: slot(number), matching: find.byIcon(Icons.warning_amber)),
        findsOneWidget,
      );
    }
  });

  testWidgets("Colors that don't clash have no warning icon", (tester) async {
    await pumpPage(tester);
    expect(
      find.descendant(of: slot(1), matching: find.byIcon(Icons.warning_amber)),
      findsNothing,
    );
  });

  testWidgets("Standard palette shows one suggestion", (tester) async {
    await pumpPage(tester);
    expect(
      tester.widget<ColorClashText>(find.byType(ColorClashText)).summary,
      isNotNull,
    );
  });

  testWidgets("Other palettes list each clash", (tester) async {
    when(managers.preferenceManager.targetPalette)
        .thenReturn(TargetPalette.custom);
    when(managers.preferenceManager.targetColors).thenReturn(custom);
    await pumpPage(tester);
    expect(
      tester.widget<ColorClashText>(find.byType(ColorClashText)).summary,
      isNull,
    );
  });

  testWidgets("Targets have no symbols when symbols are off", (tester) async {
    await pumpPage(tester);
    expect(
      find.byWidgetPredicate(
          (widget) => widget is TargetCircle && widget.symbolIndex != null),
      findsNothing,
    );
  });

  testWidgets("Preview and colors show symbols when symbols are on",
      (tester) async {
    when(managers.preferenceManager.isSymbolsOn).thenReturn(true);
    await pumpPage(tester);
    // 12 preview targets and 8 colors.
    expect(
      find.byWidgetPredicate(
          (widget) => widget is TargetCircle && widget.symbolIndex != null),
      findsNWidgets(20),
    );
  });

  testWidgets("Symbols switch sets the preference", (tester) async {
    await pumpPage(tester);
    await tapAndSettle(tester, find.text("Show Symbols"));
    verify(managers.preferenceManager.isSymbolsOn = true).called(1);
  });

  testWidgets("Page updates when preferences change", (tester) async {
    var controller = StreamController<String>.broadcast();
    when(managers.preferenceManager.stream)
        .thenAnswer((_) => controller.stream);
    await pumpPage(tester);
    expect(find.byIcon(Icons.check), findsOneWidget);

    when(managers.preferenceManager.targetPalette)
        .thenReturn(TargetPalette.custom);
    controller.add(PreferenceManager.keyTargetPalette);
    await tester.pumpAndSettle();
    expect(
      find.descendant(
          of: paletteTile("Custom"), matching: find.byIcon(Icons.check)),
      findsOneWidget,
    );
    await controller.close();
  });
}
