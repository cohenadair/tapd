import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/components/miss_tolerance_line.dart';
import 'package:mobile/difficulty.dart';
import 'package:mobile/target_color.dart';
import 'package:mobile/target_palette.dart';
import 'package:mockito/mockito.dart';

import '../mocks/mocks.mocks.dart';
import '../test_utils/stubbed_managers.dart';

void main() {
  late MockTapdGame game;
  late StubbedManagers managers;

  setUp(() {
    managers = StubbedManagers();
    when(managers.preferenceManager.difficulty).thenReturn(Difficulty.normal);

    game = MockTapdGame();
    when(game.size).thenReturn(Vector2(400, 1000));
  });

  PositionComponent buildParentWithLine(double y) {
    var line = MissToleranceLine(
      color: TargetColor.from(index: 0),
      width: 400,
      y: y,
    );
    var parent = PositionComponent()..add(line);
    // Set after adding, so the line isn't loaded as if it were in a game.
    line.game = game;
    return parent;
  }

  test("update keeps the line while it's on the screen", () {
    var parent = buildParentWithLine(1000);
    parent.children.whereType<MissToleranceLine>().first.update(0);
    expect(parent.children.whereType<MissToleranceLine>().length, 1);
  });

  test("update removes the line once it's below the screen", () {
    var parent = buildParentWithLine(1001);
    parent.children.whereType<MissToleranceLine>().first.update(0);
    expect(parent.children.whereType<MissToleranceLine>().length, 0);
  });

  test("updateAppearance repaints with the current palette", () {
    var line = MissToleranceLine(
      color: TargetColor.from(index: 0),
      width: 400,
      y: 0,
    );
    expect(line.paint.color, isSameColorAs(TargetPalette.standard.colors![0]));

    when(managers.preferenceManager.targetColors)
        .thenReturn(TargetPalette.colorBlindFriendly.colors!);
    line.updateAppearance();
    expect(line.paint.color,
        isSameColorAs(TargetPalette.colorBlindFriendly.colors![0]));
  });
}
