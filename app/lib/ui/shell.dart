import 'package:flutter/material.dart';

import 'cards_tab.dart';
import 'format.dart';
import 'map_tab.dart';
import 'scope.dart';
import 'settings_tab.dart';
import 'ville_tab.dart';
import 'welcome.dart';

/// Navigation principale : 4 onglets en bas, à portée du pouce (Material 3 NavigationBar).
class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    if (!game.seenIntro.contains(0)) return const Welcome();
    return Scaffold(
      appBar: AppBar(
        title: const Text('PACO Bourse'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Semantics(
              label: 'Épargne : ${fcfa(game.savings)} FCFA-jeu',
              child: ExcludeSemantics(
                child: Chip(
                  avatar: Image.asset('assets/tiles/billet.webp', width: 22),
                  label: Text(fcfa(game.savings)),
                ),
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _tab,
        children: [
          MapTab(onOpenVille: () => setState(() => _tab = 1)),
          const VilleTab(),
          const CardsTab(),
          const SettingsTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: 'Jouer'),
          NavigationDestination(icon: Icon(Icons.location_city_outlined), selectedIcon: Icon(Icons.location_city), label: 'Ma Ville'),
          NavigationDestination(icon: Icon(Icons.style_outlined), selectedIcon: Icon(Icons.style), label: 'Cartes'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Moi'),
        ],
      ),
    );
  }
}
