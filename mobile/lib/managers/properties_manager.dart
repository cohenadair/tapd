import 'package:adair_flutter_lib/managers/properties_manager.dart' as lib;
import 'package:flutter/material.dart';

/// A class for accessing Tapd-specific data in configuration files. Keys that
/// are shared across apps, such as the support email, are accessed through
/// [lib.PropertiesManager], which is initialized by [init].
class PropertiesManager {
  static var _instance = PropertiesManager._();

  static PropertiesManager get get => _instance;

  @visibleForTesting
  static void set(PropertiesManager manager) => _instance = manager;

  @visibleForTesting
  static void suicide() => _instance = PropertiesManager._();

  PropertiesManager._();

  final String _keyAdRewardedUnitIdIos = "adRewardedUnitId.ios";
  final String _keyAdRewardedUnitIdAndroid = "adRewardedUnitId.android";
  final String _keyAdBannerUnitIdIos = "adBannerUnitId.ios";
  final String _keyAdBannerUnitIdAndroid = "adBannerUnitId.android";
  final String _keyRevenueCatApple = "revenueCat.apple";
  final String _keyRevenueCatAndroid = "revenueCat.android";

  Future<void> init() => lib.PropertiesManager.get.init();

  String get adRewardedUnitIdIos =>
      lib.PropertiesManager.get.stringForKey(_keyAdRewardedUnitIdIos);

  String get adRewardedUnitIdAndroid =>
      lib.PropertiesManager.get.stringForKey(_keyAdRewardedUnitIdAndroid);

  String get adBannerUnitIdIos =>
      lib.PropertiesManager.get.stringForKey(_keyAdBannerUnitIdIos);

  String get adBannerUnitIdAndroid =>
      lib.PropertiesManager.get.stringForKey(_keyAdBannerUnitIdAndroid);

  String get revenueCatKeyApple =>
      lib.PropertiesManager.get.stringForKey(_keyRevenueCatApple);

  String get revenueCatKeyAndroid =>
      lib.PropertiesManager.get.stringForKey(_keyRevenueCatAndroid);
}
