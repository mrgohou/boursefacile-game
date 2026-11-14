import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'audio.dart';

/// Réglages de l'appareil : thème (clair / sombre / comme le téléphone), bruitages, musique.
class Settings extends ChangeNotifier {
  Settings(this._prefs)
      : themeMode = ThemeMode.values.byName(_prefs.getString('paco.theme') ?? ThemeMode.system.name),
        sound = _prefs.getBool('paco.sound') ?? true,
        music = _prefs.getBool('paco.music') ?? true {
    GameAudio.instance
      ..effects = sound
      ..music = music;
  }

  final SharedPreferences _prefs;
  ThemeMode themeMode;
  bool sound;
  bool music;

  void setTheme(ThemeMode m) {
    themeMode = m;
    _prefs.setString('paco.theme', m.name);
    notifyListeners();
  }

  void setSound(bool v) {
    sound = v;
    GameAudio.instance.effects = v;
    _prefs.setBool('paco.sound', v);
    notifyListeners();
  }

  void setMusic(bool v) {
    music = v;
    GameAudio.instance.setMusic(v);
    _prefs.setBool('paco.music', v);
    notifyListeners();
  }
}
