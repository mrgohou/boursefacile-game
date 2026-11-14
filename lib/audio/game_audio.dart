import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class GameAudio extends ChangeNotifier {
  bool get musicEnabled;
  bool get sfxEnabled;
  bool get ready;
  Future<void> initialize();
  Future<void> setScene(String scene);
  void play(String event, {int chain = 1});
  Future<void> setMusicEnabled(bool enabled);
  Future<void> setSfxEnabled(bool enabled);
  void pause();
  void resume();
}

/// Deterministic, plugin-free implementation for widget and state tests.
class SilentGameAudio extends GameAudio {
  bool _music = true, _sfx = true, _ready = false, _disposed = false;
  bool paused = false;
  String scene = 'city';
  @override
  bool get musicEnabled => _music;
  @override
  bool get sfxEnabled => _sfx;
  @override
  bool get ready => _ready;
  void changed() {
    if (!_disposed) notifyListeners();
  }

  @override
  Future<void> initialize() async {
    if (!_disposed) {
      _ready = true;
      changed();
    }
  }

  @override
  Future<void> setScene(String value) async {
    if (value != 'city' && value != 'puzzle') {
      throw ArgumentError.value(value, 'scene');
    }
    if (!_disposed) scene = value;
  }

  @override
  void play(String event, {int chain = 1}) {}
  @override
  Future<void> setMusicEnabled(bool enabled) async {
    if (!_disposed) {
      _music = enabled;
      changed();
    }
  }

  @override
  Future<void> setSfxEnabled(bool enabled) async {
    if (!_disposed) {
      _sfx = enabled;
      changed();
    }
  }

  @override
  void pause() {
    if (!_disposed) paused = true;
  }

  @override
  void resume() {
    if (!_disposed) paused = false;
  }

  @override
  void dispose() {
    _disposed = true;
    _ready = false;
    super.dispose();
  }
}

class PacoAudio extends GameAudio with WidgetsBindingObserver {
  PacoAudio({SharedPreferencesAsync? preferences})
    : _createdPreferences = preferences;
  SharedPreferencesAsync? _createdPreferences;
  SharedPreferencesAsync get _preferences =>
      _createdPreferences ??= SharedPreferencesAsync();
  AudioPlayer? _createdMusicPlayer;
  AudioPlayer get _musicPlayer => _createdMusicPlayer ??= AudioPlayer();
  final List<AudioPlayer> _voices = [];
  final List<int> _voiceTokens = [0, 0, 0];
  final List<Future<void>> _voiceQueues = List.generate(
    3,
    (_) => Future.value(),
  );
  static const _events = {
    'select',
    'swap',
    'invalid',
    'match',
    'cascade',
    'win',
    'lose',
    'shuffle',
    'ui',
  };
  bool _music = true,
      _sfx = true,
      _ready = false,
      _disposed = false,
      _paused = false;
  String _scene = 'city';
  int _token = 0, _nextVoice = 0, _musicRevision = 0, _sfxRevision = 0;
  Future<void>? _initialization;
  Future<void> _musicQueue = Future.value();
  Future<void> _settingsQueue = Future.value();
  @override
  bool get musicEnabled => _music;
  @override
  bool get sfxEnabled => _sfx;
  @override
  bool get ready => _ready;
  void _changed() {
    if (!_disposed) notifyListeners();
  }

  @override
  Future<void> initialize() => _initialization ??= _initialize();
  Future<void> _initialize() async {
    if (_disposed) return;
    WidgetsBinding.instance.addObserver(this);
    try {
      // Capture user changes made while preferences are loading.
      final musicRevision = _musicRevision;
      final sfxRevision = _sfxRevision;
      final music = await _preferences.getBool('paco.audio.music');
      final sfx = await _preferences.getBool('paco.audio.sfx');
      if (_disposed) return;
      if (musicRevision == _musicRevision) _music = music ?? true;
      if (sfxRevision == _sfxRevision) _sfx = sfx ?? true;
      _voices.addAll(List.generate(3, (_) => AudioPlayer()));
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer.setVolume(.22);
      for (final voice in _voices) {
        await voice.setPlayerMode(PlayerMode.lowLatency);
        await voice.setReleaseMode(ReleaseMode.stop);
        await voice.setVolume(.65);
      }
      if (_disposed) return;
      _ready = true;
      _changed();
      await _syncMusic();
    } catch (_) {
      _failed();
    }
  }

