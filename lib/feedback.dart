import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum FeedbackTone { select, success, error }

/// Small, locally generated cues: no network calls or third-party audio files.
class AppFeedback extends ChangeNotifier {
  AppFeedback._();
  static final instance = AppFeedback._();

  final Map<FeedbackTone, AudioPlayer> _players = {};
  final Map<FeedbackTone, Uint8List> _clips = {};
  bool soundsEnabled = true;
  DateTime? _lastPlayed;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      soundsEnabled = prefs.getBool('soundsEnabled') ?? true;
      notifyListeners();
    } catch (_) {
      // Keep the default if this platform cannot persist preferences.
    }
  }

  Future<void> toggle() async {
    soundsEnabled = !soundsEnabled;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('soundsEnabled', soundsEnabled);
    } catch (_) {
      // The switch still works for the current session.
    }
    if (soundsEnabled) select();
  }

  void select() => _play(FeedbackTone.select);
  void success() => _play(FeedbackTone.success);
  void error() => _play(FeedbackTone.error);

  void _play(FeedbackTone tone) {
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      unawaited(HapticFeedback.selectionClick());
    }
    if (!soundsEnabled) return;
    final now = DateTime.now();
    if (_lastPlayed != null &&
        now.difference(_lastPlayed!) < const Duration(milliseconds: 90)) {
      return;
    }
    _lastPlayed = now;
    unawaited(_playAudio(tone));
  }

  Future<void> _playAudio(FeedbackTone tone) async {
    try {
      final player = _players.putIfAbsent(tone, AudioPlayer.new);
      final bytes = _clips.putIfAbsent(tone, () => _makeWav(tone));
      await player.play(
        BytesSource(bytes, mimeType: 'audio/wav'),
        volume: 0.24,
        mode: PlayerMode.lowLatency,
      );
    } catch (_) {
      // Audio support varies between browsers/devices; never block an action.
    }
  }
}

Uint8List _makeWav(FeedbackTone tone) {
  const sampleRate = 22050;
  final duration = switch (tone) {
    FeedbackTone.select => 0.075,
    FeedbackTone.success => 0.17,
    FeedbackTone.error => 0.14,
  };
  final frequencies = switch (tone) {
    FeedbackTone.select => (740.0, 0.0),
    FeedbackTone.success => (740.0, 1110.0),
    FeedbackTone.error => (360.0, 430.0),
  };
  final samples = (sampleRate * duration).round();
  final byteData = ByteData(44 + samples * 2);
  void word(int offset, String value) {
    for (var index = 0; index < value.length; index++) {
      byteData.setUint8(offset + index, value.codeUnitAt(index));
    }
  }

  word(0, 'RIFF');
  byteData.setUint32(4, 36 + samples * 2, Endian.little);
  word(8, 'WAVE');
  word(12, 'fmt ');
  byteData.setUint32(16, 16, Endian.little);
  byteData.setUint16(20, 1, Endian.little); // PCM
  byteData.setUint16(22, 1, Endian.little); // mono
  byteData.setUint32(24, sampleRate, Endian.little);
  byteData.setUint32(28, sampleRate * 2, Endian.little);
  byteData.setUint16(32, 2, Endian.little);
  byteData.setUint16(34, 16, Endian.little);
  word(36, 'data');
  byteData.setUint32(40, samples * 2, Endian.little);

  for (var index = 0; index < samples; index++) {
    final time = index / sampleRate;
    final attack = math.min(1.0, time / 0.008);
    final tail = math.pow(1 - time / duration, 2.2).toDouble();
    final base = math.sin(2 * math.pi * frequencies.$1 * time);
    final harmonic = frequencies.$2 == 0
        ? 0.0
        : math.sin(2 * math.pi * frequencies.$2 * time) * 0.32;
    final value = ((base + harmonic) * attack * tail * 12000).round().clamp(
      -32768,
      32767,
    );
    byteData.setInt16(44 + index * 2, value, Endian.little);
  }
  return byteData.buffer.asUint8List();
}
