import 'package:material_ui/material_ui.dart';

import '../domain/cultural_catalog.dart';

class FabricRibbon extends StatelessWidget {
  const FabricRibbon({super.key, required this.pattern});
  final int pattern;
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Motif inspiré du ${fabricNames[pattern]}',
    image: true,
    child: SizedBox(
      height: 28,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CustomPaint(painter: _FabricPainter(pattern)),
      ),
    ),
  );
}

class _FabricPainter extends CustomPainter {
  const _FabricPainter(this.pattern);
  final int pattern;
  @override
  void paint(Canvas c, Size s) {
    const colors = [
      Color(0xFFDC9A28),
      Color(0xFF47342B),
      Color(0xFF303E7A),
      Color(0xFF914F66),
      Color(0xFF23716C),
    ];
    c.drawRect(Offset.zero & s, Paint()..color = colors[pattern]);
    final cream = Paint()
      ..color = const Color(0xFFFFE6AA)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (double x = 0; x < s.width; x += 28) {
      if (pattern == 0 || pattern == 3) {
        final p = Path()
          ..moveTo(x + 14, 2)
          ..lineTo(x + 26, 14)
          ..lineTo(x + 14, 26)
          ..lineTo(x + 2, 14)
          ..close();
        c.drawPath(p, cream);
        if (pattern == 3) {
          c.drawCircle(Offset(x + 14, 14), 4, cream);
        } else {
          c.drawLine(Offset(x + 9, 10), Offset(x + 19, 18), cream);
        }
      } else if (pattern == 1) {
        c.drawLine(Offset(x, 3), Offset(x + 25, 25), cream);
        c.drawCircle(Offset(x + 5, 19), 2, cream);
        c.drawCircle(Offset(x + 20, 7), 2, cream);
      } else if (pattern == 2) {
        c.drawRect(Rect.fromLTWH(x + 3, 0, 5, 28), cream);
        c.drawRect(Rect.fromLTWH(x + 14, 0, 2, 28), cream);
      } else {
        c.drawLine(Offset(x, 6), Offset(x + 28, 6), cream);
        c.drawLine(Offset(x, 22), Offset(x + 28, 22), cream);
        c.drawRect(Rect.fromLTWH(x + 8, 9, 12, 10), cream);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FabricPainter old) => pattern != old.pattern;
}
