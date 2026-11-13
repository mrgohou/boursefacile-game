# PACO — assets importés

## Provenance et état

**58 WebP originaux sont importés**, sans redimensionnement, depuis `mrgohou/boursefacile-game`, commit `c491e6ed1f14034b4b57c0eda91ace4ed63d034c` :

- `assets/buildings/` : 35 bâtiments (sept secteurs × cinq paliers) et deux passants.
- `assets/paco/` : 11 poses de Paco.
- `assets/tiles/` : six tuiles de base, trois spéciales et un cadenas.

`assets/catalog.json` enregistre chaque chemin réel, sa taille, son statut `imported` et le commit source. Le statut indique la réception des fichiers ; les contrôles visuels sur appareil et la confirmation des droits d’usage restent à consigner. Le dépôt et le commit assurent la traçabilité, sans remplacer l’accord du détenteur des créations.

## Convention réelle du dépôt

Bâtiments : `assets/buildings/{secteur}-{palier}.webp`, avec `agro`, `banque`, `distribution`, `energie`, `industrie`, `services`, `telecom`, et paliers 1 à 5. **Le nom réel est `services`, pas `logistics`.** Son rattachement pédagogique et sa correspondance avec les six tuiles de base restent à confirmer ; aucune septième tuile n’est créée.

Paco : `accueil`, `confiance`, `reflechir`, `expliquer`, `apprendre`, `analyser`, `progresser`, `reussir`, `attention`, `patience`, `reconfort`.

Tuiles : `cacao`, `telephone`, `billet`, `bidon`, `ampoule`, `engrenage`, puis `dividende`, `ago`, `diversif`, `cadenas`.

## Intégration graphique

Les rendus clay sont des images **2D précalculées** sur Flutter/Flame ; aucun moteur 3D mobile n’est nécessaire. La référence dashboard guide la composition native Material : surfaces blanc/gris, accent citron, boutons arrondis. Elle n’est pas un écran aplati à importer.

`PacoMascot(size: 112, pose: 'accueil')` charge la pose réelle ; un pictogramme sert de repli si le décodage échoue. `CityIllustration(height: 180, ownedSectors: 0, ownedCompanyIds: const [])` affiche `agro-1`, `telecom-1`, `banque-1` avec leurs libellés. Les identifiants de portefeuille sont `cacao`, `telecom`, `banque` ; un bâtiment détenu porte le texte « Détenu » et une coche. Les cinq paliers existent dans les fichiers, **mais aucune croissance n’est activée sans validation de ses règles**.

Chaque illustration fournit une seule alternative sémantique et conserve la transparence. Le décodage `Image.asset.cacheWidth` suit la largeur affichée × la densité de pixels, bornée à 512 px. Les sources sont conservées telles quelles (ex. bâtiment agro 300 × 218 px, Paco 512 px). Il n’y a ni agrandissement ni réduction des fichiers sources.

## Validation et budgets

Le catalogue fournit le poids réel total. Le budget initial proposé reste 400 ko d’art visible, à mesurer sur le paquet et l’appareil : ne pas précharger les 35 bâtiments et les 11 poses. La mémoire décodée se calcule approximativement en largeur × hauteur × 4 octets, distinctement du poids WebP.

Avant de valider l’ensemble : inspecter les contours alpha sur fonds clair/sombre ; vérifier les motifs à la taille téléphone ; conserver symboles et textes en plus des couleurs ; mesurer le décodage et la mémoire sur Android. Les pivots proposés restent centre-sol `(0.50, 0.88)` pour les bâtiments, `(0.50, 0.90)` pour Paco, centre `(0.50, 0.50)` pour les tuiles ; ils doivent être recalibrés par superposition avant toute animation ou croissance entre paliers.

La déclaration des fichiers dans `pubspec.yaml` appartient à l’intégration principale. Seuls les chemins livrés du catalogue doivent être déclarés.
