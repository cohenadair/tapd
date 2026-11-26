import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/target_symbol_set.dart';

import 'test_utils/test_utils.dart';

void main() {
  testWidgets("Every symbol set has a name and description", (tester) async {
    var context = await pumpContext(tester, (_) => const SizedBox());
    expect(TargetSymbolSet.none.displayName(context), "None");
    expect(
        TargetSymbolSet.none.description(context), "Plain coloured targets.");
    expect(TargetSymbolSet.shapes.displayName(context), "Shapes");
    expect(TargetSymbolSet.shapes.description(context),
        "A different shape on each target colour.");
  });
}
