import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'match_engine.dart';

class PacoGame extends FlameGame {
  PacoGame({
    required int level,
    required this.onUpdate,
    required this.onWin,
    required this.onLose,
    this.reducedMotion = false,
    this.onAudio,
  }) : engine = MatchEngine(level) {
    _visible = List.of(engine.board);
  }
  final MatchEngine engine;
  final void Function(int score, int moves, int target) onUpdate;
  final VoidCallback onWin, onLose;
  final void Function(String event, int chain)? onAudio;
  final bool reducedMotion;
  final revision = ValueNotifier<int>(0);
  static const symbolNames = [
    'cacao',
    'téléphone',
    'billets',
    'bidon',
    'ampoule',
    'engrenage',
  ];
  final List<Sprite> _sprites = [];
  final List<_Cell> _cells = [];
  late List<int> _visible;
  List<int> get visibleBoard => List.unmodifiable(List.generate(49, tileType));
  // During gravity the readable board describes destinations; visual pieces
  // travel between them. Never expose the internal empty-cell sentinel to UI.
  int tileType(int index) => _visible[index] >= 0
      ? _visible[index]
      : (_current?.after[index] ?? engine.board[index]);
  int? _selected;
  int? get selectedTile => _selected;
  List<int> _hint = [];
  bool isHinted(int index) => _hint.contains(index);
  List<TurnStep> _timeline = [];
  int _step = 0;
  double _elapsed = 0;
  bool _removed = false, _completed = false;
  int? _dragPointer;
  bool get isAnimating => _timeline.isNotEmpty;
  double get _unit => math.min(size.x, size.y) / 7;
  Vector2 get _origin =>
      Vector2((size.x - _unit * 7) / 2, (size.y - _unit * 7) / 2);
  TurnStep? get _current => isAnimating ? _timeline[_step] : null;
  void _announce() {
    if (!_removed) revision.value++;
  }

  void _audio(String name, [int chain = 0]) {
    if (!_removed) onAudio?.call(name, chain);
  }

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
    if (_removed) return;
    _sprites.addAll(textures.map(Sprite.new));
    for (var i = 0; i < 49; i++) {
      if (_removed) return;
      final cell = _Cell(this, i);
      _cells.add(cell);
      await add(cell);
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
    for (final cell in _cells) {
      cell.position =
          _origin + Vector2(cell.index % 7 * _unit, cell.index ~/ 7 * _unit);
      cell.size = Vector2.all(_unit);
    }
  }

  void hint() {
    if (_removed || _completed || isAnimating) return;
    _selected = null;
    _hint = engine.hint() ?? [];
    _announce();
  }

  void selectTile(int index) {
    if (index < 0 ||
        index >= 49 ||
        _removed ||
        _completed ||
        isAnimating ||
        _dragPointer != null) {
      return;
    }
    _hint = [];
    if (_selected == null) {
      _selected = index;
      _audio('select');
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
      _audio('select');
      _announce();
      return;
    }
    _exchange(first, index);
  }

  void _exchange(int a, int b) {
    if (_removed || _completed || isAnimating) return;
    _selected = null;
    _hint = [];
    engine.swap(a, b);
    _timeline = engine.lastTurn;
    if (_timeline.isEmpty) return;
    _step = 0;
    _elapsed = 0;
    _startStep();
    _announce();
  }

