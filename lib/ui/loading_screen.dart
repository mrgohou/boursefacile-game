import 'package:material_ui/material_ui.dart';

class PacoLoadingScreen extends StatelessWidget {
  const PacoLoadingScreen({super.key});
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xFF7DDAF8),
    child: SafeArea(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: Semantics(
              image: true,
              label: 'PACO bourse facile. apprendre la bourse. Paco te souhaite la bienvenue.',
              excludeSemantics: true,
              child: Image.asset(
                'assets/branding/paco-loading.png',
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 12,
            child: Center(
              child: Semantics(
                label: 'Chargement du jeu',
                child: SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
