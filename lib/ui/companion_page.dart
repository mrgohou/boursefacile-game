import 'package:material_ui/material_ui.dart';

import '../domain/companion_catalog.dart';
import '../data/player_controller.dart';

class CompanionPage extends StatefulWidget {
  const CompanionPage({
    super.key,
    required this.controller,
    required this.onAnswer,
    this.onAttempt,
    this.onClosedQuestion,
  });
  final PlayerController controller;
  final Future<bool> Function(int city, int question) onAnswer;
  final Future<bool> Function(int city, int question, bool correct)? onAttempt;
  final Future<void> Function()? onClosedQuestion;
  @override
  State<CompanionPage> createState() => _CompanionPageState();
}

class _CompanionPageState extends State<CompanionPage> {
  late Future<CompanionCatalog> catalog = CompanionCatalog.load();
  Future<void> question(Map<String, dynamic> q, int city, int question) async {
    // The source encodes the correct option first. Rotate presentation so that
    // the answer position is not fixed; preserve the source answer index.
    final answers = List<String>.from(q['a'] as List);
    final order = List.generate(
      answers.length,
      (i) => (i + city + question + 1) % answers.length,
    );
    final alreadyAnswered = widget.controller.state.journeyAnswers.contains(
      city * 3 + question,
    );
    String? feedback;
    bool saving = false, finished = false;
    await showDialog<void>(
      context: context,
      builder: (dc) => StatefulBuilder(
        builder: (dc, update) => AlertDialog(
          title: Text(q['q'] as String),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final i in order)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: OutlinedButton(
                      onPressed: saving || finished
                          ? null
                          : () async {
                              update(() => saving = true);
                              final ok =
                                  await widget.onAttempt?.call(
                                    city,
                                    question,
                                    i == 0,
                                  ) ??
                                  true;
                              if (!dc.mounted) return;
                              update(() => saving = false);
                              if (!ok) return;
                              if (i != 0) {
                                update(
                                  () => feedback = 'Essaie encore : relis la notion de Paco.',
                                );
                                return;
                              }
                              update(() => saving = true);
                              final saved = await widget.onAnswer(
                                city,
                                question,
                              );
                              if (!dc.mounted) return;
                              update(() {
                                saving = false;
                                finished = saved;
                                feedback = saved
                                    ? '${city == 6 ? 'Le PER est un ratio de valorisation, pas une promesse de remboursement. Il n’est pas pertinent si le BPA est négatif.' : q['why']}\n\n${alreadyAnswered ? 'Notion revue · récompense déjà reçue.' : 'Notion validée · +300 FCFA-jeu.'}'
                                    : 'Enregistrement impossible. Réessaie.';
                              });
                            },
                      child: Text(answers[i]),
                    ),
                  ),
                if (feedback != null)
                  Semantics(liveRegion: true, child: Text(feedback!)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(dc),
              child: const Text('Fermer'),
            ),
          ],
        ),
      ),
    );
    await widget.onClosedQuestion?.call();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Voyage de Paco')),
    body: FutureBuilder<CompanionCatalog>(
      future: catalog,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: FilledButton(
              onPressed: () =>
                  setState(() => catalog = CompanionCatalog.load()),
              child: const Text('Réessayer le chargement'),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data!;
        return AnimatedBuilder(
          animation: widget.controller,
          builder: (context, _) {
            final state = widget.controller.state;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  '15 destinations pour faire grandir ta ville',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  '${state.journeyAnswers.length}/45 notions validées. Chaque bonne réponse rapporte une fois 300 FCFA-jeu. Termine les trois quiz pour débloquer la prochaine destination.',
                ),
                const SizedBox(height: 16),
                for (var city = 0; city < data.cities.length; city++)
                  Card(
                    child: ExpansionTile(
                      title: Text('${city + 1}. ${data.cities[city]['name']}'),
                      subtitle: Text(data.cities[city]['notion'] as String),
                      leading: Icon(
                        city == 0 ||
                                List.generate(
                                  3,
                                  (i) => (city - 1) * 3 + i,
                                ).every(state.journeyAnswers.contains)
                            ? Icons.location_city_rounded
                            : Icons.lock_outline,
                      ),
                      childrenPadding: const EdgeInsets.all(16),
                      children: [
                        Text(
                          city == 6
                              ? 'Le PER compare le cours au bénéfice par action. Il ne promet ni remboursement ni durée de retour sur investissement.'
                              : data.cities[city]['pacoIntro'] as String,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          city == 6
                              ? 'PER = cours ÷ BPA positif. Les bénéfices futurs restent incertains.'
                              : data.cities[city]['retiens'] as String,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        for (var q = 0; q < 3; q++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: FilledButton.tonalIcon(
                              onPressed:
                                  widget.controller.busy ||
                                      (city > 0 &&
                                          !List.generate(
                                            3,
                                            (i) => (city - 1) * 3 + i,
                                          ).every(
                                            state.journeyAnswers.contains,
                                          ))
                                  ? null
                                  : () => question(
                                      Map<String, dynamic>.from(
                                        (data.quiz['${city + 1}'] as List)[q],
                                      ),
                                      city,
                                      q,
                                    ),
                              icon: Icon(
                                state.journeyAnswers.contains(city * 3 + q)
                                    ? Icons.check_circle_outline
                                    : Icons.quiz_outlined,
                              ),
                              label: Text(
                                state.journeyAnswers.contains(city * 3 + q)
                                    ? 'Notion ${q + 1} · revoir'
                                    : 'Notion ${q + 1} · +300 FCFA-jeu',
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                ExpansionTile(
                  title: const Text('Repères de marché · archive'),
                  subtitle: Text(
                    'Instantané du ${data.market['sessionDate']} · aucun cours en direct',
                  ),
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Exemples historiques fournis dans l’APK. Données non vérifiées ici ; BPA, PER et dividendes sont à contrôler dans les publications officielles. Ces cours servent aussi de référence au portefeuille simulé du guichet. Aucun achat réel.',
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(data.market['source'] as String),
                    ),
                    for (final c in data.market['companies'] as List)
                      ListTile(
                        title: Text('${c['symbol']} · ${c['name']}'),
                        subtitle: Text(
                          '${c['country']} · ${c['sector']}\n${c['price']} FCFA · archive',
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        );
      },
    ),
  );
}
