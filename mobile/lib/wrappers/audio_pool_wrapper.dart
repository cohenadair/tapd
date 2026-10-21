import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';

class AudioPoolWrapper {
  static var _instance = AudioPoolWrapper._();

  static AudioPoolWrapper get get => _instance;

  @visibleForTesting
  static void set(AudioPoolWrapper manager) => _instance = manager;

  AudioPoolWrapper._();

  Future<AudioPool> create({
    required Source source,
    required int maxPlayers,
    AudioCache? audioCache,
    AudioContext? audioContext,
    int minPlayers = 1,
    PlayerMode playerMode = PlayerMode.mediaPlayer,
  }) {
    return AudioPool.create(
      source: source,
      maxPlayers: maxPlayers,
      audioCache: audioCache,
      audioContext: audioContext,
      minPlayers: minPlayers,
      playerMode: playerMode,
    );
  }
}
