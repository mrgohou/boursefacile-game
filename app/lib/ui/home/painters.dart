// Décor peint (sol, arbres, fontaine) dans le style « jouet doux » des bâtiments.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'city_layout.dart';

class CityPalette {
  const CityPalette(this.dark);
  final bool dark;
  Color get water => dark ? const Color(0xFF1F4F63) : const Color(0xFF8ED6EA);
  Color get waterLight => dark ? const Color(0xFF2A6278) : const Color(0xFFB8E8F3);
  Color get sand => dark ? const Color(0xFF8C7A52) : const Color(0xFFF0DDA8);
  Color get grass => dark ? const Color(0xFF3F6B3A) : const Color(0xFF9DD66C);
  Color get grass2 => dark ? const Color(0xFF3A6436) : const Color(0xFF94CE63);
  Color get road => dark ? const Color(0xFF4A535A) : const Color(0xFF7D8890);
  Color get curb => dark ? const Color(0xFF6A747B) : const Color(0xFFD9DEE2);
  Color get dash => dark ? const Color(0xFFBFC6CB) : Colors.white;
  Color get paving => dark ? const Color(0xFF8D8270) : const Color(0xFFEBDDBA);
  Color get paving2 => dark ? const Color(0xFF857A69) : const Color(0xFFE2D2AA);
  Color get dirt => dark ? const Color(0xFF7A6142) : const Color(0xFFDDBB82);
  Color get dirtEdge => dark ? const Color(0xFF5E4A33) : const Color(0xFFC49E66);
}

Path diamond(double i0, double j0, double i1, double j1) => Path()
  ..moveTo(iso(i0, j0).dx, iso(i0, j0).dy)
  ..lineTo(iso(i1, j0).dx, iso(i1, j0).dy)
  ..lineTo(iso(i1, j1).dx, iso(i1, j1).dy)
  ..lineTo(iso(i0, j1).dx, iso(i0, j1).dy)
  ..close();

/// Sol : lagune, berge, herbe, routes, place pavée, terrains à vendre.
class GroundPainter extends CustomPainter {
  GroundPainter({required this.dark, required this.salePlots});
  final bool dark;
  final List<(int, int)> salePlots;

  @override
  void paint(Canvas canvas, Size size) {
    final p = CityPalette(dark);
    const n = gridN * 1.0;
    canvas.drawPath(diamond(-margin, -margin, n + margin, n + margin), Paint()..color = p.water);
    // Reflets de la lagune.
    final ripple = Paint()
      ..color = p.waterLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final rnd = math.Random(3);
    for (var k = 0; k < 160; k++) {
      final i = -margin + rnd.nextDouble() * (n + 2 * margin);
      final j = -margin + rnd.nextDouble() * (n + 2 * margin);
      if (i > -2.8 && i < n + 2.8 && j > -2.8 && j < n + 2.8) continue;
      final o = iso(i, j);
      canvas.drawLine(o.translate(-9, 0), o.translate(9, 0), ripple);
    }
    canvas.drawPath(diamond(-2.4, -2.4, n + 2.4, n + 2.4), Paint()..color = p.sand);
    canvas.drawPath(diamond(-2, -2, n + 2, n + 2), Paint()..color = p.grass);

    final g2 = Paint()..color = p.grass2;
    final roadPaint = Paint()..color = p.road;
    final curb = Paint()
      ..color = p.curb
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final dash = Paint()
      ..color = p.dash
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final pl = plaza;
    final pave = Paint()..color = p.paving, pave2 = Paint()..color = p.paving2;

    for (var i = 0; i < gridN; i++) {
      for (var j = 0; j < gridN; j++) {
        final tile = diamond(i * 1.0, j * 1.0, i + 1.0, j + 1.0);
        if (isRoad(i, j)) {
          canvas.drawPath(tile, roadPaint);
          final ri = i % (blockSize + 1) == 0, rj = j % (blockSize + 1) == 0;
          if (ri != rj) {
            // Pointillés au milieu de la voie.
            final a = ri ? iso(i + .5, j + .25) : iso(i + .25, j + .5);
            final b = ri ? iso(i + .5, j + .75) : iso(i + .75, j + .5);
            canvas.drawLine(a, b, dash);
          }
        } else if (i >= pl.i0 && i < pl.i0 + blockSize && j >= pl.j0 && j < pl.j0 + blockSize) {
          canvas.drawPath(tile, (i + j).isEven ? pave : pave2);
        } else if ((i * 7 + j * 3) % 5 == 0) {
          canvas.drawPath(tile, g2);
        }
      }
    }
    // Bordures de trottoir autour de chaque quartier.
    for (final b in blockPlans) {
      canvas.drawPath(diamond(b.i0 - .06, b.j0 - .06, b.i0 + blockSize + .06, b.j0 + blockSize + .06), curb);
    }
    // Terrains à vendre : terre battue.
    final dirt = Paint()..color = p.dirt;
    final edge = Paint()
      ..color = p.dirtEdge
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final (i, j) in salePlots) {
      final d = diamond(i + .15, j + .15, i + 1.85, j + 1.85);
      canvas.drawPath(d, dirt);
      canvas.drawPath(d, edge);
    }
  }

  @override
  bool shouldRepaint(GroundPainter old) => old.dark != dark || old.salePlots.length != salePlots.length;
}

