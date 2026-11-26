import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/widgets/target_symbol_icon.dart';

import '../test_utils/test_utils.dart';

void main() {
  CustomPainter painter(WidgetTester tester) => tester
      .widget<CustomPaint>(find.descendant(
        of: find.byType(TargetSymbolIcon),
        matching: find.byType(CustomPaint),
      ))
      .painter!;

  testWidgets("Paints the symbol", (tester) async {
    await pumpContext(
      tester,
      (_) => const SizedBox(
        width: 40,
        height: 40,
        child: TargetSymbolIcon(index: 1, color: Colors.yellow),
      ),
    );
    expect(painter(tester), isNotNull);
  });

  testWidgets("Repaints only when the symbol or color changes", (tester) async {
    await pumpContext(
        tester, (_) => const TargetSymbolIcon(index: 1, color: Colors.yellow));
    var original = painter(tester);

    await pumpContext(
        tester, (_) => const TargetSymbolIcon(index: 1, color: Colors.yellow));
    expect(painter(tester).shouldRepaint(original), isFalse);

    await pumpContext(
        tester, (_) => const TargetSymbolIcon(index: 2, color: Colors.yellow));
    expect(painter(tester).shouldRepaint(original), isTrue);

    await pumpContext(
        tester, (_) => const TargetSymbolIcon(index: 1, color: Colors.blue));
    expect(painter(tester).shouldRepaint(original), isTrue);
  });
}
