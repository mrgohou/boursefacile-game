// Plateau du puzzle rendu avec Flame. La logique vient de engine/board.dart ;
// les gestes sont lus par Flutter (GestureDetector) puis transmis ici.
// Sensations de jeu : glisser au doigt, rebonds, éclats, cascades, indice si l'on hésite.
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' hide TextStyle;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:flame/particles.dart';
import 'package:flutter/animation.dart' show Curve, Curves;
import 'package:flutter/painting.dart' show TextStyle;

import '../engine/board.dart' as eng;
import '../services/audio.dart';

typedef StepsCallback = void Function(List<eng.Step> steps);

/// Couleur des éclats de chaque tuile.
const tileColors = {
  'cacao': Color(0xFF9A5B2E),
  'telephone': Color(0xFF3D8BFD),
  'billet': Color(0xFF3FAE5A),
  'bidon': Color(0xFFF28C28),
  'ampoule': Color(0xFFFFC928),
  'engrenage': Color(0xFF8C96A0),
};

/// Mots d'encouragement : cascades et pièces spéciales.
String? cascadeWord(int cascade) => switch (cascade) {
      < 2 => null,
      2 => 'Bien !',
      3 => 'Super !',
      4 => 'Génial !',
      _ => 'Incroyable !',
    };

const specialWords = {
  eng.Special.dividende: 'Dividende !',
  eng.Special.ago: 'AGO !',
  eng.Special.diversif: 'Diversifié !',
};

class PuzzleGame extends FlameGame {
  PuzzleGame({
    required this.level,
    required this.onSteps,
    required this.onSettled,
    required this.onRefused,
    required this.onWord,
    required this.dark,
  });

  final eng.LevelDef level;
  final StepsCallback onSteps;
  final VoidCallback onSettled;
  final VoidCallback onRefused;
  final void Function(String word) onWord;
  final bool dark;

  late final eng.Board board = eng.Board.forLevel(level);
  final Map<int, _TileSprite> _sprites = {};
  final _rnd = math.Random();
  double cell = 48;
  Vector2 origin = Vector2.zero();
  late final ClipComponent _root;
  late final RectangleComponent _highlight;

  bool busy = true; // le plateau tombe en place au chargement
  bool active = false; // vrai pendant la partie (indice possible)
  double _idle = 0;
  eng.Pos? selected;
  eng.Pos? _pressed;

  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {
    images.prefix = 'assets/';
    await images.loadAll([
      for (final t in eng.tileTypes) 'tiles/$t.webp',
      'tiles/dividende.webp',
      'tiles/ago.webp',
      'tiles/diversif.webp',
      'tiles/cadenas.webp',
    ]);
    _layout();
    add(_BoardBackground(this));
    _root = ClipComponent.rectangle(position: origin.clone(), size: Vector2.all(cell * eng.boardSize));
    add(_root);
    _highlight = RectangleComponent(
      size: Vector2.all(cell - 2),
      anchor: Anchor.center,
      paint: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = dark ? const Color(0xFFD1F88C) : const Color(0xFF103C30),
      priority: 10,
    )..opacity = 0;
    _root.add(_highlight);
    // Entrée : les tuiles tombent du haut, rangée par rangée.
    final falls = <Future<void>>[];
    for (var r = 0; r < eng.boardSize; r++) {
      for (var c = 0; c < eng.boardSize; c++) {
        final t = board.grid[r][c];
        if (t == null) continue;
        final s = _spawn(t, eng.Pos(r, c), fromY: local(eng.Pos(r, c)).y - cell * (eng.boardSize + 1));
        falls.add(_fall(s, local(eng.Pos(r, c)), delay: (eng.boardSize - 1 - r) * .05 + c * .02));
      }
    }
    unawaited(Future.wait(falls).then((_) => busy = false));
  }

