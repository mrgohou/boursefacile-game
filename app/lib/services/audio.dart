// Sons et musique. Les erreurs audio (navigateur qui bloque la lecture, appareil sans son)
// ne doivent jamais interrompre le jeu : tout est silencieusement ignoré.
import 'dart:async';
import 'dart:io' show Platform;

import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';

enum Track { ville, puzzle }

class GameAudio {
  GameAudio._();
  static final GameAudio instance = GameAudio._();

  static const sfx = [
    'tap', 'select', 'swap', 'invalid', 'match1', 'match2', 'match3', 'match4', 'match5', 'match6', //
    'special', 'blast', 'lock', 'coin', 'star', 'win', 'lose', 'buy', 'sell', 'start', 'cascade',
  ];

  bool effects = true;
  bool music = true;
  Track? _wanted;
  Track? _playing;
  bool _ready = false;

  /// Désactivé pendant les tests automatiques (pas de lecteur audio).
  static final bool _silent = !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');

  Future<void> init() async {
    if (_silent) return;
    try {
      FlameAudio.bgm.initialize(); // met la musique en pause quand l'appli passe en arrière-plan
      await FlameAudio.audioCache.loadAll([for (final s in sfx) '$s.mp3', 'music_ville.mp3', 'music_puzzle.mp3']);
    } catch (_) {}
    _ready = true;
    _sync();
  }

  void play(String name, {double volume = .8}) {
    if (_silent || !effects) return;
    unawaited(FlameAudio.play('$name.mp3', volume: volume).then((_) {}, onError: (Object _) {}));
  }

  /// Son de combo : la note monte avec la cascade.
  void combo(int cascade) => play('match${cascade.clamp(1, 6)}');

  void track(Track t) {
    _wanted = t;
    _sync();
  }

  void setMusic(bool on) {
    music = on;
    _sync();
  }

  void _sync() {
    if (_silent || !_ready) return;
    final t = music ? _wanted : null;
    if (t == _playing) return;
    _playing = t;
    unawaited(() async {
      try {
        if (t == null) {
          await FlameAudio.bgm.stop();
        } else {
          await FlameAudio.bgm.play('music_${t.name}.mp3', volume: .32);
        }
      } catch (_) {}
    }());
  }
}
