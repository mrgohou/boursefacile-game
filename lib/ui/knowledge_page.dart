import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

class KnowledgePage extends StatefulWidget {
  const KnowledgePage({
    super.key,
    required this.topic,
    required this.onAttempt,
    this.onRecordedAttempt,
    this.onClosedQuestion,
  });
  final String topic;
  final void Function(String topic, bool correct) onAttempt;
  final Future<bool> Function(String id, bool correct)? onRecordedAttempt;
  final Future<void> Function()? onClosedQuestion;
  @override
  State<KnowledgePage> createState() => _KnowledgePageState();
}

class _KnowledgePageState extends State<KnowledgePage> {
  late final Future<List<dynamic>> bank = rootBundle
      .loadString('assets/knowledge/practical_quizzes.json')
      .then((s) => (jsonDecode(s) as Map)['questions'] as List);
  String query = '';
  Future<void> openSource() async {
    try {
      await const MethodChannel('paco/sources').invokeMethod<void>('fluxQuiz');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Ouvre https://fluxbourse.com/quiz-bourse dans ton navigateur.',
            ),
          ),
        );
      }
    }
  }

  Future<void> question(Map q) async {
    int? chosen;
    bool answered = false, saving = false;
    await showDialog<void>(
      context: context,
      builder: (dc) => StatefulBuilder(
        builder: (dc, setDialog) => AlertDialog(
          title: Text(q['question'] as String),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < (q['options'] as List).length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: OutlinedButton(
                      onPressed: answered || saving
                          ? null
                          : () async {
                              setDialog(() => saving = true);
                              final ok =
                                  await widget.onRecordedAttempt?.call(
                                    q['id'] as String,
                                    i == q['answer'],
                                  ) ??
                                  true;
                              if (!dc.mounted) return;
                              setDialog(() => saving = false);
                              if (!ok) return;
                              widget.onAttempt(
                                q['topic'] as String,
                                i == q['answer'],
                              );
                              setDialog(() {
                                chosen = i;
                                answered = true;
                              });
                            },
                      child: Text(q['options'][i] as String),
                    ),
                  ),
                if (answered) ...[
                  Text(
                    chosen == q['answer']
                        ? 'Bien compris !'
                        : 'Reprenons ensemble.',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  Text(q['explanation'] as String),
                  const SizedBox(height: 12),
                  Text('À pratiquer : ${q['practiceAction']}'),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(dc),
              child: const Text('Fermer'),
            ),
            if (answered && chosen != q['answer'])
              FilledButton(
                onPressed: () => setDialog(() {
                  answered = false;
                  chosen = null;
                }),
                child: const Text('Réessayer'),
              ),
          ],
        ),
      ),
    );
    await widget.onClosedQuestion?.call();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Les repères de Paco')),
    body: FutureBuilder<List<dynamic>>(
      future: bank,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text('La base pédagogique n’a pas pu être chargée.'),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final all = List<Map>.from(snapshot.data!);
        all.sort((a, b) {
          final at =
              (a['topic'] as String).toLowerCase() ==
              widget.topic.toLowerCase();
          final bt =
              (b['topic'] as String).toLowerCase() ==
              widget.topic.toLowerCase();
          return at == bt
              ? 0
              : at
              ? -1
              : 1;
        });
        final list = all
            .where(
              (q) => '${q['topic']} ${q['question']}'.toLowerCase().contains(
                query.toLowerCase(),
              ),
            )
            .toList();
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    '40 exercices pratiques · priorité : ${widget.topic}. Éducation générale, sans recommandation personnelle.',
                  ),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Rechercher une notion',
                    ),
                    onChanged: (v) => setState(() => query = v),
                  ),
                  TextButton.icon(
                    onPressed: openSource,
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Quiz complémentaires sur FluxBourse'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: list.length,
                itemBuilder: (context, i) => ListTile(
                  title: Text(list[i]['question'] as String),
                  subtitle: Text(list[i]['topic'] as String),
                  trailing: const Icon(Icons.quiz_outlined),
                  onTap: () => question(list[i]),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}
