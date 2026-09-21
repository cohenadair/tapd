import '../managers/properties_manager.dart';
import '../wrappers/platform_wrapper.dart';

String adUnitId({
  required String androidTestId,
  required String iosTestId,
  required String androidRealId,
  required String iosRealId,
}) {
  return PlatformWrapper.get.isDebug
      ? PlatformWrapper.get.isAndroid
          ? androidTestId
          : iosTestId
      : PlatformWrapper.get.isAndroid
          ? androidRealId
          : iosRealId;
}

String bannerAdUnitId() {
  return adUnitId(
    androidTestId: "ca-app-pub-3940256099942544/6300978111",
    iosTestId: "ca-app-pub-3940256099942544/2934735716",
    androidRealId: PropertiesManager.get.adBannerUnitIdAndroid,
    iosRealId: PropertiesManager.get.adBannerUnitIdIos,
  );
}

String rewardedAdUnitId() {
  return adUnitId(
    androidTestId: "ca-app-pub-3940256099942544/5224354917",
    iosTestId: "ca-app-pub-3940256099942544/1712485313",
    androidRealId: PropertiesManager.get.adRewardedUnitIdAndroid,
    iosRealId: PropertiesManager.get.adRewardedUnitIdIos,
  );
}
