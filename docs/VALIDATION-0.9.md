# Validation Flutter 0.9.0

## Contrôles exécutés

- **89 tests Flutter** de l’application et des règles réussis, dont dix nouveaux contrôles de récompenses, migrations, séries et villes.
- **4 contrôles d’interface et de capture** réussis : dialogue de récompense et collecte, échec de collecte à texte 200 %, plateau avec pions culturels, ville moderne. Captures revues ; retrait du fond blanc des bâtiments et cadres de pions corrigés puis contrôlés de nouveau.
- **flutter analyze : aucun problème** après les corrections de style. Format Dart appliqué.
- Achat des 31 terrains et construction rurale sur chacun atteignables avec les gains finis de campagne et Voyage ; sauvegarde et relecture vérifiées.
- Séries de 5/10 quiz et niveaux, rupture après faute/reprise, persistance après relance, absence de récompense rétroactive v6, interdiction de double collecte et de cadeaux dupliqués.
- Compilation Android ARM64 **profile/AOT** par Flutter/Gradle.
- Vérification du contenu ZIP/APK et de la signature avec les outils Android ; même certificat de développement que la version 0.8.0.

Les tests utilisent Flutter Test et le moteur de rendu Flutter. Aucun téléphone ni émulateur Android n’a été utilisé. Les captures ne constituent pas une mesure de fréquence d’images ou une validation du rendu sur tous les GPU. Les planches générées sont des évocations artistiques originales à faire relire pour une fidélité patrimoniale documentaire.

La chaîne de compilation nécessite l’accès aux caches Gradle dans `/dev/shm` de l’environnement de travail. Un premier lancement de tests de capture a manqué d’espace temporaire : le cache de tests généré a été nettoyé, puis les contrôles relancés avec succès. Aucun fichier de sauvegarde du jeu n’a été supprimé.
