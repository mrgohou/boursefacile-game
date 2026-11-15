class CulturalToken {
  const CulturalToken(this.id, this.name, this.effect, this.note);
  final String id, name, note;
  final int effect;
}

const culturalTokens = [
  CulturalToken('cauri', 'Cauri', 0, 'Coquillage ; récompense de 1 000 F jeu.'),
  CulturalToken(
    'balafon',
    'Balafon',
    1,
    'Instrument à lames de bois et résonateurs.',
  ),
  CulturalToken('kora', 'Kora', 2, 'Harpe-luth d’Afrique de l’Ouest.'),
  CulturalToken('djembe', 'Djembé', 3, 'Tambour joué à la main.'),
  CulturalToken(
    'zaouli',
    'Zaouli',
    4,
    'Évocation stylisée de la tradition de danse de Côte d’Ivoire.',
  ),
  CulturalToken(
    'ekpe',
    'Ekpê',
    0,
    'Gemme de jeu inspirée de la demande ; identification minérale non attestée.',
  ),
  CulturalToken(
    'bijagos-vache',
    'Masque bijagos · vache',
    1,
    'Évocation stylisée de traditions de Guinée-Bissau.',
  ),
  CulturalToken(
    'djenne',
    'Mosquée de Djenné',
    2,
    'Miniature inspirée de l’architecture de terre du Mali.',
  ),
  CulturalToken(
    'tombouctou',
    'Mosquée de Tombouctou',
    3,
    'Miniature inspirée de Sankoré au Mali.',
  ),
  CulturalToken(
    'tata',
    'Tata Tamberma',
    4,
    'Habitat fortifié de terre du Togo.',
  ),
  CulturalToken(
    'agadez',
    'Croix d’Agadez',
    0,
    'Trophée conservé sans valeur monétaire fixée.',
  ),
  CulturalToken(
    'coton',
    'Coton',
    1,
    'Fibre végétale importante dans plusieurs économies de la région.',
  ),
  CulturalToken('cola', 'Cola', 2, 'Récompense de 500 F jeu.'),
  CulturalToken('vache', 'Tête de vache', 3, 'Élevage et activité rurale.'),
  CulturalToken('or', 'Pièces d’or', 4, 'Récompense de 2 000 F jeu par pièce.'),
  CulturalToken(
    'poisson-scie',
    'Poisson-scie',
    0,
    'Silhouette stylisée à rostre denté.',
  ),
  CulturalToken('cafe', 'Café', 1, 'Cerises et grains de café.'),
  CulturalToken('arachide', 'Arachide', 2, 'Culture vivrière et commerciale.'),
  CulturalToken(
    'poids-akan',
    'Poids en or akan',
    3,
    'Évocation stylisée d’un poids traditionnel pour peser l’or.',
  ),
  CulturalToken(
    'bijagos-requin',
    'Masque bijagos · requin',
    4,
    'Évocation stylisée de traditions de Guinée-Bissau.',
  ),
];
const culturalEffects = [
  'Efface une ligne',
  'Récolte une catégorie',
  'Explosion de proximité',
  'Récolte la catégorie cible',
  'Efface une ligne et une colonne',
];
int specialTokenIndex(int level, int effect) => ((level ~/ 5) % 4) * 5 + effect;
const fabricNames = [
  'Kita',
  'Bogolan',
  'Faso danfani',
  'Lili pende',
  'Pano di Pinti',
];
const cityCountries = [
  'Côte d’Ivoire',
  'Mali',
  'Sénégal',
  'Guinée-Bissau',
  'Bénin',
  'Togo',
  'Burkina Faso',
  'Niger',
];
const cityTiers = ['Rural', 'Ville en essor', 'Moderne'];

// Original atlas 1122 × 1402. Per-object frames exclude neighboring silhouettes.
const culturalAtlasFrames = [
  (20, 20, 245, 270),
  (292, 40, 255, 250),
  (576, 0, 250, 310),
  (857, 20, 250, 285),
  (0, 310, 280, 275),
  (294, 330, 255, 245),
  (573, 313, 245, 274),
  (841, 320, 280, 266),
  (8, 590, 255, 285),
  (290, 615, 260, 250),
  (575, 585, 250, 285),
  (852, 600, 265, 280),
  (0, 892, 279, 235),
  (285, 880, 270, 255),
  (563, 912, 259, 217),
  (825, 885, 297, 250),
  (0, 1143, 275, 259),
  (288, 1150, 265, 252),
  (573, 1153, 247, 249),
  (846, 1140, 276, 262),
];
