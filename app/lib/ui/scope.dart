import 'package:flutter/material.dart';

import '../services/game_state.dart';
import '../services/settings.dart';

/// Accès à l'état du jeu depuis n'importe quel écran, avec reconstruction automatique.
class GameScope extends InheritedNotifier<GameState> {
  const GameScope({super.key, required GameState state, required super.child}) : super(notifier: state);

  static GameState of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<GameScope>()!.notifier!;
  static GameState read(BuildContext context) => context.getInheritedWidgetOfExactType<GameScope>()!.notifier!;
}

class SettingsScope extends InheritedNotifier<Settings> {
  const SettingsScope({super.key, required Settings settings, required super.child}) : super(notifier: settings);
  static Settings of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<SettingsScope>()!.notifier!;
}