  void _layout() {
    final s = size.x < size.y ? size.x : size.y;
    cell = ((s - 16) / eng.boardSize).floorToDouble();
    origin = Vector2((size.x - cell * eng.boardSize) / 2, (size.y - cell * eng.boardSize) / 2);
  }

  /// Centre d'une case, dans le repère du plateau.
  Vector2 local(eng.Pos p) => Vector2(p.c * cell + cell / 2, p.r * cell + cell / 2);

  /// Centre d'une case, dans le repère de l'écran du jeu.
  Vector2 global(eng.Pos p) => origin + local(p);

  /// Case touchée à partir d'une position locale du widget.
  eng.Pos? cellAt(Offset at) {
    final c = ((at.dx - origin.x) / cell).floor();
    final r = ((at.dy - origin.y) / cell).floor();
    final p = eng.Pos(r, c);
    return p.inside ? p : null;
  }

  _TileSprite _spawn(eng.Tile t, eng.Pos p, {double? fromY}) {
    final sprite = _TileSprite(this, t, cell - 6)..position = local(p);
    if (fromY != null) sprite.position.y = fromY;
    _sprites[t.id] = sprite;
    _root.add(sprite);
    return sprite;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!active || busy) return;
    _idle += dt;
    if (_idle > 6) {
      _idle = 3; // l'indice revient toutes les 3 secondes
      final m = board.findMove();
      if (m != null) {
        for (final p in [m.$1, m.$2]) {
          _sprites[board.at(p)?.id]?.add(RotateEffect.by(.16, EffectController(duration: .08, reverseDuration: .08, repeatCount: 3)));
        }
      }
    }
  }

  // ---------- Gestes ----------
  void tap(Offset at) {
    _idle = 0;
    if (busy) return;
    final p = cellAt(at);
    if (p == null) return;
    final sel = selected;
    if (sel != null && eng.Board.adjacent(sel, p)) {
      _select(null);
      swap(sel, p);
    } else if (sel == p) {
      _select(null);
    } else {
      GameAudio.instance.play('select', volume: .5);
      _select(p);
    }
  }

  /// Le doigt se pose : la tuile grossit un peu, prête à être glissée.
  void press(Offset at) {
    _idle = 0;
    if (busy) return;
    final p = cellAt(at);
    _pressed = p;
    if (p != null) _sprites[board.at(p)?.id]?.add(ScaleEffect.to(Vector2.all(1.12), EffectController(duration: .08)));
  }

  void release() {
    final p = _pressed;
    _pressed = null;
    if (p != null) _sprites[board.at(p)?.id]?.add(ScaleEffect.to(Vector2.all(1), EffectController(duration: .08)));
  }

  /// Glisser : l'échange part dès que le doigt a parcouru un tiers de case.
  bool drag(Offset start, Offset delta) {
    if (busy || delta.distance < cell * .33) return false;
    final p = cellAt(start);
    release();
    if (p == null) return true;
    final target = delta.dx.abs() > delta.dy.abs()
        ? eng.Pos(p.r, p.c + (delta.dx > 0 ? 1 : -1))
        : eng.Pos(p.r + (delta.dy > 0 ? 1 : -1), p.c);
    _select(null);
    swap(p, target);
    return true;
  }

  void _select(eng.Pos? p) {
    selected = p;
    if (p == null) {
      _highlight.opacity = 0;
    } else {
      _highlight
        ..position = local(p)
        ..opacity = 1;
    }
  }

  Future<void> _move(PositionComponent c, Vector2 to, double seconds, {Curve curve = Curves.easeInOut, double delay = 0}) {
    final done = Completer<void>();
    c.add(MoveEffect.to(to, EffectController(duration: seconds, curve: curve, startDelay: delay), onComplete: done.complete));
    return done.future;
  }

  /// Chute avec gravité, puis petit écrasement à l'atterrissage.
  Future<void> _fall(_TileSprite s, Vector2 to, {double delay = 0}) async {
    final cells = (to.y - s.position.y).abs() / cell;
    await _move(s, to, .14 + math.sqrt(cells) * .07, curve: Curves.easeIn, delay: delay);
    s.add(ScaleEffect.to(Vector2(1.12, .86), EffectController(duration: .05, reverseDuration: .09)));
  }

  Future<void> swap(eng.Pos a, eng.Pos b) async {
    _idle = 0;
    if (!b.inside || busy) return;
    final ta = board.at(a), tb = board.at(b);
    if (ta == null || tb == null) return;
    if (ta.lock != null || tb.lock != null) {
      GameAudio.instance.play('invalid', volume: .6);
      onRefused();
      return;
    }
    busy = true;
    final sa = _sprites[ta.id]!, sb = _sprites[tb.id]!;
    GameAudio.instance.play('swap', volume: .6);
    await Future.wait([_move(sa, local(b), .15), _move(sb, local(a), .15)]);
    final steps = board.play(a, b);
    if (steps == null) {
      GameAudio.instance.play('invalid', volume: .6);
      onRefused();
      await Future.wait([_move(sa, local(a), .17, curve: Curves.easeOutBack), _move(sb, local(b), .17, curve: Curves.easeOutBack)]);
      busy = false;
      return;
    }
    onSteps(steps);
    for (var i = 0; i < steps.length; i++) {
      await _animate(steps[i], i + 1);
    }
    busy = false;
    _idle = 0;
    onSettled();
  }

  Future<void> _animate(eng.Step step, int cascade) async {
    // Sons et mots.
    GameAudio.instance.combo(cascade);
    final specials = step.cleared.where((x) => x.tile.special != null).toList();
    if (specials.isNotEmpty) {
      GameAudio.instance.play('blast');
      onWord(specialWords[specials.first.tile.special]!);
      _shake(specials.length > 1 ? 9 : 6);
    } else if (cascadeWord(cascade) case final w?) {
      GameAudio.instance.play('cascade', volume: .6);
      onWord(w);
    }
    if (step.lockHits.isNotEmpty) GameAudio.instance.play('lock');
    for (final x in specials) {
      _specialBurst(x);
    }

    // Disparition : la tuile gonfle, éclate en confettis, puis s'efface.
    final fades = <Future<void>>[];
    var sum = Vector2.zero();
    for (final x in step.cleared) {
      sum += global(x.pos);
      final s = _sprites.remove(x.tile.id);
      if (s == null) continue;
      final done = Completer<void>();
      s.add(SequenceEffect([
        ScaleEffect.to(Vector2.all(1.25), EffectController(duration: .07)),
        ScaleEffect.to(Vector2.zero(), EffectController(duration: .13, curve: Curves.easeIn)),
      ], onComplete: () {
        s.removeFromParent();
        done.complete();
      }));
      _confetti(global(x.pos), tileColors[x.tile.name] ?? const Color(0xFFFFFFFF), 7);
      fades.add(done.future);
    }
    if (step.cleared.isNotEmpty) _scorePopup(sum / step.cleared.length.toDouble(), '+${step.points}');
    for (final h in step.lockHits) {
      _sprites[h.tile.id]?.refreshLock(opened: h.opened);
      _confetti(global(h.pos), const Color(0xFFB0B8C0), 5);
    }
    await Future.wait(fades);

    // Spéciales créées : apparition avec rebond et halo.
    if (step.created.isNotEmpty) GameAudio.instance.play('special', volume: .7);
    for (final x in step.created) {
      final s = _spawn(x.tile, x.pos)..scale = Vector2.all(.2);
      s.add(ScaleEffect.to(Vector2.all(1), EffectController(duration: .26, curve: Curves.easeOutBack)));
      _ring(global(x.pos), const Color(0xFFD1F88C));
    }

    // Chute et nouvelles tuiles (entrent par le haut du plateau, masquées par le cadre).
    final spawned = step.spawned.map((t) => t.id).toSet();
    final spawnRow = List<int>.filled(eng.boardSize, 0);
    final falls = <Future<void>>[];
    for (var r = eng.boardSize - 1; r >= 0; r--) {
      for (var c = 0; c < eng.boardSize; c++) {
        final t = step.grid[r][c];
        if (t == null) continue;
        final target = local(eng.Pos(r, c));
        var s = _sprites[t.id];
        if (s == null || spawned.contains(t.id)) {
          s?.removeFromParent();
          spawnRow[c]++;
          s = _spawn(t, eng.Pos(r, c), fromY: -spawnRow[c] * cell + cell / 2);
        }
        if (s.position != target) falls.add(_fall(s, target, delay: c * .012));
      }
    }
    await Future.wait(falls);
  }

  // ---------- Effets ----------
  void _shake(double amp) {
    _root.add(MoveEffect.by(Vector2(amp, 0), EffectController(duration: .04, reverseDuration: .04, repeatCount: 3)));
  }

  void _confetti(Vector2 at, Color color, int count) {
    add(ParticleSystemComponent(
      priority: 50,
      particle: Particle.generate(
        count: count,
        lifespan: .55,
        generator: (i) {
          final a = _rnd.nextDouble() * math.pi * 2;
          final v = 90 + _rnd.nextDouble() * 140;
          final r = 2.5 + _rnd.nextDouble() * 3;
          return AcceleratedParticle(
            position: at.clone(),
            speed: Vector2(math.cos(a) * v, math.sin(a) * v - 80),
            acceleration: Vector2(0, 520),
            child: ComputedParticle(
              renderer: (canvas, p) => canvas.drawCircle(
                Offset.zero,
                r * (1 - p.progress * .5),
                Paint()..color = color.withValues(alpha: 1 - p.progress),
              ),
            ),
          );
        },
      ),
    ));
  }

  void _ring(Vector2 at, Color color) {
    add(ParticleSystemComponent(
      priority: 40,
      particle: ComputedParticle(
        lifespan: .4,
        renderer: (canvas, p) => canvas.drawCircle(
          Offset(at.x, at.y),
          cell * (.3 + p.progress * .6),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 5 * (1 - p.progress)
            ..color = color.withValues(alpha: 1 - p.progress),
        ),
      ),
    ));
  }

  void _specialBurst(eng.Placed x) {
    final g = global(x.pos);
    final n = eng.boardSize * cell;
    const flash = Color(0xFFFFF4B0);
    final Rect Function(double t) area = switch (x.tile.special!) {
      eng.Special.dividende => (t) => Rect.fromCenter(center: Offset(origin.x + n / 2, g.y), width: n, height: cell * (1 - t * .6)),
      eng.Special.ago => (t) => Rect.fromCenter(center: Offset(g.x, g.y), width: cell * 3 * (.6 + t * .5), height: cell * 3 * (.6 + t * .5)),
      eng.Special.diversif => (t) => Rect.fromLTWH(origin.x, origin.y, n, n),
    };
    add(ParticleSystemComponent(
      priority: 45,
      particle: ComputedParticle(
        lifespan: .35,
        renderer: (canvas, p) => canvas.drawRRect(
          RRect.fromRectAndRadius(area(p.progress), Radius.circular(cell / 3)),
          Paint()..color = flash.withValues(alpha: (1 - p.progress) * .75),
        ),
      ),
    ));
    _confetti(g, flash, 14);
  }

  void _scorePopup(Vector2 at, String text) {
    final t = TextComponent(
      text: text,
      anchor: Anchor.center,
      position: at,
      priority: 60,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontFamily: 'Manrope',
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: Color(0xFFFFFFFF),
          shadows: [Shadow(color: Color(0xCC103C30), blurRadius: 4, offset: Offset(0, 2))],
        ),
      ),
    );
    t.addAll([
      MoveEffect.by(Vector2(0, -cell * 1.1), EffectController(duration: .7, curve: Curves.easeOut)),
      RemoveEffect(delay: .7),
    ]);
    add(t);
  }

  /// Fin de partie gagnée : chaque coup restant se transforme en épargne, tuile par tuile.
  Future<void> finale(int moves, void Function(int done) onTick) async {
    active = false;
    busy = true;
    final n = math.min(moves, 12);
    for (var k = 0; k < n; k++) {
      final list = _sprites.values.where((s) => s.tile.lock == null).toList();
      if (list.isEmpty) break;
      final s = list[_rnd.nextInt(list.length)];
      final at = origin + s.position;
      GameAudio.instance.play('coin', volume: .6);
      s.add(ScaleEffect.to(Vector2.all(1.3), EffectController(duration: .08, reverseDuration: .12)));
      _confetti(at, const Color(0xFFFFD23F), 10);
      _scorePopup(at, '+150');
      onTick(k + 1);
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }
  }
}

