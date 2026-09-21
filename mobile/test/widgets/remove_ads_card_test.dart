import 'dart:async';

import 'package:adair_flutter_lib/res/dimen.dart';
import 'package:adair_flutter_lib/widgets/loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/managers/purchases_manager.dart';
import 'package:mobile/widgets/remove_ads_card.dart';
import 'package:mockito/mockito.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../test_utils/stubbed_managers.dart';
import '../test_utils/test_utils.dart';

void main() {
  late StubbedManagers managers;
  late Package package;

  setUp(() {
    managers = StubbedManagers();

    package = buildPurchasesPackage(id: "remove_ads", price: "\$4.99");
    when(managers.purchasesManager.removeAdsPackage())
        .thenAnswer((_) => Future.value(package));
    when(managers.purchasesManager.purchaseRemoveAds())
        .thenAnswer((_) => Future.value(RemoveAdsResult.purchased));
  });

  Future<void> pumpCard(WidgetTester tester) async {
    await pumpContext(tester, (_) => const Scaffold(body: RemoveAdsCard()));
    await tester.pumpAndSettle();
  }

  testWidgets("Nothing is shown if ads were removed", (tester) async {
    when(managers.purchasesManager.hasRemovedAds).thenReturn(true);
    await pumpCard(tester);
    expect(find.byType(FilledButton), findsNothing);
    expect(find.text("Go ad-free"), findsNothing);
  });

  testWidgets("Title and subtitle are shown", (tester) async {
    await pumpCard(tester);
    expect(find.text("Go ad-free"), findsOneWidget);
    expect(find.text("One-time purchase"), findsOneWidget);
  });

  testWidgets("Button is shown with price", (tester) async {
    await pumpCard(tester);
    expect(find.text("\$4.99"), findsOneWidget);
  });

  testWidgets("Button label uses title large size", (tester) async {
    await pumpCard(tester);

    final titleLarge = Theme.of(
      tester.element(find.byType(FilledButton)),
    ).textTheme.titleLarge;
    expect(
      tester.widget<Text>(find.text("\$4.99")).style?.fontSize,
      titleLarge?.fontSize,
    );
  });

  testWidgets("Button is shown without price if package is null",
      (tester) async {
    when(managers.purchasesManager.removeAdsPackage())
        .thenAnswer((_) => Future.value());
    await pumpCard(tester);
    expect(find.text("Buy"), findsOneWidget);
  });

  testWidgets("Card is hidden when ads are removed", (tester) async {
    final controller = StreamController.broadcast();
    when(managers.purchasesManager.stream).thenAnswer((_) => controller.stream);
    await pumpCard(tester);
    expect(find.byType(FilledButton), findsOneWidget);

    when(managers.purchasesManager.hasRemovedAds).thenReturn(true);
    controller.add(null);
    await tester.pumpAndSettle();
    expect(find.byType(FilledButton), findsNothing);
    await controller.close();
  });

  testWidgets("Pressing button purchases Remove Ads", (tester) async {
    await pumpCard(tester);
    await tapAndSettle(tester, find.byType(FilledButton));
    verify(managers.purchasesManager.purchaseRemoveAds()).called(1);
    verify(managers.purchasesManager.removeAdsPackage()).called(1);
  });

  testWidgets("Purchase is logged", (tester) async {
    await pumpCard(tester);
    await tapAndSettle(tester, find.byType(FilledButton));
    verify(managers.analyticsWrapper.logEvent(name: "remove_ads_purchased"))
        .called(1);
  });

  testWidgets("Purchase is not logged if not completed", (tester) async {
    when(managers.purchasesManager.purchaseRemoveAds())
        .thenAnswer((_) => Future.value(RemoveAdsResult.notPurchased));
    await pumpCard(tester);
    await tapAndSettle(tester, find.byType(FilledButton));
    verifyNever(managers.analyticsWrapper.logEvent(name: anyNamed("name")));
  });

  testWidgets("Purchase is not logged if already owned", (tester) async {
    when(managers.purchasesManager.purchaseRemoveAds())
        .thenAnswer((_) => Future.value(RemoveAdsResult.alreadyOwned));
    await pumpCard(tester);
    await tapAndSettle(tester, find.byType(FilledButton));
    verifyNever(managers.analyticsWrapper.logEvent(name: anyNamed("name")));
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets("Package isn't loaded if ads were removed", (tester) async {
    when(managers.purchasesManager.hasRemovedAds).thenReturn(true);
    await pumpCard(tester);
    verifyNever(managers.purchasesManager.removeAdsPackage());
  });

  testWidgets("No error is shown if the purchase is cancelled", (tester) async {
    when(managers.purchasesManager.purchaseRemoveAds())
        .thenAnswer((_) => Future.value(RemoveAdsResult.notPurchased));
    await pumpCard(tester);
    await tapAndSettle(tester, find.byType(FilledButton));
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets("Error is shown if the purchase is unavailable", (tester) async {
    when(managers.purchasesManager.purchaseRemoveAds())
        .thenAnswer((_) => Future.value(RemoveAdsResult.unavailable));
    await pumpCard(tester);
    await tapAndSettle(tester, find.byType(FilledButton));

    expect(
      find.text(
        "Unable to load the purchase. Please check your connection and try "
        "again.",
      ),
      findsOneWidget,
    );
    expect(find.byType(Loading), findsNothing);
  });

  testWidgets("Loading indicator is shown while purchasing", (tester) async {
    final completer = Completer<RemoveAdsResult>();
    when(managers.purchasesManager.purchaseRemoveAds())
        .thenAnswer((_) => completer.future);
    await pumpCard(tester);
    expect(find.byType(Loading), findsNothing);

    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    expect(find.byType(Loading), findsOneWidget);

    completer.complete(RemoveAdsResult.purchased);
    await tester.pumpAndSettle();
    expect(find.byType(Loading), findsNothing);
  });

  testWidgets("Loading indicator doesn't resize the button", (tester) async {
    final completer = Completer<RemoveAdsResult>();
    when(managers.purchasesManager.purchaseRemoveAds())
        .thenAnswer((_) => completer.future);
    await pumpCard(tester);
    final size = tester.getSize(find.byType(FilledButton));

    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    expect(tester.getSize(find.byType(FilledButton)), size);
    expect(
      find.descendant(
        of: find.byType(FilledButton),
        matching: find.byType(Loading),
      ),
      findsNothing,
    );

    completer.complete(RemoveAdsResult.purchased);
    await tester.pumpAndSettle();
  });

  testWidgets("Loading indicator is spaced from the button", (tester) async {
    final completer = Completer<RemoveAdsResult>();
    when(managers.purchasesManager.purchaseRemoveAds())
        .thenAnswer((_) => completer.future);
    await pumpCard(tester);

    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    final loadingRight = tester.getTopRight(find.byType(Loading)).dx;
    final buttonLeft = tester.getTopLeft(find.byType(FilledButton)).dx;
    expect(buttonLeft - loadingRight, paddingDefault);

    completer.complete(RemoveAdsResult.purchased);
    await tester.pumpAndSettle();
  });

  testWidgets("Button is disabled while purchasing", (tester) async {
    final completer = Completer<RemoveAdsResult>();
    when(managers.purchasesManager.purchaseRemoveAds())
        .thenAnswer((_) => completer.future);
    await pumpCard(tester);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );

    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );

    completer.complete(RemoveAdsResult.purchased);
    await tester.pumpAndSettle();
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
  });

  testWidgets("Pressing button while purchasing is ignored", (tester) async {
    final completer = Completer<RemoveAdsResult>();
    when(managers.purchasesManager.purchaseRemoveAds())
        .thenAnswer((_) => completer.future);
    await pumpCard(tester);

    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    verify(managers.purchasesManager.purchaseRemoveAds()).called(1);

    completer.complete(RemoveAdsResult.purchased);
    await tester.pumpAndSettle();
  });
}
