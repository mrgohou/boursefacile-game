import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/player_state.dart';

/// Local-only sandbox. Never use this repository as a trusted economy backend.
abstract interface class PlayerRepository {
  Future<PlayerState> load();
  Future<void> save(PlayerState state);
}

class LocalPlayerRepository implements PlayerRepository {
  LocalPlayerRepository({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();
  static const key = 'paco.mobile.player.v1';
  final SharedPreferencesAsync _preferences;

  @override
  Future<PlayerState> load() async {
    final raw = await _preferences.getString(key);
    if (raw == null) return PlayerState.initial();
    try {
      return PlayerState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      throw const FormatException(
        'La sauvegarde locale est illisible. Elle n’a pas été écrasée.',
      );
    }
  }

  @override
  Future<void> save(PlayerState state) =>
      _preferences.setString(key, jsonEncode(state.toJson()));
}
