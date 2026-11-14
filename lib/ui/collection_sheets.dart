import 'package:material_ui/material_ui.dart';

import '../domain/lessons.dart';
import '../domain/player_state.dart';
import 'paco_theme.dart';

String _money(int value) =>
    '${value.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '\u202f')} FCFA-jeu';

class PropertiesSheet extends StatelessWidget {
  const PropertiesSheet({
    super.key,
    required this.state,
    required this.onCompanyTap,
    this.onOpenGuichet,
  });
  final PlayerState state;
  final ValueChanged<String> onCompanyTap;
  final VoidCallback? onOpenGuichet;

  @override
  Widget build(BuildContext context) {
    final owned = companies.where((c) => state.holdings[c.id]! > 0).toList();
    return _CollectionPage(
      title: 'Mes propriétés',
      subtitle: 'Les petites parts qui font grandir ta ville.',
      children: [
        _Balance(state: state),
        const SizedBox(height: 24),
        if (owned.isEmpty) ...[
          const Icon(Icons.cottage_outlined, size: 64),
          const SizedBox(height: 16),
          Text(
            'Ta ville attend sa première propriété',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Tu ne détiens aucune part pour le moment. Au guichet, découvre trois entreprises fictives. Acheter reste ton choix.',
          ),
          const SizedBox(height: 16),
          if (onOpenGuichet != null)
            FilledButton.icon(
              onPressed: onOpenGuichet,
              icon: const Icon(Icons.storefront_outlined),
              label: const Text('Découvrir le guichet'),
            ),
        ] else ...[
          const Text(
            'Chaque bâtiment représente une entreprise fictive dont tu détiens au moins une part.',
          ),
          const SizedBox(height: 16),
          for (final company in owned)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => onCompanyTap(company.id),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Building(company: company, height: 112),
                        Text(
                          company.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(company.sector),
                        const SizedBox(height: 12),
                        Text(
                          '${state.holdings[company.id]} part(s) détenue(s)',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          'Valeur des parts : ${_money(state.holdings[company.id]! * state.prices[company.id]!)}',
                        ),
                        Text(
                          'Cours fictif par part : ${_money(state.prices[company.id]!)}',
                        ),
                        const SizedBox(height: 8),
                        const Text('Voir cette entreprise →'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class CompanyCardsSheet extends StatelessWidget {
  const CompanyCardsSheet({
    super.key,
    required this.state,
    required this.onCompanyTap,
  });
  final PlayerState state;
  final ValueChanged<String> onCompanyTap;

  @override
  Widget build(BuildContext context) => _CollectionPage(
    title: 'Mes cartes',
    subtitle: 'Des entreprises à découvrir, des idées à garder.',
    children: [
      Text(
        'Entreprises de ma ville',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 8),
      const Text(
        'Une première acquisition débloque la carte. Elle reste dans ta collection après la vente.',
      ),
      const SizedBox(height: 16),
      LayoutBuilder(
        builder: (context, constraints) {
          final largeText = MediaQuery.textScalerOf(context).scale(16) >= 24;
          final columns = largeText
              ? 1
              : (constraints.maxWidth / 170).floor().clamp(1, 3);
          final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: companies.map((company) {
              final owned = state.companyCards.contains(company.id);
              return SizedBox(
                width: width,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Building(company: company, height: 110),
                        Text(
                          company.sector,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          company.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        const Text('Entreprise fictive'),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              owned
                                  ? Icons.check_circle_outline
                                  : Icons.lock_outline,
                              size: 20,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                owned ? 'Dans ma collection' : 'À découvrir',
                              ),
                            ),
                          ],
                        ),
                        if (owned) ...[
                          const SizedBox(height: 8),
                          Text(
                            '${state.holdings[company.id]} part(s) détenue(s)',
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton(
                            onPressed: () => onCompanyTap(company.id),
                            child: const Text('Voir la fiche'),
                          ),
                        ] else ...[
                          const SizedBox(height: 8),
                          const Text(
                            'Une première acquisition rend cette fiche consultable.',
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
      const SizedBox(height: 32),
      _LessonCards(state: state),
    ],
  );
}

class LessonCardsSheet extends StatelessWidget {
  const LessonCardsSheet({super.key, required this.state});
  final PlayerState state;
  @override
  Widget build(BuildContext context) => _CollectionPage(
    title: 'Mes idées à garder',
    subtitle: 'Les notions comprises avec Paco.',
    children: [_LessonCards(state: state)],
  );
}

class _LessonCards extends StatelessWidget {
  const _LessonCards({required this.state});
  final PlayerState state;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Les cartes de Paco', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 8),
      Text(
        '${state.answered.length} sur ${lessons.length} notions comprises. Une carte se révèle après le quiz réussi ; tu peux ensuite relire son explication ici.',
      ),
      const SizedBox(height: 16),
      for (var index = 0; index < lessons.length; index++)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Card(
            child: state.answered.contains(index)
                ? ExpansionTile(
                    leading: const Icon(Icons.auto_stories_outlined),
                    title: Text(lessons[index].topic),
                    subtitle: const Text(
                      'Notion comprise · ouvrir pour relire',
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(lessons[index].description),
                      const SizedBox(height: 12),
                      Text(
                        lessons[index].explanation,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  )
                : ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: const Icon(Icons.lock_outline),
                    title: Text(lessons[index].topic),
                    subtitle: const Text(
                      'À découvrir · termine le puzzle et son quiz',
                    ),
                  ),
          ),
        ),
    ],
  );
}

class _CollectionPage extends StatelessWidget {
  const _CollectionPage({
    required this.title,
    required this.subtitle,
    required this.children,
  });
  final String title, subtitle;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => SafeArea(
    child: Column(
      children: [
        const SizedBox(height: 10),
        Container(
          width: 40,
          height: 5,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.outlineVariant,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 12, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Fermer',
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subtitle, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 24),
                ...children,
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _Balance extends StatelessWidget {
  const _Balance({required this.state});
  final PlayerState state;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: PacoColors.lime,
      borderRadius: BorderRadius.circular(24),
    ),
    child: DefaultTextStyle.merge(
      style: const TextStyle(color: PacoColors.forest),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('MON PETIT BILAN'),
          const SizedBox(height: 8),
          Text(
            _money(state.totalValue),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: PacoColors.forest,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text('Épargne disponible : ${_money(state.cash)}'),
          Text('Valeur de mes parts : ${_money(state.holdingsValue)}'),
          const SizedBox(height: 8),
          const Text(
            'Total = épargne + valeur des parts. Tous les montants sont fictifs.',
          ),
        ],
      ),
    ),
  );
}

class _Building extends StatelessWidget {
  const _Building({required this.company, required this.height});
  final Company company;
  final double height;
  @override
  Widget build(BuildContext context) {
    final asset = company.id == 'cacao' ? 'agro' : company.id;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Color(company.colorValue).withValues(alpha: .12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Image.asset(
        'assets/buildings/$asset-1.webp',
        height: height,
        fit: BoxFit.contain,
        excludeFromSemantics: true,
        cacheWidth: 384,
        errorBuilder: (_, _, _) => SizedBox(
          height: height,
          child: const Icon(Icons.cottage_outlined, size: 60),
        ),
      ),
    );
  }
}
