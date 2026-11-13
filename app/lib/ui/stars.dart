import 'package:flutter/material.dart';

/// Rangée d'étoiles (0 à 3), en icônes pour un rendu identique sur tous les téléphones.
class Stars extends StatelessWidget {
  const Stars(this.count, {super.key, this.size = 18});
  final int count;
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
        label: '$count étoile${count > 1 ? 's' : ''} sur 3',
        child: ExcludeSemantics(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 3; i++)
                Icon(i < count ? Icons.star_rounded : Icons.star_outline_rounded, size: size, color: const Color(0xFFE0A100)),
            ],
          ),
        ),
      );
}
