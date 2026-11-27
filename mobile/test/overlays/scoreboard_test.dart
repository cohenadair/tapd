import 'dart:async';

import 'package:adair_flutter_lib/res/style.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/difficulty.dart';
import 'package:mobile/managers/preference_manager.dart';
import 'package:mobile/overlays/scoreboard.dart';
import 'package:mobile/tapd_world.dart';
import 'package:mobile/target_color.dart';
import 'package:mobile/utils/colors.dart';
import 'package:mobile/utils/keys.dart';
import 'package:mobile/widgets/target_circle.dart';
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
    when(world.fps).thenReturn(ValueNotifier<int?>(null));

    game = MockTapdGame();
    when(game.world).thenReturn(world);
    when(game.size).thenReturn(Vector2(400, 1000));
    when(game.componentsNotifier<TapdWorld>())
        .thenReturn(ComponentsNotifier<TapdWorld>([]));
  });

  testWidgets("Score is at the start of the bar", (tester) async {
    await pumpContext(tester, (context) => Scoreboard(game));
    expect(tester.getCenter(find.byKey(keyScoreboardScore)).dx,
        lessThan(tester.getCenter(find.byKey(keyCurrentTarget)).dx));
    expect(
      tester.widget<Text>(find.byKey(keyScoreboardScore)).style!.color,
      isSameColorAs(colorLightText),
    );
    expect(
      tester.widget<Text>(find.byKey(keyScoreboardScore)).style!.fontWeight,
      fontWeightBoldTitle,
    );
  });

  testWidgets("Current target is centered in the bar", (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = game.size.toSize();
    await pumpContext(tester, (context) => Scoreboard(game));
    expect(tester.getSize(find.byKey(keyCurrentTarget)), const Size(45, 45));
    expect(tester.getCenter(find.byKey(keyCurrentTarget)).dx, 200);
    expect(tester.getSize(find.byType(TargetCircle)), const Size(45, 45));
  });

  testWidgets("FPS is hidden while null", (tester) async {
    await pumpContext(tester, (context) => Scoreboard(game));
    expect(find.textContaining("FPS"), findsNothing);
  });

  testWidgets("FPS is shown in the top right corner", (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = game.size.toSize();
    tester.view.padding = const FakeViewPadding(top: 50);
    addTearDown(tester.view.resetPadding);
    var fps = ValueNotifier<int?>(null);
    when(world.fps).thenReturn(fps);
    await pumpContext(tester, (context) => Scoreboard(game));

    fps.value = 58;
    await tester.pump();
    var text = find.text("58 FPS");
    expect(text, findsOneWidget);
    expect(tester.getTopRight(text).dx, 400 - 16);
    // Centered in the top inset.
    expect(tester.getCenter(text).dy, 25);
    expect(tester.widget<Text>(text).style!.color, isSameColorAs(Colors.green));
  });

  testWidgets("Instructions start below the bar", (tester) async {
    await pumpContext(tester, (context) => Scoreboard(game));
    verify(world.instructionsY = 64).called(1);
  });

  testWidgets("Current target isn't updated for other preferences",
      (tester) async {
    var controller = StreamController<String>.broadcast();
    when(managers.preferenceManager.stream)
        .thenAnswer((_) => controller.stream);
    await pumpContext(tester, (context) => Scoreboard(game));
    var circle = tester.widget(find.byType(TargetCircle));

    controller.add(PreferenceManager.keyMusicOn);
    await tester.pumpAndSettle();
    expect(identical(tester.widget(find.byType(TargetCircle)), circle), isTrue);
    await controller.close();
  });

  testWidgets("Current target is updated when its appearance changes",
      (tester) async {
    var controller = StreamController<String>.broadcast();
    when(managers.preferenceManager.stream)
        .thenAnswer((_) => controller.stream);
    await pumpContext(tester, (context) => Scoreboard(game));
    var circle = tester.widget(find.byType(TargetCircle));

    controller.add(PreferenceManager.keyTargetType);
    await tester.pumpAndSettle();
    expect(
        identical(tester.widget(find.byType(TargetCircle)), circle), isFalse);
    await controller.close();
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

  testWidgets("Current target is updated when the color changes",
      (tester) async {
    var notifier = ComponentsNotifier<TapdWorld>([]);
    when(game.componentsNotifier<TapdWorld>()).thenReturn(notifier);
    when(world.color).thenReturn(TargetColor.from(index: 0));

    await pumpContext(tester, (context) => Scoreboard(game));
    expect(tester.widget<TargetCircle>(find.byType(TargetCircle)).index, 0);

    when(world.color).thenReturn(TargetColor.from(index: 1));
    notifier.notifyListeners();
    await tester.pump();

    expect(tester.widget<TargetCircle>(find.byType(TargetCircle)).index, 1);
  });

  testWidgets("Current target isn't rebuilt when its values don't change",
      (tester) async {
    var notifier = ComponentsNotifier<TapdWorld>([]);
    when(game.componentsNotifier<TapdWorld>()).thenReturn(notifier);

    await pumpContext(tester, (context) => Scoreboard(game));
    var text = tester.widget(find.text("10"));

    notifier.notifyListeners();
    await tester.pump();

    expect(identical(tester.widget(find.text("10")), text), isTrue);
  });

  testWidgets("Pause button isn't rebuilt when only the score changes",
      (tester) async {
    var notifier = ComponentsNotifier<TapdWorld>([]);
    when(game.componentsNotifier<TapdWorld>()).thenReturn(notifier);

    await pumpContext(tester, (context) => Scoreboard(game));
    var button = tester.widget(find.byType(IconButton));

    when(world.score).thenReturn(20);
    notifier.notifyListeners();
    await tester.pump();

    expect(find.text("20"), findsOneWidget);
    expect(identical(tester.widget(find.byType(IconButton)), button), isTrue);
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
    var notifier = ComponentsNotifier<TapdWorld>([]);
    when(game.componentsNotifier<TapdWorld>()).thenReturn(notifier);

    when(world.scrollingPaused).thenReturn(true);
    await pumpContext(tester, (context) => Scoreboard(game));

    await tester.tap(find.byIcon(Icons.play_arrow));
    verify(world.scrollingPaused = false).called(1);

    // The real world notifies its listeners when paused.
    when(world.scrollingPaused).thenReturn(false);
    notifier.notifyListeners();
    await tester.pump();

    await tapAndSettle(tester, find.byIcon(Icons.pause));
    verify(world.scrollingPaused = true).called(1);
  });
}
