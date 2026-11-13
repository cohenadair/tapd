import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/managers/orientation_manager.dart';
import 'package:mockito/mockito.dart';

import '../test_utils/stubbed_managers.dart';

void main() {
  late StubbedManagers managers;

  setUp(() {
    managers = StubbedManagers();
    OrientationManager.suicide();
  });

  test("Set orientation to same value is a no-op", () async {
    var called = false;
    OrientationManager.get.stream.listen((_) => called = true);

    OrientationManager.get.orientation = null;
    await Future.delayed(const Duration(milliseconds: 50));

    expect(called, isFalse);
  });

  test("Set orientation to new value notifies listeners", () async {
    var called = false;
    OrientationManager.get.stream.listen((_) => called = true);

    OrientationManager.get.orientation = Orientation.portrait;
    await Future.delayed(const Duration(milliseconds: 50));

    expect(called, isTrue);
  });

  test("lockCurrent() exits if orientation isn't set", () async {
    await OrientationManager.get.lockCurrent();
    verifyNever(managers.flameWrapper.setPortrait());
    verifyNever(managers.flameWrapper.setLandscape());
  });

  test("lockCurrent() locks portrait", () async {
    OrientationManager.get.orientation = Orientation.portrait;
    await OrientationManager.get.lockCurrent();
    verify(managers.flameWrapper.setPortrait()).called(1);
    verifyNever(managers.flameWrapper.setLandscape());
  });

  test("lockCurrent() locks landscape", () async {
    OrientationManager.get.orientation = Orientation.landscape;
    await OrientationManager.get.lockCurrent();
    verifyNever(managers.flameWrapper.setPortrait());
    verify(managers.flameWrapper.setLandscape()).called(1);
  });

  testWidgets("reset() sets portrait", (tester) async {
    when(managers.platformDispatcherWrapper.displaySize)
        .thenReturn(const Size(100, 200));
    when(managers.platformDispatcherWrapper.displayDevicePixelRatio)
        .thenReturn(1.0);

    await OrientationManager.get.reset();
    verify(managers.flameWrapper.setPortrait()).called(1);
    verifyNever(managers.flameWrapper.setOrientations(any));
  });

  testWidgets("reset() sets all", (tester) async {
    when(managers.platformDispatcherWrapper.displaySize)
        .thenReturn(const Size(4096, 2160));
    when(managers.platformDispatcherWrapper.displayDevicePixelRatio)
        .thenReturn(1.0);

    await OrientationManager.get.reset();
    verifyNever(managers.flameWrapper.setPortrait());
    verify(managers.flameWrapper.setOrientations(any)).called(1);
  });
}
