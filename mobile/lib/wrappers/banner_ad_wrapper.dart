import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:material_ui/material_ui.dart';

class BannerAdWrapper {
  static var _instance = BannerAdWrapper._();

  static BannerAdWrapper get get => _instance;

  @visibleForTesting
  static void set(BannerAdWrapper manager) => _instance = manager;

  BannerAdWrapper._();

  BannerAd newAd({
    required AdSize size,
    required String adUnitId,
    required BannerAdListener listener,
    required AdRequest request,
  }) {
    return BannerAd(
      size: size,
      adUnitId: adUnitId,
      listener: listener,
      request: request,
    );
  }

  /// Needs to be wrapped because an ad needs to be loaded before being
  /// displayed within an [AdWidget], otherwise an exception is thrown, and we
  /// don't want to load actual ads during testing.
  Widget newWidget({required AdWithView ad}) => AdWidget(ad: ad);
}
