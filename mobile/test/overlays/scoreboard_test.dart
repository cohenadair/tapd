import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/tapd_world.dart';
import 'package:mobile/difficulty.dart';
import 'package:mobile/overlays/scoreboard.dart';
import 'package:mobile/target_color.dart';
import 'package:mockito/mockito.dart';

import '../mocks/mocks.mocks.dart';
import '../test_utils/stubbed_managers.dart';
import '../test_utils/test_utils.dart';

void main() {
  late StubbedManagers managers;
  late MockTapdWorld world;
  late MockTapdGame game;

  setUp(() {
    managers = StubbedManagers();
    when(managers.preferenceManager.difficulty).thenReturn(Difficulty.normal);

    world = MockTapdWorld();
    when(world.score).thenReturn(10);
    when(world.scrollingPaused).thenReturn(true);
    when(world.scrollingPaused = any).thenAnswer((_) {});
    when(world.color).thenReturn(TargetColor.random());

    game = MockTapdGame();
    when(game.world).thenReturn(world);
    when(game.size).thenReturn(Vector2(400, 1000));
    when(game.componentsNotifier<TapdWorld>())
        .thenReturn(ComponentsNotifier<TapdWorld>([]));
  });

  testWidgets("State is updated on world changes", (tester) async {
    var notifier = ComponentsNotifier<TapdWorld>([]);
    when(game.componentsNotifier<TapdWorld>()).thenReturn(notifier);

    await pumpContext(tester, (context) => Scoreboard(game));
    verify(game.componentsNotifier<TapdWorld>()).called(2);
    expect(find.text("10"), findsOneWidget);

    when(world.score).thenReturn(20);
    notifier.notifyListeners();
    await tester.pump();

    expect(find.text("20"), findsOneWidget);
  });

  testWidgets("World listener is removed on dispose", (tester) async {
    var notifier = MockComponentsNotifier<TapdWorld>();
    when(game.componentsNotifier<TapdWorld>()).thenReturn(notifier);

    await pumpContext(
      tester,
      (_) => DisposableTester(
        child: Scoreboard(game),
      ),
    );
    verify(notifier.addListener(any)).called(2);

    var state =
        tester.firstState<DisposableTesterState>(find.byType(DisposableTester));
    state.removeChild();
    await tester.pumpAndSettle();
    verify(notifier.removeListener(any)).called(2);
  });

  testWidgets("Pause button follows world pausing itself", (tester) async {
    var notifier = ComponentsNotifier<TapdWorld>([]);
    when(game.componentsNotifier<TapdWorld>()).thenReturn(notifier);

    when(world.scrollingPaused).thenReturn(false);
    await pumpContext(tester, (context) => Scoreboard(game));
    expect(find.byIcon(Icons.pause), findsOneWidget);

    when(world.scrollingPaused).thenReturn(true);
    notifier.notifyListeners();
    await tester.pump();

    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    expect(find.byIcon(Icons.pause), findsNothing);
  });

  testWidgets("Play button is shown", (tester) async {
    when(world.scrollingPaused).thenReturn(true);
    await pumpContext(tester, (context) => Scoreboard(game));
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    expect(find.byIcon(Icons.pause), findsNothing);
  });

  testWidgets("Pause button is shown", (tester) async {
    when(world.scrollingPaused).thenReturn(false);
    await pumpContext(tester, (context) => Scoreboard(game));
    expect(find.byIcon(Icons.play_arrow), findsNothing);
    expect(find.byIcon(Icons.pause), findsOneWidget);
  });

  testWidgets("Play/pause buttons are functional", (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = game.size.toSize();

    when(world.scrollingPaused).thenReturn(true);
    await pumpContext(tester, (context) => Scoreboard(game));

    await tester.tap(find.byIcon(Icons.play_arrow));
    verify(world.scrollingPaused = false).called(1);

    when(world.scrollingPaused).thenReturn(false);
    await tester.pump();

    await tapAndSettle(tester, find.byIcon(Icons.pause));
    verify(world.scrollingPaused = true).called(1);
  });
}
