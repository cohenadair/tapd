import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/widgets/target_symbol_icon.dart';
import 'package:mockito/mockito.dart';

import '../mocks/mocks.mocks.dart';
import '../test_utils/stubbed_managers.dart';
import '../test_utils/test_utils.dart';

void main() {
  late StubbedManagers managers;
  late MockTargetSkin skin;

  setUp(() {
    managers = StubbedManagers();

    skin = MockTargetSkin();
    when(managers.preferenceManager.targetSkin).thenReturn(skin);
  });

  CustomPainter painter(WidgetTester tester) => tester
      .widget<CustomPaint>(find.descendant(
        of: find.byType(TargetSymbolIcon),
        matching: find.byType(CustomPaint),
      ))
      .painter!;

  Future<void> pumpIcon(WidgetTester tester, int index) => pumpContext(
        tester,
        (_) => Center(
          child:
              SizedBox(width: 40, height: 40, child: TargetSymbolIcon(index)),
        ),
      );

  testWidgets("Paints the slot's symbol with the player's skin",
      (tester) async {
    await pumpIcon(tester, 1);
    verify(skin.paintSymbol(
      any,
      index: 1,
      center: const Offset(20, 20),
      radius: 20,
    )).called(1);
  });

  testWidgets("Repaints only when the skin or slot changes", (tester) async {
    await pumpIcon(tester, 1);
    var original = painter(tester);

    await pumpIcon(tester, 1);
    expect(painter(tester).shouldRepaint(original), isFalse);

    await pumpIcon(tester, 2);
    expect(painter(tester).shouldRepaint(original), isTrue);

    when(managers.preferenceManager.targetSkin).thenReturn(MockTargetSkin());
    await pumpIcon(tester, 1);
    expect(painter(tester).shouldRepaint(original), isTrue);
  });
}
