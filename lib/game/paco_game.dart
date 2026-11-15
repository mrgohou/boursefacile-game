import '../domain/cultural_catalog.dart';

import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:material_ui/material_ui.dart' show Icons, IconData;

import 'match_engine.dart';

class PacoGame extends FlameGame {
  PacoGame({
    required int level,
    int mastery = 0,
    required this.onUpdate,
    required this.onWin,
    required this.onLose,
    this.reducedMotion = false,
    this.onAudio,
    this.canAcceptInput,
  }) : engine = MatchEngine(level, mastery: mastery) {
    _visible = List.of(engine.board);
  }
  final MatchEngine engine;
  bool inputEnabled = true;
  final bool Function()? canAcceptInput;
  bool get acceptsInput => inputEnabled && (canAcceptInput?.call() ?? true);
  void endRound() {
    inputEnabled = false;
    _completed = true;
    _timeline = [];
    _selected = null;
    _hint = [];
    _visible = List.of(engine.board);
    _announce();
    pauseEngine();
  }

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
  final List<Sprite> _culturalSprites = [];
  final List<_Cell> _cells = [];
  late List<int> _visible;
  List<int> get visibleBoard => List.unmodifiable(List.generate(81, tileType));
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
  double get _unit => math.min(size.x, size.y) / 9;
  Vector2 get _origin =>
      Vector2((size.x - _unit * 9) / 2, (size.y - _unit * 9) / 2);
  TurnStep? get _current => isAnimating ? _timeline[_step] : null;
  void _announce() {
    if (!_removed) revision.value++;
  }

  void _audio(String name, [int chain = 0]) {
    if (!_removed) onAudio?.call(name, chain);
  }

