import 'package:flutter/material.dart';

import 'paco.dart';
import 'scope.dart';

/// Premier lancement : Paco se présente.
class Welcome extends StatelessWidget {
  const Welcome({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) => SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: c.maxHeight - 48),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Apprends la bourse en jouant', style: text.headlineLarge),
                      const SizedBox(height: 8),
                      Text('Épargne. Investis. Récolte avec patience.', style: text.bodyLarge),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Image.asset('assets/paco/accueil.webp', height: 260, semanticLabel: 'Paco l’éléphant te salue'),
                  const SizedBox(height: 24),
                  const PacoBubble(
                    pose: Pose.confiance,
                    size: 0,
                    text: 'Salut, moi c’est Paco ! Je vais t’apprendre la bourse de la BRVM, ville après ville.',
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => GameScope.read(context).markIntroSeen(0),
                    child: const Text('Jouer'),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Version de test · FCFA-jeu fictifs · aucun argent réel · aucun conseil d’investissement',
                    textAlign: TextAlign.center,
                    style: text.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
