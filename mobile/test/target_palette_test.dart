import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/target_palette.dart';

import 'test_utils/test_utils.dart';

void main() {
  test("Every preset palette has colorCount colors", () {
    for (var palette in TargetPalette.values) {
      if (palette.colors == null) {
        continue;
      }
      expect(palette.colors!.length, TargetPalette.colorCount);
    }
  });

  test("Custom has no preset colors", () {
    expect(TargetPalette.custom.colors, isNull);
  });

  test("Swatches include every preset color", () {
    for (var color in [
      ...TargetPalette.standard.colors!,
      ...TargetPalette.colorBlindFriendly.colors!,
    ]) {
      expect(TargetPalette.swatches, contains(color));
    }
  });

  testWidgets("Every palette has a name", (tester) async {
    var context = await pumpContext(tester, (_) => const SizedBox());
    expect(TargetPalette.standard.displayName(context), "Default");
    expect(TargetPalette.colorBlindFriendly.displayName(context),
        "Colour-Blind Friendly");
    expect(TargetPalette.custom.displayName(context), "Custom");
  });
}
