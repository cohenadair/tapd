import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/target_color.dart';
import 'package:mobile/widgets/color_circle.dart';

import '../test_utils/test_utils.dart';

void main() {
  testWidgets("Paints the color's gradient in a circle", (tester) async {
    const color = Color(0xFF123456);
    await pumpContext(tester, (_) => const ColorCircle(color));

    var decoration = tester
        .widget<DecoratedBox>(find.byType(DecoratedBox))
        .decoration as BoxDecoration;
    expect(decoration.shape, BoxShape.circle);
    expect(decoration.gradient, TargetColor.gradientFor(color));
  });
}
