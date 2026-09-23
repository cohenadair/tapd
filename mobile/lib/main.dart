import 'dart:io';
import 'dart:isolate';

import 'package:adair_flutter_lib/managers/time_manager.dart';
import 'package:adair_flutter_lib/wrappers/analytics_wrapper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flame/flame.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mobile/managers/audio_manager.dart';
import 'package:mobile/managers/orientation_manager.dart';
import 'package:mobile/managers/preference_manager.dart';
import 'package:mobile/managers/properties_manager.dart';
import 'package:mobile/managers/stats_manager.dart';

import 'firebase_options.dart';
import 'tapd_game.dart';
import 'tapd_game_widget.dart';
import 'tapd_world.dart';
import 'managers/purchases_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  // Firebase.
  const isFirebaseEnabled = kReleaseMode;

  void killFirebaseApp() {
    if (isFirebaseEnabled) {
      exit(1);
    }
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Analytics.
  await AnalyticsWrapper.get.setAnalyticsCollectionEnabled(isFirebaseEnabled);

  // Crashlytics.
  await FirebaseCrashlytics.instance
      .setCrashlyticsCollectionEnabled(isFirebaseEnabled);

  // Pass all uncaught "fatal" errors from the framework to Crashlytics.
  FlutterError.onError = (details) async {
    await FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    killFirebaseApp();
  };

  // Catch non-Flutter errors.
  Isolate.current.addErrorListener(RawReceivePort((pair) async {
    await FirebaseCrashlytics.instance.recordError(
      pair.first,
      pair.last,
      fatal: true,
      printDetails: true,
    );
    killFirebaseApp();
  }).sendPort);

  // Pass all uncaught asynchronous errors that aren't handled by the Flutter
  // framework to Crashlytics.
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance
        .recordError(
          error,
          stack,
          fatal: true,
          printDetails: true,
        )
        .then((_) => killFirebaseApp());
    return true;
  };

  // Init game settings.
  await Flame.device.fullScreen();
  await OrientationManager.get.reset();

  // Init singletons.
  await MobileAds.instance.initialize();
  await PreferenceManager.get.init();
  await PropertiesManager.get.init();
  await PurchasesManager.get.init();
  await AudioManager.get.init();
  await StatsManager.get.init();
  await TimeManager.get.init();

  final myGame = TapdGame(world: TapdWorld());
  runApp(TapdGameWidget(myGame));
}
