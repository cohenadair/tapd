import 'dart:ui';

import 'package:confetti/confetti.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mobile/managers/orientation_manager.dart';
import 'package:mobile/tapd_game.dart';
import 'package:mobile/tapd_world.dart';
import 'package:mobile/components/target.dart';
import 'package:mobile/components/target_board.dart';
import 'package:mobile/managers/audio_manager.dart';
import 'package:mobile/managers/preference_manager.dart';
import 'package:mobile/managers/properties_manager.dart';
import 'package:mobile/managers/purchases_manager.dart';
import 'package:mobile/managers/stats_manager.dart';
import 'package:mobile/managers/time_manager.dart';
import 'package:mobile/wrappers/analytics_wrapper.dart';
import 'package:mobile/wrappers/banner_ad_wrapper.dart';
import 'package:mobile/wrappers/confetti_wrapper.dart';
import 'package:mobile/wrappers/connection_wrapper.dart';
import 'package:mobile/wrappers/crashlytics_wrapper.dart';
import 'package:mobile/wrappers/device_info_wrapper.dart';
import 'package:mobile/wrappers/fgbg_wrapper.dart';
import 'package:mobile/wrappers/flame_audio_wrapper.dart';
import 'package:mobile/wrappers/flame_wrapper.dart';
import 'package:mobile/wrappers/http_wrapper.dart';
import 'package:mobile/wrappers/in_app_review_wrapper.dart';
import 'package:mobile/wrappers/package_info_wrapper.dart';
import 'package:mobile/wrappers/platform_dispatcher_wrapper.dart';
import 'package:mobile/wrappers/platform_wrapper.dart';
import 'package:mobile/wrappers/purchases_wrapper.dart';
import 'package:mobile/wrappers/rewarded_ad_wrapper.dart';
import 'package:mobile/wrappers/url_launcher_wrapper.dart';
import 'package:mockito/annotations.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

@GenerateMocks([AnalyticsWrapper])
@GenerateMocks([AndroidBuildVersion])
@GenerateMocks([AndroidDeviceInfo])
@GenerateMocks([AudioManager])
@GenerateMocks([AudioPlayer])
@GenerateMocks([AudioPool])
@GenerateMocks([BannerAd])
@GenerateMocks([BannerAdWrapper])
@GenerateMocks([Canvas])
@GenerateMocks([CrashlyticsWrapper])
@GenerateMocks([TapdGame])
@GenerateMocks([TapdWorld])
@GenerateMocks([], customMocks: [MockSpec<ComponentsNotifier>()])
@GenerateMocks([ConnectionWrapper])
@GenerateMocks([ConfettiController])
@GenerateMocks([ConfettiWrapper])
@GenerateMocks([CustomerInfo])
@GenerateMocks([DeviceInfoWrapper])
@GenerateMocks([EntitlementInfo])
@GenerateMocks([FgbgWrapper])
@GenerateMocks([FlameWrapper])
@GenerateMocks([FlameAudioWrapper])
@GenerateMocks([FlutterView])
@GenerateMocks([HttpWrapper])
@GenerateMocks([InAppReviewWrapper])
@GenerateMocks([Offering])
@GenerateMocks([Offerings])
@GenerateMocks([OrientationManager])
@GenerateMocks([Package])
@GenerateMocks([PackageInfoWrapper])
@GenerateMocks([PlatformDispatcher])
@GenerateMocks([PlatformDispatcherWrapper])
@GenerateMocks([PlatformException])
@GenerateMocks([PlatformWrapper])
@GenerateMocks([PreferenceManager])
@GenerateMocks([PropertiesManager])
@GenerateMocks([PurchaseResult])
@GenerateMocks([PurchasesManager])
@GenerateMocks([PurchasesWrapper])
@GenerateMocks([RewardedAd])
@GenerateMocks([RewardedAdWrapper])
@GenerateMocks([SharedPreferences])
@GenerateMocks([Sprite])
@GenerateMocks([StatsManager])
@GenerateMocks([StoreProduct])
@GenerateMocks([TapDownEvent])
@GenerateMocks([Target])
@GenerateMocks([TargetBoard])
@GenerateMocks([TimeManager])
@GenerateMocks([UrlLauncherWrapper])
@GenerateMocks([Viewport])
main() {}
