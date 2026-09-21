import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/managers/purchases_manager.dart';
import 'package:mockito/mockito.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../mocks/mocks.mocks.dart';
import '../test_utils/stubbed_managers.dart';
import '../test_utils/test_utils.dart';

void main() {
  late StubbedManagers managers;

  setUp(() {
    managers = StubbedManagers();

    when(managers.purchasesWrapper.setLogLevel(any))
        .thenAnswer((_) => Future.value());
    when(managers.purchasesWrapper.configure(any))
        .thenAnswer((_) => Future.value());

    var customerInfo = MockCustomerInfo();
    when(customerInfo.entitlements).thenReturn(const EntitlementInfos({}, {}));
    when(managers.purchasesWrapper.getCustomerInfo())
        .thenAnswer((_) => Future.value(customerInfo));

    when(managers.platformWrapper.isDebug).thenReturn(true);
    when(managers.platformWrapper.isAndroid).thenReturn(true);

    when(managers.propertiesManager.revenueCatKeyAndroid).thenReturn("android");
    when(managers.propertiesManager.revenueCatKeyApple).thenReturn("apple");

    PurchasesManager.suicide();
  });

  MockCustomerInfo customerInfo({required bool hasRemovedAds}) {
    final info = MockCustomerInfo();
    final active = <String, EntitlementInfo>{};
    if (hasRemovedAds) {
      active[PurchasesManager.entitlementRemoveAds] = MockEntitlementInfo();
    }
    when(info.entitlements).thenReturn(EntitlementInfos(const {}, active));
    return info;
  }

  Package stubRemoveAdsPackage() {
    final package = buildPurchasesPackage(
      id: PurchasesManager.packageRemoveAds,
      price: "1.99",
    );
    final offering = MockOffering();
    when(offering.availablePackages).thenReturn([package]);

    final offerings = MockOfferings();
    when(offerings.getOffering(PurchasesManager.offeringRemoveAds))
        .thenReturn(offering);
    when(managers.purchasesWrapper.getOfferings())
        .thenAnswer((_) => Future.value(offerings));
    return package;
  }

  void stubPurchase(CustomerInfo info) {
    final result = MockPurchaseResult();
    when(result.customerInfo).thenReturn(info);
    when(managers.purchasesWrapper.purchase(any))
        .thenAnswer((_) => Future.value(result));
  }

  void stubPurchaseError(PurchasesErrorCode code) {
    final exception = MockPlatformException();
    when(exception.code).thenReturn(code.index.toString());
    when(exception.message).thenReturn("Test error");
    when(managers.purchasesWrapper.purchase(any)).thenThrow(exception);
  }

  test("init verbose log", () async {
    when(managers.platformWrapper.isDebug).thenReturn(true);
    await PurchasesManager.get.init();

    var result = verify(managers.purchasesWrapper.setLogLevel(captureAny));
    result.called(1);
    expect(result.captured.first, LogLevel.verbose);
  });

  test("init error log", () async {
    when(managers.platformWrapper.isDebug).thenReturn(false);
    await PurchasesManager.get.init();

    var result = verify(managers.purchasesWrapper.setLogLevel(captureAny));
    result.called(1);
    expect(result.captured.first, LogLevel.error);
  });

  test("init for Android", () async {
    when(managers.platformWrapper.isAndroid).thenReturn(true);
    await PurchasesManager.get.init();

    var result = verify(managers.purchasesWrapper.configure(captureAny));
    result.called(1);
    expect(result.captured.first.apiKey, "android");
  });

  test("init for iOS", () async {
    when(managers.platformWrapper.isAndroid).thenReturn(false);
    await PurchasesManager.get.init();

    var result = verify(managers.purchasesWrapper.configure(captureAny));
    result.called(1);
    expect(result.captured.first.apiKey, "apple");
  });

  test("removeAdsPackage returns package from remove ads offering", () async {
    var package = buildPurchasesPackage(
      id: PurchasesManager.packageRemoveAds,
      price: "1.99",
    );
    var offering = MockOffering();
    when(offering.availablePackages).thenReturn([package]);

    var offerings = MockOfferings();
    when(offerings.getOffering("remove_ads")).thenReturn(offering);
    when(managers.purchasesWrapper.getOfferings())
        .thenAnswer((_) => Future.value(offerings));

    expect(await PurchasesManager.get.removeAdsPackage(), package);
    verifyNever(offerings.current);
  });

  test("removeAdsPackage returns null when offering is missing", () async {
    var offerings = MockOfferings();
    when(offerings.getOffering("remove_ads")).thenReturn(null);
    when(managers.purchasesWrapper.getOfferings())
        .thenAnswer((_) => Future.value(offerings));

    expect(await PurchasesManager.get.removeAdsPackage(), isNull);
  });

  test("removeAdsPackage returns null when package is missing", () async {
    var package = buildPurchasesPackage(id: "other", price: "0.99");
    var offering = MockOffering();
    when(offering.availablePackages).thenReturn([package]);

    var offerings = MockOfferings();
    when(offerings.getOffering("remove_ads")).thenReturn(offering);
    when(managers.purchasesWrapper.getOfferings())
        .thenAnswer((_) => Future.value(offerings));

    expect(await PurchasesManager.get.removeAdsPackage(), isNull);
  });

  test("removeAdsPackage returns null when fetching offerings fails", () async {
    var exception = MockPlatformException();
    when(exception.message).thenReturn("Test error");
    when(managers.purchasesWrapper.getOfferings()).thenThrow(exception);

    expect(await PurchasesManager.get.removeAdsPackage(), isNull);
    verify(exception.message).called(1);
  });

  test("purchase throws loggable error", () async {
    var exception = MockPlatformException();
    when(exception.code)
        .thenReturn(PurchasesErrorCode.configurationError.index.toString());
    when(exception.message).thenReturn("Test error");
    when(managers.purchasesWrapper.purchase(any)).thenThrow(exception);

    expect(await PurchasesManager.get.purchase(MockPackage()), isNull);
    verify(exception.message).called(1);
  });

  test("purchase throws purchaseCancelledError error", () async {
    var exception = MockPlatformException();
    when(exception.code)
        .thenReturn(PurchasesErrorCode.purchaseCancelledError.index.toString());
    when(managers.purchasesWrapper.purchase(any)).thenThrow(exception);

    expect(await PurchasesManager.get.purchase(MockPackage()), isNull);
    verifyNever(exception.message);
  });

  test("purchase throws storeProblemError error", () async {
    var exception = MockPlatformException();
    when(exception.code)
        .thenReturn(PurchasesErrorCode.storeProblemError.index.toString());
    when(managers.purchasesWrapper.purchase(any)).thenThrow(exception);

    expect(await PurchasesManager.get.purchase(MockPackage()), isNull);
    verifyNever(exception.message);
  });

  testWidgets("init doesn't wait longer than the entitlements timeout",
      (tester) async {
    when(managers.purchasesWrapper.getCustomerInfo())
        .thenAnswer((_) => Completer<CustomerInfo>().future);

    var didComplete = false;
    PurchasesManager.get.init().then((_) => didComplete = true);

    await tester.pump(const Duration(milliseconds: 500));
    expect(didComplete, isFalse);

    await tester.pump(const Duration(seconds: 1));
    expect(didComplete, isTrue);
  });

  test("init fetches entitlements", () async {
    when(managers.purchasesWrapper.getCustomerInfo())
        .thenAnswer((_) => Future.value(customerInfo(hasRemovedAds: true)));

    await PurchasesManager.get.init();
    expect(PurchasesManager.get.hasRemovedAds, isTrue);
  });

  test("refreshEntitlements notifies stream when ads are removed", () async {
    when(managers.purchasesWrapper.getCustomerInfo())
        .thenAnswer((_) => Future.value(customerInfo(hasRemovedAds: true)));

    var notified = 0;
    PurchasesManager.get.stream.listen((_) => notified++);

    await PurchasesManager.get.refreshEntitlements();
    await Future.value();
    expect(PurchasesManager.get.hasRemovedAds, isTrue);
    expect(notified, 1);
  });

  test("refreshEntitlements doesn't notify stream if nothing changed",
      () async {
    var notified = 0;
    PurchasesManager.get.stream.listen((_) => notified++);

    await PurchasesManager.get.refreshEntitlements();
    await Future.value();
    expect(PurchasesManager.get.hasRemovedAds, isFalse);
    expect(notified, 0);
  });

  test("refreshEntitlements keeps cached value on error", () async {
    when(managers.purchasesWrapper.getCustomerInfo())
        .thenAnswer((_) => Future.value(customerInfo(hasRemovedAds: true)));
    await PurchasesManager.get.refreshEntitlements();

    final exception = MockPlatformException();
    when(exception.message).thenReturn("Test error");
    when(managers.purchasesWrapper.getCustomerInfo()).thenThrow(exception);

    await PurchasesManager.get.refreshEntitlements();
    expect(PurchasesManager.get.hasRemovedAds, isTrue);
    verify(exception.message).called(1);
  });

  test("removeAdsPackage is cached once found", () async {
    final package = stubRemoveAdsPackage();

    expect(await PurchasesManager.get.removeAdsPackage(), package);
    expect(await PurchasesManager.get.removeAdsPackage(), package);
    verify(managers.purchasesWrapper.getOfferings()).called(1);
  });

  test("removeAdsPackage is fetched again after a failure", () async {
    final exception = MockPlatformException();
    when(exception.message).thenReturn("Test error");
    when(managers.purchasesWrapper.getOfferings()).thenThrow(exception);
    expect(await PurchasesManager.get.removeAdsPackage(), isNull);

    final package = stubRemoveAdsPackage();
    expect(await PurchasesManager.get.removeAdsPackage(), package);
  });

  test("purchase refreshes entitlements if already purchased", () async {
    stubPurchaseError(PurchasesErrorCode.productAlreadyPurchasedError);
    when(managers.purchasesWrapper.getCustomerInfo())
        .thenAnswer((_) => Future.value(customerInfo(hasRemovedAds: true)));

    expect(await PurchasesManager.get.purchase(MockPackage()), isNull);
    expect(PurchasesManager.get.hasRemovedAds, isTrue);
  });

  test("purchase doesn't log error if already purchased", () async {
    final exception = MockPlatformException();
    when(exception.code).thenReturn(
        PurchasesErrorCode.productAlreadyPurchasedError.index.toString());
    when(managers.purchasesWrapper.purchase(any)).thenThrow(exception);

    await PurchasesManager.get.purchase(MockPackage());
    verifyNever(exception.message);
  });

  test("purchase returns customer info", () async {
    final info = customerInfo(hasRemovedAds: true);
    stubPurchase(info);
    expect(await PurchasesManager.get.purchase(MockPackage()), info);
  });

  test("purchaseRemoveAds is unavailable if package is missing", () async {
    final offerings = MockOfferings();
    when(offerings.getOffering(any)).thenReturn(null);
    when(managers.purchasesWrapper.getOfferings())
        .thenAnswer((_) => Future.value(offerings));

    expect(
      await PurchasesManager.get.purchaseRemoveAds(),
      RemoveAdsResult.unavailable,
    );
    verifyNever(managers.purchasesWrapper.purchase(any));
  });

  test("purchaseRemoveAds is purchased and removes ads", () async {
    stubRemoveAdsPackage();
    stubPurchase(customerInfo(hasRemovedAds: true));

    expect(
      await PurchasesManager.get.purchaseRemoveAds(),
      RemoveAdsResult.purchased,
    );
    expect(PurchasesManager.get.hasRemovedAds, isTrue);
  });

  test("purchaseRemoveAds is not purchased if entitlement is missing",
      () async {
    stubRemoveAdsPackage();
    stubPurchase(customerInfo(hasRemovedAds: false));

    expect(
      await PurchasesManager.get.purchaseRemoveAds(),
      RemoveAdsResult.notPurchased,
    );
    expect(PurchasesManager.get.hasRemovedAds, isFalse);
  });

  test("purchaseRemoveAds is not purchased if cancelled", () async {
    stubRemoveAdsPackage();
    stubPurchaseError(PurchasesErrorCode.purchaseCancelledError);

    expect(
      await PurchasesManager.get.purchaseRemoveAds(),
      RemoveAdsResult.notPurchased,
    );
  });

  test("purchaseRemoveAds is already owned if store account owns it", () async {
    stubRemoveAdsPackage();
    stubPurchaseError(PurchasesErrorCode.productAlreadyPurchasedError);
    when(managers.purchasesWrapper.getCustomerInfo())
        .thenAnswer((_) => Future.value(customerInfo(hasRemovedAds: true)));

    expect(
      await PurchasesManager.get.purchaseRemoveAds(),
      RemoveAdsResult.alreadyOwned,
    );
    expect(PurchasesManager.get.hasRemovedAds, isTrue);
  });

  test("restorePurchases succeeds if ads were removed", () async {
    when(managers.purchasesWrapper.restorePurchases())
        .thenAnswer((_) => Future.value(customerInfo(hasRemovedAds: true)));

    expect(
      await PurchasesManager.get.restorePurchases(),
      RestorePurchasesResult.success,
    );
    expect(PurchasesManager.get.hasRemovedAds, isTrue);
  });

  test("restorePurchases finds nothing if ads weren't removed", () async {
    when(managers.purchasesWrapper.restorePurchases())
        .thenAnswer((_) => Future.value(customerInfo(hasRemovedAds: false)));

    expect(
      await PurchasesManager.get.restorePurchases(),
      RestorePurchasesResult.none,
    );
  });

  test("restorePurchases returns error on failure", () async {
    final exception = MockPlatformException();
    when(exception.message).thenReturn("Test error");
    when(managers.purchasesWrapper.restorePurchases()).thenThrow(exception);

    expect(
      await PurchasesManager.get.restorePurchases(),
      RestorePurchasesResult.error,
    );
    verify(exception.message).called(1);
  });

  test("userId returns original app user ID", () async {
    final info = customerInfo(hasRemovedAds: false);
    when(info.originalAppUserId).thenReturn("user-id");
    when(managers.purchasesWrapper.getCustomerInfo())
        .thenAnswer((_) => Future.value(info));

    expect(await PurchasesManager.get.userId(), "user-id");
  });
}
