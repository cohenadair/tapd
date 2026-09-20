import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/managers/properties_manager.dart';
import 'package:mobile/wrappers/platform_wrapper.dart';
import 'package:mobile/wrappers/purchases_wrapper.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../log.dart';

class PurchasesManager {
  static var _instance = PurchasesManager._();

  static PurchasesManager get get => _instance;

  @visibleForTesting
  static void set(PurchasesManager manager) => _instance = manager;

  @visibleForTesting
  static void suicide() => _instance = PurchasesManager._();

  PurchasesManager._();

  static const _log = Log("PurchasesManager");

  Future<void> init() async {
    await PurchasesWrapper.get.setLogLevel(
        PlatformWrapper.get.isDebug ? LogLevel.verbose : LogLevel.error);
    await PurchasesWrapper.get.configure(PurchasesConfiguration(
      PlatformWrapper.get.isAndroid
          ? PropertiesManager.get.revenueCatKeyAndroid
          : PropertiesManager.get.revenueCatKeyApple,
    ));
  }

  Future<CustomerInfo?> purchase(Package package) async {
    // Note that this method doesn't return an error object because
    // purchase errors are shown by the underlying storefront UI.
    try {
      var result =
          await PurchasesWrapper.get.purchase(PurchaseParams.package(package));
      return result.customerInfo;
    } on PlatformException catch (e) {
      var code = PurchasesErrorHelper.getErrorCode(e);
      if (code != PurchasesErrorCode.purchaseCancelledError &&
          code != PurchasesErrorCode.storeProblemError) {
        _log.e(StackTrace.current, "Purchase error: ${e.message}");
      }
      return null;
    }
  }

  Future<String> userId() async =>
      (await PurchasesWrapper.get.getCustomerInfo()).originalAppUserId;
}
