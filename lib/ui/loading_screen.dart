import 'package:material_ui/material_ui.dart';

import 'illustrations.dart';

class PacoLoadingScreen extends StatelessWidget {
  const PacoLoadingScreen({super.key});
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xFF91DBFF),
    child: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'PACO\nBourse Facile',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2D811E),
                    shadows: [
                      Shadow(
                        color: Color(0xFF16540E),
                        offset: Offset(0, 4),
                        blurRadius: 1,
                      ),
                      Shadow(color: Colors.white70, offset: Offset(-1, -2)),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                const PacoMascot(size: 260),
                const SizedBox(height: 32),
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                const Text(
                  'Ta ville se prépare…',
                  style: TextStyle(
                    color: Color(0xFF163D56),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