  double _duration(TurnStep s) => reducedMotion
      ? .012
      : switch (s.phase) {
          TurnPhase.swap || TurnPhase.revert => .15,
          TurnPhase.clear => .16,
          TurnPhase.fall => .22,
          TurnPhase.shuffle => .24,
        };
  void _startStep() {
    final s = _current!;
    _visible = List.of(s.before);
    switch (s.phase) {
      case TurnPhase.swap:
        _audio('swap');
        break;
      case TurnPhase.revert:
        _audio('invalid');
        break;
      case TurnPhase.clear:
        _audio(s.chain > 1 ? 'cascade' : 'match', s.chain);
        break;
      case TurnPhase.shuffle:
        _audio('shuffle');
        break;
      case TurnPhase.fall:
        break;
    }
    _announce();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_removed || !isAnimating) return;
    _elapsed += dt;
    while (isAnimating && _elapsed >= _duration(_current!)) {
      final done = _current!;
      _elapsed -= _duration(done);
      _visible = List.of(done.after);
      if (done.phase == TurnPhase.clear) {
        onUpdate(done.score, done.moves, engine.target);
      }
      _step++;
      if (_step < _timeline.length) {
        _startStep();
      } else {
        _timeline = [];
        _elapsed = 0;
        _visible = List.of(engine.board);
        onUpdate(engine.score, engine.moves, engine.target);
        _announce();
        if (!_completed && (engine.won || engine.lost)) {
          _completed = true;
          _audio(engine.won ? 'win' : 'lose');
          if (engine.won) {
            onWin();
          } else {
            onLose();
          }
        }
      }
    }
  }

  Offset _position(int index) =>
      Offset((index % 7) * _unit, (index ~/ 7) * _unit);
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (_unit <= 0) return;
    canvas.save();
    canvas.translate(_origin.x, _origin.y);
    final s = _current;
    final t = s == null ? 0.0 : (_elapsed / _duration(s)).clamp(0.0, 1.0);
    final ease = 1 - math.pow(1 - t, 3).toDouble();
    for (var i = 0; i < 49; i++) {
      final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          i % 7 * _unit + 2,
          i ~/ 7 * _unit + 2,
          _unit - 4,
          _unit - 4,
        ),
        Radius.circular(_unit * .18),
      );
      canvas.drawRRect(r, Paint()..color = const Color(0xFFE3EBDF));
    }
    if (s?.phase == TurnPhase.shuffle) {
      final fresh = t >= .5;
      final board = fresh ? s!.after : s!.before;
      final scale = reducedMotion ? 1.0 : (fresh ? (t - .5) * 2 : 1 - t * 2);
      for (var i = 0; i < 49; i++) {
        _drawTile(canvas, board[i], _position(i), scale, 1);
      }
    } else if (s?.phase == TurnPhase.fall) {
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(0, 0, _unit * 7, _unit * 7));
      for (final m in s!.motions) {
        final from = m.from < 0
            ? Offset(m.to % 7 * _unit, ((m.from - m.to % 7) ~/ 7) * _unit)
            : _position(m.from);
        _drawTile(
          canvas,
          m.type,
          Offset.lerp(from, _position(m.to), ease)!,
          1,
          1,
        );
      }
      canvas.restore();
    } else {
      final moving =
          s != null &&
          (s.phase == TurnPhase.swap || s.phase == TurnPhase.revert);
      for (var i = 0; i < 49; i++) {
        if (_visible[i] < 0) continue;
        if (moving && s.motions.any((m) => m.from == i)) continue;
        final clearing = s?.phase == TurnPhase.clear && s!.cleared.contains(i);
        final scale = clearing && !reducedMotion ? 1 - .8 * t : 1.0;
        final alpha = clearing ? 1 - t : 1.0;
        _drawTile(
          canvas,
          _visible[i],
          _position(i),
          scale,
          alpha,
          marked: _selected == i || _hint.contains(i),
        );
      }
      if (moving) {
        for (final m in s.motions) {
          _drawTile(
            canvas,
            m.type,
            Offset.lerp(_position(m.from), _position(m.to), ease)!,
            1,
            1,
          );
        }
      }
    }
    if (s?.phase == TurnPhase.clear && !reducedMotion) {
      for (final i in s!.cleared) {
        final center = _position(i) + Offset(_unit / 2, _unit / 2);
        for (var n = 0; n < 6; n++) {
          final a = n * math.pi / 3;
          canvas.drawCircle(
            center + Offset(math.cos(a), math.sin(a)) * (_unit * .55 * t),
            _unit * .045 * (1 - t),
            Paint()..color = const Color(0xFFF8C954).withValues(alpha: 1 - t),
          );
        }
      }
      if (s.chain > 1) {
        final text = TextPainter(
          text: TextSpan(
            text: 'COMBO ×${s.chain}',
            style: TextStyle(
              fontSize: _unit * .42,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF315D45),
              shadows: const [Shadow(color: Color(0xFFFFFFFF), blurRadius: 6)],
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        text.paint(
          canvas,
          Offset((_unit * 7 - text.width) / 2, _unit * 3 - t * _unit * .3),
        );
      }
    }
    canvas.restore();
  }

  void _drawTile(
    Canvas canvas,
    int type,
    Offset position,
    double scale,
    double alpha, {
    bool marked = false,
  }) {
    canvas.save();
    canvas.translate(position.dx + _unit / 2, position.dy + _unit / 2);
    canvas.scale(scale);
    final bounds = Rect.fromLTWH(-_unit / 2, -_unit / 2, _unit, _unit);
    if (alpha < 1) {
      canvas.saveLayer(
        bounds,
        Paint()..color = Color.fromRGBO(255, 255, 255, alpha),
      );
    }
    final rect = RRect.fromRectAndRadius(
      bounds.deflate(_unit * .05),
      Radius.circular(_unit * .19),
    );
    const colors = [
      Color(0xFFB5D94A),
      Color(0xFF55CBAA),
      Color(0xFF6BAEE8),
      Color(0xFFEE8C79),
      Color(0xFFA58AC9),
      Color(0xFFEDC75C),
    ];
    canvas.drawRRect(rect, Paint()..color = colors[type]);
    if (_sprites.isNotEmpty) {
      _sprites[type].render(
        canvas,
        position: Vector2(-_unit * .45, -_unit * .45),
        size: Vector2.all(_unit * .9),
      );
    } else {
      final p = Paint()
        ..color = const Color(0xFF244539)
        ..strokeWidth = _unit * .06
        ..strokeCap = StrokeCap.round;
      final r = _unit * .16;
      switch (type) {
        case 0:
          canvas.drawCircle(Offset.zero, r, p);
          break;
        case 1:
          canvas.drawPath(
            Path()
              ..moveTo(0, -r)
              ..lineTo(r, 0)
              ..lineTo(0, r)
              ..lineTo(-r, 0)
              ..close(),
            p,
          );
          break;
        case 2:
          canvas.drawPath(
            Path()
              ..moveTo(0, -r)
              ..lineTo(r, r)
              ..lineTo(-r, r)
              ..close(),
            p,
          );
          break;
        case 3:
          canvas.drawLine(Offset(-r, 0), Offset(r, 0), p);
          canvas.drawLine(Offset(0, -r), Offset(0, r), p);
          break;
        case 4:
          for (final y in [-r, 0.0, r]) {
            canvas.drawLine(Offset(-r, y), Offset(r, y), p);
          }
          break;
        case 5:
          final path = Path();
          for (var n = 0; n < 10; n++) {
            final a = -math.pi / 2 + n * math.pi / 5;
            final radius = n.isEven ? r * 1.2 : r * .5;
            final x = math.cos(a) * radius, y = math.sin(a) * radius;
            if (n == 0) {
              path.moveTo(x, y);
            } else {
              path.lineTo(x, y);
            }
          }
          canvas.drawPath(path..close(), p);
          break;
      }
    }
    if (marked) {
      canvas.drawRRect(
        rect,
        Paint()
          ..color = const Color(0xFF163C32)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4,
      );
    }
    if (alpha < 1) canvas.restore();
    canvas.restore();
  }

  @override
  void onRemove() {
    if (_removed) return;
    _removed = true;
    _timeline = [];
    _hint = [];
    _dragPointer = null;
    revision.dispose();
    super.onRemove();
  }
}

class _Cell extends PositionComponent with TapCallbacks, DragCallbacks {
  _Cell(this.owner, this.index);
  final PacoGame owner;
  final int index;
  Vector2 _delta = Vector2.zero();
  bool _sent = false;
  @override
  void onTapUp(TapUpEvent event) {
    if (!_sent) owner.selectTile(index);
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (owner._dragPointer == null) {
      _sent = false;
    }
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (owner.isAnimating || owner._completed || owner._dragPointer != null) {
      return;
    }
    owner._dragPointer = event.pointerId;
    _delta = Vector2.zero();
    _sent = false;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (owner._dragPointer != event.pointerId || _sent) return;
    _delta += event.localDelta;
    if (math.max(_delta.x.abs(), _delta.y.abs()) < size.x * .2) return;
    _sent = true;
    final horizontal = _delta.x.abs() >= _delta.y.abs();
    final target =
        index +
        (horizontal ? (_delta.x > 0 ? 1 : -1) : (_delta.y > 0 ? 7 : -7));
    if (MatchEngine.adjacent(index, target)) owner._exchange(index, target);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    if (owner._dragPointer == event.pointerId) owner._dragPointer = null;
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    if (owner._dragPointer == event.pointerId) owner._dragPointer = null;
  }
}
