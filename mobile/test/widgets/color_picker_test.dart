import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/difficulty.dart';
import 'package:mobile/target_color.dart';
import 'package:mobile/utils/style.dart';
import 'package:mobile/widgets/color_picker.dart';
import 'package:mockito/mockito.dart';

import '../test_utils/stubbed_managers.dart';
import '../test_utils/test_utils.dart';

void main() {
  late StubbedManagers managers;

  setUp(() {
    managers = StubbedManagers();

    when(managers.preferenceManager.stream)
        .thenAnswer((_) => const Stream.empty());
    when(managers.preferenceManager.difficulty).thenReturn(Difficulty.veryEasy);
    when(managers.preferenceManager.colorIndex).thenReturn(null);
  });

  Finder findCircles() {
    return find.byWidgetPredicate((widget) =>
        widget is Container &&
        (widget.decoration as BoxDecoration).shape == BoxShape.circle);
  }

  testWidgets("Picker is disabled", (tester) async {
    when(managers.preferenceManager.difficulty).thenReturn(Difficulty.normal);
    await pumpContext(tester, (_) => ColorPicker());

    expect(
      tester.firstWidget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
      opacityDisabled,
    );
  });

  testWidgets("Picker is enabled", (tester) async {
    when(managers.preferenceManager.difficulty).thenReturn(Difficulty.veryEasy);
    await pumpContext(tester, (_) => ColorPicker());

    expect(
      tester.firstWidget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
      1.0,
    );
  });

  testWidgets("Picker shows selected color", (tester) async {
    when(managers.preferenceManager.colorIndex).thenReturn(2); // Yellow.
    var context = await pumpContext(tester, (_) => ColorPicker());

    var colors = tester
        .widgetList<Container>(find.byWidgetPredicate((widget) =>
            widget is Container &&
            widget.constraints?.minWidth == 30 &&
            widget.constraints?.minHeight == 30))
        .toList();
    expect(colors.length, 4);
    expect(
      (colors[1].decoration as BoxDecoration).border!.bottom.color,
      Theme.of(context).colorScheme.primary,
    );
  });

  testWidgets("Picker shows no selected color when preferences is null",
      (tester) async {
    when(managers.preferenceManager.colorIndex).thenReturn(null);
    await pumpContext(tester, (_) => ColorPicker());

    var colors = tester
        .widgetList<Container>(find.byWidgetPredicate((widget) =>
            widget is Container &&
            widget.constraints?.minWidth == 30 &&
            widget.constraints?.minHeight == 30))
        .toList();
    expect(colors.length, 4);

    // No check icons are visible.
    for (var widget in colors.sublist(1)) {
      expect(
        (widget.decoration as BoxDecoration).border!.bottom.color,
        Colors.transparent,
      );
    }
  });

  testWidgets("All expected colors are shown", (tester) async {
    await pumpContext(tester, (_) => ColorPicker());
    expect(findCircles(), findsNWidgets(TargetColor.veryEasy().length));
  });

  testWidgets("Picking a color updates preferences", (tester) async {
    when(managers.preferenceManager.colorIndex).thenReturn(null);
    await pumpContext(tester, (_) => ColorPicker());

    // Select.
    await tapAndSettle(tester, findCircles().first);
    var result = verify(managers.preferenceManager.colorIndex = captureAny);
    result.called(1);
    expect(result.captured.first, 0);
  });

  testWidgets("Picking a color sets preferences to null", (tester) async {
    when(managers.preferenceManager.colorIndex).thenReturn(0);
    await pumpContext(tester, (_) => ColorPicker());

    // Deselect.
    await tapAndSettle(tester, findCircles().first);
    var result = verify(managers.preferenceManager.colorIndex = captureAny);
    result.called(1);
    expect(result.captured.first, isNull);
  });

  testWidgets("Picker updates when preferences updates", (tester) async {
    var controller = StreamController<String>.broadcast();
    when(managers.preferenceManager.stream)
        .thenAnswer((_) => controller.stream);

    await pumpContext(tester, (_) => ColorPicker());

    // Verify enabled.
    expect(
      tester.firstWidget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
      1.0,
    );

    when(managers.preferenceManager.difficulty).thenReturn(Difficulty.normal);
    controller.add("");
    await tester.pump(const Duration(milliseconds: 500));

    // Verify disabled.
    expect(
      tester.firstWidget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
      opacityDisabled,
    );
  });
}
