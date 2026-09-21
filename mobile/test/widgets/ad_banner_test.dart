import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mobile/widgets/ad_banner.dart';
import 'package:mockito/mockito.dart';

import '../mocks/mocks.mocks.dart';
import '../test_utils/stubbed_managers.dart';
import '../test_utils/test_utils.dart';

void main() {
  late StubbedManagers managers;
  late MockBannerAd bannerAd;

  setUp(() {
    managers = StubbedManagers();

    bannerAd = MockBannerAd();
    when(bannerAd.dispose()).thenAnswer((_) => Future.value());
    when(bannerAd.load()).thenAnswer((_) => Future.value());
    when(managers.bannerAdWrapper.newAd(
      size: anyNamed("size"),
      adUnitId: anyNamed("adUnitId"),
      listener: anyNamed("listener"),
      request: anyNamed("request"),
    )).thenReturn(bannerAd);

    when(managers.platformWrapper.isDebug).thenReturn(true);
    when(managers.platformWrapper.isAndroid).thenReturn(true);

    when(managers.propertiesManager.adBannerUnitIdAndroid)
        .thenReturn("test-id-android");
    when(managers.propertiesManager.adBannerUnitIdIos)
        .thenReturn("test-id-ios");
  });

  testWidgets("No ad is shown", (tester) async {
    when(bannerAd.load()).thenAnswer(
        (_) => Future.delayed(const Duration(milliseconds: 50), () {}));

    await pumpContext(tester, (_) => const AdBanner());
    expect(find.byType(Container), findsOneWidget);
    expect(find.byType(AdWidget), findsNothing);

    // Exhaust timers.
    await tester.pumpAndSettle(const Duration(milliseconds: 50));
  });

  testWidgets("Ad is disposed when widget is disposed", (tester) async {
    when(managers.bannerAdWrapper.newWidget(ad: anyNamed("ad")))
        .thenReturn(const Text("Test Banner"));

    await pumpContext(tester, (_) => const DisposableTester(child: AdBanner()));

    var result = verify(managers.bannerAdWrapper.newAd(
      size: anyNamed("size"),
      adUnitId: anyNamed("adUnitId"),
      listener: captureAnyNamed("listener"),
      request: anyNamed("request"),
    ));
    result.called(1);
    (result.captured.first as BannerAdListener).onAdLoaded?.call(bannerAd);
    await tester.pumpAndSettle();

    var state =
        tester.firstState<DisposableTesterState>(find.byType(DisposableTester));
    state.removeChild();
    await tester.pumpAndSettle();

    verify(bannerAd.dispose()).called(1);
  });

  testWidgets("Ad is disposed if loaded while not mounted", (tester) async {
    when(managers.bannerAdWrapper.newWidget(ad: anyNamed("ad")))
        .thenReturn(const Text("Test Banner"));

    await pumpContext(tester, (_) => const DisposableTester(child: AdBanner()));

    var result = verify(managers.bannerAdWrapper.newAd(
      size: anyNamed("size"),
      adUnitId: anyNamed("adUnitId"),
      listener: captureAnyNamed("listener"),
      request: anyNamed("request"),
    ));
    result.called(1);

    // Dispose of widget first, then invoke listener.
    var state =
        tester.firstState<DisposableTesterState>(find.byType(DisposableTester));
    state.removeChild();
    await tester.pumpAndSettle();

    (result.captured.first as BannerAdListener).onAdLoaded?.call(bannerAd);
    await tester.pumpAndSettle();
    verify(bannerAd.dispose()).called(1);
  });

  testWidgets("Ad is shown", (tester) async {
    when(managers.bannerAdWrapper.newWidget(ad: anyNamed("ad")))
        .thenReturn(const Text("Test Banner"));

    await pumpContext(tester, (_) => const DisposableTester(child: AdBanner()));
    expect(find.text("Test Banner"), findsNothing);

    // Simulate loaded banner.
    var result = verify(managers.bannerAdWrapper.newAd(
      size: anyNamed("size"),
      adUnitId: anyNamed("adUnitId"),
      listener: captureAnyNamed("listener"),
      request: anyNamed("request"),
    ));
    result.called(1);
    (result.captured.first as BannerAdListener).onAdLoaded?.call(bannerAd);
    await tester.pumpAndSettle();

    expect(find.text("Test Banner"), findsOneWidget);
  });

  testWidgets("Ad is disposed on failure to load", (tester) async {
    when(managers.bannerAdWrapper.newWidget(ad: anyNamed("ad")))
        .thenReturn(const Text("Test Banner"));

    await pumpContext(tester, (_) => const DisposableTester(child: AdBanner()));
    expect(find.text("Test Banner"), findsNothing);

    // Simulator failed load.
    var result = verify(managers.bannerAdWrapper.newAd(
      size: anyNamed("size"),
      adUnitId: anyNamed("adUnitId"),
      listener: captureAnyNamed("listener"),
      request: anyNamed("request"),
    ));
    result.called(1);
    (result.captured.first as BannerAdListener)
        .onAdFailedToLoad
        ?.call(bannerAd, LoadAdError(1, "", "", null));
    await tester.pumpAndSettle();

    expect(find.text("Test Banner"), findsNothing);
    verify(bannerAd.dispose()).called(1);
  });

  testWidgets("No ad is loaded if ads were removed", (tester) async {
    when(managers.purchasesManager.hasRemovedAds).thenReturn(true);

    await pumpContext(tester, (_) => const AdBanner());

    verifyNever(managers.bannerAdWrapper.newAd(
      size: anyNamed("size"),
      adUnitId: anyNamed("adUnitId"),
      listener: anyNamed("listener"),
      request: anyNamed("request"),
    ));
    expect(find.byType(Container), findsNothing);
  });

  testWidgets("Loaded ad is disposed when ads are removed", (tester) async {
    final controller = StreamController.broadcast();
    when(managers.purchasesManager.stream).thenAnswer((_) => controller.stream);
    when(managers.bannerAdWrapper.newWidget(ad: anyNamed("ad")))
        .thenReturn(const Text("Test Banner"));

    await pumpContext(tester, (_) => const AdBanner());
    var result = verify(managers.bannerAdWrapper.newAd(
      size: anyNamed("size"),
      adUnitId: anyNamed("adUnitId"),
      listener: captureAnyNamed("listener"),
      request: anyNamed("request"),
    ));
    (result.captured.first as BannerAdListener).onAdLoaded?.call(bannerAd);
    await tester.pumpAndSettle();
    expect(find.text("Test Banner"), findsOneWidget);

    when(managers.purchasesManager.hasRemovedAds).thenReturn(true);
    controller.add(null);
    await tester.pumpAndSettle();

    expect(find.text("Test Banner"), findsNothing);
    verify(bannerAd.dispose()).called(1);
    await controller.close();
  });

  testWidgets("Ad is disposed if loaded after ads were removed",
      (tester) async {
    when(managers.bannerAdWrapper.newWidget(ad: anyNamed("ad")))
        .thenReturn(const Text("Test Banner"));

    await pumpContext(tester, (_) => const AdBanner());
    var result = verify(managers.bannerAdWrapper.newAd(
      size: anyNamed("size"),
      adUnitId: anyNamed("adUnitId"),
      listener: captureAnyNamed("listener"),
      request: anyNamed("request"),
    ));

    when(managers.purchasesManager.hasRemovedAds).thenReturn(true);
    (result.captured.first as BannerAdListener).onAdLoaded?.call(bannerAd);
    await tester.pumpAndSettle();

    expect(find.text("Test Banner"), findsNothing);
    verify(bannerAd.dispose()).called(1);
  });

  testWidgets("Entitlement changes keep the ad if ads weren't removed",
      (tester) async {
    final controller = StreamController.broadcast();
    when(managers.purchasesManager.stream).thenAnswer((_) => controller.stream);

    await pumpContext(tester, (_) => const AdBanner());
    controller.add(null);
    await tester.pumpAndSettle();

    verifyNever(bannerAd.dispose());
    expect(find.byType(Container), findsOneWidget);
    await controller.close();
  });

  testWidgets("Purchases subscription is cancelled on dispose", (tester) async {
    final controller = StreamController.broadcast();
    when(managers.purchasesManager.stream).thenAnswer((_) => controller.stream);

    await pumpContext(tester, (_) => const DisposableTester(child: AdBanner()));
    expect(controller.hasListener, isTrue);

    var state =
        tester.firstState<DisposableTesterState>(find.byType(DisposableTester));
    state.removeChild();
    await tester.pumpAndSettle();

    expect(controller.hasListener, isFalse);
    await controller.close();
  });
}
