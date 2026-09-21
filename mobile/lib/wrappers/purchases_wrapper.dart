import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class PurchasesWrapper {
  static var _instance = PurchasesWrapper._();

  static PurchasesWrapper get get => _instance;

  @visibleForTesting
  static void set(PurchasesWrapper manager) => _instance = manager;

  PurchasesWrapper._();

  Future<void> configure(PurchasesConfiguration config) =>
      Purchases.configure(config);

  Future<void> setLogLevel(LogLevel logLevel) =>
      Purchases.setLogLevel(logLevel);

  Future<Offerings> getOfferings() => Purchases.getOfferings();

  Future<CustomerInfo> getCustomerInfo() => Purchases.getCustomerInfo();

  Future<PurchaseResult> purchase(PurchaseParams params) =>
      Purchases.purchase(params);

  Future<CustomerInfo> restorePurchases() => Purchases.restorePurchases();
}
