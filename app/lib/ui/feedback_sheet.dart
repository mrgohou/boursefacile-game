import 'package:flutter/material.dart';

import '../services/game_state.dart';
import 'scope.dart';

/// Avis testeur (GDD §11) : 3 questions après chaque ville validée, sans donnée personnelle.
Future<void> showFeedbackSheet(BuildContext context, int city, String cityName) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _FeedbackForm(city: city, cityName: cityName, game: GameScope.read(context)),
  );
}

class _FeedbackForm extends StatefulWidget {
  const _FeedbackForm({required this.city, required this.cityName, required this.game});
  final int city;
  final String cityName;
  final GameState game;

  @override
  State<_FeedbackForm> createState() => _FeedbackFormState();
}

class _FeedbackFormState extends State<_FeedbackForm> {
  int? compris, amusant;
  final _changer = TextEditingController();

  @override
  void dispose() {
    _changer.dispose();
    super.dispose();
  }

  Widget _faces(int? value, ValueChanged<int> set) => SegmentedButton<int>(
        segments: const [
          ButtonSegment(value: 1, label: Text('😕', style: TextStyle(fontSize: 24)), tooltip: 'Pas vraiment'),
          ButtonSegment(value: 2, label: Text('🙂', style: TextStyle(fontSize: 24)), tooltip: 'Un peu'),
          ButtonSegment(value: 3, label: Text('😀', style: TextStyle(fontSize: 24)), tooltip: 'Oui'),
        ],
        emptySelectionAllowed: true,
        showSelectedIcon: false,
        selected: {if (value != null) value},
        onSelectionChanged: (s) => setState(() => set(s.first)),
      );

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Ton avis sur ${widget.cityName}', style: text.titleLarge),
            const SizedBox(height: 4),
            Text('Tu testes PACO Bourse : tes réponses aident l’équipe. Elles ne contiennent ni ton nom ni ton e-mail.', style: text.bodySmall),
            const SizedBox(height: 16),
            Text('As-tu compris la leçon ?', style: text.titleMedium),
            const SizedBox(height: 8),
            _faces(compris, (v) => compris = v),
            const SizedBox(height: 16),
            Text('C’était amusant ?', style: text.titleMedium),
            const SizedBox(height: 8),
            _faces(amusant, (v) => amusant = v),
            const SizedBox(height: 16),
            TextField(
              controller: _changer,
              maxLength: 500,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Une chose à changer ? (facultatif)'),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: compris == null || amusant == null
                  ? null
                  : () {
                      widget.game.saveFeedback(widget.city, TesterFeedback(compris!, amusant!, _changer.text.trim()));
                      Navigator.pop(context);
                    },
              child: const Text('Envoyer'),
            ),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Passer')),
          ],
        ),
      ),
    );
  }
}
