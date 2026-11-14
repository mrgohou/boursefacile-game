import 'package:flutter/material.dart';

import 'scope.dart';

/// Moi : titre, apparence (clair / sombre / comme le téléphone), sons, musique, Paco discret.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Moi')), body: const SettingsTab());
}

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final settings = SettingsScope.of(context);
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.emoji_events_outlined),
            title: Text(game.title),
            subtitle: Text('${game.citiesDone}/15 villes validées · Score PACO ${game.score}'),
          ),
        ),
        const SizedBox(height: 20),
        Text('Apparence', style: text.titleMedium),
        Text('« Auto » suit le réglage de ton téléphone.', style: text.bodySmall),
        const SizedBox(height: 8),
        SegmentedButton<ThemeMode>(
          segments: const [
            ButtonSegment(value: ThemeMode.system, label: Text('Auto'), icon: Icon(Icons.brightness_auto_outlined)),
            ButtonSegment(value: ThemeMode.light, label: Text('Clair'), icon: Icon(Icons.light_mode_outlined)),
            ButtonSegment(value: ThemeMode.dark, label: Text('Sombre'), icon: Icon(Icons.dark_mode_outlined)),
          ],
          selected: {settings.themeMode},
          onSelectionChanged: (s) => settings.setTheme(s.first),
        ),
        const SizedBox(height: 20),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.volume_up_outlined),
                title: const Text('Bruitages'),
                value: settings.sound,
                onChanged: settings.setSound,
              ),
              const Divider(height: 1),
              SwitchListTile(
                secondary: const Icon(Icons.music_note_outlined),
                title: const Text('Musique'),
                value: settings.music,
                onChanged: settings.setMusic,
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('Paco discret'),
                subtitle: const Text('Paco parle seulement avant et après les parties.'),
                value: game.pacoDiscret,
                onChanged: game.setPacoDiscret,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'PACO Bourse est un jeu éducatif : FCFA-jeu fictifs, aucun argent réel, aucun conseil d’investissement. '
          'Les performances passées ne garantissent pas les résultats futurs.',
          style: text.bodySmall,
        ),
      ],
    );
  }
}
