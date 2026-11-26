import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/widgets/target_circle.dart';
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
          .widgetList<TargetCircle>(find.byType(TargetCircle))
          .map((e) => e.color),
      [Colors.red, Colors.blue],
    );
    expect(tester.getSize(find.byType(TargetCircle).first), const Size(12, 12));
  });
}