  void _failed() {
    if (!_disposed) {
      _ready = false;
      _changed();
    }
  }

  Future<void> _syncMusic() {
    final token = ++_token;
    _musicQueue = _musicQueue.then((_) async {
      if (_disposed || token != _token) return;
      try {
        final player = _createdMusicPlayer;
        if (player == null) return;
        await player.stop();
        if (_disposed || token != _token || !_ready || !_music || _paused) {
          return;
        }
        await _musicPlayer.setSource(AssetSource('audio/$_scene.wav'));
        if (_disposed || token != _token || !_music || _paused) return;
        await _musicPlayer.resume();
        if (_disposed || token != _token || !_music || _paused) {
          await _musicPlayer.stop();
        }
      } catch (_) {
        _failed();
      }
    });
    return _musicQueue;
  }

  @override
  Future<void> setScene(String scene) async {
    if (scene != 'city' && scene != 'puzzle') {
      throw ArgumentError.value(scene, 'scene');
    }
    if (_disposed || scene == _scene) return;
    _scene = scene;
    await _syncMusic();
  }

  Future<void> _persist(String key, bool value) {
    _settingsQueue = _settingsQueue.then((_) async {
      try {
        await _preferences.setBool(key, value);
      } catch (_) {
        /* Sound remains usable without persistence. */
      }
    });
    return _settingsQueue;
  }

  @override
  Future<void> setMusicEnabled(bool enabled) async {
    if (_disposed) return;
    _music = enabled;
    _musicRevision++;
    _changed();
    await Future.wait([_syncMusic(), _persist('paco.audio.music', enabled)]);
  }

  @override
  Future<void> setSfxEnabled(bool enabled) async {
    if (_disposed) return;
    _sfx = enabled;
    _sfxRevision++; // Preserve only the option changed by the user.
    if (!enabled) {
      for (var i = 0; i < _voices.length; i++) {
        _voiceTokens[i]++;
        unawaited(_stopVoice(_voices[i]));
      }
    }
    _changed();
    await _persist('paco.audio.sfx', enabled);
  }

  Future<void> _stopVoice(AudioPlayer voice) async {
    try {
      await voice.stop();
    } catch (_) {
      _failed();
    }
  }

  @override
  void play(String event, {int chain = 1}) {
    if (!_ready || _disposed || _paused || !_sfx || !_events.contains(event)) {
      return;
    }
    final index = _nextVoice++ % _voices.length;
    final token = ++_voiceTokens[index];
    final name = event == 'match' && chain > 1 ? 'cascade' : event;
    _voiceQueues[index] = _voiceQueues[index].then(
      (_) => _playVoice(index, token, name),
    );
  }

  Future<void> _playVoice(int index, int token, String event) async {
    try {
      final voice = _voices[index];
      await voice.stop();
      if (_disposed || !_sfx || _paused || token != _voiceTokens[index]) return;
      await voice.setSource(AssetSource('audio/$event.wav'));
      if (_disposed || !_sfx || _paused || token != _voiceTokens[index]) return;
      await voice.resume();
      if (_disposed || !_sfx || _paused || token != _voiceTokens[index]) {
        await voice.stop();
      }
    } catch (_) {
      _failed();
    }
  }

  @override
  void pause() {
    if (_disposed) return;
    _paused = true;
    for (var i = 0; i < _voices.length; i++) {
      _voiceTokens[i]++;
      unawaited(_stopVoice(_voices[i]));
    }
    unawaited(_syncMusic());
  }

  @override
  void resume() {
    if (!_disposed) {
      _paused = false;
      unawaited(_syncMusic());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      resume();
    } else {
      pause();
    }
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _ready = false;
    _token++;
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_release());
    super.dispose();
  }

  Future<void> _release() async {
    await _musicQueue;
    await Future.wait(_voiceQueues);
    for (final player in [?_createdMusicPlayer, ..._voices]) {
      try {
        await player.dispose();
      } catch (_) {
        /* Best-effort plugin cleanup. */
      }
    }
  }
}
