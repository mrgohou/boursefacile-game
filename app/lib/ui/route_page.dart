// La route des 15 villes : un chemin sinueux de bas en haut, 3 niveaux et un quiz par ville.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../engine/board.dart' show LevelDef;
import '../services/audio.dart';
import '../services/game_state.dart';
import 'brand_theme.dart';
import 'city_page.dart';
import 'home/painters.dart' show TreePainter;
import 'level_page.dart';
import 'motion.dart';
import 'paco.dart';
import 'scope.dart';
import 'stars.dart';

const _gap = 104.0, _bottom = 120.0, _top = 160.0;

sealed class _Node {
  const _Node(this.city);
  final int city;
}

class _LevelNode extends _Node {
  const _LevelNode(super.city, this.level);
  final LevelDef level;
}

class _QuizNode extends _Node {
  const _QuizNode(super.city);
}

class RoutePage extends StatefulWidget {
  const RoutePage({super.key});

  @override
  State<RoutePage> createState() => _RoutePageState();
}

class _RoutePageState extends State<RoutePage> {
  ScrollController? _scroll;

  @override
  void dispose() {
    _scroll?.dispose();
    super.dispose();
  }

  List<_Node> _nodes(GameState g) => [
        for (final c in g.content.cities) ...[
          for (final l in g.content.levelsOf(c.n)) _LevelNode(c.n, l),
          _QuizNode(c.n),
        ],
      ];

  int _current(GameState g, List<_Node> nodes) {
    for (var k = 0; k < nodes.length; k++) {
      final n = nodes[k];
      switch (n) {
        case _LevelNode(:final level):
          if (g.levelUnlocked(level) && (g.stars[level.id] ?? 0) == 0) return k;
        case _QuizNode(:final city):
          if (g.cityStars(city) >= 5 && !g.cityValidated(city)) return k;
      }
    }
    return 0;
  }

  Offset _pos(int k, double w) => Offset(w / 2 + w * .26 * math.sin(k * .9), _bottom + k * _gap);

