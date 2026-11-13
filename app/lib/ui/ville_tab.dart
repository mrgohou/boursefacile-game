import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../engine/city.dart';
import 'format.dart';
import 'paco.dart';
import 'scope.dart';

enum _View { ville, sgi }

/// Ma Ville : indicateurs, bâtiments des entreprises détenues, guichet SGI.
class VilleTab extends StatefulWidget {
  const VilleTab({super.key});

  @override
  State<VilleTab> createState() => _VilleTabState();
}

class _VilleTabState extends State<VilleTab> {
  _View view = _View.ville;

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final city = game.city;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final companies = game.unlockedCompanies;
    final toAgo = seancesToAgo(city);
    final tip = game.pacoDiscret ? null : pacoTip(city, game.companies, game.citiesDone);
    final owned = city.holdings.entries.toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        Row(
          children: [
            Expanded(child: _Kpi(label: 'Score PACO', value: '${game.score}', highlight: true)),
            const SizedBox(width: 8),
            Expanded(child: _Kpi(label: 'Valeur de ta ville', value: fcfa(portfolioValue(city)))),
            const SizedBox(width: 8),
            Expanded(child: _Kpi(label: 'Dividendes reçus', value: fcfa(city.dividends))),
          ],
        ),
        const SizedBox(height: 12),
        Text('Séance ${city.seance} · AGO dans $toAgo ${plural(toAgo, 'séance')}${toAgo <= hourglass ? ' ⏳' : ''}', style: text.bodyMedium),
        if (city.lastEvent != null) ...[
          const SizedBox(height: 8),
          Card(
            color: scheme.secondaryContainer,
            child: ListTile(leading: const Icon(Icons.newspaper_outlined), title: Text(city.lastEvent!.text)),
          ),
        ],
        const SizedBox(height: 16),
        if (!game.cityUnlocked(2))
          const PacoBubble(
            pose: Pose.reflechir,
            text: 'Termine Abidjan (5 étoiles et le quiz) : ta ville et le guichet SGI s’ouvriront à Dakar.',
          )
        else ...[
          SegmentedButton<_View>(
            segments: [
              ButtonSegment(value: _View.ville, icon: const Icon(Icons.location_city), label: Text('Ma Ville (${owned.length})')),
              const ButtonSegment(value: _View.sgi, icon: Icon(Icons.account_balance), label: Text('Guichet SGI')),
            ],
            selected: {view},
            onSelectionChanged: (s) => setState(() => view = s.first),
          ),
          const SizedBox(height: 16),
          if (view == _View.ville) ...[
            if (tip != null) ...[
              PacoBubble(
                pose: switch (tip.kind) {
                  TipKind.empty => Pose.expliquer,
                  TipKind.ago => Pose.patience,
                  _ => Pose.attention,
                },
                text: tip.text,
              ),
              const SizedBox(height: 16),
            ],
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: .78,
              children: [
                for (final e in owned)
                  if (_find(game.companies, e.key) case final c?) _Building(company: c, holding: e.value),
              ],
            ),
          ] else
            for (final f in Family.values)
              if (companies.any((c) => c.family == f)) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
                  child: Text(familyLabels[f]!, style: text.titleMedium),
                ),
                for (final c in companies.where((c) => c.family == f)) _SgiRow(company: c),
              ],
          const SizedBox(height: 12),
          Text('Cours réels de la BRVM · frais 1 %, minimum 50 · FCFA-jeu fictifs', style: text.bodySmall, textAlign: TextAlign.center),
        ],
      ],
    );
  }
}

Company? _find(List<Company> list, String sym) {
  for (final c in list) {
    if (c.symbol == sym) return c;
  }
  return null;
}

class _Kpi extends StatelessWidget {
  const _Kpi({required this.label, required this.value, this.highlight = false});
  final String label, value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Card(
      color: highlight ? scheme.primaryContainer : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: text.bodySmall),
            FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: text.titleLarge)),
          ],
        ),
      ),
    );
  }
}

