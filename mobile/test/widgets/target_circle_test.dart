import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/target_color.dart';
import 'package:mobile/widgets/target_circle.dart';
import 'package:mobile/widgets/target_symbol_icon.dart';
import 'package:mockito/mockito.dart';

import '../test_utils/stubbed_managers.dart';
import '../test_utils/test_utils.dart';

void main() {
  late StubbedManagers managers;

  setUp(() {
    managers = StubbedManagers();
  });

  testWidgets("Paints the color's gradient in a circle", (tester) async {
    var color = TargetColor.from(index: 3);
    await pumpContext(tester, (_) => TargetCircle(color));

    var decoration = tester
        .widget<DecoratedBox>(find.byType(DecoratedBox))
        .decoration as BoxDecoration;
    expect(decoration.shape, BoxShape.circle);
    expect(decoration.gradient, TargetColor.gradientFor(color.color));
  });

  testWidgets("Shows no symbol by default", (tester) async {
    await pumpContext(tester, (_) => TargetCircle(TargetColor.from(index: 3)));
    expect(find.byType(TargetSymbolIcon), findsNothing);
  });

  testWidgets("Shows the color's symbol", (tester) async {
    await pumpContext(
      tester,
      (_) => TargetCircle(TargetColor.from(index: 3), showsSymbol: true),
    );
    expect(
      tester.widget<TargetSymbolIcon>(find.byType(TargetSymbolIcon)).index,
      3,
    );
  });

  testWidgets("TargetCircle.raw paints any color with a symbol",
      (tester) async {
    const color = Color(0xFF123456);
    await pumpContext(
        tester, (_) => const TargetCircle.raw(color, symbolIndex: 5));

    var icon = tester.widget<TargetSymbolIcon>(find.byType(TargetSymbolIcon));
    expect(icon.index, 5);
    expect(icon.color, color);
  });

  testWidgets("TargetCircle.slot has no symbol when symbols are off",
      (tester) async {
    await pumpContext(tester, (_) => TargetCircle.slot(2, Colors.red));
    expect(find.byType(TargetSymbolIcon), findsNothing);
  });

  testWidgets("TargetCircle.slot shows the slot's symbol when symbols are on",
      (tester) async {
    when(managers.preferenceManager.isSymbolsOn).thenReturn(true);
    await pumpContext(tester, (_) => TargetCircle.slot(2, Colors.red));
    expect(
      tester.widget<TargetSymbolIcon>(find.byType(TargetSymbolIcon)).index,
      2,
    );
  });
}
