import 'package:flame/flame.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class FlameWrapper {
  static var _instance = FlameWrapper._();

  static FlameWrapper get get => _instance;

  @visibleForTesting
  static void set(FlameWrapper manager) => _instance = manager;

  FlameWrapper._();

  Future<void> setPortrait() => Flame.device.setPortrait();

  Future<void> setLandscape() => Flame.device.setLandscape();

  Future<void> setOrientations(List<DeviceOrientation> orientations) =>
      Flame.device.setOrientations(orientations);
}
