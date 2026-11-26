import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/widgets/target_row.dart';

import '../test_utils/test_utils.dart';

void main() {
  testWidgets("Shows each target in a square of the given size",
      (tester) async {
    await pumpContext(
      tester,
      (_) => const TargetRow(
        [Placeholder(key: ValueKey(1)), Placeholder(key: ValueKey(2))],
        size: 12,
      ),
    );
    expect(find.byType(Placeholder), findsNWidgets(2));
    expect(tester.getSize(find.byKey(const ValueKey(1))), const Size(12, 12));
    expect(tester.getSize(find.byKey(const ValueKey(2))), const Size(12, 12));
  });
}
