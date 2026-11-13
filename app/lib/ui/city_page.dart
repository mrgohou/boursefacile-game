import 'package:flutter/material.dart';

import 'feedback_sheet.dart';
import 'level_page.dart';
import 'paco.dart';
import 'quiz_page.dart';
import 'scope.dart';

/// Une ville : présentation par Paco, 3 niveaux, quiz de validation.
class CityPage extends StatelessWidget {
  const CityPage({super.key, required this.city});
  final int city;

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final c = game.content.cities[city - 1];
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final first = !game.seenIntro.contains(city);
    final done = game.cityStars(city) >= 5;
    final validated = game.cityValidated(city);

    Future<void> openQuiz() async {
      final score = await Navigator.of(context).push<int>(MaterialPageRoute(builder: (_) => QuizPage(city: city)));
      if (score == null || !context.mounted) return;
      final card = game.finishQuiz(city, score);
      if (card != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Nouvelle carte : $card !')));
      }
      if (score >= 2 && !game.feedback.containsKey(city)) await showFeedbackSheet(context, city, c.name);
    }

    return Scaffold(
      appBar: AppBar(title: Text('${c.n}. ${c.name}')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          Text('${c.country} · ${c.notion}', style: text.titleMedium?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 16),
          if (first)
            PacoBubble(
              pose: Pose.expliquer,
              text: c.pacoIntro,
              action: 'Compris !',
              onAction: () => game.markIntroSeen(city),
            )
          else ...[
            Row(
              children: [
                for (final l in game.content.levelsOf(city)) ...[
                  Expanded(child: _LevelCard(levelIndex: l.index, levelId: l.id, city: city)),
                  if (l.index < 3) const SizedBox(width: 10),
                ],
              ],
            ),
            const SizedBox(height: 20),
            if (validated)
              PacoBubble(
                pose: Pose.reussir,
                text: 'Ville validée ! ${c.retiens}${city < 15 ? ' Direction ${game.content.cities[city].name}.' : ''}',
              )
            else if (done) ...[
              PacoBubble(pose: Pose.apprendre, text: 'Ce qu’on retient : ${c.retiens}'),
              const SizedBox(height: 16),
              FilledButton.icon(onPressed: openQuiz, icon: const Icon(Icons.quiz_outlined), label: const Text('Quiz de Paco')),
            ] else
              Text('Gagne 5 étoiles sur 9 pour débloquer le quiz de Paco.', style: text.bodyMedium),
          ],
        ],
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.levelIndex, required this.levelId, required this.city});
  final int levelIndex, city;
  final String levelId;

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final level = game.content.levels.firstWhere((l) => l.id == levelId);
    final open = game.levelUnlocked(level);
    final st = game.stars[levelId] ?? 0;
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      enabled: open,
      label: open ? 'Niveau $levelIndex, $st étoiles sur 3' : 'Niveau $levelIndex verrouillé',
      child: ExcludeSemantics(
        child: Card(
          color: open ? scheme.primaryContainer : scheme.surfaceContainerHighest,
          child: InkWell(
            onTap: open
                ? () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => LevelPage(level: level)))
                : null,
            child: AspectRatio(
              aspectRatio: 1,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  open
                      ? Text('$levelIndex', style: Theme.of(context).textTheme.headlineLarge)
                      : Icon(Icons.lock_outline, color: scheme.onSurfaceVariant),
                  const SizedBox(height: 4),
                  Text('★' * st + '☆' * (3 - st), style: const TextStyle(color: Color(0xFFE09F00), letterSpacing: 2)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
