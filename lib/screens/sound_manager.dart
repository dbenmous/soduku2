import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

enum SoundType {
  click,
  success,
  error,
  complete
}

class SoundManager {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static final Map<SoundType, String> _soundPaths = {
    SoundType.click: 'sounds/click.mp3',
    SoundType.success: 'sounds/success.mp3',
    SoundType.error: 'sounds/error.mp3',
    SoundType.complete: 'sounds/complete.mp3',
  };

  static Future<void> playSound(SoundType type) async {
    if (Hive.box('settings').get('audio', defaultValue: false)) {
      try {
        double volume = Hive.box('settings').get('volume', defaultValue: 0.5);
        await _audioPlayer.setVolume(volume);
        await _audioPlayer.play(AssetSource(_soundPaths[type]!));
      } catch (e) {
        debugPrint('Error playing sound: $e');
      }
    }
  }

  static Future<void> initialize() async {
// Pre-load sounds for faster playback
    for (String path in _soundPaths.values) {
      await _audioPlayer.setSource(AssetSource(path));
    }
  }

  static void dispose() {
    _audioPlayer.dispose();
  }

  static Future<void> testSound() async {
    await playSound(SoundType.click);
  }
}
