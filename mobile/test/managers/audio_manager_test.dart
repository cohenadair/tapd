import 'dart:async';
import 'dart:io';

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
    var state = PlayerState.stopped;
    when(result.state).thenAnswer((_) => state);
    when(result.pause()).thenAnswer((_) async => state = PlayerState.paused);
    when(result.resume()).thenAnswer((_) async => state = PlayerState.playing);
    return result;
  }

  Future<void> initAudioManager() async {
    await AudioManager.get.init();
    verify(gamePlayer.pause()).called(1);
    verify(menuPlayer.pause()).called(1);
  }

  /// Starts the menu music, then clears the player interactions so tests only
  /// verify what happens after it.
  Future<void> playMenuMusic() async {
    await AudioManager.get.playMenuBackground();
    verify(menuPlayer.resume()).called(1);
    clearInteractions(menuPlayer);
    clearInteractions(gamePlayer);
  }

  void verifyNoMusicCalls() {
    verifyNever(menuPlayer.pause());
    verifyNever(menuPlayer.resume());
    verifyNever(gamePlayer.pause());
    verifyNever(gamePlayer.resume());
  }

  void verifySoundPoolCreated(String file, int players) {
    verify(managers.audioPoolWrapper.create(
      source: argThat(
        predicate<AssetSource>((source) => source.path == file),
        named: "source",
      ),
      minPlayers: players,
      maxPlayers: players,
      playerMode: anyNamed("playerMode"),
      audioCache: anyNamed("audioCache"),
      audioContext: anyNamed("audioContext"),
    )).called(1);
  }

  List<dynamic> capturePlayerModes() {
    return verify(managers.audioPoolWrapper.create(
      source: anyNamed("source"),
      minPlayers: anyNamed("minPlayers"),
      maxPlayers: anyNamed("maxPlayers"),
      playerMode: captureAnyNamed("playerMode"),
      audioCache: anyNamed("audioCache"),
      audioContext: anyNamed("audioContext"),
    )).captured;
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
      minPlayers: anyNamed("minPlayers"),
      maxPlayers: anyNamed("maxPlayers"),
      playerMode: anyNamed("playerMode"),
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
      minPlayers: anyNamed("minPlayers"),
      maxPlayers: anyNamed("maxPlayers"),
      playerMode: anyNamed("playerMode"),
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
      minPlayers: anyNamed("minPlayers"),
      maxPlayers: anyNamed("maxPlayers"),
      playerMode: anyNamed("playerMode"),
      audioCache: anyNamed("audioCache"),
      audioContext: captureAnyNamed("audioContext"),
    )).captured;
    expect(contexts.length, 4);
    expect(contexts.every((context) => context == null), isTrue);
  });

  test("Sound effects use low latency players on Android", () async {
    when(managers.platformWrapper.isAndroid).thenReturn(true);
    await initAudioManager();

    var modes = capturePlayerModes();
    expect(modes.length, 4);
    expect(modes.every((mode) => mode == PlayerMode.lowLatency), isTrue);
  });

  test("Sound effects use media players on iOS", () async {
    await initAudioManager();

    var modes = capturePlayerModes();
    expect(modes.length, 4);
    expect(modes.every((mode) => mode == PlayerMode.mediaPlayer), isTrue);
  });

  test("Sound effect player is returned to its pool after playing on Android",
      () async {
    when(managers.platformWrapper.isAndroid).thenReturn(true);
    var stopped = false;
    when(targetCorrectPool.start(volume: anyNamed("volume")))
        .thenAnswer((_) => Future.value(() async => stopped = true));

    await initAudioManager();
    await AudioManager.get.playCorrectHit();
    expect(stopped, isFalse);

    await Future.delayed(const Duration(milliseconds: 200));
    expect(stopped, isTrue);
  });

  test("Sound effect player isn't stopped manually on iOS", () async {
    var stopped = false;
    when(targetCorrectPool.start(volume: anyNamed("volume")))
        .thenAnswer((_) => Future.value(() async => stopped = true));

    await initAudioManager();
    await AudioManager.get.playCorrectHit();
    await Future.delayed(const Duration(milliseconds: 200));

    expect(stopped, isFalse);
  });

  test("Rapid sound effects preload players so taps don't create new ones",
      () async {
    await initAudioManager();
    verifySoundPoolCreated("button-tap.mp3", 3);
    verifySoundPoolCreated("target-correct.mp3", 3);
  });

  test("Other sound effects preload a single player", () async {
    await initAudioManager();
    verifySoundPoolCreated("target-incorrect.mp3", 1);
    verifySoundPoolCreated("target-switch.mp3", 1);
  });

  test("Music is paused when app is backgrounded", () async {
    var controller = StreamController<FGBGType>.broadcast();
    when(managers.fgbgWrapper.stream).thenAnswer((_) => controller.stream);

    await initAudioManager();
    await playMenuMusic();
    controller.add(FGBGType.background);
    await Future.delayed(const Duration(milliseconds: 50));

    verify(menuPlayer.pause()).called(1);
    verifyNever(menuPlayer.resume());
    verifyNever(gamePlayer.pause());
    verifyNever(gamePlayer.resume());
  });

  test("Music is resumed when app is foregrounded", () async {
    var controller = StreamController<FGBGType>.broadcast();
    when(managers.fgbgWrapper.stream).thenAnswer((_) => controller.stream);

    await initAudioManager();
    controller.add(FGBGType.foreground);
    await Future.delayed(const Duration(milliseconds: 50));

    verifyNever(menuPlayer.pause());
    verify(menuPlayer.resume()).called(1);
    verifyNever(gamePlayer.pause());
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
    await playMenuMusic();
    when(managers.preferenceManager.isMusicOn).thenReturn(false);
    controller.add(PreferenceManager.keyMusicOn);
    await Future.delayed(const Duration(milliseconds: 50));

    verify(menuPlayer.pause()).called(1);
    verifyNever(menuPlayer.resume());
    verifyNever(gamePlayer.pause());
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

    verifyNever(menuPlayer.pause());
    verify(menuPlayer.resume()).called(1);
    verifyNever(gamePlayer.pause());
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
    verifyNever(menuPlayer.pause());
    verifyNever(menuPlayer.resume());
    verify(gamePlayer.resume()).called(1);
    verifyNever(gamePlayer.pause());
  });

  test("resumeMusic in menu", () async {
    await initAudioManager();

    await AudioManager.get.playMenuBackground();
    verify(menuPlayer.resume()).called(1);
    verifyNever(menuPlayer.pause());
    verifyNever(gamePlayer.pause());
    verifyNever(gamePlayer.resume());
  });

  test("resumeMusic pauses the other player", () async {
    await initAudioManager();
    await playMenuMusic();

    await AudioManager.get.playGameBackground();
    verify(menuPlayer.pause()).called(1);
    verify(gamePlayer.resume()).called(1);
  });

  test("resumeMusic is a no-op if the player is already playing", () async {
    await initAudioManager();
    await playMenuMusic();

    await AudioManager.get.resumeMusic();
    verifyNoMusicCalls();
  });

  test("resumeMusic resumes a player paused outside of AudioManager", () async {
    await initAudioManager();
    await playMenuMusic();

    // Simulates the platform pausing the player, such as on audio focus loss.
    when(menuPlayer.state).thenReturn(PlayerState.paused);

    await AudioManager.get.resumeMusic();
    verify(menuPlayer.resume()).called(1);
    verifyNever(gamePlayer.pause());
    verifyNever(gamePlayer.resume());
  });

  test("Overlapping resumeMusic calls leave only the last player playing",
      () async {
    await initAudioManager();
    await playMenuMusic();

    // Holds the menu player's pause, so the next call starts while the first
    // is still pausing.
    var pauseCompleter = Completer<void>();
    when(menuPlayer.pause()).thenAnswer((_) => pauseCompleter.future);

    var toGame = AudioManager.get.playGameBackground();
    var toMenu = AudioManager.get.playMenuBackground();
    pauseCompleter.complete();
    await Future.wait([toGame, toMenu]);

    verifyNever(gamePlayer.resume());
    verify(menuPlayer.resume()).called(1);
  });

  test("Sound effect durations cover each file", () async {
    for (var MapEntry(key: file, value: duration)
        in AudioManager.soundEffectDurations.entries) {
      var info = await Process.run("afinfo", ["assets/audio/$file"]);
      var seconds = double.parse(RegExp(r"estimated duration: ([\d.]+)")
          .firstMatch(info.stdout as String)!
          .group(1)!);
      expect(duration.inMicroseconds, greaterThan(seconds * 1000000),
          reason: file);
    }
  }, skip: Platform.isMacOS ? false : "Requires macOS's afinfo");

  test("pauseMusic pauses the playing player", () async {
    await initAudioManager();
    await playMenuMusic();

    await AudioManager.get.pauseMusic();
    verify(menuPlayer.pause()).called(1);
    verifyNever(gamePlayer.pause());
  });

  test("pauseMusic is a no-op if nothing is playing", () async {
    await initAudioManager();

    await AudioManager.get.pauseMusic();
    verifyNoMusicCalls();
  });

  test("resumeMusic resumes after pauseMusic", () async {
    await initAudioManager();
    await playMenuMusic();
    await AudioManager.get.pauseMusic();

    await AudioManager.get.resumeMusic();
    verify(menuPlayer.resume()).called(1);
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

    verifyNoMusicCalls();
  });

  test("resumeMusic pauses music that's playing after it's turned off",
      () async {
    await initAudioManager();
    await playMenuMusic();
    when(managers.preferenceManager.isMusicOn).thenReturn(false);

    await AudioManager.get.resumeMusic();
    verify(menuPlayer.pause()).called(1);
    verifyNever(menuPlayer.resume());
  });

  test("Incorrect hit pauses music", () async {
    await initAudioManager();
    await playMenuMusic();
    await AudioManager.get.playIncorrectHit();

    verify(menuPlayer.pause()).called(1);
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
