import 'package:material_ui/material_ui.dart';

import '../domain/player_state.dart';

/// The player picks a district and one of its sixteen building sites.
class CityPlacementSheet extends StatefulWidget {
  const CityPlacementSheet({
    super.key,
    required this.state,
    required this.companyId,
    required this.onPlace,
  });
  final PlayerState state;
  final String companyId;
  final Future<bool> Function(String landId, int cell) onPlace;
  @override
  State<CityPlacementSheet> createState() => _CityPlacementSheetState();
}

class _CityPlacementSheetState extends State<CityPlacementSheet> {
  String land = baseCityId;
  bool saving = false;
  String? error;
  @override
  void initState() {
    super.initState();
    land = widget.state.placements[widget.companyId]?.landId ?? baseCityId;
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Choisir l’emplacement',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              IconButton(
                tooltip: 'Fermer',
                onPressed: saving ? null : () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  companies.firstWhere((c) => c.id == widget.companyId).name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Un bâtiment représente ton entreprise tant que tu détiens au moins une part. Le déplacement est gratuit. Chaque terrain possède 16 emplacements.',
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: land,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Ville à développer',
                  ),
                  items: [baseCityId, ...widget.state.ownedPlots]
                      .map(
                        (id) => DropdownMenuItem(
                          value: id,
                          child: Text(cityName(id)),
                        ),
                      )
                      .toList(),
                  onChanged: saving ? null : (id) => setState(() => land = id!),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: List.generate(citySiteCount, (cell) {
                    final occupant = widget.state.placements.entries.where(
                      (e) =>
                          e.key != widget.companyId &&
                          e.value.landId == land &&
                          e.value.cell == cell,
                    );
                    final blocked = occupant.isNotEmpty;
                    return SizedBox(
                      width: 130,
                      child: FilledButton.tonal(
                        onPressed: saving || blocked
                            ? null
                            : () async {
                                setState(() {
                                  saving = true;
                                  error = null;
                                });
                                try {
                                  final ok = await widget.onPlace(land, cell);
                                  if (!mounted || !context.mounted) return;
                                  if (ok) {
                                    Navigator.pop(context, true);
                                  } else {
                                    setState(() {
                                      saving = false;
                                      error = 'Le placement n’a pas été enregistré. Réessaie.';
                                    });
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    setState(() {
                                      saving = false;
                                      error = e.toString();
                                    });
                                  }
                                }
                              },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            blocked
                                ? '${cell + 1} · occupé'
                                : 'Placer ici\n${cell + 1}',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(error!),
                  ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
