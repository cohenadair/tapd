import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/difficulty.dart';
import 'package:mobile/utils/target_utils.dart';
import 'package:mockito/mockito.dart';

import '../test_utils/stubbed_managers.dart';
import '../test_utils/test_utils.dart';

void main() {
  test("targetScrollBackDistance returns the correct distance", () {
    expect(targetScrollBackDistance(1000), 500);
  });

  testWidgets("targetDiameterForRect returns the correct diameter",
      (tester) async {
    var managers = StubbedManagers();
    when(managers.preferenceManager.difficulty).thenReturn(Difficulty.normal);
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(100, 100);

    await pumpContext(tester, (_) => Container());
    expect(targetDiameterForRect(const Rect.fromLTRB(0, 0, 100, 100)), 25);
  });

  testWidgets("targetRadiusForSize returns the correct radius", (tester) async {
    var managers = StubbedManagers();
    when(managers.preferenceManager.difficulty).thenReturn(Difficulty.normal);
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(100, 100);

    await pumpContext(tester, (_) => Container());
    expect(targetRadiusForSize(Vector2(100, 100)), 12.5);
  });

  test("targetBoardSize returns the correct size", () {
    expect(targetBoardSize(Vector2(100, 1000)), Vector2(100, 1750));
  });
}
