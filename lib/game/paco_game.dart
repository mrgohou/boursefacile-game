import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';

import 'match_engine.dart';

class PacoGame extends FlameGame {
  PacoGame({
    required int level,
    required this.onUpdate,
    required this.onWin,
    required this.onLose,
    this.reducedMotion = false,
  }) : engine = MatchEngine(level);

  final MatchEngine engine;
  final void Function(int score, int moves, int target) onUpdate;
  final VoidCallback onWin;
  final VoidCallback onLose;
  final bool reducedMotion;
  final List<_Tile> _tiles = [];
  final List<Sprite> _sprites = [];
  final revision = ValueNotifier<int>(0);
  int? get selectedTile => _selected;
  bool isHinted(int index) => _hint.contains(index);
  static const symbolNames = [
    'cacao',
    'téléphone',
    'billets',
    'bidon',
    'ampoule',
    'engrenage',
  ];
  void selectTile(int index) {
    if (index >= 0 && index < 49) {
      _tap(index);
    }
  }

  void _announce() {
    if (!_removed) revision.value++;
  }

  int? _selected;
  List<int> _hint = [];
  double _lockTime = 0;
  bool _completed = false;
  bool _removed = false;
  bool _pendingResult = false;

  @override
  Color backgroundColor() => const Color(0xFFF4F7EF);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    images.prefix = 'assets/';
    final textures = await images.loadAll([
      'tiles/cacao.webp',
      'tiles/telephone.webp',
      'tiles/billet.webp',
      'tiles/bidon.webp',
      'tiles/ampoule.webp',
      'tiles/engrenage.webp',
    ]);
    if (_removed) {
      return;
    }
    _sprites.addAll(textures.map(Sprite.new));
    for (var i = 0; i < 49; i++) {
      final tile = _Tile(this, i);
      _tiles.add(tile);
      await add(tile);
    }
    _layout();
    if (!_removed) {
      onUpdate(engine.score, engine.moves, engine.target);
      _announce();
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _layout();
  }

  void _layout() {
    final side = math.min(size.x, size.y);
    final unit = side / 7;
    final origin = Vector2((size.x - side) / 2, (size.y - side) / 2);
    for (final tile in _tiles) {
      tile.position =
          origin + Vector2(tile.index % 7 * unit, tile.index ~/ 7 * unit);
      tile.size = Vector2.all(unit);
    }
  }

  void hint() {
    if (_removed || _completed || _lockTime > 0) return;
    _selected = null;
    _hint = engine.hint() ?? [];
    _announce();
  }

  void _tap(int index) {
    if (_removed || _completed || _lockTime > 0) return;
    _hint = [];
    if (_selected == null) {
      _selected = index;
      _announce();
      return;
    }
    final first = _selected!;
    _selected = null;
    if (first == index) {
      _announce();
      return;
    }
    if (!MatchEngine.adjacent(first, index)) {
      _selected = index;
      _announce();
      return;
    }
    if (engine.swap(first, index)) {
      _lockTime = reducedMotion ? 0.01 : 0.24;
      _pendingResult = true;
      for (final tile in _tiles) {
        tile.pulse = reducedMotion ? 0 : 0.24;
      }
      onUpdate(engine.score, engine.moves, engine.target);
    }
    _announce();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_removed) return;
    _lockTime = math.max(0.0, _lockTime - dt);
    if (_pendingResult && _lockTime == 0) {
      _pendingResult = false;
      if (engine.won || engine.lost) {
        _completed = true;
        if (engine.won) {
          onWin();
        } else {
          onLose();
        }
      }
    }
  }

  @override
  void onRemove() {
    if (!_removed) {
      revision.dispose();
    }
    _removed = true;
    _pendingResult = false;
    _hint = [];
    super.onRemove();
  }
}

class _Tile extends PositionComponent with TapCallbacks {
  _Tile(this.owner, this.index);
  final PacoGame owner;
  final int index;
  double pulse = 0;
  static const colors = [
    Color(0xFFB5D94A),
    Color(0xFF55CBAA),
    Color(0xFF6BAEE8),
    Color(0xFFEE8C79),
    Color(0xFFA58AC9),
    Color(0xFFEDC75C),
  ];
  @override
  void onTapUp(TapUpEvent event) => owner._tap(index);
  @override
  void update(double dt) {
    super.update(dt);
    pulse = math.max(0.0, pulse - dt);
  }

  @override
  void render(Canvas canvas) {
    if (size.x <= 0) return;
    final unit = size.x;
    final inset =
        unit *
        (0.055 + (pulse > 0 ? 0.035 * math.sin(pulse / 0.24 * math.pi) : 0));
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(inset, inset, unit - inset * 2, unit - inset * 2),
      Radius.circular(unit * 0.2),
    );
    canvas.drawRRect(rect, Paint()..color = colors[owner.engine.board[index]]);
    final marked = owner._selected == index || owner._hint.contains(index);
    canvas.drawRRect(
      rect,
      Paint()
        ..color = marked ? const Color(0xFF244E42) : const Color(0xFFFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = marked ? 3 : 1,
    );
    if (owner._sprites.isNotEmpty) {
      owner._sprites[owner.engine.board[index]].render(
        canvas,
        position: Vector2(inset, inset),
        size: Vector2.all(unit - inset * 2),
      );
      if (marked) {
        canvas.drawRRect(
          rect,
          Paint()
            ..color = const Color(0xFF163C32)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4,
        );
      }
      return;
    }
    final p = Paint()
      ..color = const Color(0xFF244539)
      ..strokeWidth = unit * 0.065
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final c = Offset(unit / 2, unit / 2), r = unit * 0.16;
    switch (owner.engine.board[index]) {
      case 0:
        canvas.drawCircle(c, r, p);
        break;
      case 1:
        canvas.drawPath(
          Path()
            ..moveTo(c.dx, c.dy - r)
            ..lineTo(c.dx + r, c.dy)
            ..lineTo(c.dx, c.dy + r)
            ..lineTo(c.dx - r, c.dy)
            ..close(),
          p,
        );
        break;
      case 2:
        canvas.drawPath(
          Path()
            ..moveTo(c.dx, c.dy - r)
            ..lineTo(c.dx + r, c.dy + r)
            ..lineTo(c.dx - r, c.dy + r)
            ..close(),
          p,
        );
        break;
      case 3:
        canvas.drawLine(c.translate(-r, 0), c.translate(r, 0), p);
        canvas.drawLine(c.translate(0, -r), c.translate(0, r), p);
        break;
      case 4:
        for (final y in [-r, 0.0, r]) {
          canvas.drawLine(c.translate(-r, y), c.translate(r, y), p);
        }
        break;
      case 5:
        final path = Path();
        for (var i = 0; i < 10; i++) {
          final a = -math.pi / 2 + i * math.pi / 5,
              radius = i.isEven ? r * 1.2 : r * 0.5;
          final x = c.dx + math.cos(a) * radius,
              y = c.dy + math.sin(a) * radius;
          if (i == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
        canvas.drawPath(path..close(), p);
        break;
    }
  }
}
