import 'package:adair_flutter_lib/managers/email_manager.dart';
import 'package:adair_flutter_lib/managers/properties_manager.dart' as lib;
import 'package:mobile/managers/audio_manager.dart';
import 'package:mobile/managers/orientation_manager.dart';
import 'package:mobile/managers/preference_manager.dart';
import 'package:mobile/managers/properties_manager.dart';
import 'package:mobile/managers/purchases_manager.dart';
import 'package:mobile/managers/stats_manager.dart';
import 'package:mobile/managers/time_manager.dart';
import 'package:adair_flutter_lib/wrappers/analytics_wrapper.dart';
import 'package:mobile/wrappers/banner_ad_wrapper.dart';
import 'package:mobile/wrappers/confetti_wrapper.dart';
import 'package:mobile/wrappers/crashlytics_wrapper.dart';
import 'package:mobile/wrappers/device_info_wrapper.dart';
import 'package:mobile/wrappers/fgbg_wrapper.dart';
import 'package:mobile/wrappers/flame_audio_wrapper.dart';
import 'package:mobile/wrappers/flame_wrapper.dart';
import 'package:mobile/wrappers/connection_wrapper.dart';
import 'package:mobile/wrappers/in_app_review_wrapper.dart';
import 'package:mobile/wrappers/package_info_wrapper.dart';
import 'package:mobile/wrappers/platform_dispatcher_wrapper.dart';
import 'package:mobile/wrappers/platform_wrapper.dart';
import 'package:mobile/wrappers/purchases_wrapper.dart';
import 'package:mobile/wrappers/rewarded_ad_wrapper.dart';
import 'package:mobile/wrappers/url_launcher_wrapper.dart';
import 'package:mockito/mockito.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../mocks/mocks.mocks.dart';

class StubbedManagers {
  late final MockEmailManager emailManager;
  late final MockLibPropertiesManager libPropertiesManager;

  late final MockAudioManager audioManager;
  late final MockOrientationManager orientationManager;
  late final MockPreferenceManager preferenceManager;
  late final MockPropertiesManager propertiesManager;
  late final MockPurchasesManager purchasesManager;
  late final MockStatsManager statsManager;
  late final MockTimeManager timeManager;

  late final MockAnalyticsWrapper analyticsWrapper;
  late final MockBannerAdWrapper bannerAdWrapper;
  late final MockCrashlyticsWrapper crashlyticsWrapper;
  late final MockDeviceInfoWrapper deviceInfoWrapper;
  late final MockFgbgWrapper fgbgWrapper;
  late final MockFlameWrapper flameWrapper;
  late final MockFlameAudioWrapper flameAudioWrapper;
  late final MockInAppReviewWrapper inAppReviewWrapper;
  late final MockConnectionWrapper connectionWrapper;
  late final MockConfettiWrapper confettiWrapper;
  late final MockPackageInfoWrapper packageInfoWrapper;
  late final MockPlatformWrapper platformWrapper;
  late final MockPlatformDispatcherWrapper platformDispatcherWrapper;
  late final MockPurchasesWrapper purchasesWrapper;
  late final MockRewardedAdWrapper rewardedAdWrapper;
  late final MockUrlLauncherWrapper urlLauncherWrapper;

  StubbedManagers() {
    emailManager = MockEmailManager();
    EmailManager.set(emailManager);

    libPropertiesManager = MockLibPropertiesManager();
    lib.PropertiesManager.set(libPropertiesManager);

    audioManager = MockAudioManager();
    when(audioManager.onButtonPressed(any)).thenAnswer(
        (invocation) => invocation.positionalArguments.first ?? () {});
    AudioManager.set(audioManager);

    orientationManager = MockOrientationManager();
    when(orientationManager.stream).thenAnswer((_) => const Stream.empty());
    OrientationManager.set(orientationManager);

    preferenceManager = MockPreferenceManager();
    when(preferenceManager.init()).thenAnswer((_) => Future.value());
    when(preferenceManager.stream).thenAnswer((_) => const Stream.empty());
    PreferenceManager.set(preferenceManager);

    propertiesManager = MockPropertiesManager();
    when(propertiesManager.init()).thenAnswer((_) => Future.value());
    PropertiesManager.set(propertiesManager);

    purchasesManager = MockPurchasesManager();
    when(purchasesManager.init()).thenAnswer((_) => Future.value());
    when(purchasesManager.stream).thenAnswer((_) => const Stream.empty());
    when(purchasesManager.hasRemovedAds).thenReturn(false);
    when(purchasesManager.removeAdsPackage()).thenAnswer((_) => Future.value());
    PurchasesManager.set(purchasesManager);

    statsManager = MockStatsManager();
    StatsManager.set(statsManager);

    timeManager = MockTimeManager();
    when(timeManager.millisSinceEpoch)
        .thenReturn(DateTime.now().millisecondsSinceEpoch);
    TimeManager.set(timeManager);

    fgbgWrapper = MockFgbgWrapper();
    when(fgbgWrapper.stream).thenAnswer((_) => const Stream.empty());
    FgbgWrapper.set(fgbgWrapper);

    flameWrapper = MockFlameWrapper();
    FlameWrapper.set(flameWrapper);
    when(flameWrapper.loadSprite(any))
        .thenAnswer((_) => Future.value(MockSprite()));

    flameAudioWrapper = MockFlameAudioWrapper();
    FlameAudioWrapper.set(flameAudioWrapper);

    analyticsWrapper = MockAnalyticsWrapper();
    AnalyticsWrapper.set(analyticsWrapper);

    bannerAdWrapper = MockBannerAdWrapper();
    BannerAdWrapper.set(bannerAdWrapper);

    crashlyticsWrapper = MockCrashlyticsWrapper();
    CrashlyticsWrapper.set(crashlyticsWrapper);

    deviceInfoWrapper = MockDeviceInfoWrapper();
    DeviceInfoWrapper.set(deviceInfoWrapper);

    inAppReviewWrapper = MockInAppReviewWrapper();
    InAppReviewWrapper.set(inAppReviewWrapper);

    connectionWrapper = MockConnectionWrapper();
    ConnectionWrapper.set(connectionWrapper);

    confettiWrapper = MockConfettiWrapper();
    ConfettiWrapper.set(confettiWrapper);

    packageInfoWrapper = MockPackageInfoWrapper();
    when(packageInfoWrapper.fromPlatform()).thenAnswer(
      (_) => Future.value(
        PackageInfo(
          buildNumber: "5",
          appName: "Test",
          version: "2.7.0",
          packageName: "test.com",
        ),
      ),
    );
    PackageInfoWrapper.set(packageInfoWrapper);

    platformWrapper = MockPlatformWrapper();
    PlatformWrapper.set(platformWrapper);

    platformDispatcherWrapper = MockPlatformDispatcherWrapper();
    PlatformDispatcherWrapper.set(platformDispatcherWrapper);

    purchasesWrapper = MockPurchasesWrapper();
    PurchasesWrapper.set(purchasesWrapper);

    urlLauncherWrapper = MockUrlLauncherWrapper();
    UrlLauncherWrapper.set(urlLauncherWrapper);

    rewardedAdWrapper = MockRewardedAdWrapper();
    RewardedAdWrapper.set(rewardedAdWrapper);
  }
}
