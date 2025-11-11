import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  final ValueNotifier<bool> isSpeaking = ValueNotifier<bool>(false);

  TtsService() {
    _init();
  }

  Future<void> _init() async {
    try {
      await _flutterTts.setLanguage("pl-PL");
    } catch (_) {}
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.45);

    _flutterTts.setStartHandler(() {
      isSpeaking.value = true;
    });

    _flutterTts.setCompletionHandler(() {
      isSpeaking.value = false;
    });

    _flutterTts.setCancelHandler(() {
      isSpeaking.value = false;
    });

    _flutterTts.setErrorHandler((err) {
      if (kDebugMode) print("TTS error: $err");
      isSpeaking.value = false;
    });
  }

  Future<void> speak(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    try {
      await _flutterTts.stop();
      isSpeaking.value = true;
      await _flutterTts.speak(trimmed);
    } catch (e) {
      if (kDebugMode) print("TTS speak failed: $e");
      isSpeaking.value = false;
    }
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      if (kDebugMode) print("TTS stop failed: $e");
    } finally {
      isSpeaking.value = false;
    }
  }

  Future<void> toggle(String text) async {
    if (isSpeaking.value) {
      await stop();
    } else {
      await speak(text);
    }
  }

  void dispose() {
    isSpeaking.dispose();
    _flutterTts.stop();
  }
}
