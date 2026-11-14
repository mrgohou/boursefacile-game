# PACO Kotlin — édition Android native

Version indépendante du jeu PACO, écrite en **Kotlin avec Jetpack Compose**. Le moteur de puzzle est natif Kotlin, rendu par un Canvas Android/Compose. Aucun runtime Flutter, Dart, Unity ou WebView n'est embarqué.

[APK et notes de livraison](https://github.com/mrgohou/boursefacile-game/releases/tag/kotlin-v1.1.0-30-stages)

## Jouer

Installer l'APK de développement depuis la version GitHub associée. L'application s'appelle **PACO Kotlin**, identifiant `ci.paco.bourse.kotlin` : elle s'installe à côté de PACO Flutter sans le remplacer et possède sa propre sauvegarde.

- Ville isométrique tactile, zoom et recentrage, acquis, cartes permanentes et guichet.
- Trente puzzles Match-3, organisés en cinq chapitres, à glissement ou deux taps, échanges, chutes et cascades animés, indice et mélange des plateaux bloqués.
- Consigne avant le démarrage, chrono de 60/70/75/90 secondes, résultats GAGNE / PAS DE CHANCE en relief avec rebond et retour au menu.
- Achat de parts, Acheter plus en vert, Vendre en rouge, frais, baisse fictive et démonstration de dividende.
- Six terrains supplémentaires, sept familles de constructions, dépenses enregistrées avant validation.
- Quinze destinations et 45 quiz avec récompenses uniques, carnet et réglages audio.
- Musiques et bruitages via MediaPlayer et SoundPool, pause de l'audio en arrière-plan. Le délai de puzzle utilise une horloge monotone et continue en arrière-plan.
- Import/export manuel JSON compatible avec le format PACO v1/v2/v3/v4 documenté. L'import est vérifié et confirmé avant remplacement, sans addition de soldes.

**Démo locale, monnaie et entreprises fictives.** La sauvegarde Kotlin est indépendante : aucune donnée privée d'une autre application n'est lue automatiquement. Les 45 définitions de niveaux du catalogue compagnon restent des données de référence ; les puzzles jouables sont les 30 étapes du parcours PACO. L'archive de marché est embarquée comme donnée de référence, sans flux en direct ni écran de trading réel.

Voir [PROGRESSION-30.md](docs/PROGRESSION-30.md) pour les nouveaux niveaux et la reprise des sauvegardes.

## Compiler

Ouvrir le dossier dans Android Studio ou installer JDK 21 et Android SDK 36 / Build Tools 36.0.0. Le wrapper Gradle est inclus. Définir `ANDROID_HOME` ou créer `local.properties` avec `sdk.dir=...` (fichier ignoré).

```sh
./gradlew :app:testDebugUnitTest :app:lintDebug :app:assembleDebug
adb install -r app/build/outputs/apk/debug/app-debug.apk
```

Versions validées : Gradle 9.5.0, AGP 9.3.1, Kotlin/compilateur Compose 2.4.20, Compose BOM 2025.12.00, Activity Compose 1.13.0, Lifecycle 2.10.0. Android minimum 7 / API 24, cible API 36. L'APK debug utilise une signature de développement ; aucune clé privée n'est versionnée. Ne pas utiliser cette signature pour une publication store.

Le workflow GitHub prépare l'APK et les rapports de vérification sans déploiement store.

## Architecture

```text
MainActivity
  └─ Compose UI (ui/)
       └─ PacoViewModel : UiState / StateFlow
            ├─ domain/ : Player, PuzzleEngine, RoundClock, Lessons
            ├─ data/PlayerRepository : stockage local, commit atomique
            ├─ data/PlayerCodec : validation et migrations JSON
            ├─ data/Catalog : lecture des données embarquées
            └─ data/GameAudio : MediaPlayer + SoundPool
```

Les règles ne dépendent pas de Compose. La couche UI ne modifie pas directement le solde : les mutations passent par un mutex et une écriture sur le dispatcher IO ; l'état observable n'est publié qu'après succès. Le moteur produit des trames d'animation séparées de la résolution des règles. Les appels de navigation et de cycle de vie restent Android natifs.

Voir [ARCHITECTURE.md](docs/ARCHITECTURE.md), [VALIDATION.md](docs/VALIDATION.md) et [ASSETS.md](docs/ASSETS.md).