  Future<void> _tapLevel(GameState g, LevelDef l) async {
    if (!g.levelUnlocked(l)) {
      GameAudio.instance.play('invalid', volume: .5);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Gagne le niveau précédent pour ouvrir celui-ci.')));
      return;
    }
    GameAudio.instance.play('select');
    HapticFeedback.selectionClick();
    if (!g.seenIntro.contains(l.city)) {
      final ok = await _cityIntro(g, l.city);
      if (ok != true || !mounted) return;
    }
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => LevelPage(level: l)));
  }

  Future<bool?> _cityIntro(GameState g, int city) {
    final c = g.content.cities[city - 1];
    return showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${c.n}. ${c.name}', style: Theme.of(context).textTheme.headlineSmall),
              Text('${c.country} · ${c.notion}', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 12),
              PacoBubble(
                pose: Pose.expliquer,
                text: c.pacoIntro,
                action: 'Compris, on joue !',
                onAction: () {
                  g.markIntroSeen(city);
                  Navigator.pop(context, true);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _tapQuiz(GameState g, int city) async {
    if (g.cityStars(city) < 5) {
      GameAudio.instance.play('invalid', volume: .5);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Gagne 5 étoiles sur 9 dans cette ville pour ouvrir le quiz de Paco.')));
      return;
    }
    GameAudio.instance.play('select');
    await openCityQuiz(context, city);
  }

  @override
  Widget build(BuildContext context) {
    final g = GameScope.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final nodes = _nodes(g);
    final cur = _current(g, nodes);
    final height = _bottom + (nodes.length - 1) * _gap + _top;
    return Scaffold(
      appBar: AppBar(
        title: const Text('La route des villes'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(child: Text('${g.citiesDone}/15', style: const TextStyle(fontWeight: FontWeight.w800))),
          ),
        ],
      ),
      body: LayoutBuilder(builder: (context, box) {
        final w = box.maxWidth;
        _scroll ??= ScrollController(initialScrollOffset: math.max(0, _bottom + cur * _gap - box.maxHeight * .4));
        final pts = [for (var k = 0; k < nodes.length; k++) _pos(k, w)];
        return SingleChildScrollView(
          controller: _scroll,
          reverse: true,
          child: SizedBox(
            width: w,
            height: height,
            child: Stack(
              children: [
                Positioned.fill(child: CustomPaint(painter: _RoutePainter(points: pts, done: cur, height: height, dark: dark, cities: g.content.cities.length))),
                // Décor : arbres sur les bords.
                for (var k = 0; k < nodes.length; k += 2)
                  Positioned(
                    left: (pts[k].dx > w / 2 ? 8.0 : w - 58) + (k % 3) * 6,
                    top: height - pts[k].dy - 40,
                    width: 50,
                    height: 72,
                    child: IgnorePointer(child: CustomPaint(painter: TreePainter(seed: k, dark: dark, palm: k % 4 == 0))),
                  ),
                for (var k = 0; k < nodes.length; k++) ...[
                  if (nodes[k] case _LevelNode(:final level) when level.index == 1)
                    Positioned(
                      left: pts[k].dx > w / 2 ? 12.0 : null,
                      right: pts[k].dx > w / 2 ? null : 12.0,
                      top: height - pts[k].dy - 34,
                      child: _CityBanner(
                        city: nodes[k].city,
                        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => CityPage(city: nodes[k].city))),
                      ),
                    ),
                  Positioned(
                    left: pts[k].dx - 36,
                    top: height - pts[k].dy - 36,
                    width: 72,
                    height: 96,
                    child: switch (nodes[k]) {
                      _LevelNode(:final level) => _LevelButton(level: level, current: k == cur, onTap: () => _tapLevel(g, level)),
                      _QuizNode(:final city) => _QuizButton(city: city, current: k == cur, onTap: () => _tapQuiz(g, city)),
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _RoutePainter extends CustomPainter {
  _RoutePainter({required this.points, required this.done, required this.height, required this.dark, required this.cities});
  final List<Offset> points;
  final int done, cities;
  final double height;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    // Bandes de couleur : une par ville.
    final bands = dark
        ? [const Color(0xFF16302A), const Color(0xFF1B3832)]
        : [const Color(0xFFEAF6D9), const Color(0xFFDDF0C8)];
    final per = points.length ~/ cities;
    for (var c = 0; c < cities; c++) {
      final y0 = c == 0 ? height : height - points[c * per].dy + _gap / 2;
      final y1 = c == cities - 1 ? 0.0 : height - points[(c + 1) * per].dy + _gap / 2;
      canvas.drawRect(Rect.fromLTRB(0, y1, size.width, y0), Paint()..color = bands[c % 2]);
    }
    Path through(List<Offset> pts) {
      final path = Path()..moveTo(pts.first.dx, height - pts.first.dy);
      for (var k = 1; k < pts.length; k++) {
        final a = Offset(pts[k - 1].dx, height - pts[k - 1].dy), b = Offset(pts[k].dx, height - pts[k].dy);
        path.cubicTo(a.dx, (a.dy + b.dy) / 2, b.dx, (a.dy + b.dy) / 2, b.dx, b.dy);
      }
      return path;
    }

    final all = through(points);
    canvas.drawPath(all, Paint()
      ..color = dark ? const Color(0xFF3B4A44) : const Color(0xFFD9C9A3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 26
      ..strokeCap = StrokeCap.round);
    if (done > 0) {
      canvas.drawPath(through(points.sublist(0, done + 1)), Paint()
        ..color = Brand.lime
        ..style = PaintingStyle.stroke
        ..strokeWidth = 18
        ..strokeCap = StrokeCap.round);
    }
    // Pointillés au milieu du chemin.
    final dash = Paint()
      ..color = Colors.white.withValues(alpha: .7)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (final m in all.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 22) {
        final a = m.getTangentForOffset(d)?.position, b = m.getTangentForOffset(d + 8)?.position;
        if (a != null && b != null) canvas.drawLine(a, b, dash);
      }
    }
  }

  @override
  bool shouldRepaint(_RoutePainter old) => old.done != done || old.dark != dark || old.points.length != points.length;
}

class _CityBanner extends StatelessWidget {
  const _CityBanner({required this.city, required this.onTap});
  final int city;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final g = GameScope.of(context);
    final c = g.content.cities[city - 1];
    final open = g.cityUnlocked(city);
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: 'Ville ${c.n}, ${c.name}, ${c.notion}${open ? '' : ', verrouillée'}',
      child: ExcludeSemantics(
        child: Material(
          color: open ? scheme.primary : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          elevation: 2,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: open ? onTap : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 130),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (g.cityValidated(city)) ...[Icon(Icons.verified, size: 16, color: scheme.onPrimary), const SizedBox(width: 4)],
                        if (!open) ...[Icon(Icons.lock_outline, size: 16, color: scheme.onSurfaceVariant), const SizedBox(width: 4)],
                        Flexible(
                          child: Text(c.name,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontWeight: FontWeight.w800, color: open ? scheme.onPrimary : scheme.onSurfaceVariant)),
                        ),
                      ],
                    ),
                    Text(c.notion,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: (open ? scheme.onPrimary : scheme.onSurfaceVariant).withValues(alpha: .85))),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pastille de niveau ; la pastille en cours respire et porte Paco.
class _LevelButton extends StatefulWidget {
  const _LevelButton({required this.level, required this.current, required this.onTap});
  final LevelDef level;
  final bool current;
  final VoidCallback onTap;

  @override
  State<_LevelButton> createState() => _LevelButtonState();
}

class _LevelButtonState extends State<_LevelButton> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final g = GameScope.of(context);
    final open = g.levelUnlocked(widget.level);
    final st = g.stars[widget.level.id] ?? 0;
    final scheme = Theme.of(context).colorScheme;
    final number = (widget.level.city - 1) * 3 + widget.level.index;
    if (widget.current && ambientMotion(context)) {
      if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
    } else {
      _pulse.stop();
    }
    final dark = Theme.of(context).brightness == Brightness.dark;
    final doneColor = dark ? const Color(0xFF2F6B4F) : Brand.ink;
    final bg = !open ? scheme.surfaceContainerHighest : (st > 0 ? doneColor : Brand.lime);
    final fg = !open ? scheme.onSurfaceVariant : (st > 0 ? Colors.white : Brand.ink);
    return Semantics(
      button: true,
      label: open ? 'Niveau $number, $st étoiles sur 3' : 'Niveau $number verrouillé',
      child: ExcludeSemantics(
        child: Column(
          children: [
            ScaleTransition(
              scale: Tween(begin: 1.0, end: 1.12).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut)),
              child: Material(
                color: bg,
                shape: CircleBorder(side: BorderSide(color: widget.current ? Colors.white : Colors.transparent, width: 4)),
                elevation: open ? 4 : 0,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: widget.onTap,
                  child: SizedBox.square(
                    dimension: 64,
                    child: Center(
                      child: open
                          ? Text('$number', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: fg))
                          : Icon(Icons.lock_outline, color: fg),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 2),
            if (open) Stars(st, size: 18),
          ],
        ),
      ),
    );
  }
}

class _QuizButton extends StatelessWidget {
  const _QuizButton({required this.city, required this.current, required this.onTap});
  final int city;
  final bool current;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final g = GameScope.of(context);
    final ready = g.cityStars(city) >= 5;
    final done = g.cityValidated(city);
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: done ? 'Quiz de Paco réussi' : (ready ? 'Quiz de Paco disponible' : 'Quiz de Paco verrouillé'),
      child: ExcludeSemantics(
        child: Column(
          children: [
            Material(
              color: done ? (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2F6B4F) : Brand.ink) : (ready ? const Color(0xFFFFC94D) : scheme.surfaceContainerHighest),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: current ? Colors.white : Colors.transparent, width: 4),
              ),
              elevation: ready ? 4 : 0,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: onTap,
                child: SizedBox.square(
                  dimension: 64,
                  child: done
                      ? const Icon(Icons.verified, color: Colors.white, size: 30)
                      : Image.asset('assets/paco/apprendre.webp', fit: BoxFit.contain, opacity: AlwaysStoppedAnimation<double>(ready ? 1.0 : .35)),
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text('Quiz', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: scheme.onSurface)),
          ],
        ),
      ),
    );
  }
}
