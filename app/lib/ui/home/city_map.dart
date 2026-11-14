// Ma Ville en vue isométrique : un bâtiment par entreprise détenue, terrains à vendre,
// forêts sur les quartiers pas encore débloqués, passants qui se promènent.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../engine/city.dart';
import '../../services/game_state.dart';
import '../format.dart';
import '../motion.dart';
import '../scope.dart';
import 'city_layout.dart';
import 'painters.dart';

class CityMap extends StatefulWidget {
  const CityMap({super.key, required this.controller, required this.onPlot, required this.onPlaza});
  final TransformationController controller;
  final void Function(Plot plot) onPlot;
  final VoidCallback onPlaza;

  /// Cadrage : le point [p] de la carte au centre de l'écran, au zoom [scale].
  static Matrix4 focus(Size viewport, Offset p, double scale) =>
      Matrix4.diagonal3Values(scale, scale, 1)..setTranslationRaw(viewport.width / 2 - p.dx * scale, viewport.height / 2 - p.dy * scale, 0);

  @override
  State<CityMap> createState() => _CityMapState();
}

class _CityMapState extends State<CityMap> {
  List<Company>? _companies;
  List<Plot> _plots = const [];
  bool _framed = false;

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (!identical(_companies, game.companies)) {
      _companies = game.companies;
      _plots = planPlots(game.companies);
    }
    final unlocked = {for (final c in game.unlockedCompanies) c.symbol};
    final city = game.city;

    final objects = <(double, Widget)>[];
    final sale = <(int, int)>[];
    for (final b in blockPlans) {
      final plots = _plots.where((p) => p.i >= b.i0 && p.i < b.i0 + blockSize && p.j >= b.j0 && p.j < b.j0 + blockSize);
      final locked = b.kind == BlockKind.district && plots.every((p) => p.company == null || !unlocked.contains(p.company!.symbol));
      if (locked) {
        final country = plots.map((p) => p.company?.country).whereType<String>().firstOrNull;
        objects.add((b.i0 + b.j0 + blockSize + .5, _LockSign(center: b.center, country: country)));
      }
      switch (b.kind) {
        case BlockKind.plaza:
          objects.addAll(_plaza(b, dark));
        case BlockKind.park:
          objects.addAll(_park(b, dark));
        case BlockKind.district:
          break;
      }
    }
    for (final p in _plots) {
      final c = p.company;
      final h = c == null ? null : city.holdings[c.symbol];
      if (c != null && h != null) {
        final lvl = buildingLevel(city, c.symbol);
        final up = (city.prices[c.symbol] ?? 0) >= c.price;
        objects.add((p.depth + 2.0, _Building(plot: p, company: c, holding: h, level: lvl, up: up, onTap: () => widget.onPlot(p))));
      } else if (c != null && unlocked.contains(c.symbol)) {
        sale.add((p.i, p.j));
        objects.add((p.depth + 2.0, _SaleSign(plot: p, company: c, onTap: () => widget.onPlot(p))));
      } else {
        // Forêt (quartier verrouillé) ou jardin (terrain sans entreprise).
        final n = c == null ? 2 : 4;
        for (var k = 0; k < n; k++) {
          final r = math.Random(p.i * 31 + p.j * 7 + k);
          final fi = p.i + .35 + r.nextDouble() * 1.3, fj = p.j + .35 + r.nextDouble() * 1.3;
          objects.add((fi + fj, _Tree(at: iso(fi, fj), seed: p.i * 13 + k, dark: dark)));
        }
      }
    }
    // Couronne d'arbres et de palmiers au bord de la lagune.
    const n = gridN * 1.0;
    for (var t = -1.0; t <= n + 1; t += 1.7) {
      for (final (fi, fj, palm) in [(t, -1.3, false), (-1.3, t, false), (t, n + 1.3, true), (n + 1.3, t, true)]) {
        objects.add((fi + fj, _Tree(at: iso(fi, fj), seed: (t * 10).round() + (palm ? 99 : 0), dark: dark, palm: palm)));
      }
    }
    objects.sort((a, b) => a.$1.compareTo(b.$1));

