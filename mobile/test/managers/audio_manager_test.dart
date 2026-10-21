import 'dart:async';

import 'package:flame_audio/flame_audio.dart';
import 'package:flutter_fgbg/flutter_fgbg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/managers/audio_manager.dart';
import 'package:mobile/managers/preference_manager.dart';
import 'package:mockito/mockito.dart';

import '../mocks/mocks.mocks.dart';
import '../test_utils/stubbed_managers.dart';

void main() {
  late StubbedManagers managers;
  late MockAudioPool buttonTapPool;
  late MockAudioPool targetCorrectPool;
  late MockAudioPool targetIncorrectPool;
  late MockAudioPool targetSwitchPool;
  late MockAudioPlayer gamePlayer;
  late MockAudioPlayer menuPlayer;

  MockAudioPool stubAudioPool() {
    var result = MockAudioPool();
    when(result.start(volume: anyNamed("volume")))
        .thenAnswer((_) => Future.value(() async {}));
    return result;
  }

  MockAudioPlayer stubAudioPlayer() {
    var result = MockAudioPlayer();
    when(result.pause()).thenAnswer((_) => Future.value());
    when(result.resume()).thenAnswer((_) => Future.value());
    return result;
  }

  Future<void> initAudioManager() async {
    await AudioManager.get.init();
    verify(gamePlayer.pause()).called(1);
    verify(menuPlayer.pause()).called(1);
  }

  setUp(() {
    managers = StubbedManagers();
    buttonTapPool = stubAudioPool();
    targetCorrectPool = stubAudioPool();
    targetIncorrectPool = stubAudioPool();
    targetSwitchPool = stubAudioPool();
    gamePlayer = stubAudioPlayer();
    menuPlayer = stubAudioPlayer();

    when(managers.flameAudioWrapper.loadAll(any))
        .thenAnswer((_) => Future.value([]));

    when(managers.flameAudioWrapper.audioCache).thenReturn(MockAudioCache());
    when(managers.audioPoolWrapper.create(
      source: anyNamed("source"),
      maxPlayers: anyNamed("maxPlayers"),
      audioCache: anyNamed("audioCache"),
      audioContext: anyNamed("audioContext"),
    )).thenAnswer((invocation) {
      var fileName = (invocation.namedArguments[#source] as AssetSource).path;
      switch (fileName) {
        case "button-tap.mp3":
          return Future.value(buttonTapPool);
        case "target-correct.mp3":
          return Future.value(targetCorrectPool);
        case "target-incorrect.mp3":
          return Future.value(targetIncorrectPool);
        case "target-switch.mp3":
          return Future.value(targetSwitchPool);
        default:
          fail("Unknown audio pool file name: $fileName");
      }
    });
    when(managers.flameAudioWrapper.loop(
      any,
      volume: anyNamed("volume"),
    )).thenAnswer((invocation) {
      var fileName = invocation.positionalArguments.first;
      switch (fileName) {
        case "bg-game.mp3":
          return Future.value(gamePlayer);
        case "bg-menu.mp3":
          return Future.value(menuPlayer);
        default:
          fail("Unknown audio player file name: $fileName");
      }
    });

    when(managers.fgbgWrapper.stream).thenAnswer((_) => const Stream.empty());

    when(managers.preferenceManager.stream)
        .thenAnswer((_) => const Stream.empty());
    when(managers.preferenceManager.isMusicOn).thenReturn(true);
    when(managers.preferenceManager.isSoundOn).thenReturn(true);

    when(managers.platformWrapper.isAndroid).thenReturn(false);

    AudioManager.suicide();
  });

  test("Sound effects don't request audio focus on Android", () async {
    when(managers.platformWrapper.isAndroid).thenReturn(true);

    await initAudioManager();

    var contexts = verify(managers.audioPoolWrapper.create(
      source: anyNamed("source"),
      maxPlayers: anyNamed("maxPlayers"),
      audioCache: anyNamed("audioCache"),
      audioContext: captureAnyNamed("audioContext"),
    )).captured;
    expect(contexts.length, 4);
    for (var context in contexts) {
      expect(
        (context as AudioContext).android.audioFocus,
        AndroidAudioFocus.none,
      );
    }
  });

  test("Sound effects use the default audio context on iOS", () async {
    await initAudioManager();

    var contexts = verify(managers.audioPoolWrapper.create(
      source: anyNamed("source"),
      maxPlayers: anyNamed("maxPlayers"),
      audioCache: anyNamed("audioCache"),
      audioContext: captureAnyNamed("audioContext"),
    )).captured;
    expect(contexts.length, 4);
    expect(contexts.every((context) => context == null), isTrue);
  });

  test("Music is paused when app is backgrounded", () async {
    var controller = StreamController<FGBGType>.broadcast();
    when(managers.fgbgWrapper.stream).thenAnswer((_) => controller.stream);

    await initAudioManager();
    controller.add(FGBGType.background);
    await Future.delayed(const Duration(milliseconds: 50));

    verify(menuPlayer.pause()).called(1);
    verifyNever(menuPlayer.resume());
    verify(gamePlayer.pause()).called(1);
    verifyNever(gamePlayer.resume());
  });

  test("Music is resumed when app is foregrounded", () async {
    var controller = StreamController<FGBGType>.broadcast();
    when(managers.fgbgWrapper.stream).thenAnswer((_) => controller.stream);

    await initAudioManager();
    controller.add(FGBGType.foreground);
    await Future.delayed(const Duration(milliseconds: 50));

    verify(menuPlayer.pause()).called(1);
    verify(menuPlayer.resume()).called(1);
    verify(gamePlayer.pause()).called(1);
    verifyNever(gamePlayer.resume());
  });

  test("Non-music preferences update is a no-op", () async {
    var controller = StreamController<String>.broadcast();
    when(managers.preferenceManager.stream)
        .thenAnswer((_) => controller.stream);

    await initAudioManager();
    when(managers.preferenceManager.isMusicOn).thenReturn(true);
    controller.add(PreferenceManager.keyDifficulty);
    await Future.delayed(const Duration(milliseconds: 50));

    verifyNever(menuPlayer.resume());
    verifyNever(gamePlayer.resume());
  });

  test("Music is paused when turned off in preferences", () async {
    var controller = StreamController<String>.broadcast();
    when(managers.preferenceManager.stream)
        .thenAnswer((_) => controller.stream);
    when(managers.preferenceManager.isMusicOn).thenReturn(true);

    await initAudioManager();
    when(managers.preferenceManager.isMusicOn).thenReturn(false);
    controller.add(PreferenceManager.keyMusicOn);
    await Future.delayed(const Duration(milliseconds: 50));

    verify(menuPlayer.pause()).called(1);
    verifyNever(menuPlayer.resume());
    verify(gamePlayer.pause()).called(1);
    verifyNever(gamePlayer.resume());
  });

  test("Music is resumed when turned on in preferences", () async {
    var controller = StreamController<String>.broadcast();
    when(managers.preferenceManager.stream)
        .thenAnswer((_) => controller.stream);
    when(managers.preferenceManager.isMusicOn).thenReturn(false);

    await initAudioManager();
    when(managers.preferenceManager.isMusicOn).thenReturn(true);
    controller.add(PreferenceManager.keyMusicOn);
    await Future.delayed(const Duration(milliseconds: 50));

    verify(menuPlayer.pause()).called(1);
    verify(menuPlayer.resume()).called(1);
    verify(gamePlayer.pause()).called(1);
    verifyNever(gamePlayer.resume());
  });

  test("onButtonPressed plays sound and relays input", () async {
    await initAudioManager();

    var called = false;
    var callback = AudioManager.get.onButtonPressed(() => called = true);
    callback();

    expect(called, true);
    verify(buttonTapPool.start(volume: anyNamed("volume"))).called(1);
  });

  test("resumeMusic in game", () async {
    await initAudioManager();

    await AudioManager.get.playGameBackground();
    verify(menuPlayer.pause()).called(1);
    verifyNever(menuPlayer.resume());
    verify(gamePlayer.resume()).called(1);
    verify(gamePlayer.pause()).called(1);
  });

  test("resumeMusic in menu", () async {
    await initAudioManager();

    await AudioManager.get.playMenuBackground();
    verify(menuPlayer.resume()).called(1);
    verify(menuPlayer.pause()).called(1);
    verify(gamePlayer.pause()).called(1);
    verifyNever(gamePlayer.resume());
  });

  test("pauseMusic pauses both players", () async {
    await initAudioManager();

    await AudioManager.get.pauseMusic();
    verify(menuPlayer.pause()).called(1);
    verifyNever(menuPlayer.resume());
    verify(gamePlayer.pause()).called(1);
    verifyNever(gamePlayer.resume());
  });

  test("Sound not played when turned off", () async {
    when(managers.preferenceManager.isSoundOn).thenReturn(false);

    await initAudioManager();

    var called = false;
    var callback = AudioManager.get.onButtonPressed(() => called = true);
    callback();

    expect(called, true);
    verifyNever(buttonTapPool.start(volume: anyNamed("volume")));
  });

  test("Music not played when turned off", () async {
    when(managers.preferenceManager.isMusicOn).thenReturn(false);

    await initAudioManager();
    await AudioManager.get.playGameBackground();

    verify(menuPlayer.pause()).called(1);
    verifyNever(menuPlayer.resume());
    verifyNever(gamePlayer.resume());
    verify(gamePlayer.pause()).called(1);
  });

  test("Incorrect hit pauses music", () async {
    await initAudioManager();
    await AudioManager.get.playIncorrectHit();

    verify(menuPlayer.pause()).called(1);
    verify(gamePlayer.pause()).called(1);
    verify(targetIncorrectPool.start(volume: anyNamed("volume"))).called(1);
  });

  test("Correct hit plays right sound", () async {
    await initAudioManager();
    await AudioManager.get.playCorrectHit();
    verify(targetCorrectPool.start(volume: anyNamed("volume"))).called(1);
  });

  test("Switch target plays right sound", () async {
    await initAudioManager();
    await AudioManager.get.playSwitchTarget();
    verify(targetSwitchPool.start(volume: anyNamed("volume"))).called(1);
  });
}
