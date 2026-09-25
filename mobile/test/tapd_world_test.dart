import 'dart:async';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/tapd_game.dart';
import 'package:mobile/tapd_game_widget.dart';
import 'package:mobile/tapd_world.dart';
import 'package:mobile/components/target.dart';
import 'package:mobile/components/target_board.dart';
import 'package:mobile/difficulty.dart';
import 'package:mobile/effects/target_board_rewind_effect.dart';
import 'package:mobile/overlays/instructions.dart';
import 'package:mobile/utils/overlay_utils.dart';
import 'package:mockito/mockito.dart';

import 'mocks/mocks.mocks.dart';
import 'test_utils/stubbed_managers.dart';

void main() {
  late StubbedManagers managers;

  late TapdGame game;
  late TapdWorld world;

  setUp(() {
    managers = StubbedManagers();

    var bannerAd = MockBannerAd();
    when(bannerAd.load()).thenAnswer((_) => Future.value());
    when(managers.bannerAdWrapper.newAd(
      size: anyNamed("size"),
      adUnitId: anyNamed("adUnitId"),
      listener: anyNamed("listener"),
      request: anyNamed("request"),
    )).thenReturn(bannerAd);

    when(managers.platformWrapper.isDebug).thenReturn(true);
    when(managers.platformWrapper.isAndroid).thenReturn(true);

    when(managers.preferenceManager.difficulty).thenReturn(Difficulty.normal);
    when(managers.preferenceManager.colorIndex).thenReturn(null);
    when(managers.preferenceManager.isFpsOn).thenReturn(false);
    when(managers.preferenceManager.didOnboard).thenReturn(true);

    when(managers.propertiesManager.adBannerUnitIdAndroid)
        .thenReturn("test-id-android");
    when(managers.propertiesManager.adBannerUnitIdIos)
        .thenReturn("test-id-ios");
    when(managers.propertiesManager.adRewardedUnitIdAndroid)
        .thenReturn("test-rewarded-id-android");
    when(managers.propertiesManager.adRewardedUnitIdIos)
        .thenReturn("test-rewarded-id-ios");

    when(managers.statsManager.currentHighScore).thenReturn(0);
    when(managers.statsManager.currentGamesPlayed).thenReturn(0);
    when(managers.statsManager.gamesPlayed).thenReturn(0);
    when(managers.statsManager.updateCurrentHighScore(any)).thenReturn(false);

    when(managers.inAppReviewWrapper.isAvailable())
        .thenAnswer((_) => Future.value(false));

    world = TapdWorld();
    game = TapdGame(world: world);
  });

  Future<void> pumpWorld(WidgetTester tester) async {
    await tester.pumpWidget(TapdGameWidget(game));
    await tester.pump();
  }

  Future<void> pumpOffer(WidgetTester tester) async {
    await pumpWorld(tester);
    world.handleTargetHit(isCorrect: false);
  }

  Future<void> pumpCountdown(WidgetTester tester) async {
    await pumpOffer(tester);
    world.continueRun();
  }

  testWidgets("onLoad", (tester) async {
    await tester.pumpWidget(TapdGameWidget(game));
    await tester.pump();

    expect(game.overlays.activeOverlays.contains(overlayIdMainMenu), true);
    expect(game.overlays.activeOverlays.contains(overlayIdScoreboard), true);
    expect(world.children.whereType<FpsTextComponent>().length, 0);
    expect(world.children.whereType<TargetBoard>().length, 2);

    verify(managers.audioManager.playMenuBackground()).called(1);
  });

  testWidgets("FPS component is shown", (tester) async {
    when(managers.preferenceManager.isFpsOn).thenReturn(true);

    await tester.pumpWidget(TapdGameWidget(game));
    await tester.pump();

    expect(world.children.whereType<FpsTextComponent>().length, 1);
  });

  testWidgets("FPS component is added/removed on preference change",
      (tester) async {
    var controller = StreamController<String>.broadcast();
    when(managers.preferenceManager.stream)
        .thenAnswer((_) => controller.stream);
    when(managers.preferenceManager.isFpsOn).thenReturn(true);

    // Verify FPS is already shown.
    await tester.pumpWidget(TapdGameWidget(game));
    await tester.pump();
    expect(world.children.whereType<FpsTextComponent>().length, 1);

    // Turn FPS off.
    when(managers.preferenceManager.isFpsOn).thenReturn(false);
    controller.add("");
    await tester.pump();
    expect(world.children.whereType<FpsTextComponent>().length, 0);

    // Turn FPS back on.
    when(managers.preferenceManager.isFpsOn).thenReturn(true);
    controller.add("");
    await tester.pump();
    expect(world.children.whereType<FpsTextComponent>().length, 1);
  });

  testWidgets("Correct hit without color change", (tester) async {
    await tester.pumpWidget(TapdGameWidget(game));
    await tester.pump();

    var startSpeed = world.speed;
    var startScore = world.score;
    var startColor = world.color;
    var notified = false;
    game.componentsNotifier<TapdWorld>().addListener(() => notified = true);
    world.handleTargetHit(isCorrect: true);

    expect(world.speed > startSpeed, true);
    expect(world.score > startScore, true);
    expect(world.color == startColor, true);
    expect(notified, true);
    verify(managers.audioManager.playCorrectHit()).called(1);
    verifyNever(managers.audioManager.playIncorrectHit());
  });

  testWidgets("Correct hit with color change", (tester) async {
    await tester.pumpWidget(TapdGameWidget(game));
    await tester.pump();

    var startColor = world.color;
    for (var i = 1; i <= 10; i++) {
      world.handleTargetHit(isCorrect: true);
    }
    expect(world.color != startColor, true);
    expect(world.gracePeriod, isNotNull);

    // Time out grace period.
    await tester.pump(const Duration(milliseconds: 2000));
    expect(world.gracePeriod, isNull);
    verify(managers.audioManager.playSwitchTarget()).called(1);
    verify(managers.audioManager.playCorrectHit()).called(9);
    verifyNever(managers.audioManager.playIncorrectHit());
  });

  testWidgets("Correct hit with Very Easy color set", (tester) async {
    when(managers.preferenceManager.difficulty).thenReturn(Difficulty.veryEasy);
    when(managers.preferenceManager.colorIndex).thenReturn(1);

    await tester.pumpWidget(TapdGameWidget(game));
    await tester.pump();

    var startColor = world.color;
    for (var i = 1; i <= 10; i++) {
      world.handleTargetHit(isCorrect: true);
    }
    expect(world.color == startColor, true);
    expect(world.gracePeriod, isNull);
    verify(managers.audioManager.playCorrectHit()).called(10);
    verifyNever(managers.audioManager.playIncorrectHit());
    verifyNever(managers.audioManager.playSwitchTarget());
  });

  testWidgets("Incorrect hit ends game", (tester) async {
    await tester.pumpWidget(TapdGameWidget(game));
    await tester.pump();

    // Reset counter.
    verify(managers.audioManager.playMenuBackground()).called(1);

    var startSpeed = world.speed;
    var startScore = world.score;
    var startColor = world.color;
    var notified = false;
    game.componentsNotifier<TapdWorld>().addListener(() => notified = true);
    world.handleTargetHit(isCorrect: false);
    world.declineContinue();

    expect(world.speed == startSpeed, true);
    expect(world.score == startScore, true);
    expect(world.color == startColor, true);
    expect(game.overlays.activeOverlays.contains(overlayIdGameOver), true);
    expect(notified, true);
    verify(managers.audioManager.playMenuBackground()).called(1);
    verify(managers.statsManager.updateCurrentHighScore(any)).called(1);
    verify(managers.statsManager.incCurrentGamesPlayed()).called(1);
    verify(managers.orientationManager.reset()).called(1);
    verifyNever(managers.audioManager.playCorrectHit());

    await tester.pump();
    expect(find.text("Game Over"), findsOneWidget);
  });

  testWidgets("Incorrect hit ends game for Very Easy difficulty",
      (tester) async {
    when(managers.preferenceManager.difficulty).thenReturn(Difficulty.veryEasy);

    await tester.pumpWidget(TapdGameWidget(game));
    await tester.pump();

    // Reset counter.
    verify(managers.audioManager.playMenuBackground()).called(1);

    world.handleTargetHit(isCorrect: false);
    verify(managers.audioManager.playMenuBackground()).called(1);
    verifyNever(managers.audioManager.playCorrectHit());
    verify(managers.statsManager.updateCurrentHighScore(any)).called(1);
    verify(managers.statsManager.incCurrentGamesPlayed()).called(1);
  });

  testWidgets("Target missed ends game", (tester) async {
    await tester.pumpWidget(TapdGameWidget(game));
    await tester.pump();
    await tester.pump(); // Second pump ensures children are loaded.

    var board = world.children.whereType<TargetBoard>().first;
    var target = board.children.whereType<Target>().first;
    world.handleTargetMissed(target, board);
    await tester.pump();

    expect(world.scrollingPaused, true);
    expect(board.children.whereType<TargetBoardRewindEffect>().length, 1);
    expect(
      (game.findByKey(board.otherBoardKey) as TargetBoard)
          .children
          .whereType<TargetBoardRewindEffect>()
          .length,
      1,
    );

    // Verify target's "pulse" is invoked.
    await tester.pump(const Duration(milliseconds: 300));
    expect(board.priority, 1);

    verify(managers.audioManager.playIncorrectHit()).called(1);
    verifyNever(managers.audioManager.playCorrectHit());
  });

  testWidgets("Play starts the game", (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(600, 1000);

    var notified = false;
    game.componentsNotifier<TapdWorld>().addListener(() => notified = true);

    await tester.pumpWidget(TapdGameWidget(game));
    var startColor = world.color;

    world.play();

    expect(world.children.whereType<TargetBoard>().first.position.y, -3600);
    expect(world.children.whereType<TargetBoard>().last.position.y, -1800);
    expect(world.speed, 4.0);
    expect(world.color != startColor, true);
    expect(world.score, 0);
    expect(world.gracePeriod, isNull);
    expect(world.scrollingPaused, false);
    expect(notified, true);
    expect(game.overlays.activeOverlays.length, 1); // Scoreboard.

    verify(managers.audioManager.playGameBackground()).called(1);
    verify(managers.orientationManager.lockCurrent()).called(1);
  });

  testWidgets("Pausing/resuming stops/plays music", (tester) async {
    await tester.pumpWidget(TapdGameWidget(game));
    await tester.pump();
    verify(managers.audioManager.pauseMusic()).called(1); // From onLoad.

    world.scrollingPaused = true;
    verify(managers.audioManager.pauseMusic()).called(1);
    verifyNever(managers.audioManager.resumeMusic());

    world.scrollingPaused = false;
    verify(managers.audioManager.resumeMusic()).called(1);
    verifyNever(managers.audioManager.pauseMusic());
  });

  testWidgets("Hiding instructions updates preferences", (tester) async {
    await tester.pumpWidget(TapdGameWidget(game));
    await tester.pump();

    world.hideInstructions();
    verify(managers.preferenceManager.didOnboard = true).called(1);
  });

  testWidgets("Show instructions exits early if already onboarded",
      (tester) async {
    when(managers.preferenceManager.didOnboard).thenReturn(true);

    await tester.pumpWidget(TapdGameWidget(game));
    await tester.pump();

    world.play();
    await tester.pump();

    expect(game.overlays.activeOverlays.length, 1); // Scoreboard.
  });

  testWidgets("Instructions are shown", (tester) async {
    when(managers.preferenceManager.didOnboard).thenReturn(false);

    await tester.pumpWidget(TapdGameWidget(game));
    await tester.pump(const Duration(milliseconds: 50));

    world.play();

    // Delay so instructions are shown.
    await tester.pump(const Duration(milliseconds: 3000));

    // Trigger start rendering of instructions.
    await tester.pump();

    // Fade in duration.
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(Instructions), findsOneWidget);
  });

  testWidgets("Incorrect hit offers continue", (tester) async {
    await pumpOffer(tester);

    expect(game.overlays.isActive(overlayIdContinueOffer), true);
    expect(game.overlays.isActive(overlayIdGameOver), false);
    expect(world.scrollingPaused, true);
    verify(managers.analyticsWrapper.logEvent(name: "continue_offered"))
        .called(1);
    verifyNever(managers.statsManager.incCurrentGamesPlayed());
  });

  testWidgets("Incorrect hit pauses scrolling if it was resumed",
      (tester) async {
    await pumpWorld(tester);
    world.scrollingPaused = false;

    world.handleTargetHit(isCorrect: false);
    expect(world.scrollingPaused, true);
  });

  testWidgets("Incorrect hit pauses scrolling if run ends", (tester) async {
    when(managers.preferenceManager.difficulty).thenReturn(Difficulty.veryEasy);
    await pumpWorld(tester);
    world.scrollingPaused = false;

    world.handleTargetHit(isCorrect: false);
    expect(world.scrollingPaused, true);
  });

  testWidgets("Setting scrolling paused notifies listeners", (tester) async {
    await pumpWorld(tester);

    var notified = false;
    game.componentsNotifier<TapdWorld>().addListener(() => notified = true);
    world.scrollingPaused = false;
    expect(notified, true);
  });

  testWidgets("Declining continue ends the run", (tester) async {
    await pumpOffer(tester);

    world.declineContinue();

    expect(game.overlays.isActive(overlayIdContinueOffer), false);
    expect(game.overlays.isActive(overlayIdGameOver), true);
    verify(managers.statsManager.incCurrentGamesPlayed()).called(1);
  });

  testWidgets("Declining continue does nothing without an offer",
      (tester) async {
    await pumpWorld(tester);

    world.declineContinue();

    expect(game.overlays.isActive(overlayIdGameOver), false);
    verifyNever(managers.statsManager.incCurrentGamesPlayed());
  });

  testWidgets("Continuing does nothing without an offer", (tester) async {
    await pumpWorld(tester);

    world.continueRun();

    expect(game.overlays.isActive(overlayIdContinueCountdown), false);
    verifyNever(managers.analyticsWrapper.logEvent(name: "continue_used"));
  });

  testWidgets("Continuing starts the countdown", (tester) async {
    await pumpCountdown(tester);

    expect(game.overlays.isActive(overlayIdContinueOffer), false);
    expect(game.overlays.isActive(overlayIdContinueCountdown), true);
    expect(world.continueSecondsLeft.value, 5);
    expect(world.scrollingPaused, true);
    verify(managers.analyticsWrapper.logEvent(name: "continue_used")).called(1);
    verifyNever(managers.statsManager.incCurrentGamesPlayed());
  });

  testWidgets("Continuing resets the target that ended the run",
      (tester) async {
    await pumpWorld(tester);
    await tester.pump(); // Ensures children are loaded.

    game.descendants().whereType<Target>().first.pulse();
    world.handleTargetHit(isCorrect: false);
    clearInteractions(managers.flameWrapper);

    world.continueRun();
    verify(managers.flameWrapper.loadSprite(any)).called(1);
  });

  testWidgets("Continue countdown ticks with game updates", (tester) async {
    await pumpCountdown(tester);

    world.update(0.5);
    expect(world.continueSecondsLeft.value, 5);

    world.update(0.5);
    expect(world.continueSecondsLeft.value, 4);
    expect(world.scrollingPaused, true);
    expect(game.overlays.isActive(overlayIdContinueCountdown), true);
  });

  testWidgets("Continue countdown resumes the game when finished",
      (tester) async {
    await pumpCountdown(tester);

    var notified = false;
    game.componentsNotifier<TapdWorld>().addListener(() => notified = true);

    for (var i = 0; i < 5; i++) {
      world.update(1);
    }

    expect(world.continueSecondsLeft.value, 0);
    expect(game.overlays.isActive(overlayIdContinueCountdown), false);
    expect(world.scrollingPaused, false);
    expect(world.gracePeriod, isNotNull);
    expect(notified, true);

    // The timer stops once the countdown finishes.
    world.update(1);
    expect(world.continueSecondsLeft.value, 0);

    // Time out grace period.
    await tester.pump(const Duration(milliseconds: 3000));
  });

  testWidgets("Continue is only offered once per run", (tester) async {
    await pumpCountdown(tester);
    for (var i = 0; i < 5; i++) {
      world.update(1);
    }

    world.handleTargetHit(isCorrect: false);

    expect(game.overlays.isActive(overlayIdContinueOffer), false);
    expect(game.overlays.isActive(overlayIdGameOver), true);

    // Time out grace period.
    await tester.pump(const Duration(milliseconds: 3000));
  });

  testWidgets("Continue is offered again in a new game", (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(600, 1000);

    await pumpCountdown(tester);
    for (var i = 0; i < 5; i++) {
      world.update(1);
    }

    world.play();
    world.handleTargetHit(isCorrect: false);

    expect(game.overlays.isActive(overlayIdContinueOffer), true);

    // Time out grace period.
    await tester.pump(const Duration(milliseconds: 3000));
  });

  testWidgets("Play discards a running continue countdown", (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(600, 1000);

    await pumpCountdown(tester);
    world.play();

    world.update(1);
    expect(world.continueSecondsLeft.value, 5);
  });
}