class _BoardBackground extends Component {
  _BoardBackground(this.game);
  final PuzzleGame game;

  @override
  void render(Canvas canvas) {
    final o = game.origin, n = eng.boardSize, s = game.cell;
    final rect = RRect.fromRectAndRadius(Rect.fromLTWH(o.x - 6, o.y - 6, s * n + 12, s * n + 12), const Radius.circular(22));
    canvas.drawRRect(rect.shift(const Offset(0, 4)), Paint()..color = const Color(0x33000000));
    canvas.drawRRect(rect, Paint()..color = game.dark ? const Color(0xFF1E3A31) : const Color(0xE6FFFFFF));
    final light = Paint()..color = game.dark ? const Color(0x22D1F88C) : const Color(0x40D1F88C);
    for (var r = 0; r < n; r++) {
      for (var c = 0; c < n; c++) {
        if ((r + c).isEven) {
          canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(o.x + c * s + 1, o.y + r * s + 1, s - 2, s - 2), const Radius.circular(8)), light);
        }
      }
    }
  }
}

/// Une tuile : image du secteur + calque spéciale + cadenas éventuel.
class _TileSprite extends PositionComponent {
  _TileSprite(this.game_, this.tile, double side) : super(size: Vector2.all(side), anchor: Anchor.center);

