import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/widgets/target_circle.dart';
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
        of: find.byType(TargetCircle),
        matching: find.byType(CustomPaint),
      ))
      .painter!;

  Future<void> pumpCircle(WidgetTester tester, TargetCircle circle) =>
      pumpContext(
        tester,
        (_) => Center(child: SizedBox(width: 40, height: 40, child: circle)),
      );

  testWidgets("Paints the slot with the player's skin", (tester) async {
    await pumpCircle(tester, TargetCircle(3));
    verify(skin.paint(
      any,
      index: 3,
      center: const Offset(20, 20),
      radius: 20,
    )).called(1);
  });

  testWidgets("Repaints only when the skin or slot changes", (tester) async {
    await pumpCircle(tester, TargetCircle(1));
    var original = painter(tester);

    await pumpCircle(tester, TargetCircle(1));
    expect(painter(tester).shouldRepaint(original), isFalse);

    await pumpCircle(tester, TargetCircle(2));
    expect(painter(tester).shouldRepaint(original), isTrue);

    when(managers.preferenceManager.targetSkin).thenReturn(MockTargetSkin());
    await pumpCircle(tester, TargetCircle(1));
    expect(painter(tester).shouldRepaint(original), isTrue);
  });
}
