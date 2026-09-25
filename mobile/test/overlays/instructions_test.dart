import 'dart:ui';

import 'package:adair_flutter_lib/res/anim.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/tapd_game.dart';
import 'package:mobile/tapd_game_widget.dart';
import 'package:mobile/tapd_world.dart';
import 'package:mobile/difficulty.dart';
import 'package:mobile/overlays/instructions.dart';

import 'package:mockito/mockito.dart';

import '../mocks/mocks.mocks.dart';
import '../test_utils/stubbed_managers.dart';

void main() {
  late StubbedManagers managers;

  late TapdGame game;
  late TapdWorld world;

  setUp(() {
    managers = StubbedManagers();
    when(managers.audioManager.onButtonPressed(any))
        .thenAnswer((invocation) => invocation.positionalArguments.first);

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

    when(managers.statsManager.currentHighScore).thenReturn(50);
    when(managers.statsManager.currentGamesPlayed).thenReturn(100);
    when(managers.statsManager.gamesPlayed).thenReturn(0);

    when(managers.inAppReviewWrapper.isAvailable())
        .thenAnswer((_) => Future.value(false));

    world = TapdWorld();
    game = TapdGame(world: world);
  });

  testWidgets("Entire flow", (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(400, 1000);

    when(managers.preferenceManager.didOnboard).thenReturn(false);

    await tester.pumpWidget(TapdGameWidget(game));
    await tester.pump();

    world.play();

    // Delay that shows the instructions.
    await tester.pump(const Duration(milliseconds: 3000));

    // Fade in duration.
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(Instructions), findsOneWidget);

    // Go through instructions flow.
    expect(
      find.text(
          "Your score will increase by 1 each time you tap a correct target."),
      findsOneWidget,
    );
    await tester.tap(find.text("Next"));
    await tester.pump();

    expect(
      find.text(
          "Watch out! The current target will change throughout the game."),
      findsOneWidget,
    );
    await tester.tap(find.text("Next"));
    await tester.pump();

    expect(
      find.text("You can pause and resume the game at any time."),
      findsOneWidget,
    );
    await tester.tap(find.text("Next"));
    await tester.pump();

    expect(
      find.text(
          "Tap the targets that match the current target as they fall down the screen. Tapping the wrong target, or missing a matching one, ends your run, though you may be offered one chance to continue where you left off."),
      findsOneWidget,
    );
    when(managers.preferenceManager.didOnboard).thenReturn(true);
    await tester.ensureVisible(find.text("Resume Game"));
    await tester.tap(find.text("Resume Game"));
    await tester.pump(animDurationDefault); // Fade out.

    expect(find.byType(Instructions), findsNothing);
  });
}
