// Plateau du puzzle rendu avec Flame. La logique vient de engine/board.dart ;
// les gestes sont lus par Flutter (GestureDetector) puis transmis ici.
import 'dart:async';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:flutter/animation.dart' show Curves;

import '../engine/board.dart' as eng;

typedef StepsCallback = void Function(List<eng.Step> steps);

class PuzzleGame extends FlameGame {
  PuzzleGame({required this.level, required this.onSteps, required this.onSettled, required this.onRefused, required this.dark});

  final eng.LevelDef level;
  final StepsCallback onSteps;
  final VoidCallback onSettled;
  final VoidCallback onRefused;
  final bool dark;

  late final eng.Board board = eng.Board.forLevel(level);
  final Map<int, _TileSprite> _sprites = {};
  double cell = 48;
  Vector2 origin = Vector2.zero();
  bool busy = false;
  eng.Pos? selected;
  late final RectangleComponent _highlight;

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
    _highlight = RectangleComponent(
      size: Vector2.all(cell),
      anchor: Anchor.center,
      paint: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = dark ? const Color(0xFFD1F88C) : const Color(0xFF103C30),
      priority: 10,
    )..opacity = 0;
    add(_highlight);
    for (var r = 0; r < eng.boardSize; r++) {
      for (var c = 0; c < eng.boardSize; c++) {
        final t = board.grid[r][c];
        if (t != null) _spawn(t, eng.Pos(r, c));
      }
    }
  }

  void _layout() {
    final s = size.x < size.y ? size.x : size.y;
    cell = ((s - 12) / eng.boardSize).floorToDouble();
    origin = Vector2((size.x - cell * eng.boardSize) / 2, (size.y - cell * eng.boardSize) / 2);
  }

  Vector2 center(eng.Pos p) => origin + Vector2(p.c * cell + cell / 2, p.r * cell + cell / 2);

  /// Case touchée à partir d'une position locale du widget.
  eng.Pos? cellAt(Offset local) {
    final c = ((local.dx - origin.x) / cell).floor();
    final r = ((local.dy - origin.y) / cell).floor();
    final p = eng.Pos(r, c);
    return p.inside ? p : null;
  }

  _TileSprite _spawn(eng.Tile t, eng.Pos p, {double? fromY}) {
    final sprite = _TileSprite(this, t, cell - 6)..position = center(p);
    if (fromY != null) sprite.position.y = fromY;
    _sprites[t.id] = sprite;
    add(sprite);
    return sprite;
  }

  // ---------- Gestes ----------
  void tap(Offset local) {
    if (busy) return;
    final p = cellAt(local);
    if (p == null) return;
    final sel = selected;
    if (sel != null && eng.Board.adjacent(sel, p)) {
      _select(null);
      swap(sel, p);
    } else {
      _select(p);
    }
  }

  void swipe(Offset start, Offset delta) {
    if (busy) return;
    final p = cellAt(start);
    if (p == null) return;
    final target = delta.dx.abs() > delta.dy.abs()
        ? eng.Pos(p.r, p.c + (delta.dx > 0 ? 1 : -1))
        : eng.Pos(p.r + (delta.dy > 0 ? 1 : -1), p.c);
    _select(null);
    swap(p, target);
  }

  void _select(eng.Pos? p) {
    selected = p;
    if (p == null) {
      _highlight.opacity = 0;
    } else {
      _highlight
        ..position = center(p)
        ..opacity = 1;
    }
  }

  Future<void> _move(PositionComponent c, Vector2 to, double seconds) {
    final done = Completer<void>();
    c.add(MoveEffect.to(to, EffectController(duration: seconds, curve: Curves.easeInOut), onComplete: done.complete));
    return done.future;
  }

  Future<void> swap(eng.Pos a, eng.Pos b) async {
    if (!b.inside) return;
    final ta = board.at(a), tb = board.at(b);
    if (ta == null || tb == null) return;
    busy = true;
    final sa = _sprites[ta.id]!, sb = _sprites[tb.id]!;
    await Future.wait([_move(sa, center(b), .14), _move(sb, center(a), .14)]);
    final steps = board.play(a, b);
    if (steps == null) {
      onRefused();
      await Future.wait([_move(sa, center(a), .14), _move(sb, center(b), .14)]);
      busy = false;
      return;
    }
    onSteps(steps);
    for (final s in steps) {
      await _animate(s);
    }
    busy = false;
    onSettled();
  }

  Future<void> _animate(eng.Step step) async {
    // Disparition.
    final fades = <Future<void>>[];
    for (final x in step.cleared) {
      final s = _sprites.remove(x.tile.id);
      if (s == null) continue;
      final done = Completer<void>();
      s.add(ScaleEffect.to(Vector2.zero(), EffectController(duration: .16), onComplete: () {
        s.removeFromParent();
        done.complete();
      }));
      fades.add(done.future);
    }
    for (final h in step.lockHits) {
      _sprites[h.tile.id]?.refreshLock(opened: h.opened);
    }
    await Future.wait(fades);
    // Spéciales créées.
    for (final x in step.created) {
      final s = _spawn(x.tile, x.pos)..scale = Vector2.all(.2);
      s.add(ScaleEffect.to(Vector2.all(1), EffectController(duration: .18, curve: Curves.easeOutBack)));
    }
    // Chute et nouvelles tuiles.
    final spawned = step.spawned.map((t) => t.id).toSet();
    final spawnRow = List<int>.filled(eng.boardSize, 0);
    final falls = <Future<void>>[];
    for (var r = 0; r < eng.boardSize; r++) {
      for (var c = 0; c < eng.boardSize; c++) {
        final t = step.grid[r][c];
        if (t == null) continue;
        final target = center(eng.Pos(r, c));
        var s = _sprites[t.id];
        if (s == null || spawned.contains(t.id)) {
          s?.removeFromParent();
          spawnRow[c]++;
          s = _spawn(t, eng.Pos(r, c), fromY: origin.y - spawnRow[c] * cell);
        }
        if (s.position != target) {
          falls.add(_move(s, target, .12 + (target.y - s.position.y).abs() / cell * .05));
        }
      }
    }
    await Future.wait(falls);
  }
}

class _BoardBackground extends Component {
  _BoardBackground(this.game);
  final PuzzleGame game;

  @override
  void render(Canvas canvas) {
    final o = game.origin, n = eng.boardSize, s = game.cell;
    final rect = RRect.fromRectAndRadius(Rect.fromLTWH(o.x - 4, o.y - 4, s * n + 8, s * n + 8), const Radius.circular(20));
    canvas.drawRRect(rect, Paint()..color = game.dark ? const Color(0x33FFFFFF) : const Color(0x8CFFFFFF));
    final light = Paint()..color = const Color(0x40D1F88C);
    for (var r = 0; r < n; r++) {
      for (var c = 0; c < n; c++) {
        if ((r + c).isEven) canvas.drawRect(Rect.fromLTWH(o.x + c * s, o.y + r * s, s, s), light);
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
      add(SpriteComponent(sprite: Sprite(img.fromCache('tiles/${sp.name}.webp')), size: size));
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
