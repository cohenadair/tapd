import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/widgets/color_circle.dart';
import 'package:mobile/widgets/target_color_row.dart';

import '../test_utils/test_utils.dart';

void main() {
  testWidgets("Shows a sized circle for each color", (tester) async {
    await pumpContext(
      tester,
      (_) => const TargetColorRow([Colors.red, Colors.blue], size: 12),
    );
    expect(
      tester
          .widgetList<ColorCircle>(find.byType(ColorCircle))
          .map((e) => e.color),
      [Colors.red, Colors.blue],
    );
    expect(tester.getSize(find.byType(ColorCircle).first), const Size(12, 12));
  });
}
