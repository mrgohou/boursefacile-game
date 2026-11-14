import 'package:material_ui/material_ui.dart';

import '../domain/city_growth.dart';
import '../domain/player_state.dart';

class CityGrowthSheet extends StatelessWidget {
  const CityGrowthSheet({
    super.key,
    required this.state,
    required this.busy,
    required this.onBuy,
    required this.onBuild,
  });
  final PlayerState state;
  final bool busy;
  final ValueChanged<String> onBuy;
  final void Function(String land, String building) onBuild;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        '${state.ownedPlots.length}/${lands.length} terrains · ${state.townBuildings.length} bâtiments',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 8),
      Text(
        'Épargne : ${state.cash} FCFA-jeu. Récompenses gagnées : ${state.earnedRewards} FCFA-jeu.',
      ),
      const SizedBox(height: 8),
      const Text(
        'Les puzzles et le Voyage de Paco débloquent les quartiers. Terrain et construction se paient séparément. Ces bâtiments restent à toi ; ils ne rapportent pas de revenu automatique et ne sont pas des actions.',
      ),
      const SizedBox(height: 20),
      for (var i = 0; i < lands.length; i++) _land(context, lands[i], i),
    ],
  );
  Widget _land(BuildContext context, LandSpec land, int index) {
    final owned = state.ownedPlots.contains(land.id);
    final type = state.townBuildings[land.id];
    final unlocked =
        state.earnedRewards >= land.requiredGains &&
        (index == 0 || state.ownedPlots.contains(lands[index - 1].id));
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(land.name, style: Theme.of(context).textTheme.titleMedium),
              Text(
                owned
                    ? 'Terrain acquis'
                    : '${land.price} FCFA-jeu · seuil ${land.requiredGains} de récompenses',
              ),
              if (!owned) ...[
                if (!unlocked)
                  Text(
                    index > 0 && !state.ownedPlots.contains(lands[index - 1].id)
                        ? 'Acquiers le quartier précédent.'
                        : 'Encore ${land.requiredGains - state.earnedRewards} FCFA-jeu à gagner.',
                  ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: !busy && unlocked && state.cash >= land.price
                      ? () => onBuy(land.id)
                      : null,
                  icon: const Icon(Icons.add_location_alt_outlined),
                  label: const Text('Acheter le terrain'),
                ),
              ] else if (type != null) ...[
                Image.asset(
                  'assets/buildings/${townBuildingTypes.firstWhere((b) => b.id == type).asset}.webp',
                  height: 110,
                  excludeFromSemantics: true,
                ),
                Text(
                  townBuildingTypes.firstWhere((b) => b.id == type).name,
                  textAlign: TextAlign.center,
                ),
                const Text(
                  'Construit · conservé dans ta ville',
                  textAlign: TextAlign.center,
                ),
              ] else ...[
                const SizedBox(height: 12),
                const Text('Choisis ton bâtiment :'),
                for (final building in townBuildingTypes)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: OutlinedButton(
                      onPressed: !busy && state.cash >= building.cost
                          ? () => onBuild(land.id, building.id)
                          : null,
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/buildings/${building.asset}.webp',
                            width: 48,
                            height: 48,
                            excludeFromSemantics: true,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${building.name}\n${building.cost} FCFA-jeu',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
