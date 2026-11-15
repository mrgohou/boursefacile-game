import 'package:material_ui/material_ui.dart';

import '../domain/player_state.dart';

class MarketList extends StatefulWidget {
  const MarketList({super.key, required this.state, required this.onCompany});
  final PlayerState state;
  final ValueChanged<String> onCompany;
  @override
  State<MarketList> createState() => _MarketListState();
}

class _MarketListState extends State<MarketList> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final list = [...legacyCompanies, ...archivedCompanies]
        .where(
          (c) => '${c.id} ${c.name} ${c.sector} ${c.country}'
              .toLowerCase()
              .contains(query.toLowerCase()),
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          decoration: const InputDecoration(
            labelText: 'Rechercher une entreprise, un symbole ou un pays',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (v) => setState(() => query = v),
        ),
        const SizedBox(height: 12),
        Text('${list.length} titres affichés'),
        for (final c in list)
          Card.outlined(
            child: ListTile(
              leading: Image.asset(
                'assets/buildings/${c.family}-1.webp',
                width: 48,
              ),
              title: Text(c.archived ? '${c.id} · ${c.name}' : c.name),
              subtitle: Text(
                '${widget.state.prices[c.id]} FCFA-jeu / part · ${widget.state.holdings[c.id]} part(s)\n${c.archived ? c.country : 'Titre pédagogique'}',
              ),
              isThreeLine: false,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => widget.onCompany(c.id),
            ),
          ),
        if (list.isEmpty)
          const Text('Aucune entreprise ne correspond à cette recherche.'),
      ],
    );
  }
}
