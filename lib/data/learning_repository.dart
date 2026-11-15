import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/learning_director.dart';

/// Optional local adaptation data. Failure must never block game progression.
class LearningRepository {
  LearningRepository({
    SharedPreferencesAsync? preferences,
    this._read,
    this._write,
  }) : _createdPreferences = preferences;
  static const key = 'paco.mobile.learning.v1';
  SharedPreferencesAsync? _createdPreferences;
  SharedPreferencesAsync get _preferences =>
      _createdPreferences ??= SharedPreferencesAsync();
  final Future<String?> Function(String key)? _read;
  final Future<void> Function(String key, String value)? _write;
  String? lastError;
  Future<LearningProfile> load() async {
    try {
      final raw = await (_read?.call(key) ?? _preferences.getString(key));
      lastError = null;
      return raw == null
          ? LearningProfile()
          : LearningProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      lastError =
          'Le suivi pédagogique local est indisponible. Le jeu reste jouable.';
      return LearningProfile();
    }
  }

  Future<bool> save(LearningProfile profile) async {
    try {
      final text = jsonEncode(profile.toJson());
      if (_write != null) {
        await _write(key, text);
      } else {
        await _preferences.setString(key, text);
      }
      lastError = null;
      return true;
    } catch (_) {
      lastError = 'Le suivi pédagogique n’a pas été enregistré. Les acquis du jeu restent indépendants.';
      return false;
    }
  }
}
