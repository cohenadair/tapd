import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/components/target.dart';
import 'package:mobile/difficulty.dart';
import 'package:mobile/target_color.dart';
import 'package:mockito/mockito.dart';

import '../mocks/mocks.mocks.dart';
import '../test_utils/stubbed_managers.dart';

main() {
  late MockTargetBoard board;
  late MockTapdGame game;
  late MockTapdWorld world;
  late StubbedManagers managers;

  setUp(() {
    board = MockTargetBoard();
    when(board.position).thenReturn(NotifyingVector2.zero());
    when(board.parent).thenReturn(World());
    when(board.anchor).thenReturn(Anchor.topLeft);
    when(board.scale).thenReturn(NotifyingVector2.all(1));
    when(board.angle).thenReturn(0);
    world = MockTapdWorld();

    game = MockTapdGame();
    when(game.world).thenReturn(world);
    when(game.size).thenReturn(Vector2(400, 1000));
    when(game.hasLayout).thenReturn(true);

    managers = StubbedManagers();

    when(managers.preferenceManager.difficulty).thenReturn(Difficulty.normal);
    when(managers.preferenceManager.didOnboard).thenReturn(true);
  });

  Target buildTarget() {
    var target = Target(Vector2(0, 0), 50, board);
    target.world = world;
    target.game = game;
    return target;
  }

  void stubDifferentWorldColor(Target target) {
    when(world.color).thenAnswer((_) {
      var color = TargetColor.random();
      while (color == target.color) {
        color = TargetColor.random();
      }
      return color;
    });
  }

  Future<Target> buildLoadedTarget() async {
    WidgetsFlutterBinding.ensureInitialized();
    var target = buildTarget();
    await target.onLoad();
    return target;
  }

  /// Marks [target] as having passed the bottom of the screen.
  void passBottom(Target target) {
    when(managers.preferenceManager.difficulty).thenReturn(Difficulty.veryEasy);
    target.position.y = game.size.y + target.height + 1;
    target.update(0);
  }

  /// Sets up [target] so its next update fades it, which shows whether its
  /// update ran.
  void stubFadeOnUpdate(Target target) {
    when(world.color).thenReturn(target.color);
    target.updateMissTolerance(target.absolutePosition.y - 1);
  }

  test("onLoad paints the target's gradient", () async {
    var target = await buildLoadedTarget();
    expect(target.paint.shader, isNotNull);
    expect(target.paint.color.a, 1);
  });

  test("Targets of the same color and size share a paint", () async {
    var target1 = await buildLoadedTarget();
    var target2 = await buildLoadedTarget();
    while (target2.color != target1.color) {
      target2.reset();
    }
    expect(target2.paint, same(target1.paint));
  });

  test("Paints are rebuilt when the target size changes", () async {
    var target1 = await buildLoadedTarget();
    var target2 = Target(Vector2(0, 0), 30, board)
      ..world = world
      ..game = game;
    await target2.onLoad();
    while (target2.color != target1.color) {
      target2.reset();
    }
    expect(target2.paint, isNot(same(target1.paint)));
  });

  test("render draws a circle", () async {
    var target = await buildLoadedTarget();
    var canvas = MockCanvas();
    target.render(canvas);
    verify(canvas.drawCircle(const Offset(50, 50), 48.5, target.paint))
        .called(1);
  });

  test("renderTree skips a target above the screen", () async {
    var target = await buildLoadedTarget();
    target.position.y = -target.height - 1;
    var canvas = MockCanvas();
    target.renderTree(canvas);
    verifyNever(canvas.drawCircle(any, any, any));
  });

  test("renderTree skips a target below the screen", () async {
    var target = await buildLoadedTarget();
    target.position.y = game.size.y + target.height + 1;
    var canvas = MockCanvas();
    target.renderTree(canvas);
    verifyNever(canvas.drawCircle(any, any, any));
  });

  test("renderTree draws a target on the screen", () async {
    var target = await buildLoadedTarget();
    target.position.y = game.size.y / 2;
    var canvas = MockCanvas();
    target.renderTree(canvas);
    verify(canvas.drawCircle(any, any, any)).called(1);
  });

  test("renderTree uses the board's position", () async {
    when(board.position).thenReturn(NotifyingVector2(0, -2000));
    var target = await buildLoadedTarget();
    target.position.y = game.size.y / 2;
    var canvas = MockCanvas();
    target.renderTree(canvas);
    verifyNever(canvas.drawCircle(any, any, any));
  });

  test("updateTree skips a target above the screen", () async {
    var target = await buildLoadedTarget();
    stubFadeOnUpdate(target);
    target.position.y = -target.height - 1;
    target.updateTree(0);
    expect(target.opacity, 1);
  });

  test("updateTree skips a target below the screen that passed the bottom",
      () async {
    var target = await buildLoadedTarget();
    passBottom(target);
    stubFadeOnUpdate(target);
    target.updateTree(0);
    expect(target.opacity, 1);
  });

  test("updateTree updates a target that passed the bottom if it's visible",
      () async {
    var target = await buildLoadedTarget();
    passBottom(target);
    stubFadeOnUpdate(target);
    target.position.y = game.size.y / 2;
    target.updateTree(0);
    expect(target.opacity, closeTo(0.5, 0.01));
  });

  test("updateTree updates a target below the screen that hasn't passed",
      () async {
    var target = await buildLoadedTarget();
    target.position.y = game.size.y + target.height + 1;
    when(world.color).thenReturn(target.color);
    when(world.scrollingPaused).thenReturn(false);
    target.updateTree(0);
    verify(world.handleTargetMissed(any, any)).called(1);
  });

  test("onTapDown is a no-op when paused", () {
    when(world.scrollingPaused).thenReturn(true);

    var target = buildTarget();
    target.onTapDown(MockTapDownEvent());
    verifyNever(world.color);
  });

  test("onTapDown is a no-op if already hit", () {
    var target = buildTarget();
    when(world.scrollingPaused).thenReturn(false);
    when(world.color).thenReturn(target.color);
    when(world.handleTargetHit(isCorrect: anyNamed("isCorrect")))
        .thenAnswer((_) {});

    // Initial hit.
    target.onTapDown(MockTapDownEvent());
    verify(world.color).called(1);

    // Next hit.
    target.onTapDown(MockTapDownEvent());
    verifyNever(world.color);
  });

  test("onTapDown is a no-op if user isn't onboarded", () {
    when(managers.preferenceManager.didOnboard).thenReturn(false);

    var target = buildTarget();
    when(world.scrollingPaused).thenReturn(false);
    when(world.color).thenReturn(target.color);
    when(world.handleTargetHit(isCorrect: anyNamed("isCorrect")))
        .thenAnswer((_) {});

    target.onTapDown(MockTapDownEvent());
    verifyNever(world.color);
  });

  test("Correct hit", () {
    var target = buildTarget();
    when(world.scrollingPaused).thenReturn(false);
    when(world.color).thenReturn(target.color);
    when(world.handleTargetHit(isCorrect: anyNamed("isCorrect")))
        .thenAnswer((_) {});

    target.onTapDown(MockTapDownEvent());
    var result =
        verify(world.handleTargetHit(isCorrect: captureAnyNamed("isCorrect")));
    result.called(1);
    expect(result.captured.first, true);
  });

  test("Incorrect hit", () {
    var target = buildTarget();
    stubDifferentWorldColor(target);
    when(world.scrollingPaused).thenReturn(false);
    when(world.handleTargetHit(isCorrect: anyNamed("isCorrect")))
        .thenAnswer((_) {});
    when(board.priority = any).thenAnswer((_) {});
    when(world.scrollingPaused = any).thenAnswer((_) {});

    // Verify updated state.
    target.onTapDown(MockTapDownEvent());
    expect(target.priority, 1);

    var result = verify(board.priority = captureAny);
    result.called(1);
    expect(result.captured.first, 1);

    result = verify(world.scrollingPaused = captureAny);
    result.called(1);
    expect(result.captured.first, true);

    // Trigger pulse animation completion and verify state is reset.
    expect(target.children.last is ScaleEffect, isTrue);
    (target.children.last as ScaleEffect).onComplete?.call();

    expect(target.priority, 0);

    result = verify(board.priority = captureAny);
    result.called(1);
    expect(result.captured.first, 0);

    result =
        verify(world.handleTargetHit(isCorrect: captureAnyNamed("isCorrect")));
    result.called(1);
    expect(result.captured.first, false);

    verify(managers.audioManager.playIncorrectHit()).called(1);
  });

  test("update is a no-op if passed the bottom of the screen", () {
    var target = buildTarget();
    target.position.y = game.size.y + target.height + 1;

    when(world.color).thenReturn(target.color);
    when(world.scrollingPaused).thenReturn(false);

    // Initial update to set _isPassedBottom to true.
    target.update(0);
    verify(world.handleTargetMissed(any, any)).called(1);

    // Next update that exits early.
    target.update(0);
    verifyNever(world.handleTargetMissed(any, any));
  });

  test("update is a no-op when still on the screen", () {
    buildTarget().update(0);
    verifyNever(world.handleTargetMissed(any, any));
  });

  test("update is a no-op if the difficulty allows missed targets", () {
    when(managers.preferenceManager.difficulty).thenReturn(Difficulty.veryEasy);

    var target = buildTarget();
    target.position.y = game.size.y + target.height + 1;
    target.update(0);
    verifyNever(world.handleTargetMissed(any, any));
  });

  test("update is a no-op if color doesn't match", () {
    var target = buildTarget();
    target.position.y = game.size.y + target.height + 1;

    stubDifferentWorldColor(target);

    target.update(0);
    verify(world.color).called(1);
    verifyNever(world.scrollingPaused);
    verifyNever(world.handleTargetMissed(any, any));
  });

  test("update is a no-op if already hit", () {
    var target = buildTarget();
    target.position.y = game.size.y + target.height + 1;

    when(world.color).thenReturn(target.color);
    when(world.scrollingPaused).thenReturn(false);

    // Mark target as hit.
    target.onTapDown(MockTapDownEvent());
    var result =
        verify(world.handleTargetHit(isCorrect: captureAnyNamed("isCorrect")));
    result.called(1);
    expect(result.captured.first, true);
    verify(world.scrollingPaused).called(1);
    verify(world.color).called(1);

    // Verify early exit.
    target.update(0);
    verify(world.color).called(1);
    verifyNever(world.scrollingPaused);
    verifyNever(world.handleTargetMissed(any, any));
  });

  test("update is a no-op if scrolling is paused", () {
    var target = buildTarget();
    target.position.y = game.size.y + target.height + 1;

    when(world.color).thenReturn(target.color);
    when(world.scrollingPaused).thenReturn(true);

    // Verify early exit.
    target.update(0);
    verify(world.scrollingPaused).called(1);
    verifyNever(world.handleTargetMissed(any, any));
  });

  test("update handles target missed", () {
    var target = buildTarget();
    target.position.y = game.size.y + target.height + 1;

    when(world.color).thenReturn(target.color);
    when(world.scrollingPaused).thenReturn(false);

    // Verify early exit.
    target.update(0);
    verify(world.handleTargetMissed(any, any)).called(1);
  });

  test("update is a no-op if the miss is tolerated", () {
    var target = buildTarget();
    target.updateMissTolerance(target.absolutePosition.y - 1);
    target.position.y = game.size.y + target.height + 1;

    when(world.color).thenReturn(target.color);
    when(world.scrollingPaused).thenReturn(false);

    target.update(0);
    verifyNever(world.handleTargetMissed(any, any));
  });

  test("updateMissTolerance revokes tolerance for a target above y", () {
    var target = buildTarget();
    target.updateMissTolerance(target.absolutePosition.y - 1);
    target.updateMissTolerance(target.absolutePosition.y + 1);
    target.position.y = game.size.y + target.height + 1;

    when(world.color).thenReturn(target.color);
    when(world.scrollingPaused).thenReturn(false);

    target.update(0);
    verify(world.handleTargetMissed(any, any)).called(1);
  });

  test("Tolerated target matching the current color is faded", () async {
    var target = await buildLoadedTarget();
    when(world.color).thenReturn(target.color);

    target.updateMissTolerance(target.absolutePosition.y - 1);
    target.update(0);
    expect(target.opacity, closeTo(0.5, 0.01));
  });

  test("Tolerated target of another color isn't faded", () async {
    var target = await buildLoadedTarget();
    stubDifferentWorldColor(target);

    target.updateMissTolerance(target.absolutePosition.y - 1);
    target.update(0);
    expect(target.opacity, 1);
  });

  test("Faded target is restored when the current color changes", () async {
    var target = await buildLoadedTarget();
    when(world.color).thenReturn(target.color);
    target.updateMissTolerance(target.absolutePosition.y - 1);
    target.update(0);
    expect(target.opacity, closeTo(0.5, 0.01));

    stubDifferentWorldColor(target);
    target.update(0);
    expect(target.opacity, 1);
  });

  test("reset clears miss tolerance and fading", () async {
    var target = await buildLoadedTarget();
    when(world.color).thenAnswer((_) => target.color);
    when(world.scrollingPaused).thenReturn(false);
    target.updateMissTolerance(target.absolutePosition.y - 1);
    target.update(0);
    expect(target.opacity, closeTo(0.5, 0.01));

    target.reset();
    expect(target.opacity, 1);

    target.position.y = game.size.y + target.height + 1;
    target.update(0);
    verify(world.handleTargetMissed(any, any)).called(1);
  });

  test("reset", () async {
    WidgetsFlutterBinding.ensureInitialized();
    var target = buildTarget();

    when(world.color).thenReturn(target.color);
    when(world.scrollingPaused).thenReturn(false);

    // Mark target as hit.
    target.onTapDown(MockTapDownEvent());
    var result =
        verify(world.handleTargetHit(isCorrect: captureAnyNamed("isCorrect")));
    result.called(1);
    expect(result.captured.first, true);

    expect(target.children.whereType<ScaleEffect>(), isNotEmpty);
    target.scale.setValues(0.2, 0.2);

    target.reset();
    expect(target.children.whereType<ScaleEffect>(), isEmpty);
    expect(target.scale, Vector2.all(1));
  });

  test("reset leaves an incorrect hit pulse to finish", () {
    when(world.scrollingPaused = any).thenAnswer((_) {});
    when(board.priority = any).thenAnswer((_) {});
    var target = buildTarget();

    target.pulse();
    var pulse = target.children.whereType<ScaleEffect>().single;

    target.reset();
    expect(target.children, contains(pulse));
  });

  test("pulse", () {
    when(world.scrollingPaused = any).thenAnswer((_) {});
    var target = buildTarget();
    target.pulse();
    verify(world.scrollingPaused = any).called(1);
  });

  test("resetIfEndedRun resets a target that ended the run", () {
    var target = buildTarget();
    stubDifferentWorldColor(target);
    when(world.scrollingPaused).thenReturn(false);
    when(world.scrollingPaused = any).thenAnswer((_) {});
    when(board.priority = any).thenAnswer((_) {});
    target.onTapDown(MockTapDownEvent());

    expect(target.endedRun, isTrue);

    target.resetIfEndedRun();
    expect(target.endedRun, isFalse);
  });

  test("resetIfEndedRun is a no-op if the target didn't end the run", () async {
    var target = await buildLoadedTarget();
    var paint = target.paint;
    target.resetIfEndedRun();
    expect(target.paint, same(paint));
  });
}