/// Arbre rond ou palmier, avec ombre au sol.
class TreePainter extends CustomPainter {
  TreePainter({required this.seed, required this.dark, this.palm = false});
  final int seed;
  final bool dark, palm;

  @override
  void paint(Canvas canvas, Size s) {
    final r = math.Random(seed);
    final base = Offset(s.width / 2, s.height - 6);
    canvas.drawOval(Rect.fromCenter(center: base, width: s.width * .8, height: 10), Paint()..color = const Color(0x33000000));
    final trunk = Paint()..color = dark ? const Color(0xFF6B4A33) : const Color(0xFF9A6B45);
    final greens = dark
        ? [const Color(0xFF2F5A2C), const Color(0xFF3C7036), const Color(0xFF4F8744)]
        : [const Color(0xFF4FA048), const Color(0xFF66BC56), const Color(0xFF8BD66E)];
    if (palm) {
      final top = Offset(s.width / 2 + 6, s.height * .2);
      final path = Path()
        ..moveTo(base.dx - 3, base.dy)
        ..quadraticBezierTo(base.dx - 2, s.height * .5, top.dx - 2, top.dy)
        ..lineTo(top.dx + 2, top.dy)
        ..quadraticBezierTo(base.dx + 3, s.height * .5, base.dx + 3, base.dy)
        ..close();
      canvas.drawPath(path, trunk);
      final leaf = Paint()..color = greens[1];
      for (var k = 0; k < 6; k++) {
        final a = -math.pi / 2 + (k - 2.5) * .55;
        final end = top + Offset(math.cos(a) * s.width * .48, math.sin(a) * s.width * .3 + 10);
        final ctrl = top + Offset(math.cos(a) * s.width * .3, math.sin(a) * s.width * .3 - 8);
        canvas.drawPath(
          Path()
            ..moveTo(top.dx, top.dy)
            ..quadraticBezierTo(ctrl.dx, ctrl.dy, end.dx, end.dy)
            ..quadraticBezierTo(ctrl.dx + 4, ctrl.dy + 8, top.dx, top.dy + 3),
          k.isEven ? leaf : (Paint()..color = greens[2]),
        );
      }
      return;
    }
    final h = s.height * (.55 + r.nextDouble() * .1);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: base.translate(0, -h * .25), width: 7, height: h * .5), const Radius.circular(3)),
      trunk,
    );
    final c = base.translate(0, -h * .75);
    final rad = s.width * .38;
    canvas.drawCircle(c.translate(0, 4), rad, Paint()..color = greens[0]);
    canvas.drawCircle(c, rad * .9, Paint()..color = greens[1]);
    canvas.drawCircle(c.translate(-rad * .3, -rad * .35), rad * .42, Paint()..color = greens[2]);
  }

  @override
  bool shouldRepaint(TreePainter old) => old.dark != dark;
}

/// Fontaine de la Place de la Bourse.
class FountainPainter extends CustomPainter {
  FountainPainter({required this.dark});
  final bool dark;

  @override
  void paint(Canvas canvas, Size s) {
    final c = Offset(s.width / 2, s.height * .72);
    final stone = Paint()..color = dark ? const Color(0xFFA9A193) : const Color(0xFFF4EFE4);
    final stoneDark = Paint()..color = dark ? const Color(0xFF7E776B) : const Color(0xFFD5CCBB);
    final water = Paint()..color = dark ? const Color(0xFF3E87A0) : const Color(0xFF7FD0EA);
    final w = s.width * .9;
    canvas.drawOval(Rect.fromCenter(center: c.translate(0, 8), width: w, height: w * .5), stoneDark);
    canvas.drawOval(Rect.fromCenter(center: c, width: w, height: w * .5), stone);
    canvas.drawOval(Rect.fromCenter(center: c, width: w * .82, height: w * .38), water);
    canvas.drawRect(Rect.fromCenter(center: c.translate(0, -18), width: 12, height: 36), stone);
    canvas.drawOval(Rect.fromCenter(center: c.translate(0, -36), width: w * .4, height: w * .16), stoneDark);
    canvas.drawOval(Rect.fromCenter(center: c.translate(0, -38), width: w * .36, height: w * .13), water);
    final spray = Paint()
      ..color = (dark ? const Color(0xFF9FD8EA) : Colors.white).withValues(alpha: .9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (final dx in [-14.0, 0.0, 14.0]) {
      canvas.drawPath(
        Path()
          ..moveTo(c.dx, c.dy - 42)
          ..quadraticBezierTo(c.dx + dx * .6, c.dy - 62, c.dx + dx, c.dy - 44),
        spray,
      );
    }
  }

  @override
  bool shouldRepaint(FountainPainter old) => old.dark != dark;
}
