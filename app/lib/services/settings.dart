import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Réglages de l'appareil : thème (clair / sombre / comme le téléphone), son.
class Settings extends ChangeNotifier {
  Settings(this._prefs)
      : themeMode = ThemeMode.values.byName(_prefs.getString('paco.theme') ?? ThemeMode.system.name),
        sound = _prefs.getBool('paco.sound') ?? true;

  final SharedPreferences _prefs;
  ThemeMode themeMode;
  bool sound;

  void setTheme(ThemeMode m) {
    themeMode = m;
    _prefs.setString('paco.theme', m.name);
    notifyListeners();
  }

  void setSound(bool v) {
    sound = v;
    _prefs.setBool('paco.sound', v);
    notifyListeners();
  }
}
