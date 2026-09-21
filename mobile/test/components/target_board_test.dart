import 'dart:async';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/components/target.dart';
import 'package:mobile/components/target_board.dart';
import 'package:mobile/difficulty.dart';
import 'package:mobile/managers/preference_manager.dart';
import 'package:mobile/utils/target_utils.dart';
import 'package:mockito/mockito.dart';

import '../mocks/mocks.mocks.dart';
import '../test_utils/stubbed_managers.dart';

main() {
  late StubbedManagers managers;
  late MockTapdGame game;
  late MockTapdWorld world;

  const width = 400.0;
  const height = 1000.0;

  setUp(() async {
    managers = StubbedManagers();
    when(managers.preferenceManager.difficulty).thenReturn(Difficulty.normal);

    world = MockTapdWorld();
    when(world.speed).thenReturn(1.0);

    game = MockTapdGame();
    when(game.world).thenReturn(world);
    when(game.size).thenReturn(Vector2(width, height));
    when(game.hasLayout).thenReturn(true);
  });

  TargetBoard buildBoard({
    Color? backgroundColor,
    bool isUpdater = true,
  }) {
    var board = TargetBoard(
      otherBoardKey: ComponentKey.unique(),
      verticalStartFactor: 1,
      backgroundColor: backgroundColor,
      isUpdater: isUpdater,
    );
    board.game = game;
    board.world = world;
    return board;
  }

  void stubScreenSize(WidgetTester tester) {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(100, 100);
  }

  testWidgets("onLoad", (tester) async {
    stubScreenSize(tester);

    var board = buildBoard();
    board.onLoad();

    // Height * targetBoardHeightFactor.
    expect(board.position.y, -1800);
    expect(board.children.whereType<Target>().length, 72);
  });

  testWidgets("Update is no-op when paused", (tester) async {
    stubScreenSize(tester);
    when(world.scrollingPaused).thenReturn(true);

    var board = buildBoard();
    var expectedPos = board.position;

    board.update(0);
    expect(board.position, expectedPos);
  });

  testWidgets("Update is no-op when isUpdater is false", (tester) async {
    stubScreenSize(tester);
    when(world.scrollingPaused).thenReturn(false);

    var board = buildBoard(isUpdater: false);
    var expectedPos = board.position;

    board.update(0);
    expect(board.position, expectedPos);
  });

  testWidgets("Update resets to top position", (tester) async {
    stubScreenSize(tester);
    when(world.scrollingPaused).thenReturn(false);

    var otherBoard = TargetBoard(
      otherBoardKey: ComponentKey.unique(),
      verticalStartFactor: 0,
      isUpdater: true,
    );
    otherBoard.position = Vector2(0, -1000);
    when(game.findByKey(any)).thenReturn(otherBoard);

    var board = buildBoard();
    board.onLoad();

    board.position = Vector2(board.x, targetBoardSize(game.size).y);
    board.update(1 / 60);
    expect(board.position.y, -2799);
  });

  testWidgets("Update scrolls down", (tester) async {
    stubScreenSize(tester);
    when(world.scrollingPaused).thenReturn(false);
    when(world.speed).thenReturn(2.0);
    when(game.findByKey(any)).thenReturn(buildBoard());

    var board = buildBoard();
    board.onLoad();
    var startY = board.position.y;

    board.update(1 / 60);
    expect(board.position.y, startY + 2);

    board.update(1 / 60);
    expect(board.position.y, startY + 4);

    board.update(1 / 60);
    expect(board.position.y, startY + 6);
  });

  testWidgets("Update scrolls down 120 FPS", (tester) async {
    stubScreenSize(tester);
    when(world.scrollingPaused).thenReturn(false);
    when(world.speed).thenReturn(2.0);
    when(game.findByKey(any)).thenReturn(buildBoard());

    var board = buildBoard();
    board.onLoad();
    var startY = board.position.y;

    // Changes in y position for 120 FPS should be 0.5 * 60 FPS.
    board.update(1 / 120);
    expect(board.position.y, startY + 1);

    board.update(1 / 120);
    expect(board.position.y, startY + 2);

    board.update(1 / 120);
    expect(board.position.y, startY + 3);
  });

  testWidgets("Reset", (tester) async {
    stubScreenSize(tester);
    when(world.scrollingPaused).thenReturn(false);
    when(world.speed).thenReturn(2.0);
    when(game.findByKey(any)).thenReturn(buildBoard());

    var board = buildBoard();
    board.onLoad();
    var startY = board.position.y;
    var startChildren = board.children.length;

    board.update(1 / 60);
    expect(board.position.y, startY + 2);

    board.resetForNewGame();
    expect(board.position.y, startY);
    expect(board.children.length, startChildren);
  });

  testWidgets("Board is reset when difficulty changes", (tester) async {
    stubScreenSize(tester);
    when(managers.preferenceManager.difficulty).thenReturn(Difficulty.veryEasy);
    when(world.scrollingPaused).thenReturn(false);
    when(world.speed).thenReturn(2.0);
    when(game.findByKey(any)).thenReturn(buildBoard());

    var controller = StreamController<String>.broadcast();
    when(managers.preferenceManager.stream)
        .thenAnswer((_) => controller.stream);

    var board = buildBoard();
    board.onLoad();
    var startY = board.position.y;
    var startHeight = board.height;

    // Verify listener was added.
    expect(controller.hasListener, isTrue);

    // Move the board a little.
    board.update(1 / 60);
    expect(board.position.y, startY + 2);

    // Fire preferences event that isn't a difficulty change.
    controller.add(PreferenceManager.keyMusicOn);
    await tester.pump(const Duration(seconds: 1)); // Streams are async.
    expect(board.position.y, startY + 2);

    // Change difficulty to one that requires a board size change.
    when(managers.preferenceManager.difficulty).thenReturn(Difficulty.hard);
    // Verify reset.
    controller.add(PreferenceManager.keyDifficulty);
    await tester.pump(const Duration(seconds: 1)); // Streams are async.
    expect(board.position.y, -board.size.y);
    expect(board.children.length, greaterThan(0));
    expect(startHeight == board.height, isFalse);

    // Verify stream sub is cancelled.
    board.onRemove();
    expect(controller.hasListener, isFalse);
  });

  testWidgets("Board is reset on orientation change", (tester) async {
    stubScreenSize(tester);
    when(managers.preferenceManager.difficulty).thenReturn(Difficulty.veryEasy);
    when(world.scrollingPaused).thenReturn(false);
    when(world.speed).thenReturn(2.0);
    when(game.findByKey(any)).thenReturn(buildBoard());

    var controller = StreamController<void>.broadcast();
    when(managers.orientationManager.stream)
        .thenAnswer((_) => controller.stream);

    var board = buildBoard();
    board.onLoad();
    var startY = board.position.y;
    var startHeight = board.height;

    // Verify listener was added.
    expect(controller.hasListener, isTrue);

    // Move the board a little.
    board.update(1 / 60);
    expect(board.position.y, startY + 2);

    // Change difficulty to one that requires a board size change.
    when(managers.preferenceManager.difficulty).thenReturn(Difficulty.hard);
    // Verify reset.
    controller.add(null);
    await tester.pump(const Duration(seconds: 1)); // Streams are async.
    expect(board.position.y, -board.size.y);
    expect(board.children.length, greaterThan(0));
    expect(startHeight == board.height, isFalse);

    // Verify stream sub is cancelled.
    board.onRemove();
    expect(controller.hasListener, isFalse);
  });

  testWidgets("Renders background", (tester) async {
    stubScreenSize(tester);
    when(world.scrollingPaused).thenReturn(false);
    when(world.speed).thenReturn(2.0);
    when(game.findByKey(any)).thenReturn(buildBoard());

    var mockCanvas = MockCanvas();
    var board = buildBoard(
      backgroundColor: Colors.red,
    );
    board.render(mockCanvas);

    var result = verify(mockCanvas.drawRect(any, captureAny));
    result.called(1);
    expect(
      (result.captured.first as Paint).color,
      (Paint()..color = Colors.red).color,
    );
  });

  testWidgets("Only one target has a key value", (tester) async {
    stubScreenSize(tester);
    when(world.scrollingPaused).thenReturn(false);
    when(world.speed).thenReturn(2.0);
    when(game.findByKey(any)).thenReturn(buildBoard());

    var board = buildBoard();
    board.onLoad();

    var targetsWithKey = 0;
    for (var child in board.children) {
      targetsWithKey += child is Target && child.key != null ? 1 : 0;
    }
    expect(targetsWithKey, 1);
  });
}
