import 'package:flutter/material.dart';

enum Pose { accueil, confiance, reflechir, expliquer, apprendre, analyser, progresser, reussir, attention, patience, reconfort }

/// Paco qui parle : image + bulle. 2 phrases max (GDD §8).
class PacoBubble extends StatelessWidget {
  const PacoBubble({super.key, required this.pose, required this.text, this.action, this.onAction, this.size = 104});

  final Pose pose;
  final String text;
  final String? action;
  final VoidCallback? onAction;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Paco dit : $text',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (size > 0) ...[
            ExcludeSemantics(child: Image.asset('assets/paco/${pose.name}.webp', width: size, fit: BoxFit.contain)),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(22),
                  topRight: Radius.circular(22),
                  bottomRight: Radius.circular(22),
                  bottomLeft: Radius.circular(6),
                ),
                border: Border.all(color: scheme.outlineVariant.withValues(alpha: .6)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExcludeSemantics(child: Text(text, style: Theme.of(context).textTheme.bodyLarge)),
                  if (action != null) ...[
                    const SizedBox(height: 12),
                    FilledButton(onPressed: onAction, child: Text(action!)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
