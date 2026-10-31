import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';

/// Handles audio playback and device vibration for alerts.
class AlarmService {
  static final AlarmService _instance = AlarmService._internal();
  factory AlarmService() => _instance;
  AlarmService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Timer? _vibrationTimer;

  bool get isPlaying => _isPlaying;

  /// Trigger Stage 1: Approaching alert (gentle chime + double pulse haptic)
  Future<void> triggerApproachingAlert() async {
    try {
      await _playAudio('sounds/approaching.wav', isLooping: false);
    } catch (_) {}

    try {
      final hasVib = await Vibration.hasVibrator();
      if (hasVib == true) {
        // Double pulse: vibrate 300ms, pause 200ms, vibrate 400ms
        await Vibration.vibrate(pattern: [0, 300, 200, 400]);
      }
    } catch (_) {}
  }

  /// Trigger Stage 2: Wake Up alert (urgent loud repeating alarm + repeating vibration)
  Future<void> triggerWakeUpAlarm() async {
    _isPlaying = true;
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(1.0);
      await _playAudio('sounds/wakeup.wav', isLooping: true);
    } catch (_) {}

    try {
      final hasVib = await Vibration.hasVibrator();
      if (hasVib == true) {
        // Repeating vibration pattern: 500ms on, 300ms off
        _vibrationTimer?.cancel();
        _vibrationTimer = Timer.periodic(const Duration(milliseconds: 1200), (_) async {
          if (!_isPlaying) {
            _vibrationTimer?.cancel();
            return;
          }
          await Vibration.vibrate(duration: 600);
        });
        await Vibration.vibrate(duration: 600);
      }
    } catch (_) {}
  }

  Future<void> _playAudio(String assetPath, {required bool isLooping}) async {
    try {
      await _audioPlayer.stop();
      if (isLooping) {
        await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      } else {
        await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      }
      await _audioPlayer.play(AssetSource(assetPath));
    } catch (_) {
      // In case native audio system fails or audio player platform is unsupported
    }
  }

  /// Stop current alarm sound and vibration
  Future<void> stopAlarm() async {
    _isPlaying = false;
    _vibrationTimer?.cancel();
    _vibrationTimer = null;
    try {
      await _audioPlayer.stop();
    } catch (_) {}
    try {
      await Vibration.cancel();
    } catch (_) {}
  }

  void dispose() {
    stopAlarm();
  }
}
