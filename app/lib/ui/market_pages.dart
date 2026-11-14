import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../engine/city.dart';
import '../services/audio.dart';
import '../services/game_state.dart';
import 'format.dart';
import 'paco.dart';
import 'scope.dart';

Company? findCompany(List<Company> list, String sym) {
  for (final c in list) {
    if (c.symbol == sym) return c;
  }
  return null;
}

/// Le guichet ouvre à Dakar : avant, on apprend ce qu'est une action.
const marketLockedText = 'Termine Abidjan (5 étoiles et le quiz) : le guichet SGI s’ouvrira à Dakar et tu pourras acheter tes premières parts.';

void _buy(BuildContext context, GameState game, Company c) {
  final cost = buyCost(game.city, c.symbol, 1);
  if (!game.buyOne(c.symbol)) return;
  HapticFeedback.selectionClick();
  GameAudio.instance.play('buy');
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text('1 part de ${c.symbol} achetée : ${fcfa(cost)} FCFA-jeu, frais compris.')));
}

void _sell(BuildContext context, GameState game, Company c) {
  final gain = game.sellOne(c.symbol);
  if (gain == null) return;
  HapticFeedback.selectionClick();
  GameAudio.instance.play('sell');
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text('1 part vendue. ${gain >= 0 ? 'Plus-value' : 'Moins-value'} : ${gain >= 0 ? '+' : ''}${fcfa(gain)} FCFA-jeu, frais compris.'),
    ));
}

