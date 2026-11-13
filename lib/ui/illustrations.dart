import 'package:material_ui/material_ui.dart';

/// Original PACO render, with a single alternative for assistive technology.
class PacoMascot extends StatelessWidget {
  const PacoMascot({super.key, this.size = 112, this.pose = 'accueil'});
  final double size;
  final String pose;

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: 'Paco, ton guide éléphant',
    excludeSemantics: true,
    child: SizedBox.square(
      dimension: size,
      child: Image.asset(
        'assets/paco/$pose.webp',
        fit: BoxFit.contain,
        cacheWidth: (size * MediaQuery.devicePixelRatioOf(context))
            .ceil()
            .clamp(1, 512)
            .toInt(),
        excludeFromSemantics: true,
        errorBuilder: (context, error, stackTrace) => Icon(
          Icons.eco_outlined,
          size: size * .5,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    ),
  );
}

/// Level-one renders only: ownership never implies unvalidated growth.
class CityIllustration extends StatelessWidget {
  const CityIllustration({
    super.key,
    this.height = 180,
    this.ownedSectors = 0,
    this.ownedCompanyIds = const [],
  });
  final double height;
  final int ownedSectors;
  final List<String> ownedCompanyIds;

  static const _buildings = [
    (id: 'cacao', sector: 'Agro-industrie', asset: 'agro-1'),
    (id: 'telecom', sector: 'Télécoms', asset: 'telecom-1'),
    (id: 'banque', sector: 'Banque', asset: 'banque-1'),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final count = ownedCompanyIds.isEmpty
        ? ownedSectors.clamp(0, 3)
        : _buildings.where((b) => ownedCompanyIds.contains(b.id)).length;
    final details = _buildings
        .map(
          (b) =>
              '${b.sector}${ownedCompanyIds.contains(b.id) ? ', détenu' : ''}',
        )
        .join(' ; ');
    return Semantics(
      image: true,
      label: 'Ta ville illustrée. $count secteurs détenus sur trois. $details.',
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: height),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.secondaryContainer.withValues(alpha: .35),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 18),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final decodeWidth =
                    ((constraints.maxWidth / 3) *
                            MediaQuery.devicePixelRatioOf(context))
                        .ceil()
                        .clamp(1, 512)
                        .toInt();
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _buildings.map((b) {
                    final owned = ownedCompanyIds.contains(b.id);
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              height: (height - 78).clamp(56, 160).toDouble(),
                              child: Image.asset(
                                'assets/buildings/${b.asset}.webp',
                                fit: BoxFit.contain,
                                cacheWidth: decodeWidth,
                                excludeFromSemantics: true,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(
                                      Icons.location_city_outlined,
                                      size: 48,
                                      color: scheme.primary,
                                    ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              b.sector,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 5),
                            if (owned)
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 3,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Icon(
                                    Icons.check_circle_outline,
                                    size: 14,
                                    color: scheme.primary,
                                  ),
                                  Text(
                                    'Détenu',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(color: scheme.onSurface),
                                  ),
                                ],
                              )
                            else
                              Text(
                                'À découvrir',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(color: scheme.onSurfaceVariant),
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
