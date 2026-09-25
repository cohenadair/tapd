import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/difficulty.dart';
import 'package:mobile/overlays/menu.dart';
import 'package:mobile/utils/alert_utils.dart';
import 'package:mockito/mockito.dart';

import '../mocks/mocks.mocks.dart';
import '../test_utils/stubbed_managers.dart';
import '../test_utils/test_utils.dart';

void main() {
  late StubbedManagers managers;
  late MockTapdGame game;
  late MockTapdWorld world;

  setUp(() {
    world = MockTapdWorld();
    when(world.shouldShowNewHighScore).thenReturn(false);

    game = MockTapdGame();
    when(game.world).thenReturn(world);

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

    when(managers.propertiesManager.adBannerUnitIdAndroid)
        .thenReturn("test-id-android");
    when(managers.propertiesManager.adBannerUnitIdIos)
        .thenReturn("test-id-ios");

    when(managers.statsManager.currentHighScore).thenReturn(0);
    when(managers.statsManager.currentGamesPlayed).thenReturn(0);
    when(managers.statsManager.gamesPlayed).thenReturn(0);

    when(managers.inAppReviewWrapper.isAvailable())
        .thenAnswer((_) => Future.value(false));
  });

  testWidgets("showErrorDialog", (tester) async {
    var context = await pumpContext(tester, (_) => Menu.main(game));
    var wasCalled = false;

    showErrorDialog(
      context,
      "Test error message",
      onDismissed: () => wasCalled = true,
    );
    await tester.pumpAndSettle();

    expect(find.text("Test error message"), findsOneWidget);

    await tapAndSettle(tester, find.text("Ok"));
    expect(find.text("Test error message"), findsNothing);
    expect(wasCalled, isTrue);
  });

  testWidgets("showContinueDialog", (tester) async {
    var context = await pumpContext(tester, (_) => Menu.main(game));
    var wasCalled = false;

    showContinueDialog(
      context,
      "Title",
      "Test continue message",
      onDismissed: () => wasCalled = true,
    );
    await tester.pumpAndSettle();

    expect(find.text("Test continue message"), findsOneWidget);

    await tapAndSettle(tester, find.text("Continue"));
    expect(find.text("Test continue message"), findsNothing);
    expect(wasCalled, isTrue);
  });
}