class Kpi extends StatelessWidget {
  const Kpi({super.key, required this.label, required this.value, this.highlight = false});
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

/// Mes propriétés : ce que j'ai acquis, ce que ça vaut, ce que ça a rapporté.
class PropertiesPage extends StatelessWidget {
  const PropertiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final city = game.city;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final toAgo = seancesToAgo(city);
    final owned = [
      for (final e in city.holdings.entries)
        if (findCompany(game.companies, e.key) case final c?) (c, e.value),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Mes propriétés')),
      floatingActionButton: game.cityUnlocked(2)
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SgiPage())),
              icon: const Icon(Icons.account_balance),
              label: const Text('Guichet SGI'),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
        children: [
          Row(
            children: [
              Expanded(child: Kpi(label: 'Score PACO', value: '${game.score}', highlight: true)),
              const SizedBox(width: 8),
              Expanded(child: Kpi(label: 'Valeur', value: fcfa(portfolioValue(city)))),
              const SizedBox(width: 8),
              Expanded(child: Kpi(label: 'Dividendes', value: fcfa(city.dividends))),
            ],
          ),
          const SizedBox(height: 8),
          Text('Séance ${city.seance} · AGO dans $toAgo ${plural(toAgo, 'séance')}${toAgo <= hourglass ? ' ⏳' : ''}', style: text.bodyMedium),
          if (city.lastEvent != null)
            Card(
              color: scheme.secondaryContainer,
              child: ListTile(leading: const Icon(Icons.newspaper_outlined), title: Text(city.lastEvent!.text)),
            ),
          const SizedBox(height: 12),
          if (owned.isEmpty)
            PacoBubble(
              pose: Pose.expliquer,
              text: game.cityUnlocked(2)
                  ? 'Tu n’as encore aucune part. Ouvre le guichet SGI ou touche un terrain « à vendre » dans ta ville.'
                  : marketLockedText,
            )
          else
            for (final (c, h) in owned) _PropertyCard(company: c, holding: h),
          const SizedBox(height: 12),
          Text('Cours réels de la BRVM · FCFA-jeu fictifs · ce n’est pas un conseil d’investissement', style: text.bodySmall, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _PropertyCard extends StatelessWidget {
  const _PropertyCard({required this.company, required this.holding});
  final Company company;
  final Holding holding;

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final city = game.city;
    final lvl = buildingLevel(city, company.symbol);
    final price = city.prices[company.symbol] ?? company.price;
    final value = price * holding.qty;
    final gain = value - holding.cost;
    final text = Theme.of(context).textTheme;
    final up = gain >= 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => showCompanySheet(context, company),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Image.asset('assets/buildings/${company.family.name}-$lvl.webp', width: 72, height: 72, fit: BoxFit.contain),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(company.name, style: text.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text('${company.symbol} · ${holding.qty} ${plural(holding.qty, 'part')} · bâtiment niv. $lvl', style: text.bodySmall),
                    const SizedBox(height: 4),
                    Text('${fcfa(value)} FCFA-jeu', style: text.titleSmall),
                    Text(
                      '${up ? '+' : ''}${fcfa(gain)} depuis l’achat',
                      style: text.bodySmall?.copyWith(color: up ? const Color(0xFF2E9E4F) : const Color(0xFFD9534F), fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

/// Guichet SGI : acheter et vendre des parts, rangées par familles.
class SgiPage extends StatelessWidget {
  const SgiPage({super.key});

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final text = Theme.of(context).textTheme;
    final companies = game.unlockedCompanies;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guichet SGI'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Chip(avatar: Image.asset('assets/tiles/billet.webp', width: 22), label: Text(fcfa(game.savings))),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          if (!game.cityUnlocked(2))
            const PacoBubble(pose: Pose.reflechir, text: marketLockedText)
          else ...[
            for (final f in Family.values)
              if (companies.any((c) => c.family == f)) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
                  child: Text(familyLabels[f]!, style: text.titleMedium),
                ),
                for (final c in companies.where((c) => c.family == f)) SgiRow(company: c),
              ],
            const SizedBox(height: 12),
            Text('Cours réels de la BRVM · frais 1 %, minimum 50 · FCFA-jeu fictifs', style: text.bodySmall, textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }
}

class SgiRow extends StatelessWidget {
  const SgiRow({super.key, required this.company});
  final Company company;

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final price = game.city.prices[company.symbol] ?? company.price;
    final held = game.city.holdings[company.symbol];
    final canBuy = buyCost(game.city, company.symbol, 1) <= game.savings;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () => showCompanySheet(context, company),
        title: Text(company.symbol),
        subtitle: Text(held == null ? company.name : '${company.name} · ${held.qty} ${plural(held.qty, 'part')}', maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(fcfa(price), style: const TextStyle(fontWeight: FontWeight.w800, fontFeatures: [FontFeature.tabularFigures()])),
            const SizedBox(width: 8),
            if (held != null)
              IconButton.filledTonal(
                tooltip: 'Vendre 1 part de ${company.name}',
                icon: const Icon(Icons.remove),
                onPressed: () => _sell(context, game, company),
              ),
            IconButton.filled(
              tooltip: 'Acheter 1 part de ${company.name}',
              icon: const Icon(Icons.add),
              onPressed: canBuy ? () => _buy(context, game, company) : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// Fiche entreprise (feuille du bas, M3) : notions dévoilées au rythme des villes, achat et vente.
Future<void> showCompanySheet(BuildContext context, Company c) {
  final game = GameScope.read(context);
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => ListenableBuilder(
      listenable: game,
      builder: (context, _) {
        final done = game.citiesDone;
        final held = game.city.holdings[c.symbol];
        final open = game.cityUnlocked(2);
        final text = Theme.of(context).textTheme;
        final lvl = held == null ? 1 : buildingLevel(game.city, c.symbol);
        Widget row(String k, String v) => ListTile(dense: true, title: Text(k), trailing: Text(v, style: text.titleSmall));
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Image.asset('assets/buildings/${c.family.name}-$lvl.webp', width: 56),
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
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: open
                      ? Row(
                          children: [
                            if (held != null) ...[
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _sell(context, game, c),
                                  icon: const Icon(Icons.remove),
                                  label: const Text('Vendre 1 part'),
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: buyCost(game.city, c.symbol, 1) <= game.savings ? () => _buy(context, game, c) : null,
                                icon: const Icon(Icons.add),
                                label: Text('Acheter · ${fcfa(buyCost(game.city, c.symbol, 1))}'),
                              ),
                            ),
                          ],
                        )
                      : const PacoBubble(pose: Pose.reflechir, size: 64, text: marketLockedText),
                ),
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
    ),
  );
}