  final PuzzleGame game_;
  final eng.Tile tile;
  SpriteComponent? _lock;
  RectangleComponent? _veil;

  @override
  Future<void> onLoad() async {
    final img = game_.images;
    add(SpriteComponent(sprite: Sprite(img.fromCache('tiles/${tile.name}.webp')), size: size));
    final sp = tile.special;
    if (sp != null) {
      final overlay = SpriteComponent(sprite: Sprite(img.fromCache('tiles/${sp.name}.webp')), size: size, anchor: Anchor.center, position: size / 2);
      add(overlay);
      // Les pièces spéciales respirent doucement pour attirer l'œil.
      overlay.add(ScaleEffect.to(Vector2.all(1.06), EffectController(duration: .6, reverseDuration: .6, infinite: true)));
    }
    if (tile.lock != null) {
      _veil = RectangleComponent(size: size, paint: Paint()..color = const Color(0x73103C30));
      _lock = SpriteComponent(
        sprite: Sprite(img.fromCache('tiles/cadenas.webp')),
        size: Vector2(size.x * .62, size.y * .5),
        position: size / 2,
        anchor: Anchor.center,
      );
      addAll([_veil!, _lock!]);
    }
  }

  void refreshLock({required bool opened}) {
    if (!opened) {
      _lock?.add(ScaleEffect.by(Vector2.all(1.15), EffectController(duration: .09, reverseDuration: .09)));
      return;
    }
    _veil?.removeFromParent();
    final l = _lock;
    if (l != null) {
      l.add(ScaleEffect.to(Vector2.all(1.4), EffectController(duration: .2), onComplete: l.removeFromParent));
    }
  }
}
