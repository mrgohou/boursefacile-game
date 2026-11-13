import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/content.dart';
import 'services/game_state.dart';
import 'services/settings.dart';
import 'ui/brand_theme.dart';
import 'ui/scope.dart';
import 'ui/shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final content = await Content.load(rootBundle);
  runApp(PacoApp(state: GameState(content, prefs), settings: Settings(prefs)));
}

class PacoApp extends StatefulWidget {
  const PacoApp({super.key, required this.state, required this.settings});
  final GameState state;
  final Settings settings;

  @override
  State<PacoApp> createState() => _PacoAppState();
}

class _PacoAppState extends State<PacoApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // L'appli passe en arrière-plan : on sauvegarde tout de suite.
  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.paused || s == AppLifecycleState.inactive) widget.state.flush();
  }

  @override
  Widget build(BuildContext context) {
    return SettingsScope(
      settings: widget.settings,
      child: GameScope(
        state: widget.state,
        child: ListenableBuilder(
          listenable: widget.settings,
          builder: (context, _) => MaterialApp(
            title: 'PACO Bourse',
            debugShowCheckedModeBanner: false,
            theme: Brand.theme(Brightness.light),
            darkTheme: Brand.theme(Brightness.dark),
            themeMode: widget.settings.themeMode,
            home: const Shell(),
          ),
        ),
      ),
    );
  }
}
