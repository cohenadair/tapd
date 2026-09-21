import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/overlays/continue_countdown.dart';
import 'package:mobile/overlays/continue_offer.dart';
import 'package:mobile/utils/overlay_utils.dart';
import 'package:mockito/mockito.dart';

import '../mocks/mocks.mocks.dart';
import '../test_utils/stubbed_managers.dart';
import '../test_utils/test_utils.dart';

void main() {
  late MockTapdGame game;
  late MockTapdWorld world;

  setUp(() {
    StubbedManagers();

    world = MockTapdWorld();
    game = MockTapdGame();
    when(game.world).thenReturn(world);
  });

  testWidgets("buildContinueOffer builds the continue offer", (tester) async {
    final context = await pumpContext(tester, (_) => const SizedBox());
    expect(buildContinueOffer(context, game), isA<ContinueOffer>());
  });

  testWidgets("buildContinueCountdown shows the world's countdown",
      (tester) async {
    final secondsLeft = ValueNotifier(5);
    when(world.continueSecondsLeft).thenReturn(secondsLeft);

    final context = await pumpContext(tester, (_) => const SizedBox());
    final countdown =
        buildContinueCountdown(context, game) as ContinueCountdown;
    expect(countdown.secondsLeft, secondsLeft);
  });
}