    return LayoutBuilder(builder: (context, box) {
      if (!_framed) {
        _framed = true;
        widget.controller.value = CityMap.focus(box.biggest, plaza.center.translate(0, 40), .5);
      }
      return InteractiveViewer(
        transformationController: widget.controller,
        constrained: false,
        minScale: .32,
        maxScale: 1.8,
        boundaryMargin: const EdgeInsets.all(120),
        child: SizedBox(
          width: mapWidth,
          height: mapHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(child: CustomPaint(painter: GroundPainter(dark: dark, salePlots: sale))),
              for (final o in objects) o.$2,
              if (ambientMotion(context)) Positioned.fill(child: IgnorePointer(child: _Walkers(owned: city.holdings.length, upShare: _upShare(game)))),
            ],
          ),
        ),
      );
    });
  }

  double _upShare(GameState game) {
    final city = game.city;
    if (city.holdings.isEmpty) return .5;
    var up = 0;
    for (final c in game.companies) {
      if (city.holdings.containsKey(c.symbol) && (city.prices[c.symbol] ?? 0) >= c.price) up++;
    }
    return up / city.holdings.length;
  }

  List<(double, Widget)> _plaza(BlockPlan b, bool dark) {
    final c = b.center;
    final out = <(double, Widget)>[
      (b.i0 + b.j0 + 4.0, Positioned(
        left: c.dx - 70,
        top: c.dy - 96,
        width: 140,
        height: 130,
        child: GestureDetector(onTap: widget.onPlaza, child: CustomPaint(painter: FountainPainter(dark: dark))),
      )),
      (b.i0 + b.j0 + 6.5, Positioned(
        left: iso(b.i0 + 3.2, b.j0 + 3.2).dx - 40,
        top: iso(b.i0 + 3.2, b.j0 + 3.2).dy - 92,
        width: 80,
        height: 100,
        child: GestureDetector(
          onTap: widget.onPlaza,
          child: Image.asset('assets/paco/accueil.webp', fit: BoxFit.contain, alignment: Alignment.bottomCenter),
        ),
      )),
      (b.i0 + b.j0 + 9.0, Positioned(
        left: c.dx - 110,
        top: c.dy - 150,
        width: 220,
        child: Center(
          child: Semantics(
            button: true,
            label: 'Place de la Bourse : ouvrir le guichet SGI',
            child: ExcludeSemantics(child: _Pill(icon: Icons.account_balance, text: 'Place de la Bourse', onTap: widget.onPlaza, strong: true)),
          ),
        ),
      )),
    ];
    for (final (fi, fj) in [(.3, .3), (.3, 3.7), (3.7, .3), (3.7, 3.7)]) {
      out.add((b.i0 + b.j0 + fi + fj, _Tree(at: iso(b.i0 + fi, b.j0 + fj), seed: (fi * 7 + fj).round(), dark: dark, palm: true)));
    }
    return out;
  }

  List<(double, Widget)> _park(BlockPlan b, bool dark) {
    final out = <(double, Widget)>[];
    final r = math.Random(b.bi * 5 + b.bj);
    for (var k = 0; k < 11; k++) {
      final fi = b.i0 + .3 + r.nextDouble() * (blockSize - .6), fj = b.j0 + .3 + r.nextDouble() * (blockSize - .6);
      out.add((fi + fj, _Tree(at: iso(fi, fj), seed: k + b.bi * 17, dark: dark, palm: k % 4 == 0)));
    }
    return out;
  }
}

class _Tree extends StatelessWidget {
  const _Tree({required this.at, required this.seed, required this.dark, this.palm = false});
  final Offset at;
  final int seed;
  final bool dark, palm;

  @override
  Widget build(BuildContext context) {
    final w = palm ? 54.0 : 46.0, h = palm ? 82.0 : 66.0;
    return Positioned(
      left: at.dx - w / 2,
      top: at.dy - h + 6,
      width: w,
      height: h,
      child: IgnorePointer(child: CustomPaint(painter: TreePainter(seed: seed, dark: dark, palm: palm))),
    );
  }
}

