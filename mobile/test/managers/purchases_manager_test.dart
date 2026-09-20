import 'package:mobile/managers/purchases_manager.dart';
import 'package:mockito/mockito.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:test/test.dart';

import '../mocks/mocks.mocks.dart';
import '../test_utils/stubbed_managers.dart';

void main() {
  late StubbedManagers managers;

  setUp(() {
    managers = StubbedManagers();

    when(managers.purchasesWrapper.setLogLevel(any))
        .thenAnswer((_) => Future.value());
    when(managers.purchasesWrapper.configure(any))
        .thenAnswer((_) => Future.value());

    when(managers.platformWrapper.isDebug).thenReturn(true);
    when(managers.platformWrapper.isAndroid).thenReturn(true);

    when(managers.propertiesManager.revenueCatKeyAndroid).thenReturn("android");
    when(managers.propertiesManager.revenueCatKeyApple).thenReturn("apple");

    PurchasesManager.suicide();
  });

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
}
