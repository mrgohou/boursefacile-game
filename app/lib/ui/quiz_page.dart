import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'paco.dart';
import 'scope.dart';

/// Quiz de Paco : 3 questions, 2 bonnes réponses pour valider la ville. Renvoie le score.
class QuizPage extends StatefulWidget {
  const QuizPage({super.key, required this.city});
  final int city;

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  int i = 0, score = 0;
  String? picked;
  final _rand = Random();
  List<String>? _options;

  @override
  Widget build(BuildContext context) {
    final questions = GameScope.read(context).content.quiz[widget.city]!;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    if (i >= questions.length) {
      final ok = score >= 2;
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz de Paco')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(ok ? 'Quiz réussi !' : 'Presque !', style: text.headlineLarge),
            Text('$score / 3', style: text.displayMedium?.copyWith(color: scheme.primary, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            PacoBubble(
              pose: ok ? (score == 3 ? Pose.reussir : Pose.confiance) : Pose.reconfort,
              text: ok
                  ? (score == 3 ? 'Sans faute ! Tu gagnes une carte entreprise pour ta collection.' : 'Bravo, la ville suivante est ouverte !')
                  : 'Il faut 2 bonnes réponses. Relis la leçon de la ville et réessaie, rien n’est perdu.',
              action: ok ? 'Continuer' : 'Retour',
              onAction: () => Navigator.pop(context, score),
            ),
          ],
        ),
      );
    }

    final q = questions[i];
    final options = _options ??= ([...q.answers]..shuffle(_rand));
    return Scaffold(
      appBar: AppBar(title: Text('Question ${i + 1} / ${questions.length}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          LinearProgressIndicator(value: (i + (picked == null ? 0 : 1)) / questions.length),
          const SizedBox(height: 20),
          Text(q.q, style: text.headlineMedium),
          const SizedBox(height: 16),
          for (final o in options) ...[
            _Answer(
              label: o,
              state: picked == null ? null : (o == q.good ? true : (o == picked ? false : null)),
              onTap: picked != null
                  ? null
                  : () {
                      setState(() {
                        picked = o;
                        if (o == q.good) score++;
                      });
                      o == q.good ? HapticFeedback.lightImpact() : HapticFeedback.heavyImpact();
                    },
            ),
            const SizedBox(height: 10),
          ],
          if (picked != null) ...[
            const SizedBox(height: 8),
            PacoBubble(
              pose: picked == q.good ? Pose.confiance : Pose.expliquer,
              text: (picked == q.good ? 'Exact ! ' : 'Pas tout à fait. ') + q.why,
              action: 'Suivant',
              onAction: () => setState(() {
                picked = null;
                _options = null;
                i++;
              }),
            ),
          ],
        ],
      ),
    );
  }
}

class _Answer extends StatelessWidget {
  const _Answer({required this.label, required this.state, required this.onTap});
  final String label;
  final bool? state; // true = bonne réponse, false = mauvais choix
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = state == true ? scheme.primaryContainer : (state == false ? scheme.errorContainer : scheme.surface);
    return Semantics(
      button: true,
      label: '$label${state == true ? ', bonne réponse' : state == false ? ', mauvaise réponse' : ''}',
      child: ExcludeSemantics(
        child: Material(
          color: bg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: state == null ? scheme.outlineVariant : Colors.transparent, width: 1.5),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Row(
                children: [
                  Expanded(child: Text(label, style: Theme.of(context).textTheme.titleMedium)),
                  if (state == true) Icon(Icons.check_circle, color: scheme.primary),
                  if (state == false) Icon(Icons.cancel, color: scheme.error),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
