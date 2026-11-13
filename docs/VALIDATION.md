# Validation du 13 novembre 2026

## Vérifié

- Flutter 3.50.0 / Dart 3.14.0 : analyse sans problème signalé.
- 14 tests Flutter réussis : économie, progression, sauvegarde, concurrence locale, UI compacte et texte à 200 %, rendu Flame et sémantique des tuiles.
- Test ciblé final du plateau réussi après intégration des assets : indice accessible et échange par deux événements tactiles réels du moteur de test Flutter.
- 7 tests Node API réussis ; audit npm sans vulnérabilité signalée à cette date.
- Compilation Android ARM64 debug réussie avec JDK 21.0.13, SDK 35/36, Build Tools 36.0.0, NDK 28.2.13676358 et CMake 3.22.1.
- APK contrôlé par `aapt` : `com.example.paco_bourse`, version 0.1.0, versionCode 2001, minSdk 24, targetSdk 36, uniquement `arm64-v8a`.
- Signature APK v2 vérifiée avec `apksigner`. Certificat de développement Android Debug ; aucune clé privée incluse dans le dépôt.
- Archive APK contrôlée : 58 fichiers WebP originaux inclus.

## Artifact

Fichier : `paco-bourse-0.1.0-arm64-debug.apk` — 93 701 239 octets.

SHA-256 : `9d53db71665b6987e4e838de9f39e74e00a8ef64a3ad696fc57c119b8e1a79ad`.

La signature de développement varie selon l'environnement de compilation. Une future alpha signée avec une autre clé peut exiger une désinstallation, qui efface la sauvegarde locale. Une signature stable de distribution reste à configurer hors du dépôt.

## Non vérifié / non livré

Pas d'installation sur téléphone physique, pas de compilation iOS, pas de test de charge cloud ni d'accès à un Firebase de staging. L'API est préparée mais non raccordée à l'application. Les contrôles automatisés ne remplacent pas ces validations.

Le workflow GitHub est fourni pour reproduire les vérifications et récupérer un APK ARM64 comme artifact ; il n'a pas encore été exécuté sur GitHub dans cette session.
