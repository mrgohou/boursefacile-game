import 'package:flutter/material.dart';

import '../engine/city.dart';
import 'scope.dart';
import 'ville_tab.dart' show showCompanySheet;

/// Collection de cartes entreprises, rangées par familles de secteurs.
class CardsTab extends StatelessWidget {
  const CardsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final companies = game.unlockedCompanies;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        Text('Mes cartes', style: text.headlineMedium),
        Text('${game.cards.length} / ${companies.length} entreprises de la BRVM', style: text.bodyMedium),
        const SizedBox(height: 4),
        Text('Gagne une carte en gardant une part 10 séances, ou avec un quiz de Paco sans faute.', style: text.bodySmall),
        for (final f in Family.values)
          if (companies.where((c) => c.family == f).toList() case final list when list.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
              child: Row(
                children: [
                  Expanded(child: Text(familyLabels[f]!, style: text.titleMedium)),
                  Text(
                    '${list.where((c) => game.cards.contains(c.symbol)).length}/${list.length}'
                    '${list.every((c) => game.cards.contains(c.symbol)) ? ' · famille complète 🛡️' : ''}',
                    style: text.bodySmall,
                  ),
                ],
              ),
            ),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: .75,
              children: [
                for (final c in list)
                  if (game.cards.contains(c.symbol))
                    Card(
                      color: scheme.primaryContainer,
                      child: InkWell(
                        onTap: () => showCompanySheet(context, c),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Column(
                            children: [
                              Expanded(child: Image.asset('assets/buildings/${f.name}-1.webp', semanticLabel: c.name)),
                              Text(c.symbol, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    Card(
                      color: scheme.surfaceContainerHighest,
                      child: Center(
                        child: Text('?', style: text.headlineMedium?.copyWith(color: scheme.onSurfaceVariant), semanticsLabel: 'Carte à gagner'),
                      ),
                    ),
              ],
            ),
          ],
      ],
    );
  }
}
