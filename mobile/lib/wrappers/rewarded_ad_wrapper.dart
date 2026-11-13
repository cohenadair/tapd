import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:material_ui/material_ui.dart';

class RewardedAdWrapper {
  static var _instance = RewardedAdWrapper._();

  static RewardedAdWrapper get get => _instance;

  @visibleForTesting
  static void set(RewardedAdWrapper manager) => _instance = manager;

  RewardedAdWrapper._();

  Future<void> load({
    required String adUnitId,
    required AdRequest request,
    required RewardedAdLoadCallback rewardedAdLoadCallback,
  }) {
    return RewardedAd.load(
      adUnitId: adUnitId,
      request: request,
      rewardedAdLoadCallback: rewardedAdLoadCallback,
    );
  }
}
