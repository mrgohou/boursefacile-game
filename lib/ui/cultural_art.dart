import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../domain/cultural_catalog.dart';

/// Atlas frames are extracted at rendering time. The original generated images
/// stay intact; a decoded atlas is shared across all visible frames.
class CulturalArt extends StatefulWidget {
  const CulturalArt({
    super.key,
    required this.index,
    this.building = false,
    this.size = 64,
    this.label,
  });
  final int index;
  final bool building;
  final double size;
  final String? label;
  @override
  State<CulturalArt> createState() => _CulturalArtState();
}

class _CulturalArtState extends State<CulturalArt> {
  static final Map<String, Future<ui.Image>> cache = {};
  Future<ui.Image> image(String path) => cache.putIfAbsent(path, () async {
    final b = await rootBundle.load(path);
    final c = await ui.instantiateImageCodec(b.buffer.asUint8List());
    final f = await c.getNextFrame();
    c.dispose();
    return f.image;
  });
  @override
  Widget build(BuildContext context) => Semantics(
    label: widget.label,
    image: true,
    excludeSemantics: true,
    child: SizedBox(
      width: widget.size,
      height: widget.size,
      child: FutureBuilder<ui.Image>(
        future: image(
          'assets/culture/${widget.building ? 'villes' : 'pions'}-atlas.png',
        ),
        builder: (context, s) => s.hasData
            ? CustomPaint(
                painter: _AtlasPainter(
                  s.data!,
                  widget.index,
                  widget.building ? 6 : 4,
                  widget.building ? 4 : 5,
                ),
              )
            : const SizedBox.shrink(),
      ),
    ),
  );
}

class _AtlasPainter extends CustomPainter {
  const _AtlasPainter(this.image, this.index, this.columns, this.rows);
  final ui.Image image;
  final int index, columns, rows;
  @override
  void paint(Canvas canvas, Size size) {
    final w = image.width / columns, h = image.height / rows;
    final frame = columns == 4 ? culturalAtlasFrames[index] : null;
    final source = frame == null
        ? Rect.fromLTWH(index % columns * w, index ~/ columns * h, w, h)
        : Rect.fromLTWH(
            frame.$1 / 1122 * image.width,
            frame.$2 / 1402 * image.height,
            frame.$3 / 1122 * image.width,
            frame.$4 / 1402 * image.height,
          );
    canvas.drawImageRect(
      image,
      source,
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  @override
  bool shouldRepaint(covariant _AtlasPainter old) =>
      image != old.image || index != old.index;
}

class CulturalGuide extends StatelessWidget {
  const CulturalGuide({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Les trésors de Paco')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          '20 pions · 5 pouvoirs',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
        ),
        const Text(
          'Les pions spéciaux changent au fil des niveaux. Leur symbole et cette légende indiquent toujours leur effet. Les représentations culturelles sont des évocations artistiques.',
        ),
        for (var i = 0; i < culturalTokens.length; i++)
          ListTile(
            leading: CulturalArt(index: i, size: 52),
            title: Text(culturalTokens[i].name),
            subtitle: Text(
              '${culturalEffects[culturalTokens[i].effect]}\n${culturalTokens[i].note}',
            ),
            isThreeLine: true,
          ),
        const Text(
          'Motifs de tableau',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        Text(
          'Inspirations graphiques : ${fabricNames.join(', ')}. Les motifs du jeu sont originaux ; ils ne reproduisent pas un textile traditionnel précis.',
        ),
        const Text(
          'Séries sans faute',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        const Text(
          'Quiz : première réponse juste, sur des questions différentes. Niveau sans faute : première tentative du puzzle, aucun échange refusé, puis quiz juste au premier essai. Une erreur ou un nouvel essai rompt la série ; les acquis restent conservés. Les paliers 5 et 10 alternent à chaque tranche de 10 réussites. Les nouveaux gains attendent le bouton COLLECTER.',
        ),
      ],
    ),
  );
}
