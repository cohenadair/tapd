import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/target_palette.dart';
import 'package:mobile/target_skin.dart';
import 'package:mobile/target_type.dart';

import 'test_utils/test_utils.dart';

void main() {
  testWidgets("displayName for colors", (tester) async {
    var context = await pumpContext(tester, (_) => const SizedBox());
    expect(TargetType.colors.displayName(context), "Colours");
  });

  testWidgets("displayName for shapes", (tester) async {
    var context = await pumpContext(tester, (_) => const SizedBox());
    expect(TargetType.shapes.displayName(context), "Shapes");
  });

  testWidgets("chooseTitle for colors", (tester) async {
    var context = await pumpContext(tester, (_) => const SizedBox());
    expect(TargetType.colors.chooseTitle(context), "Colour");
  });

  testWidgets("chooseTitle for shapes", (tester) async {
    var context = await pumpContext(tester, (_) => const SizedBox());
    expect(TargetType.shapes.chooseTitle(context), "Shape");
  });

  testWidgets("chooseMessage for colors", (tester) async {
    var context = await pumpContext(tester, (_) => const SizedBox());
    expect(TargetType.colors.chooseMessage(context),
        startsWith("Selecting a colour ensures"));
  });

  testWidgets("chooseMessage for shapes", (tester) async {
    var context = await pumpContext(tester, (_) => const SizedBox());
    expect(TargetType.shapes.chooseMessage(context),
        startsWith("Selecting a shape ensures"));
  });

  test("skin for colors paints the given colors", () {
    expect(
      (TargetType.colors.skin(TargetPalette.colorBlindFriendly.colors!)
              as PaletteSkin)
          .colors,
      TargetPalette.colorBlindFriendly.colors,
    );
  });

  test("skin for shapes draws shapes", () {
    expect(TargetType.shapes.skin(TargetPalette.standard.colors!),
        isA<ShapeSkin>());
  });
}
