import 'package:flutter/material.dart';

import '../services/game_state.dart';
import 'city_page.dart';
import 'paco.dart';
import 'scope.dart';

/// Onglet Jouer : titre du joueur, raccourci Ma Ville, route des 15 villes.
class MapTab extends StatelessWidget {
  const MapTab({super.key, required this.onOpenVille});
  final VoidCallback onOpenVille;

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        Text(game.title, style: text.headlineMedium),
        Text('Cours BRVM du ${game.content.market.sessionDate.split('-').reversed.join('/')}', style: text.bodySmall),
        const SizedBox(height: 16),
        if (game.citiesDone >= 15 && game.score < goatScore) ...[
          PacoBubble(
            pose: Pose.progresser,
            text: 'Les 15 villes sont validées ! Fais grimper ton Score PACO à $goatScore pour devenir GOAT de la BRVM.',
          ),
          const SizedBox(height: 16),
        ],
        Card(
          color: scheme.primary,
          child: InkWell(
            onTap: onOpenVille,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ma Ville', style: text.titleLarge?.copyWith(color: scheme.onPrimary)),
                        Text(
                          'Score PACO ${game.score} · séance ${game.city.seance}',
                          style: text.bodyMedium?.copyWith(color: scheme.onPrimary.withValues(alpha: .85)),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward, color: scheme.onPrimary),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        for (final c in game.content.cities) ...[
          _CityTile(n: c.n, name: c.name, notion: c.notion),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _CityTile extends StatelessWidget {
  const _CityTile({required this.n, required this.name, required this.notion});
  final int n;
  final String name, notion;

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final open = game.cityUnlocked(n);
    final done = game.cityValidated(n);
    final st = game.cityStars(n);
    return Card(
      color: open && !done ? scheme.primaryContainer : null,
      child: ListTile(
        enabled: open,
        minVerticalPadding: 14,
        leading: CircleAvatar(
          backgroundColor: open ? scheme.primary : scheme.surfaceContainerHighest,
          foregroundColor: open ? scheme.onPrimary : scheme.onSurfaceVariant,
          child: open ? Text('$n', style: const TextStyle(fontWeight: FontWeight.w800)) : const Icon(Icons.lock_outline, size: 20),
        ),
        title: Text(name),
        subtitle: Text('$notion · $st/9 ★'),
        trailing: done ? Icon(Icons.verified, color: scheme.primary, semanticLabel: 'Ville validée') : const Icon(Icons.chevron_right),
        onTap: open ? () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => CityPage(city: n))) : null,
      ),
    );
  }
}
