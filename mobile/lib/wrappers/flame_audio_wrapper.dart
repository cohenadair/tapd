import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';

class FlameAudioWrapper {
  static var _instance = FlameAudioWrapper._();

  static FlameAudioWrapper get get => _instance;

  @visibleForTesting
  static void set(FlameAudioWrapper manager) => _instance = manager;

  FlameAudioWrapper._();

  Future<List<Uri>> loadAll(List<String> fileNames) =>
      FlameAudio.audioCache.loadAll(fileNames);

  Future<AudioPlayer> loop(String file, {double volume = 1.0}) =>
      FlameAudio.loop(file, volume: volume);

  AudioCache get audioCache => FlameAudio.audioCache;
}
