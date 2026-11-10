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

  /// How long each sound effect's player is held before it's returned to its
  /// pool. Slightly longer than each file, so a sound is never cut off. Only
  /// used on Android, where low latency players never report completion.
  ///
  /// These must be updated when a file changes; a test checks them against
  /// each file's actual length.
  @visibleForTesting
  static const soundEffectDurations = {
    _fileButtonTap: _durationButtonTap,
    _fileTargetCorrect: _durationTargetCorrect,
    _fileTargetIncorrect: _durationTargetIncorrect,
    _fileTargetSwitch: _durationTargetSwitch,
  };

  static const _durationButtonTap = Duration(milliseconds: 300);
  static const _durationTargetCorrect = Duration(milliseconds: 150);
  static const _durationTargetIncorrect = Duration(milliseconds: 1400);
  static const _durationTargetSwitch = Duration(milliseconds: 550);

  /// The number of players preloaded for sound effects that can overlap when
  /// tapped in quick succession. A pool with no free player creates a new one,
  /// then releases it when the sound ends. On Android, both happen on the main
  /// thread, which delays the next tap.
  static const _rapidSoundEffectPlayers = 3;

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

  /// The music player that's currently playing, if any. Each player call is a
  /// blocking platform call on Android's main thread, which also renders
  /// frames, so players are only called when the music actually changes.
  AudioPlayer? _playingPlayer;

  /// Whether music was playing when the app was backgrounded. Music is only
  /// resumed in the foreground if it was, so a paused game stays silent.
  var _wasMusicPlayingWhenBackgrounded = false;

  /// On Android, sound effects use SoundPool (low latency) players. Media
  /// players make several blocking calls per sound on the main thread, which
  /// also renders frames, causing dropped frames when targets are tapped.
  bool get _isLowLatency => PlatformWrapper.get.isAndroid;

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
          if (_wasMusicPlayingWhenBackgrounded) {
            resumeMusic();
          }
        case FGBGType.background:
          _wasMusicPlayingWhenBackgrounded = _playingPlayer != null;
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

    _buttonTapPool = await _createSoundPool(
      _fileButtonTap,
      players: _rapidSoundEffectPlayers,
    );
    _targetCorrectPool = await _createSoundPool(
      _fileTargetCorrect,
      players: _rapidSoundEffectPlayers,
    );
    _targetIncorrectPool = await _createSoundPool(_fileTargetIncorrect);
    _targetSwitchPool = await _createSoundPool(_fileTargetSwitch);
  }

  VoidCallback onButtonPressed([VoidCallback? callback]) {
    return () {
      _playSound(_buttonTapPool, _durationButtonTap);
      callback?.call();
    };
  }

  Future<void> resumeMusic() async {
    if (!PreferenceManager.get.isMusicOn) {
      return pauseMusic();
    }

    var player = switch (_gameState) {
      _AudioManagerState.inGame => _gamePlayer,
      _AudioManagerState.inMenu => _menuPlayer,
    };
    // A player's state is cached in Dart, so checking it isn't a platform
    // call. It catches a player paused outside of this class, such as when the
    // app loses audio focus.
    if (player == _playingPlayer && player.state == PlayerState.playing) {
      return;
    }

    // Set before pausing, so a call made while pausing sees the new player.
    var previous = _playingPlayer;
    _playingPlayer = player;

    // Stop the other player before resuming the correct one.
    if (previous != null && previous != player) {
      await previous.pause();
    }

    // Another call may have changed or paused the music while pausing.
    if (_playingPlayer != player) {
      return;
    }
    return player.resume();
  }

  Future<void> pauseMusic() async {
    var player = _playingPlayer;
    if (player == null) {
      return;
    }
    _playingPlayer = null;
    return player.pause();
  }

  Future<void> playMenuBackground() {
    _gameState = _AudioManagerState.inMenu;
    return resumeMusic();
  }

  Future<void> playGameBackground() {
    _gameState = _AudioManagerState.inGame;
    return resumeMusic();
  }

  Future<void> playCorrectHit() =>
      _playSound(_targetCorrectPool, _durationTargetCorrect);

  Future<void> playIncorrectHit() async {
    await pauseMusic();
    return _playSound(
      _targetIncorrectPool,
      _durationTargetIncorrect,
      volume: _volumeSoundEffectDefault,
    );
  }

  Future<void> playSwitchTarget() =>
      _playSound(_targetSwitchPool, _durationTargetSwitch);

  Future<void> _playSound(
    AudioPool pool,
    Duration duration, {
    double volume = _volumeSoundEffectDefault,
  }) async {
    if (!PreferenceManager.get.isSoundOn) {
      return;
    }
    var stop = await pool.start(volume: volume);

    // Low latency players never report completion, so the pool can't return
    // them on its own.
    if (_isLowLatency) {
      Timer(duration, stop);
    }
  }

  Future<AudioPool> _createSoundPool(String file, {int players = 1}) =>
      AudioPoolWrapper.get.create(
        source: AssetSource(file),
        audioCache: FlameAudioWrapper.get.audioCache,
        minPlayers: players,
        maxPlayers: players,
        playerMode:
            _isLowLatency ? PlayerMode.lowLatency : PlayerMode.mediaPlayer,
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
