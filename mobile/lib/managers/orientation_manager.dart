import 'dart:async';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/wrappers/platform_dispatcher_wrapper.dart';

import '../wrappers/flame_wrapper.dart';

class OrientationManager {
  static var _instance = OrientationManager._();

  static OrientationManager get get => _instance;

  @visibleForTesting
  static void set(OrientationManager manager) => _instance = manager;

  @visibleForTesting
  static void suicide() => _instance = OrientationManager._();

  OrientationManager._();

  final _controller = StreamController.broadcast();

  Orientation? _orientation;

  Stream get stream => _controller.stream;

  Orientation? get orientation => _orientation;

  set orientation(Orientation? orientation) {
    if (_orientation == orientation) {
      return;
    }
    _orientation = orientation;
    _controller.add(null);
  }

  Future<void> lockCurrent() async {
    if (orientation == null) {
      return;
    }
    return orientation == Orientation.portrait
        ? FlameWrapper.get.setPortrait()
        : FlameWrapper.get.setLandscape();
  }

  Future<void> reset() async {
    // Restrict orientation to portrait for devices with a small width. A width
    // of 740 is less than the smallest iPad, and most Android tablets.
    return PlatformDispatcherWrapper.get.displaySize.shortestSide /
                PlatformDispatcherWrapper.get.displayDevicePixelRatio <
            740
        ? FlameWrapper.get.setPortrait()
        : FlameWrapper.get.setOrientations(DeviceOrientation.values);
  }
}
