import 'package:flutter/foundation.dart';

import '../domain/player_state.dart';
import 'player_repository.dart';

/// Serializes local mutations, persisting before publishing the next state.
class PlayerController extends ChangeNotifier {
  PlayerController(this.repository);
  final PlayerRepository repository;
  PlayerState _state = PlayerState.initial();
  PlayerState get state => _state;
  bool loading = true;
  bool busy = false;
  String? error;
  bool _disposed = false;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> load() async {
    loading = true;
    error = null;
    _notify();
    try {
      _state = await repository.load().timeout(const Duration(seconds: 15));
    } catch (_) {
      error = 'Impossible de lire la sauvegarde. Réessaie ou confirme une remise à zéro.';
    } finally {
      loading = false;
      _notify();
    }
  }

  Future<bool> change(PlayerState Function(PlayerState) action) async {
    if (busy || loading || error != null) return false;
    busy = true;
    _notify();
    try {
      final next = action(_state);
      await repository.save(next);
      if (!_disposed) _state = next;
      return true;
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> reset() async {
    if (busy) return;
    busy = true;
    _notify();
    try {
      final fresh = PlayerState.initial();
      await repository.save(fresh);
      _state = fresh;
      error = null;
    } finally {
      busy = false;
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
