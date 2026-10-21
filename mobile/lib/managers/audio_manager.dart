import 'dart:async';

import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_fgbg/flutter_fgbg.dart';
import 'package:mobile/managers/preference_manager.dart';
import 'package:mobile/wrappers/audio_pool_wrapper.dart';
import 'package:mobile/wrappers/fgbg_wrapper.dart';
import 'package:mobile/wrappers/flame_audio_wrapper.dart';
import 'package:mobile/wrappers/platform_wrapper.dart';

class AudioManager {
  static var _instance = AudioManager._();

  static AudioManager get get => _instance;

  @visibleForTesting
  static void set(AudioManager manager) => _instance = manager;

  @visibleForTesting
  static void suicide() => _instance = AudioManager._();

  AudioManager._();

  static const _fileGame = "bg-game.mp3";
  static const _fileMenu = "bg-menu.mp3";
  static const _fileButtonTap = "button-tap.mp3";
  static const _fileTargetCorrect = "target-correct.mp3";
  static const _fileTargetIncorrect = "target-incorrect.mp3";
  static const _fileTargetSwitch = "target-switch.mp3";

  static const _volumeSoundEffectDefault = 1.0;
  static const _volumeMusicDefault = 0.25;

  /// On Android, every player requests audio focus by default, and a music
  /// player that loses focus is paused. Sound effects must not request focus,
  /// otherwise the first one played stops the background music.
  static final _soundEffectContextAndroid = AudioContext(
    android: const AudioContextAndroid(audioFocus: AndroidAudioFocus.none),
  );

  late final AudioPlayer _gamePlayer;
  late final AudioPlayer _menuPlayer;
  late final AudioPool _buttonTapPool;
  late final AudioPool _targetCorrectPool;
  late final AudioPool _targetIncorrectPool;
  late final AudioPool _targetSwitchPool;

  var _gameState = _AudioManagerState.inMenu;

  Future<void> init() async {
    // Cache all sounds and music.
    await FlameAudioWrapper.get.loadAll([
      _fileGame,
      _fileMenu,
      _fileButtonTap,
      _fileTargetCorrect,
      _fileTargetIncorrect,
      _fileTargetSwitch,
    ]);

    FgbgWrapper.get.stream.listen((type) {
      switch (type) {
        case FGBGType.foreground:
          resumeMusic();
        case FGBGType.background:
          pauseMusic();
      }
    });

    PreferenceManager.get.stream.listen((key) {
      if (key != PreferenceManager.keyMusicOn) {
        return;
      }

      if (PreferenceManager.get.isMusicOn) {
        resumeMusic();
      } else {
        pauseMusic();
      }
    });

    _gamePlayer = await _createMusicPlayer(_fileGame)
      ..pause();
    _menuPlayer = await _createMusicPlayer(_fileMenu)
      ..pause();

    _buttonTapPool = await _createSoundPool(_fileButtonTap);
    _targetCorrectPool = await _createSoundPool(_fileTargetCorrect);
    _targetIncorrectPool = await _createSoundPool(_fileTargetIncorrect);
    _targetSwitchPool = await _createSoundPool(_fileTargetSwitch);
  }

  VoidCallback onButtonPressed([VoidCallback? callback]) {
    return () {
      _playSound(_buttonTapPool);
      callback?.call();
    };
  }

  Future<void> resumeMusic() async {
    // Stop all players before resuming the correct one.
    await pauseMusic();

    switch (_gameState) {
      case _AudioManagerState.inGame:
        return _resumePlayer(_gamePlayer);
      case _AudioManagerState.inMenu:
        return _resumePlayer(_menuPlayer);
    }
  }

  Future<void> pauseMusic() async {
    await _gamePlayer.pause();
    return _menuPlayer.pause();
  }

  Future<void> playMenuBackground() {
    _gameState = _AudioManagerState.inMenu;
    return resumeMusic();
  }

  Future<void> playGameBackground() {
    _gameState = _AudioManagerState.inGame;
    return resumeMusic();
  }

  Future<void> playCorrectHit() => _playSound(_targetCorrectPool);

  Future<void> playIncorrectHit() async {
    await pauseMusic();
    return _playSound(_targetIncorrectPool, volume: _volumeSoundEffectDefault);
  }

  Future<void> playSwitchTarget() => _playSound(_targetSwitchPool);

  Future<void> _playSound(
    AudioPool pool, {
    double volume = _volumeSoundEffectDefault,
  }) async {
    if (!PreferenceManager.get.isSoundOn) {
      return;
    }
    await pool.start(volume: volume);
  }

  Future<void> _resumePlayer(AudioPlayer player) async {
    if (!PreferenceManager.get.isMusicOn) {
      return;
    }
    return player.resume();
  }

  Future<AudioPool> _createSoundPool(String file) =>
      AudioPoolWrapper.get.create(
        source: AssetSource(file),
        audioCache: FlameAudioWrapper.get.audioCache,
        maxPlayers: 1,
        audioContext:
            PlatformWrapper.get.isAndroid ? _soundEffectContextAndroid : null,
      );

  Future<AudioPlayer> _createMusicPlayer(String file) =>
      FlameAudioWrapper.get.loop(file, volume: _volumeMusicDefault);
}

enum _AudioManagerState {
  inGame,
  inMenu,
}
