import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/widgets/circle_grid.dart';

import '../test_utils/test_utils.dart';

void main() {
  testWidgets("Circles fill evenly spaced columns", (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(400, 800);
    await pumpContext(
      tester,
      (_) => Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 104,
          child: CircleGrid(
            List.generate(4, (index) => SizedBox(key: ValueKey(index))),
            columns: 2,
          ),
        ),
      ),
    );

    // 104 wide, less one gap of 8, in 2 columns.
    expect(tester.getSize(find.byKey(const ValueKey(0))), const Size(48, 48));
    expect(
        tester.getTopLeft(find.byKey(const ValueKey(1))), const Offset(56, 0));
    expect(
        tester.getTopLeft(find.byKey(const ValueKey(2))), const Offset(0, 56));
  });

  testWidgets("Grid isn't padded by the screen's insets", (tester) async {
    tester.view.padding = const FakeViewPadding(bottom: 34);
    addTearDown(tester.view.resetPadding);
    await pumpContext(
      tester,
      (_) => const CircleGrid([SizedBox()], columns: 1),
    );
    expect(tester.widget<GridView>(find.byType(GridView)).padding,
        EdgeInsets.zero);
  });
}
