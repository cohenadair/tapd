import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mobile/overlays/continue_offer.dart';
import 'package:mockito/mockito.dart';

import '../mocks/mocks.mocks.dart';
import '../test_utils/stubbed_managers.dart';
import '../test_utils/test_utils.dart';

void main() {
  late StubbedManagers managers;
  late MockTapdGame game;
  late MockTapdWorld world;
  late MockRewardedAd ad;

  setUp(() {
    managers = StubbedManagers();
    when(managers.platformWrapper.isDebug).thenReturn(true);
    when(managers.platformWrapper.isAndroid).thenReturn(true);
    when(managers.propertiesManager.adRewardedUnitIdAndroid)
        .thenReturn("android-id");
    when(managers.propertiesManager.adRewardedUnitIdIos).thenReturn("ios-id");

    world = MockTapdWorld();
    when(world.score).thenReturn(7);

    game = MockTapdGame();
    when(game.world).thenReturn(world);

    ad = MockRewardedAd();
    when(ad.dispose()).thenAnswer((_) => Future.value());
    when(ad.show(onUserEarnedReward: anyNamed("onUserEarnedReward")))
        .thenAnswer((_) => Future.value());
  });

  Future<void> pumpOffer(WidgetTester tester, {Widget? wrapper}) async {
    await pumpContext(tester, (_) => wrapper ?? ContinueOffer(game));
    await tester.pumpAndSettle();
  }

  RewardedAdLoadCallback loadCallback() {
    return verify(managers.rewardedAdWrapper.load(
      adUnitId: anyNamed("adUnitId"),
      request: anyNamed("request"),
      rewardedAdLoadCallback: captureAnyNamed("rewardedAdLoadCallback"),
    )).captured.first as RewardedAdLoadCallback;
  }

  FullScreenContentCallback<RewardedAd> contentCallback() {
    return verify(ad.fullScreenContentCallback = captureAny).captured.first
        as FullScreenContentCallback<RewardedAd>;
  }

  // The loading indicator animates forever once the button is pressed, so
  // these can't settle.
  Future<void> tapWatchAd(WidgetTester tester) async {
    await tester.tap(find.text("Watch Short Ad"));
    await tester.pump();
  }

  Future<void> pumpLoadedOffer(WidgetTester tester) async {
    await pumpOffer(tester);
    loadCallback().onAdLoaded(ad);
    await tester.pump();
  }

  Future<void> pumpShownAd(WidgetTester tester) async {
    await pumpLoadedOffer(tester);
    await tapWatchAd(tester);
  }

  testWidgets("Title, score, and messages are shown", (tester) async {
    await pumpOffer(tester);

    expect(find.text("Continue?"), findsOneWidget);
    expect(find.text("7"), findsOneWidget);
    expect(
      find.text("Watch a short ad to pick up right where you left off."),
      findsOneWidget,
    );
    expect(find.text("Watch Short Ad"), findsOneWidget);
    expect(find.text("No Thanks"), findsOneWidget);
  });

  testWidgets("Message and button change if ads were removed", (tester) async {
    when(managers.purchasesManager.hasRemovedAds).thenReturn(true);
    await pumpOffer(tester);

    expect(find.text("Pick up right where you left off."), findsOneWidget);
    expect(find.text("Continue"), findsOneWidget);
    expect(find.text("Watch Short Ad"), findsNothing);
  });

  testWidgets("Ad is preloaded", (tester) async {
    await pumpOffer(tester);

    verify(managers.rewardedAdWrapper.load(
      adUnitId: "ca-app-pub-3940256099942544/5224354917",
      request: anyNamed("request"),
      rewardedAdLoadCallback: anyNamed("rewardedAdLoadCallback"),
    )).called(1);
  });

  testWidgets("Ad isn't loaded if ads were removed", (tester) async {
    when(managers.purchasesManager.hasRemovedAds).thenReturn(true);
    await pumpOffer(tester);

    verifyNever(managers.rewardedAdWrapper.load(
      adUnitId: anyNamed("adUnitId"),
      request: anyNamed("request"),
      rewardedAdLoadCallback: anyNamed("rewardedAdLoadCallback"),
    ));
  });

  testWidgets("Run continues immediately if ads were removed", (tester) async {
    when(managers.purchasesManager.hasRemovedAds).thenReturn(true);
    await pumpOffer(tester);
    await tapAndSettle(tester, find.text("Continue"));

    verify(world.continueRun()).called(1);
    verifyNever(world.declineContinue());
  });

  testWidgets("Preloaded ad is shown when continue is pressed", (tester) async {
    await pumpShownAd(tester);

    verify(ad.show(onUserEarnedReward: anyNamed("onUserEarnedReward")))
        .called(1);
    verify(managers.audioManager.pauseMusic()).called(1);
    verifyNever(world.continueRun());
    verifyNever(world.declineContinue());
  });

  testWidgets("Ad is shown once loaded if continue was pressed early",
      (tester) async {
    await pumpOffer(tester);
    await tapWatchAd(tester);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    verifyNever(ad.show(onUserEarnedReward: anyNamed("onUserEarnedReward")));

    loadCallback().onAdLoaded(ad);
    await tester.pump();

    verify(ad.show(onUserEarnedReward: anyNamed("onUserEarnedReward")))
        .called(1);
  });

  testWidgets("No loading indicator is shown before continue is pressed",
      (tester) async {
    await pumpOffer(tester);

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
  });

  testWidgets("Run ends if ad failed to load before continue was pressed",
      (tester) async {
    await pumpOffer(tester);
    loadCallback().onAdFailedToLoad(LoadAdError(1, "", "", null));
    await tester.pump();
    verifyNever(world.declineContinue());

    await tapWatchAd(tester);
    verify(world.declineContinue()).called(1);
  });

  testWidgets("Run ends if ad fails to load after continue was pressed",
      (tester) async {
    await pumpOffer(tester);
    await tapWatchAd(tester);
    verifyNever(world.declineContinue());

    loadCallback().onAdFailedToLoad(LoadAdError(1, "", "", null));
    await tester.pump();
    verify(world.declineContinue()).called(1);
  });

  testWidgets("Ad is disposed if loaded after the offer was closed",
      (tester) async {
    await pumpOffer(tester,
        wrapper: DisposableTester(child: ContinueOffer(game)));
    final callback = loadCallback();

    tester
        .firstState<DisposableTesterState>(find.byType(DisposableTester))
        .removeChild();
    await tester.pumpAndSettle();

    callback.onAdLoaded(ad);
    verify(ad.dispose()).called(1);
    verifyNever(ad.show(onUserEarnedReward: anyNamed("onUserEarnedReward")));
  });

  testWidgets("Unused preloaded ad is disposed with the offer", (tester) async {
    await pumpOffer(tester,
        wrapper: DisposableTester(child: ContinueOffer(game)));
    loadCallback().onAdLoaded(ad);
    await tester.pump();

    tester
        .firstState<DisposableTesterState>(find.byType(DisposableTester))
        .removeChild();
    await tester.pumpAndSettle();

    verify(ad.dispose()).called(1);
  });

  testWidgets("Shown ad isn't disposed twice with the offer", (tester) async {
    await pumpOffer(tester,
        wrapper: DisposableTester(child: ContinueOffer(game)));
    loadCallback().onAdLoaded(ad);
    await tester.pump();
    await tapWatchAd(tester);

    tester
        .firstState<DisposableTesterState>(find.byType(DisposableTester))
        .removeChild();
    await tester.pumpAndSettle();

    verifyNever(ad.dispose());
  });

  testWidgets("Run continues if ad is dismissed after reward", (tester) async {
    await pumpShownAd(tester);

    final reward = verify(
      ad.show(onUserEarnedReward: captureAnyNamed("onUserEarnedReward")),
    ).captured.first as OnUserEarnedRewardCallback;
    reward(ad, RewardItem(1, "reward"));
    contentCallback().onAdDismissedFullScreenContent?.call(ad);

    verify(ad.dispose()).called(1);
    verify(world.continueRun()).called(1);
    verifyNever(world.declineContinue());
  });

  testWidgets("Run ends if ad is dismissed before reward", (tester) async {
    await pumpShownAd(tester);

    contentCallback().onAdDismissedFullScreenContent?.call(ad);

    verify(ad.dispose()).called(1);
    verify(world.declineContinue()).called(1);
    verifyNever(world.continueRun());
  });

  testWidgets("Run ends if ad fails to show", (tester) async {
    await pumpShownAd(tester);

    contentCallback().onAdFailedToShowFullScreenContent?.call(
          ad,
          AdError(1, "", ""),
        );

    verify(ad.dispose()).called(1);
    verify(world.declineContinue()).called(1);
  });

  testWidgets("Declining ends the run", (tester) async {
    await pumpOffer(tester);
    await tapAndSettle(tester, find.text("No Thanks"));

    verify(world.declineContinue()).called(1);
  });

  testWidgets("Declining is possible while waiting for the ad", (tester) async {
    await pumpOffer(tester);
    await tapWatchAd(tester);
    await tester.tap(find.text("No Thanks"));
    await tester.pump();

    verify(world.declineContinue()).called(1);
  });
}
