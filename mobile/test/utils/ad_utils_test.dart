import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/utils/ad_utils.dart';
import 'package:mockito/mockito.dart';

import '../test_utils/stubbed_managers.dart';

void main() {
  late StubbedManagers managers;

  setUp(() {
    managers = StubbedManagers();

    when(managers.propertiesManager.adBannerUnitIdAndroid)
        .thenReturn("real-banner-android");
    when(managers.propertiesManager.adBannerUnitIdIos)
        .thenReturn("real-banner-ios");
    when(managers.propertiesManager.adRewardedUnitIdAndroid)
        .thenReturn("real-rewarded-android");
    when(managers.propertiesManager.adRewardedUnitIdIos)
        .thenReturn("real-rewarded-ios");
  });

  test("Test Android ad unit IDs are used for debug builds", () {
    when(managers.platformWrapper.isDebug).thenReturn(true);
    when(managers.platformWrapper.isAndroid).thenReturn(true);

    expect(
      adUnitId(
        androidTestId: "androidTestId",
        iosTestId: "iosTestId",
        androidRealId: "androidRealId",
        iosRealId: "iosRealId",
      ),
      "androidTestId",
    );
  });

  test("Test iOS ad unit IDs are used for debug builds", () {
    when(managers.platformWrapper.isDebug).thenReturn(true);
    when(managers.platformWrapper.isAndroid).thenReturn(false);

    expect(
      adUnitId(
        androidTestId: "androidTestId",
        iosTestId: "iosTestId",
        androidRealId: "androidRealId",
        iosRealId: "iosRealId",
      ),
      "iosTestId",
    );
  });

  test("Valid Android ad unit IDs are used for non-debug builds", () {
    when(managers.platformWrapper.isDebug).thenReturn(false);
    when(managers.platformWrapper.isAndroid).thenReturn(true);

    expect(
      adUnitId(
        androidTestId: "androidTestId",
        iosTestId: "iosTestId",
        androidRealId: "androidRealId",
        iosRealId: "iosRealId",
      ),
      "androidRealId",
    );
  });

  test("Valid iOS ad unit IDs are used for non-debug builds", () {
    when(managers.platformWrapper.isDebug).thenReturn(false);
    when(managers.platformWrapper.isAndroid).thenReturn(false);

    expect(
      adUnitId(
        androidTestId: "androidTestId",
        iosTestId: "iosTestId",
        androidRealId: "androidRealId",
        iosRealId: "iosRealId",
      ),
      "iosRealId",
    );
  });

  test("bannerAdUnitId uses the test ID for debug builds", () {
    when(managers.platformWrapper.isDebug).thenReturn(true);
    when(managers.platformWrapper.isAndroid).thenReturn(true);

    expect(bannerAdUnitId(), "ca-app-pub-3940256099942544/6300978111");
  });

  test("bannerAdUnitId uses the real ID for non-debug builds", () {
    when(managers.platformWrapper.isDebug).thenReturn(false);
    when(managers.platformWrapper.isAndroid).thenReturn(false);

    expect(bannerAdUnitId(), "real-banner-ios");
  });

  test("rewardedAdUnitId uses the test ID for debug builds", () {
    when(managers.platformWrapper.isDebug).thenReturn(true);
    when(managers.platformWrapper.isAndroid).thenReturn(false);

    expect(rewardedAdUnitId(), "ca-app-pub-3940256099942544/1712485313");
  });

  test("rewardedAdUnitId uses the real ID for non-debug builds", () {
    when(managers.platformWrapper.isDebug).thenReturn(false);
    when(managers.platformWrapper.isAndroid).thenReturn(true);

    expect(rewardedAdUnitId(), "real-rewarded-android");
  });
}
