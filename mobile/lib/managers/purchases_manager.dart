import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/managers/properties_manager.dart';
import 'package:mobile/wrappers/platform_wrapper.dart';
import 'package:mobile/wrappers/purchases_wrapper.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../log.dart';

/// The outcome of [PurchasesManager.restorePurchases].
enum RestorePurchasesResult {
  /// Purchases were restored and the user has "Remove Ads".
  success,

  /// The restore completed, but the user hasn't purchased "Remove Ads".
  none,

  /// The restore failed, such as when the device is offline.
  error,
}

/// The outcome of [PurchasesManager.purchaseRemoveAds].
enum RemoveAdsResult {
  /// The user purchased "Remove Ads".
  purchased,

  /// The user already owned "Remove Ads" on their store account, such as after
  /// a reinstall. Entitlements are refreshed, so ads are removed.
  alreadyOwned,

  /// The product couldn't be loaded, such as when the device is offline.
  unavailable,

  /// The purchase was cancelled or failed.
  notPurchased,
}

class PurchasesManager {
  static var _instance = PurchasesManager._();

  static PurchasesManager get get => _instance;

  @visibleForTesting
  static void set(PurchasesManager manager) => _instance = manager;

  @visibleForTesting
  static void suicide() => _instance = PurchasesManager._();

  PurchasesManager._();

  static const _log = Log("PurchasesManager");

  /// The entitlement granted by the "Remove Ads" purchase. Equal to the ID in
  /// the RevenueCat dashboard. This _cannot_ change.
  static const entitlementRemoveAds = "remove_ads";

  /// The ID of the "Remove Ads" offering. Equal to the ID in the RevenueCat
  /// dashboard. This _cannot_ change. Note that this offering is intentionally
  /// not the "current" offering; that is reserved for the lives packages, which
  /// older app versions read from.
  static const offeringRemoveAds = "remove_ads";

  /// The ID of the "Remove Ads" package in [offeringRemoveAds]. Equal to the ID
  /// in the RevenueCat dashboard, which is RevenueCat's standard lifetime
  /// package ID (not the product ID). This _cannot_ change.
  static const packageRemoveAds = r"$rc_lifetime";

  /// The longest [init] will wait for entitlements to be fetched. If the
  /// request takes longer, startup continues and listeners of [stream] are
  /// notified when the request finally completes.
  static const _entitlementsInitTimeout = Duration(seconds: 1);

  final _controller = StreamController.broadcast();

  var _hasRemovedAds = false;

  Package? _removeAdsPackage;

  /// Emits whenever [hasRemovedAds] changes.
  Stream get stream => _controller.stream;

  /// True if the user has purchased "Remove Ads". This value is cached, and
  /// updated on app start, after a purchase, and after purchases are restored.
  bool get hasRemovedAds => _hasRemovedAds;

  Future<void> init() async {
    await PurchasesWrapper.get.setLogLevel(
        PlatformWrapper.get.isDebug ? LogLevel.verbose : LogLevel.error);
    await PurchasesWrapper.get.configure(PurchasesConfiguration(
      PlatformWrapper.get.isAndroid
          ? PropertiesManager.get.revenueCatKeyAndroid
          : PropertiesManager.get.revenueCatKeyApple,
    ));

    // Wait for entitlements so users who removed ads don't see ads (or the
    // purchase card) flash on launch. The wait is capped so a slow or offline
    // connection can't stall app startup. The timeout doesn't cancel the
    // request; when it completes, [stream] notifies listeners. Note that
    // widgets that read [hasRemovedAds] without listening to [stream] won't
    // update if they were built before then.
    await refreshEntitlements()
        .timeout(_entitlementsInitTimeout, onTimeout: () {});
  }

  /// Fetches the user's entitlements and updates [hasRemovedAds]. Never throws;
  /// on error, the previously cached value is kept.
  Future<void> refreshEntitlements() async {
    try {
      _updateEntitlements(await PurchasesWrapper.get.getCustomerInfo());
    } on PlatformException catch (e) {
      _log.e(StackTrace.current, "Error fetching customer info: ${e.message}");
    }
  }

  /// Returns the "Remove Ads" package, or null if it can't be found, such as
  /// when the device is offline. A found package is cached, so offerings are
  /// only fetched again after a failure.
  Future<Package?> removeAdsPackage() async {
    final cached = _removeAdsPackage;
    if (cached != null) {
      return cached;
    }

    try {
      final offerings = await PurchasesWrapper.get.getOfferings();
      _removeAdsPackage = offerings
          .getOffering(offeringRemoveAds)
          ?.availablePackages
          .firstWhereOrNull((e) => e.identifier == packageRemoveAds);
    } on PlatformException catch (e) {
      _log.e(StackTrace.current, "Error fetching offerings: ${e.message}");
    }
    return _removeAdsPackage;
  }

  /// Purchases the "Remove Ads" package, loading it first if necessary.
  Future<RemoveAdsResult> purchaseRemoveAds() async {
    final package = await removeAdsPackage();
    if (package == null) {
      return RemoveAdsResult.unavailable;
    }

    final info = await purchase(package);
    if (info == null) {
      // A null result with entitlements is the "already purchased" case, which
      // is handled by [purchase].
      return hasRemovedAds
          ? RemoveAdsResult.alreadyOwned
          : RemoveAdsResult.notPurchased;
    }

    _updateEntitlements(info);
    return hasRemovedAds
        ? RemoveAdsResult.purchased
        : RemoveAdsResult.notPurchased;
  }

  /// Restores previous purchases.
  Future<RestorePurchasesResult> restorePurchases() async {
    try {
      _updateEntitlements(await PurchasesWrapper.get.restorePurchases());
    } on PlatformException catch (e) {
      _log.e(StackTrace.current, "Error restoring purchases: ${e.message}");
      return RestorePurchasesResult.error;
    }
    return hasRemovedAds
        ? RestorePurchasesResult.success
        : RestorePurchasesResult.none;
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
      if (code == PurchasesErrorCode.productAlreadyPurchasedError) {
        // The store account already owns the product, but the app doesn't know
        // it yet. Fetch entitlements so the purchase is reflected.
        await refreshEntitlements();
      } else if (code != PurchasesErrorCode.purchaseCancelledError &&
          code != PurchasesErrorCode.storeProblemError) {
        _log.e(StackTrace.current, "Purchase error: ${e.message}");
      }
      return null;
    }
  }

  Future<String> userId() async =>
      (await PurchasesWrapper.get.getCustomerInfo()).originalAppUserId;

  void _updateEntitlements(CustomerInfo info) {
    var hasRemovedAds =
        info.entitlements.active.containsKey(entitlementRemoveAds);
    if (hasRemovedAds == _hasRemovedAds) {
      return;
    }
    _hasRemovedAds = hasRemovedAds;
    _controller.add(null);
  }
}
