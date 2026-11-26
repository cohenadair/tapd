import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/target_type.dart';

import 'test_utils/test_utils.dart';

void main() {
  testWidgets("Every target type has a name", (tester) async {
    var context = await pumpContext(tester, (_) => const SizedBox());
    expect(TargetType.colors.displayName(context), "Colours");
    expect(TargetType.shapes.displayName(context), "Shapes");
  });

  testWidgets("Every target type names its choose setting", (tester) async {
    var context = await pumpContext(tester, (_) => const SizedBox());
    expect(TargetType.colors.chooseTitle(context), "Colour");
    expect(TargetType.colors.chooseMessage(context),
        startsWith("Selecting a colour ensures"));
    expect(TargetType.shapes.chooseTitle(context), "Shape");
    expect(TargetType.shapes.chooseMessage(context),
        startsWith("Selecting a shape ensures"));
  });
}
