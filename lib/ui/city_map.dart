import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../domain/player_state.dart';

/// A pan-and-pinch 2D town. Portfolio rules remain in PlayerState.
class CityMap extends StatefulWidget {
  const CityMap({
    super.key,
    required this.state,
    required this.onBuildingTap,
    this.onGuichetTap,
    this.reducedMotion = false,
    this.controlsBottomInset = 112,
  });
  final PlayerState state;
  final ValueChanged<String> onBuildingTap;
  final VoidCallback? onGuichetTap;
  final bool reducedMotion;
  final double controlsBottomInset;

  @override
  State<CityMap> createState() => _CityMapState();
}

class _CityMapState extends State<CityMap> with SingleTickerProviderStateMixin {
  static const _world = Size(1400, 1000);
  final _transform = TransformationController();
  late final AnimationController _life;
  Size? _viewport;
  bool _motionOff = false;

  @override
  void initState() {
    super.initState();
    _life = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateMotion();
  }

  @override
  void didUpdateWidget(covariant CityMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateMotion();
  }

  void _updateMotion() {
    _motionOff =
        widget.reducedMotion || MediaQuery.disableAnimationsOf(context);
    if (_motionOff) {
      _life.stop();
    } else if (!_life.isAnimating) {
      _life.repeat();
    }
  }

  void _center(Size viewport) {
    final scale = math
        .min(viewport.width / 960, viewport.height / 760)
        .clamp(.5, 1.0);
    _transform.value = Matrix4.identity()
      ..translateByDouble(
        viewport.width / 2 - 700 * scale,
        viewport.height / 2 - 500 * scale,
        0,
        1,
      )
      ..scaleByDouble(scale, scale, 1, 1);
  }

  void _zoom(double factor) {
    final viewport = _viewport;
    if (viewport == null) return;
    final current = _transform.value.getMaxScaleOnAxis();
    final next = (current * factor).clamp(.5, 2.3);
    final focus = Offset(viewport.width / 2, viewport.height / 2);
    final scene = _transform.toScene(focus);
    _transform.value = Matrix4.identity()
      ..translateByDouble(
        focus.dx - scene.dx * next,
        focus.dy - scene.dy * next,
        0,
        1,
      )
      ..scaleByDouble(next, next, 1, 1);
  }

