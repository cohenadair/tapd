import 'package:flame/game.dart';
import 'package:flutter/src/widgets/basic.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/tapd_game.dart';
import 'package:mobile/tapd_game_widget.dart';
import 'package:mobile/tapd_world.dart';
import 'package:mobile/difficulty.dart';
import 'package:mockito/mockito.dart';

import 'mocks/mocks.mocks.dart';
import 'test_utils/stubbed_managers.dart';

void main() {
  late StubbedManagers managers;

  setUp(() {
    managers = StubbedManagers();

    var bannerAd = MockBannerAd();
    when(bannerAd.load()).thenAnswer((_) => Future.value());
    when(managers.bannerAdWrapper.newAd(
      size: anyNamed("size"),
      adUnitId: anyNamed("adUnitId"),
      listener: anyNamed("listener"),
      request: anyNamed("request"),
    )).thenReturn(bannerAd);

    when(managers.platformWrapper.isDebug).thenReturn(true);
    when(managers.platformWrapper.isAndroid).thenReturn(true);

    when(managers.preferenceManager.difficulty).thenReturn(Difficulty.normal);
    when(managers.preferenceManager.colorIndex).thenReturn(null);
    when(managers.preferenceManager.isFpsOn).thenReturn(false);
    when(managers.preferenceManager.didOnboard).thenReturn(true);

    when(managers.propertiesManager.adBannerUnitIdAndroid)
        .thenReturn("test-id-android");
    when(managers.propertiesManager.adBannerUnitIdIos)
        .thenReturn("test-id-ios");

    when(managers.statsManager.currentHighScore).thenReturn(0);
    when(managers.statsManager.currentGamesPlayed).thenReturn(0);

    when(managers.inAppReviewWrapper.isAvailable())
        .thenAnswer((_) => Future.value(false));
  });

  testWidgets("onLoad", (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(600, 1000);

    final game = TapdGame(world: TapdWorld());

    await tester.pumpWidget(TapdGameWidget(game));
    await tester.pump();
    expect(game.camera.viewport.position, Vector2(-300, -500));
  });
}