class _Building extends StatelessWidget {
  const _Building({required this.company, required this.holding});
  final Company company;
  final Holding holding;

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final lvl = buildingLevel(game.city, company.symbol);
    final up = (game.city.prices[company.symbol] ?? 0) >= company.price;
    return Semantics(
      button: true,
      label: '${company.name}, ${holding.qty} ${plural(holding.qty, 'part')}, bâtiment niveau $lvl, '
          '${up ? 'plus d’acheteurs' : 'plus de vendeurs'}',
      child: ExcludeSemantics(
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => showCompanySheet(context, company),
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(child: Image.asset('assets/buildings/${company.family.name}-$lvl.webp', fit: BoxFit.contain)),
                    Positioned(
                      left: 0,
                      bottom: 6,
                      width: 26,
                      child: Image.asset('assets/buildings/passant-${up ? 'vert' : 'rouge'}.webp'),
                    ),
                  ],
                ),
              ),
              Text(company.symbol, style: const TextStyle(fontWeight: FontWeight.w800)),
              Text('${holding.qty} ${plural(holding.qty, 'part')} · niv. $lvl', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _SgiRow extends StatelessWidget {
  const _SgiRow({required this.company});
  final Company company;

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final price = game.city.prices[company.symbol] ?? company.price;
    final held = game.city.holdings[company.symbol];
    final canBuy = buyCost(game.city, company.symbol, 1) <= game.savings;
    final messenger = ScaffoldMessenger.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () => showCompanySheet(context, company),
        title: Text(company.symbol),
        subtitle: Text(company.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(fcfa(price), style: const TextStyle(fontWeight: FontWeight.w800, fontFeatures: [FontFeature.tabularFigures()])),
            const SizedBox(width: 8),
            if (held != null)
              IconButton.filledTonal(
                tooltip: 'Vendre 1 part de ${company.name}',
                icon: const Icon(Icons.remove),
                onPressed: () {
                  final gain = game.sellOne(company.symbol);
                  if (gain == null) return;
                  HapticFeedback.selectionClick();
                  messenger.showSnackBar(SnackBar(
                    content: Text('1 part vendue. ${gain >= 0 ? 'Plus-value' : 'Moins-value'} : ${gain >= 0 ? '+' : ''}${fcfa(gain)} FCFA-jeu, frais compris.'),
                  ));
                },
              ),
            IconButton.filled(
              tooltip: 'Acheter 1 part de ${company.name}',
              icon: const Icon(Icons.add),
              onPressed: canBuy
                  ? () {
                      final cost = buyCost(game.city, company.symbol, 1);
                      if (!game.buyOne(company.symbol)) return;
                      HapticFeedback.selectionClick();
                      messenger.showSnackBar(SnackBar(content: Text('1 part achetée : ${fcfa(cost)} FCFA-jeu, frais compris.')));
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// Fiche entreprise (feuille du bas, M3) : notions dévoilées au rythme des villes.
Future<void> showCompanySheet(BuildContext context, Company c) {
  final game = GameScope.read(context);
  final done = game.citiesDone;
  final held = game.city.holdings[c.symbol];
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) {
      final text = Theme.of(context).textTheme;
      Widget row(String k, String v) => ListTile(dense: true, title: Text(k), trailing: Text(v, style: text.titleSmall));
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Image.asset('assets/buildings/${c.family.name}-3.webp', width: 56),
                title: Text(c.name, style: text.titleLarge),
                subtitle: Text('${c.symbol} · ${c.country}'),
              ),
              row('Prix d’une part', '${fcfa(game.city.prices[c.symbol] ?? c.price)} FCFA-jeu'),
              row('Vrai cours BRVM', '${fcfa(c.price)} FCFA'),
              row('Secteur', c.sector),
              if (done >= 4 && c.lastDividend != null) row('Dernier dividende', '${fcfa(c.lastDividend!)} par part'),
              if (done >= 4 && c.dividendYield != null) row('Rendement', '${c.dividendYield} pièces pour 100'),
              if (done >= 5) row('Cœur (BPA)', c.eps == null ? '?' : (c.eps! > 0 ? '💚 ${fcfa(c.eps!)}' : '❤️‍🩹 ${fcfa(c.eps!)}')),
              if (done >= 6) row('PER', c.per != null && (c.eps ?? 0) > 0 ? '${c.per!.round()} années' : 'non calculable'),
              if (held != null) row('Tes parts', '${held.qty} · payées ${fcfa(held.cost)}'),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Chiffres financiers de test, à vérifier. Ce n’est pas un conseil d’investissement.',
                    style: text.bodySmall, textAlign: TextAlign.center),
              ),
            ],
          ),
        ),
      );
    },
  );
}
