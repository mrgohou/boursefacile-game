import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../domain/lessons.dart';
import '../domain/player_state.dart';
import 'illustrations.dart';

class PuzzleMapPage extends StatelessWidget {
  const PuzzleMapPage({
    super.key,
    required this.state,
    required this.onLevelTap,
  });
  final PlayerState state;
  final ValueChanged<int> onLevelTap;
  static const positions = [.28, .67, .37, .72, .31, .62];
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFEAF2D8),
    appBar: AppBar(
      title: const Text('Le chemin de Paco'),
      backgroundColor: const Color(0xFFEAF2D8),
    ),
    body: SafeArea(
      child: SingleChildScrollView(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  child: Row(
                    children: [
                      const PacoMascot(size: 76, pose: 'progresser'),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Chaque pas compte.',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(color: const Color(0xFF163C32)),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Un puzzle, une idée à emporter.',
                              style: TextStyle(color: Color(0xFF34583E)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${state.unlockedLevel} / 6 étapes',
                        style: const TextStyle(color: Color(0xFF34583E)),
                      ),
                      const Chip(label: Text('Sans vies limitées')),
                    ],
                  ),
                ),
                LayoutBuilder(
                  builder: (context, c) {
                    const step = 148.0;
                    return SizedBox(
                      height: step * 6 + 60,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _JourneyPainter(positions),
                            ),
                          ),
                          for (var i = 0; i < 6; i++)
                            Positioned(
                              left: (c.maxWidth - 112) * positions[i],
                              top: 28 + i * step,
                              width: 112,
                              child: Column(
                                children: [
                                  Semantics(
                                    button: true,
                                    label:
                                        'Niveau ${i + 1}, ${lessons[i].topic}, ${i > state.unlockedLevel
                                            ? 'verrouillé'
                                            : state.answered.contains(i)
                                            ? 'terminé'
                                            : 'disponible'}',
                                    excludeSemantics: true,
                                    child: Material(
                                      elevation: i == state.unlockedLevel
                                          ? 7
                                          : 2,
                                      shadowColor: const Color(0x553F6532),
                                      color: i > state.unlockedLevel
                                          ? const Color(0xFFCFD8BF)
                                          : state.answered.contains(i)
                                          ? const Color(0xFF4F9368)
                                          : const Color(0xFFFFD875),
                                      shape: const CircleBorder(
                                        side: BorderSide(
                                          color: Colors.white,
                                          width: 5,
                                        ),
                                      ),
                                      child: InkWell(
                                        customBorder: const CircleBorder(),
                                        onTap: i > state.unlockedLevel
                                            ? null
                                            : () => onLevelTap(i),
                                        child: SizedBox(
                                          width: 78,
                                          height: 78,
                                          child: Center(
                                            child: i > state.unlockedLevel
                                                ? const Icon(
                                                    Icons.lock_outline,
                                                    size: 27,
                                                    color: Color(0xFF75826D),
                                                  )
                                                : Text(
                                                    '${i + 1}',
                                                    style: TextStyle(
                                                      fontSize: 31,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                      color:
                                                          state.answered
                                                              .contains(i)
                                                          ? Colors.white
                                                          : const Color(
                                                              0xFF5F4817,
                                                            ),
                                                    ),
                                                  ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 9,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: .95,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      lessons[i].topic,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Color(0xFF244C38),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  if (state.completed.contains(i))
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: List.generate(
                                        3,
                                        (j) => Icon(
                                          j <
                                                  (state.answered.contains(i)
                                                      ? 3
                                                      : 1)
                                              ? Icons.star_rounded
                                              : Icons.star_outline_rounded,
                                          size: 17,
                                          color: const Color(0xFFBA831F),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Text(
                    'Les étoiles indiquent ici ta progression pédagogique. Rejouer ne distribue pas une nouvelle récompense.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF34583E)),
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

class _JourneyPainter extends CustomPainter {
  _JourneyPainter(this.positions);
  final List<double> positions;
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final points = List.generate(
      6,
      (i) => Offset((size.width - 112) * positions[i] + 56, 67 + i * 148.0),
    );
    path.moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final a = points[i - 1], b = points[i];
      path.cubicTo(a.dx, a.dy + 75, b.dx, b.dy - 75, b.dx, b.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFCAD7B3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 30
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFFFF5D6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 21
        ..strokeCap = StrokeCap.round,
    );
    for (var i = 0; i < 18; i++) {
      final x = (i.isEven ? .08 : .86) * size.width;
      final y = 70 + i * 49.0;
      canvas.drawCircle(
        Offset(x, y),
        10 + math.sin(i) * 3,
        Paint()..color = const Color(0xFF96BA77).withValues(alpha: .55),
      );
      canvas.drawCircle(
        Offset(x + 9, y + 5),
        7,
        Paint()..color = const Color(0xFFB1CC8C),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _JourneyPainter old) => false;
}