  Widget _building(String id, Offset ground, String asset) {
    final company = companies.firstWhere((c) => c.id == id);
    final quantity = widget.state.holdings[id] ?? 0;
    final owned = quantity > 0;
    return Positioned(
      key: ValueKey('city-position-$id'),
      left: ground.dx - 100,
      top: ground.dy - 155,
      width: 200,
      height: 270,
      child: Semantics(
        button: true,
        label: owned
            ? '${company.name}, $quantity part${quantity > 1 ? 's' : ''} détenue${quantity > 1 ? 's' : ''}. Ouvrir.'
            : 'Emplacement ${company.name}, aucune part. Ouvrir le guichet.',
        excludeSemantics: true,
        child: InkWell(
          key: ValueKey('city-building-$id'),
          onTap: () => widget.onBuildingTap(id),
          borderRadius: BorderRadius.circular(22),
          child: Column(
            children: [
              SizedBox(
                height: 146,
                child: owned
                    ? _asset('assets/buildings/$asset.webp', 220)
                    : Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: const Size(188, 100),
                            painter: _EmptyPlotPainter(),
                          ),
                          Container(
                            width: 58,
                            height: 64,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9F8EC),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFF93A96D),
                                width: 2,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x22163C32),
                                  blurRadius: 8,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.add_rounded,
                              size: 38,
                              color: Color(0xFF527543),
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDFDF4),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A274732),
                      blurRadius: 5,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  owned
                      ? '${company.sector} · $quantity part${quantity > 1 ? 's' : ''}'
                      : '＋ ${company.sector}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF274C38),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hub() => Positioned(
    left: 678,
    top: 215,
    width: 190,
    height: 205,
    child: Semantics(
      button: true,
      label: 'Guichet, ouvrir les échanges de ta ville.',
      excludeSemantics: true,
      child: InkWell(
        key: const ValueKey('city-guichet'),
        onTap: widget.onGuichetTap,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            SizedBox(
              height: 154,
              child: _asset('assets/buildings/services-1.webp', 220),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF163C32),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.account_balance_outlined,
                    size: 17,
                    color: Color(0xFFD9EE83),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Guichet',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _asset(String asset, double width) => Image.asset(
    asset,
    fit: BoxFit.contain,
    cacheWidth: (width * MediaQuery.devicePixelRatioOf(context))
        .ceil()
        .clamp(1, 512)
        .toInt(),
    excludeFromSemantics: true,
    errorBuilder: (context, error, stackTrace) => const Icon(
      Icons.location_city_outlined,
      size: 70,
      color: Color(0xFF5A7C56),
    ),
  );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final viewport = Size(constraints.maxWidth, constraints.maxHeight);
      if (_viewport != viewport) {
        _viewport = viewport;
        _center(viewport);
      }
      return Stack(
        children: [
          Positioned.fill(
            child: ColoredBox(
              color: const Color(0xFFCDE5DE),
              child: InteractiveViewer(
                key: const ValueKey('city-interactive'),
                transformationController: _transform,
                constrained: false,
                minScale: .5,
                maxScale: 2.3,
                boundaryMargin: const EdgeInsets.all(250),
                child: SizedBox(
                  width: _world.width,
                  height: _world.height,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Positioned.fill(
                        child: RepaintBoundary(
                          child: CustomPaint(painter: _IslandPainter()),
                        ),
                      ),
                      _hub(),
                      _building('telecom', const Offset(980, 510), 'telecom-1'),
                      _building('cacao', const Offset(530, 510), 'agro-1'),
                      _building('banque', const Offset(755, 680), 'banque-1'),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: ExcludeSemantics(
                            child: RepaintBoundary(
                              child: AnimatedBuilder(
                                animation: _life,
                                builder: (context, child) => Stack(
                                  children: [
                                    Positioned.fill(
                                      child: CustomPaint(
                                        painter: _LifePainter(
                                          _motionOff ? .22 : _life.value,
                                        ),
                                      ),
                                    ),
                                    _passant(
                                      'vert',
                                      _motionOff ? .25 : _life.value,
                                      false,
                                    ),
                                    _passant(
                                      'rouge',
                                      _motionOff ? .6 : (_life.value + .5) % 1,
                                      true,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 14,
            bottom: widget.controlsBottomInset,
            child: SafeArea(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFFDFDF5),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x222B543D),
                      blurRadius: 15,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      key: const ValueKey('city-zoom-in'),
                      tooltip: 'Agrandir la ville',
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                      onPressed: () => _zoom(1.25),
                      icon: const Icon(Icons.add),
                    ),
                    IconButton(
                      key: const ValueKey('city-zoom-out'),
                      tooltip: 'Réduire la ville',
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                      onPressed: () => _zoom(.8),
                      icon: const Icon(Icons.remove),
                    ),
                    IconButton(
                      key: const ValueKey('city-recenter'),
                      tooltip: 'Recentrer la ville',
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                      onPressed: () => _center(viewport),
                      icon: const Icon(Icons.center_focus_strong_outlined),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    },
  );

  Widget _passant(String color, double t, bool reverse) {
    final p = Offset.lerp(
      const Offset(585, 450),
      const Offset(815, 575),
      reverse ? 1 - t : t,
    )!;
    return Positioned(
      left: p.dx,
      top: p.dy - 30,
      width: 27,
      height: 38,
      child: Image.asset(
        'assets/buildings/passant-$color.webp',
        fit: BoxFit.contain,
        cacheWidth: 80,
        excludeFromSemantics: true,
        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
      ),
    );
  }

  @override
  void dispose() {
    _life.dispose();
    _transform.dispose();
    super.dispose();
  }
}

void _poly(Canvas c, List<Offset> points, Color color) {
  final path = Path()..addPolygon(points, true);
  c.drawPath(path, Paint()..color = color);
}

class _EmptyPlotPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size size) {
    _poly(c, const [
      Offset(4, 54),
      Offset(92, 6),
      Offset(184, 54),
      Offset(94, 99),
    ], const Color(0xFFB5C686));
    final paint = Paint()
      ..color = const Color(0xFFDAE7A8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    c.drawPath(
      Path()..addPolygon(const [
        Offset(13, 54),
        Offset(92, 13),
        Offset(174, 54),
        Offset(94, 91),
      ], true),
      paint,
    );
    for (final p in const [
      Offset(12, 54),
      Offset(93, 15),
      Offset(174, 54),
      Offset(94, 91),
    ]) {
      c.drawLine(
        p,
        p - const Offset(0, 17),
        Paint()
          ..color = const Color(0xFFDBD5AD)
          ..strokeWidth = 5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _EmptyPlotPainter oldDelegate) => false;
}

class _IslandPainter extends CustomPainter {
  const _IslandPainter();
  static const grass = Color(0xFFBBD78E);
  void _tree(Canvas c, double x, double y, [double s = 1]) {
    c.save();
    c.translate(x, y);
    c.scale(s);
    c.drawOval(
      const Rect.fromLTWH(-22, 2, 50, 16),
      Paint()..color = const Color(0x22587437),
    );
    c.drawLine(
      Offset.zero,
      const Offset(0, -30),
      Paint()
        ..color = const Color(0xFF9A8960)
        ..strokeWidth = 7,
    );
    c.drawOval(
      const Rect.fromLTWH(-25, -83, 50, 64),
      Paint()..color = const Color(0xFF729E60),
    );
    c.drawOval(
      const Rect.fromLTWH(-20, -85, 34, 48),
      Paint()..color = const Color(0xFF92BA70),
    );
    c.drawOval(
      const Rect.fromLTWH(-12, -81, 20, 28),
      Paint()..color = const Color(0xFFACCE7D),
    );
    c.restore();
  }

  void _bench(Canvas c, Offset p) {
    c.save();
    c.translate(p.dx, p.dy);
    c.drawLine(
      const Offset(-17, 1),
      const Offset(-17, 14),
      Paint()
        ..color = const Color(0xFF6F8162)
        ..strokeWidth = 4,
    );
    c.drawLine(
      const Offset(15, 17),
      const Offset(15, 29),
      Paint()
        ..color = const Color(0xFF6F8162)
        ..strokeWidth = 4,
    );
    _poly(c, const [
      Offset(-25, -6),
      Offset(-14, -12),
      Offset(27, 11),
      Offset(16, 17),
    ], const Color(0xFFD4AE78));
    _poly(c, const [
      Offset(-24, -7),
      Offset(-24, -18),
      Offset(17, 5),
      Offset(17, 16),
    ], const Color(0xFFDEC194));
    c.restore();
  }

  @override
  void paint(Canvas c, Size size) {
    // Shore relief, pale retaining edge, then grass diamond.
    c.drawOval(
      const Rect.fromLTWH(135, 382, 1130, 510),
      Paint()..color = const Color(0x143D8E88),
    );
    _poly(c, const [
      Offset(85, 526),
      Offset(700, 180),
      Offset(1315, 526),
      Offset(700, 880),
    ], const Color(0xFF82B5A0));
    _poly(c, const [
      Offset(85, 500),
      Offset(700, 155),
      Offset(1315, 500),
      Offset(700, 850),
    ], const Color(0xFFE7DFC0));
    _poly(c, const [
      Offset(100, 495),
      Offset(700, 158),
      Offset(1300, 495),
      Offset(700, 833),
    ], grass);
    // Consistent isometric lawn patches give the map depth without 3D shaders.
    for (var i = -3; i <= 3; i++) {
      for (var j = -2; j <= 2; j++) {
        final x = 700.0 + (i - j) * 88;
        final y = 470.0 + (i + j) * 49;
        _poly(c, [
          Offset(x, y - 43),
          Offset(x + 77, y),
          Offset(x, y + 43),
          Offset(x - 77, y),
        ], (i + j).isEven ? const Color(0xFFBEDA91) : const Color(0xFFBAD68C));
      }
    }
    final river = Path()
      ..moveTo(263, 414)
      ..cubicTo(374, 450, 282, 536, 429, 577)
      ..cubicTo(486, 590, 450, 674, 547, 715);
    c.drawPath(
      river,
      Paint()
        ..color = const Color(0xFF95BC92)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 71
        ..strokeCap = StrokeCap.round,
    );
    c.drawPath(
      river,
      Paint()
        ..color = const Color(0xFF8BCDD0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 54
        ..strokeCap = StrokeCap.round,
    );
    // Two diagonals crossing at the central square.
    for (final ends in const [
      [Offset(380, 320), Offset(1090, 718)],
      [Offset(385, 690), Offset(1030, 328)],
    ]) {
      c.drawLine(
        ends[0],
        ends[1],
        Paint()
          ..color = const Color(0xFFE8E1C1)
          ..strokeWidth = 69
          ..strokeCap = StrokeCap.round,
      );
      c.drawLine(
        ends[0],
        ends[1],
        Paint()
          ..color = const Color(0xFFB8BBA3)
          ..strokeWidth = 48
          ..strokeCap = StrokeCap.round,
      );
      final d = ends[1] - ends[0];
      for (var k = 0; k < 16; k++) {
        final p = ends[0] + d * (k / 16);
        c.drawLine(
          p,
          p + d * .025,
          Paint()
            ..color = const Color(0xFFECEAD5)
            ..strokeWidth = 2,
        );
      }
    }
    _poly(c, const [
      Offset(627, 493),
      Offset(704, 450),
      Offset(781, 493),
      Offset(704, 538),
    ], const Color(0xFFE6DFBD));
    // Fountain at the crossing, small open plaza.
    c.drawOval(
      const Rect.fromLTWH(671, 475, 66, 32),
      Paint()..color = const Color(0xFFAFBCA1),
    );
    c.drawOval(
      const Rect.fromLTWH(676, 475, 56, 24),
      Paint()..color = const Color(0xFF93CDD0),
    );
    c.drawOval(
      const Rect.fromLTWH(693, 474, 22, 10),
      Paint()..color = const Color(0xFFDFE6CC),
    );
    // Timber bridge across the stream on the southwest road.
    _poly(c, const [
      Offset(395, 659),
      Offset(447, 630),
      Offset(484, 650),
      Offset(432, 679),
    ], const Color(0xFFD2AF7B));
    for (var i = 0; i < 7; i++) {
      c.drawLine(
        Offset(399 + i * 7, 657 - i * 4),
        Offset(433 + i * 7, 676 - i * 4),
        Paint()
          ..color = const Color(0xFFB38F62)
          ..strokeWidth = 2,
      );
    }
    // Park and planted borders.
    _poly(c, const [
      Offset(831, 565),
      Offset(947, 500),
      Offset(1075, 571),
      Offset(958, 636),
    ], const Color(0xFFA9C980));
    c.drawOval(
      const Rect.fromLTWH(900, 549, 104, 47),
      Paint()..color = const Color(0xFFE6DFC0),
    );
    c.drawOval(
      const Rect.fromLTWH(913, 555, 78, 32),
      Paint()..color = const Color(0xFFB3D08A),
    );
    for (final p in const [
      Offset(398, 350),
      Offset(475, 309),
      Offset(580, 272),
      Offset(907, 356),
      Offset(1040, 437),
      Offset(1138, 511),
      Offset(1020, 615),
      Offset(901, 706),
      Offset(813, 749),
      Offset(608, 718),
      Offset(344, 482),
      Offset(970, 557),
    ]) {
      _tree(c, p.dx, p.dy, .8);
    }
    _bench(c, const Offset(890, 600));
    _bench(c, const Offset(1006, 554));
    _bench(c, const Offset(608, 392));
    final random = math.Random(18);
    for (var i = 0; i < 44; i++) {
      final center = i < 22 ? const Offset(516, 622) : const Offset(1059, 481);
      final p =
          center + Offset(random.nextDouble() * 73, random.nextDouble() * 34);
      c.drawCircle(
        p,
        3.2,
        Paint()
          ..color = i.isEven
              ? const Color(0xFFF0D68D)
              : const Color(0xFFE9B3A3),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _IslandPainter oldDelegate) => false;
}

class _LifePainter extends CustomPainter {
  _LifePainter(this.t);
  final double t;
  void _car(Canvas c, Offset p, Color color) {
    c.save();
    c.translate(p.dx, p.dy);
    c.drawOval(
      const Rect.fromLTWH(-19, 4, 43, 13),
      Paint()..color = const Color(0x22476B50),
    );
    _poly(c, const [
      Offset(-20, -4),
      Offset(-7, -12),
      Offset(22, 4),
      Offset(8, 12),
    ], color);
    _poly(c, const [
      Offset(-10, -8),
      Offset(-5, -20),
      Offset(12, -10),
      Offset(15, 0),
    ], color);
    _poly(c, const [
      Offset(-4, -17),
      Offset(7, -11),
      Offset(10, -3),
      Offset(-7, -12),
    ], const Color(0xFFD8E9DF));
    c.drawCircle(
      const Offset(-10, 6),
      4,
      Paint()..color = const Color(0xFF5F725D),
    );
    c.drawCircle(
      const Offset(15, 7),
      4,
      Paint()..color = const Color(0xFF5F725D),
    );
    c.restore();
  }

  @override
  void paint(Canvas c, Size size) {
    _car(
      c,
      Offset.lerp(const Offset(407, 341), const Offset(1083, 719), t)!,
      const Color(0xFFF1CF7C),
    );
    _car(
      c,
      Offset.lerp(
        const Offset(390, 677),
        const Offset(1015, 326),
        (t + .45) % 1,
      )!,
      const Color(0xFFDC9F8B),
    );
    final paint = Paint()
      ..color = const Color(0xAAE4FAED)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 6; i++) {
      final y = 454.0 + i * 42;
      final x =
          350 + math.sin(i.toDouble()) * 22 + math.sin(t * math.pi * 2) * 5;
      c.drawArc(Rect.fromLTWH(x, y, 19, 6), 0, math.pi, false, paint);
    }
    c.drawOval(
      Rect.fromCenter(
        center: const Offset(704, 484),
        width: 21 + math.sin(t * math.pi * 2) * 4,
        height: 8,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _LifePainter oldDelegate) => t != oldDelegate.t;
}
