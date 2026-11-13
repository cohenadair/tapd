import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:material_ui/material_ui.dart';

class CrashlyticsWrapper {
  static var _instance = CrashlyticsWrapper._();

  static CrashlyticsWrapper get get => _instance;

  @visibleForTesting
  static void set(CrashlyticsWrapper manager) => _instance = manager;

  CrashlyticsWrapper._();

  Future<void> log(String message) => FirebaseCrashlytics.instance.log(message);

  Future<void> recordError(String message, StackTrace? stack, String reason) =>
      FirebaseCrashlytics.instance.recordError(message, stack, reason: reason);
}
