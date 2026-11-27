import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/widgets/color_circle.dart';
import 'package:mobile/widgets/selectable_circle.dart';

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
      (_) => const SelectableCircle(
        ColorCircle(Colors.red),
        size: 30,
        isSelected: true,
      ),
    );
    expect(
        border(tester), isSameColorAs(Theme.of(context).colorScheme.primary));
  });

  testWidgets("Unselected circle has a transparent border", (tester) async {
    await pumpContext(
      tester,
      (_) => const SelectableCircle(
        ColorCircle(Colors.red),
        size: 30,
        isSelected: false,
      ),
    );
    expect(border(tester), isSameColorAs(Colors.transparent));
  });

  testWidgets("Circle fills its parent without a size", (tester) async {
    await pumpContext(
      tester,
      (_) => const Center(
        child: SizedBox(
          width: 50,
          height: 50,
          child: SelectableCircle(
            ColorCircle(Colors.red),
            isSelected: false,
          ),
        ),
      ),
    );
    expect(tester.getSize(find.byType(Container)), const Size(50, 50));
  });

  testWidgets("Tapping calls onTap", (tester) async {
    var isTapped = false;
    await pumpContext(
      tester,
      (_) => SelectableCircle(
        const ColorCircle(Colors.red),
        size: 30,
        isSelected: false,
        onTap: () => isTapped = true,
      ),
    );
    await tapAndSettle(tester, find.byType(SelectableCircle));
    expect(isTapped, isTrue);
  });
}