  @override
  Color backgroundColor() => HSLColor.fromAHSL(
    1,
    (engine.challenge.themeIndex * 47.0 + 265) % 360,
    .35,
    .25,
  ).toColor();
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
      'culture/pions-atlas.png',
    ]);
    if (_removed) return;
    _sprites.addAll(textures.take(6).map(Sprite.new));
    final atlas = textures.last;
    for (var i = 0; i < 20; i++) {
      final frame = culturalAtlasFrames[i];
      _culturalSprites.add(
        Sprite(
          atlas,
          srcPosition: Vector2(
            frame.$1 / 1122 * atlas.width,
            frame.$2 / 1402 * atlas.height,
          ),
          srcSize: Vector2(
            frame.$3 / 1122 * atlas.width,
            frame.$4 / 1402 * atlas.height,
          ),
        ),
      );
    }
    for (var i = 0; i < 81; i++) {
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
          _origin + Vector2(cell.index % 9 * _unit, cell.index ~/ 9 * _unit);
      cell.size = Vector2.all(_unit);
    }
  }

  void hint() {
    if (!acceptsInput) return;
    if (!acceptsInput || _removed || _completed || isAnimating) return;
    _selected = null;
    _hint = engine.hint() ?? [];
    _announce();
  }

  void selectTile(int index) {
    if (!acceptsInput) return;
    if (index < 0 ||
        index >= 81 ||
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
    if (!acceptsInput || _removed || _completed || isAnimating) return;
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
      if (done.phase == TurnPhase.fall) _audio('ui');
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
      Offset((index % 9) * _unit, (index ~/ 9) * _unit);
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (_unit <= 0) return;
    canvas.save();
    canvas.translate(_origin.x, _origin.y);
    final s = _current;
    final t = s == null ? 0.0 : (_elapsed / _duration(s)).clamp(0.0, 1.0);
    final ease = 1 - math.pow(1 - t, 3).toDouble();
    for (var i = 0; i < 81; i++) {
      final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          i % 9 * _unit + 2,
          i ~/ 9 * _unit + 2,
          _unit - 4,
          _unit - 4,
        ),
        Radius.circular(_unit * .18),
      );
      canvas.drawRRect(
        r,
        Paint()
          ..color = HSLColor.fromAHSL(
            1,
            (engine.challenge.themeIndex * 47.0 + 265) % 360,
            .30,
            .28,
          ).toColor(),
      );
      _fabric(canvas, r.outerRect, i);
    }
    if (!isAnimating) {
      for (final i in engine.lockedCells) {
        final pos = _position(i);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(pos.dx + 3, pos.dy + 3, _unit - 6, _unit - 6),
            const Radius.circular(8),
          ),
          Paint()..color = const Color(0x55FFD773),
        );
      }
    }
    if (s?.phase == TurnPhase.shuffle) {
      final fresh = t >= .5;
      final board = fresh ? s!.after : s!.before;
      final scale = reducedMotion ? 1.0 : (fresh ? (t - .5) * 2 : 1 - t * 2);
      for (var i = 0; i < 81; i++) {
        _drawTile(canvas, board[i], _position(i), scale, 1);
      }
    } else if (s?.phase == TurnPhase.fall) {
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(0, 0, _unit * 9, _unit * 9));
      for (final m in s!.motions) {
        final from = m.from < 0
            ? Offset(m.to % 9 * _unit, ((m.from - m.to % 9) ~/ 9) * _unit)
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
      for (var i = 0; i < 81; i++) {
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
            text: '${s.chain > 2 ? 'Magnifique !' : 'Super !'} ×${s.chain}',
            style: TextStyle(
              fontSize: _unit * .42,
              fontWeight: FontWeight.w900,
              color: const Color(0xFFFFE182),
              shadows: const [Shadow(color: Color(0xFFFFFFFF), blurRadius: 6)],
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        text.paint(
          canvas,
          Offset((_unit * 9 - text.width) / 2, _unit * 3 - t * _unit * .3),
        );
      }
    }
    final locks = s?.lockedCells ?? engine.lockedCells;
    final specialPieces = s?.specials ?? engine.specials;
    for (final i in {...locks, ...specialPieces.keys}) {
      if (!locks.contains(i) && _culturalSprites.isNotEmpty) {
        final type = specialPieces[i]!.index;
        final sprite =
            _culturalSprites[specialTokenIndex(
              engine.challenge.themeIndex,
              type,
            )];
        final p = _position(i);
        canvas.save();
        canvas.clipRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(p.dx + 3, p.dy + 3, _unit - 6, _unit - 6),
            Radius.circular(_unit * .18),
          ),
        );
        sprite.render(
          canvas,
          position: Vector2(p.dx + 3, p.dy + 3),
          size: Vector2.all(_unit - 6),
        );
        canvas.restore();
        final effect = TextPainter(
          text: TextSpan(
            text: '${type + 1}',
            style: TextStyle(
              fontSize: _unit * .22,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF182B40),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        canvas.drawCircle(
          p + Offset(_unit * .8, _unit * .8),
          _unit * .15,
          Paint()..color = const Color(0xFFFFD86A),
        );
        effect.paint(canvas, p + Offset(_unit * .75, _unit * .65));
        continue;
      }
      final IconData symbol = locks.contains(i)
          ? Icons.lock
          : switch (specialPieces[i]!.name) {
              'lightning' => Icons.bolt,
              'goldCoin' => Icons.monetization_on,
              'goldFuel' => Icons.local_gas_station,
              'silverSickle' => Icons.grass,
              _ => Icons.local_shipping,
            };
      final silver = specialPieces[i]?.name == 'silverSickle';
      final text = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(symbol.codePoint),
          style: TextStyle(
            fontFamily: symbol.fontFamily,
            package: symbol.fontPackage,
            color: silver ? const Color(0xFFE1F0FF) : const Color(0xFFFFD35E),
            fontSize: _unit * .50,
            shadows: const [Shadow(color: Color(0xFF21394B), blurRadius: 3)],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final pos = _position(i) + Offset(_unit * .48, 0);
      canvas.drawCircle(
        pos + Offset(_unit * .23, _unit * .23),
        _unit * .25,
        Paint()..color = const Color(0xD92A354B),
      );
      text.paint(canvas, pos);
    }
    canvas.restore();
  }

  void _fabric(Canvas canvas, Rect rect, int cell) {
    final style = engine.challenge.themeIndex % 5;
    final ink = Paint()
      ..color = const Color(0xFFEDD6A4).withValues(alpha: .30)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    canvas.save();
    canvas.clipRect(rect);
    final x = rect.center.dx, y = rect.center.dy, u = rect.width;
    if (style == 0 || style == 3) {
      final path = Path()
        ..moveTo(x, rect.top)
        ..lineTo(rect.right, y)
        ..lineTo(x, rect.bottom)
        ..lineTo(rect.left, y)
        ..close();
      canvas.drawPath(path, ink);
      if (style == 3) canvas.drawCircle(rect.center, u * .18, ink);
    } else if (style == 1) {
      for (var j = 0; j < 3; j++) {
        canvas.drawCircle(
          Offset(rect.left + u * (j + .5) / 3, y),
          u * .045,
          ink,
        );
      }
      canvas.drawLine(rect.topLeft, rect.bottomRight, ink);
      canvas.drawLine(rect.topRight, rect.bottomLeft, ink);
    } else if (style == 2) {
      for (var j = 0; j < 5; j++) {
        final dx = rect.left + u * j / 4;
        canvas.drawLine(Offset(dx, rect.top), Offset(dx, rect.bottom), ink);
      }
    } else {
      for (var j = 0; j < 4; j++) {
        final dy = rect.top + u * j / 3;
        canvas.drawLine(Offset(rect.left, dy), Offset(rect.right, dy), ink);
      }
      canvas.drawRect(rect.deflate(u * .18), ink);
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
        (horizontal ? (_delta.x > 0 ? 1 : -1) : (_delta.y > 0 ? 9 : -9));
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
