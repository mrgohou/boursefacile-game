import 'package:material_ui/material_ui.dart';

/// Native layered text stays sharp at any density; lighting and extrusion give
/// the rounded Nunito glyphs a soft clay volume. One finite, accessible bounce.
class ClayHeading extends StatelessWidget {
  const ClayHeading({super.key, required this.won});
  final bool won;
  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    final text = won ? 'GAGNE' : 'PAS DE\nCHANCE';
    final style = TextStyle(
      fontFamily: 'Nunito',
      fontSize: won ? 50 : 37,
      fontWeight: FontWeight.w900,
      height: 1.02,
      letterSpacing: 1,
      color: won ? const Color(0xFFFFE47E) : const Color(0xFFFFC4B7),
    );
    final title = Semantics(
      header: true,
      liveRegion: true,
      label: won ? 'GAGNE' : 'PAS DE CHANCE',
      excludeSemantics: true,
      child: MediaQuery.withClampedTextScaling(
        minScaleFactor: 1,
        maxScaleFactor: 1.2,
        child: Stack(
          alignment: Alignment.center,
          children: [
            for (var i = 7; i >= 1; i--)
              Transform.translate(
                offset: Offset(0, i.toDouble()),
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: style.copyWith(
                    color: won
                        ? const Color(0xFF9D5B1E)
                        : const Color(0xFF9F4F5C),
                    shadows: [
                      if (i == 7)
                        const Shadow(
                          color: Color(0x66000000),
                          blurRadius: 14,
                          offset: Offset(0, 6),
                        ),
                    ],
                  ),
                ),
              ),
            Text(
              text,
              textAlign: TextAlign.center,
              style: style.copyWith(
                shadows: const [
                  Shadow(
                    color: Color(0x99FFFFFF),
                    offset: Offset(0, -2),
                    blurRadius: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    if (reduced) return title;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 850),
      curve: Curves.elasticOut,
      child: title,
      builder: (context, value, child) => Transform.translate(
        offset: Offset(0, -36 * (1 - value)),
        child: Transform.scale(scale: .78 + .22 * value, child: child),
      ),
    );
  }
}