class _Building extends StatelessWidget {
  const _Building({required this.plot, required this.company, required this.holding, required this.level, required this.up, required this.onTap});
  final Plot plot;
  final Company company;
  final Holding holding;
  final int level;
  final bool up;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = plot.center;
    final w = 150.0 + level * 8, h = 170.0 + level * 10;
    return Positioned(
      left: c.dx - w / 2,
      top: c.dy + tileH * .62 - h,
      width: w,
      height: h + 18,
      child: Semantics(
        button: true,
        label: '${company.name}, ${holding.qty} ${plural(holding.qty, 'part')}, bâtiment niveau $level, '
            '${up ? 'plus d’acheteurs' : 'plus de vendeurs'}',
        child: ExcludeSemantics(
          child: GestureDetector(
            onTap: onTap,
            child: Stack(
              children: [
                Positioned.fill(
                  bottom: 18,
                  child: Image.asset('assets/buildings/${company.family.name}-$level.webp', fit: BoxFit.contain, alignment: Alignment.bottomCenter),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Center(child: _Pill(text: company.symbol, icon: up ? Icons.trending_up : Icons.trending_down, iconColor: up ? const Color(0xFF2E9E4F) : const Color(0xFFD9534F))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Panneau en bois planté sur un terrain à vendre.
class _SaleSign extends StatelessWidget {
  const _SaleSign({required this.plot, required this.company, required this.onTap});
  final Plot plot;
  final Company company;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = plot.center;
    return Positioned(
      left: c.dx - 40,
      top: c.dy - 66,
      width: 80,
      height: 74,
      child: Semantics(
        button: true,
        label: 'Terrain à vendre : ${company.name}',
        child: ExcludeSemantics(
          child: GestureDetector(
            onTap: onTap,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6E3B4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFB07A45), width: 2.5),
                    boxShadow: const [BoxShadow(color: Color(0x33000000), offset: Offset(0, 3), blurRadius: 3)],
                  ),
                  child: Column(
                    children: [
                      Text(company.symbol, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF5A3A1E))),
                      const Text('à vendre', style: TextStyle(fontSize: 10, color: Color(0xFF7A5230))),
                    ],
                  ),
                ),
                Container(width: 6, height: 22, color: const Color(0xFF9A6B45)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LockSign extends StatelessWidget {
  const _LockSign({required this.center, this.country});
  final Offset center;
  final String? country;

  @override
  Widget build(BuildContext context) => Positioned(
        left: center.dx - 90,
        top: center.dy - 120,
        width: 180,
        child: Center(child: _Pill(icon: Icons.lock_outline, text: country == null ? 'Bientôt' : 'Quartier $country')),
      );
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, this.icon, this.iconColor, this.onTap, this.strong = false});
  final String text;
  final IconData? icon;
  final Color? iconColor;
  final VoidCallback? onTap;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = strong ? scheme.primary : scheme.surface.withValues(alpha: .92);
    final fg = strong ? scheme.onPrimary : scheme.onSurface;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: strong ? 14 : 8, vertical: strong ? 8 : 3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 4, offset: Offset(0, 2))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: strong ? 18 : 14, color: iconColor ?? fg), const SizedBox(width: 4)],
            Text(text, style: TextStyle(fontWeight: FontWeight.w800, fontSize: strong ? 14 : 11, color: fg)),
          ],
        ),
      ),
    );
  }
}

// ---------- Passants ----------
class _Walker {
  _Walker(this.a, this.b, this.green, this.t);
  (int, int) a, b; // carrefours de départ et d'arrivée
  final bool green;
  double t;
}

class _Walkers extends StatefulWidget {
  const _Walkers({required this.owned, required this.upShare});
  final int owned;
  final double upShare;

  @override
  State<_Walkers> createState() => _WalkersState();
}

class _WalkersState extends State<_Walkers> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _rnd = math.Random(5);
  final _walkers = <_Walker>[];
  Duration _last = Duration.zero;

  @override
  void initState() {
    super.initState();
    _populate();
    _ticker = createTicker(_tick)..start();
  }

  void _populate() {
    final n = (widget.owned + 4).clamp(4, 12);
    _walkers.clear();
    for (var k = 0; k < n; k++) {
      final a = (_rnd.nextInt(blocks + 1), _rnd.nextInt(blocks + 1));
      _walkers.add(_Walker(a, _next(a, null), k < n * widget.upShare, _rnd.nextDouble()));
    }
  }

  @override
  void didUpdateWidget(_Walkers old) {
    super.didUpdateWidget(old);
    if (old.owned != widget.owned) _populate();
  }

  (int, int) _next((int, int) at, (int, int)? from) {
    final opts = [
      (at.$1 + 1, at.$2), (at.$1 - 1, at.$2), (at.$1, at.$2 + 1), (at.$1, at.$2 - 1), //
    ].where((p) => p.$1 >= 0 && p.$1 <= blocks && p.$2 >= 0 && p.$2 <= blocks && p != from).toList();
    return opts[_rnd.nextInt(opts.length)];
  }

  void _tick(Duration now) {
    final dt = ((now - _last).inMicroseconds / 1e6).clamp(0.0, .1);
    _last = now;
    for (final w in _walkers) {
      w.t += dt * .11;
      if (w.t >= 1) {
        final prev = w.a;
        w.a = w.b;
        w.b = _next(w.a, prev);
        w.t = 0;
      }
    }
    setState(() {});
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const step = blockSize + 1.0;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        for (final w in _walkers)
          () {
            final di = (w.b.$1 - w.a.$1).toDouble(), dj = (w.b.$2 - w.a.$2).toDouble();
            // Sur le trottoir de droite : léger décalage perpendiculaire au sens de marche.
            final fi = (w.a.$1 + di * w.t) * step + .5 + dj * .28;
            final fj = (w.a.$2 + dj * w.t) * step + .5 - di * .28;
            final o = iso(fi, fj);
            final goingLeft = (di - dj) < 0;
            return Positioned(
              left: o.dx - 11,
              top: o.dy - 30,
              width: 22,
              height: 32,
              child: Transform.flip(
                flipX: goingLeft,
                child: Image.asset('assets/buildings/passant-${w.green ? 'vert' : 'rouge'}.webp', fit: BoxFit.contain),
              ),
            );
          }(),
      ],
    );
  }
}
