import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/widgets/selectable_target_circle.dart';
import 'package:mobile/widgets/target_circle.dart';

import '../test_utils/test_utils.dart';

void main() {
  Color border(WidgetTester tester) =>
      (tester.widget<Container>(find.byType(Container)).decoration
              as BoxDecoration)
          .border!
          .top
          .color;

  testWidgets("Selected circle has a border", (tester) async {
    var context = await pumpContext(
      tester,
      (_) => const SelectableTargetCircle(
        TargetCircle.raw(Colors.red),
        size: 30,
        isSelected: true,
      ),
    );
    expect(border(tester), Theme.of(context).colorScheme.primary);
  });

  testWidgets("Unselected circle has a transparent border", (tester) async {
    await pumpContext(
      tester,
      (_) => const SelectableTargetCircle(
        TargetCircle.raw(Colors.red),
        size: 30,
        isSelected: false,
      ),
    );
    expect(border(tester), Colors.transparent);
  });

  testWidgets("Tapping calls onTap", (tester) async {
    var isTapped = false;
    await pumpContext(
      tester,
      (_) => SelectableTargetCircle(
        const TargetCircle.raw(Colors.red),
        size: 30,
        isSelected: false,
        onTap: () => isTapped = true,
      ),
    );
    await tapAndSettle(tester, find.byType(SelectableTargetCircle));
    expect(isTapped, isTrue);
  });
}
