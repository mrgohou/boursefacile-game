# PACO Bourse Facile — variantes Construct 3 et Unreal Engine

Deux prototypes natifs éditables, livrés avec leurs sources. Construct 3 utilise des objets Sprite/Text de son runtime et des modules JavaScript. Unreal Engine utilise un module C++, des acteurs StaticMesh, une caméra orthographique et un HUD natif. Aucune des deux éditions n’embarque Flutter ou une WebView.

**Statut : prototypes de migration, non validés dans les éditeurs. Aucun APK Construct ou Unreal n’a été compilé.** Le moteur et ses licences doivent être installés séparément. Ces projets ne constituent pas une édition finale au niveau graphique de Township.

## Contenu livré

- Puzzle 9 × 9, six catégories, échanges par sélection ou glissement, cascades, score, chrono et limite de coups.
- 30 étapes de campagne, puis variantes d’entraînement calculées localement.
- Objectifs alternés : score, cadenas, récolte de 30 pions, sept alignements de quatre, activation de pièces spéciales, objectifs combinés.
- Guichet avec 48 entreprises : acheter/vendre, frais simulés, carte conservée après la vente. Le guichet se débloque après deux notions validées.
- Placement libre d’une entreprise détenue sur une des 16 cases de chaque terrain ; six extensions successives, conditionnées aux gains et au solde. La dernière vente retire le bâtiment.
- Catalogue commun de 40 quiz originaux et pratiques. La campagne en utilise les 30 premiers. Les cours sont des références historiques/simulées, sans connexion aux marchés.
- Ressources PACO : six pions 2D, mascotte et visuel de chargement ; 21 modèles FBX originaux fournis à Unreal.

Les règles et les données sont communes, mais chaque moteur conserve son implémentation. Les sauvegardes sont **séparées** : stockage navigateur `paco-construct-v1` pour Construct et `Saved/PacoUnreal-v1.json` pour Unreal. Aucun serveur de synchronisation, agent IA distant ou transfert automatique des sauvegardes Flutter n’est fourni.

## Ouvrir Construct 3

1. Dans une version récente de [Construct 3](https://editor.construct.net/), choisir **Ouvrir → Fichier**, puis `PACO-Construct3.c3p`. Une licence permettant les scripts JavaScript peut être nécessaire.
2. Le dossier `construct3/` contient aussi le projet décompressé `project.c3proj`.
3. Lancer l’aperçu de `Main` : vérifier le menu, le puzzle tactile, le retour au menu, les quiz, puis les transactions et le placement.
4. Valider ensuite l’export Android avec l’outil d’export Construct et sa chaîne Android. Le `.c3p` est une archive de **sources**, pas un jeu exporté.

Le script `python scripts/build_construct.py` reconstruit l’archive sans appeler Construct. Le format de dossier suit la structure du [projet public officiel de Scirra](https://github.com/Scirra/Ghost-Shooter-TypeScript) ; aucun contenu créatif de cet exemple n’est repris.

## Ouvrir Unreal Engine 5.5

1. Installer UE 5.5 et sa chaîne de compilation C++ : Visual Studio avec les outils Unreal sous Windows, ou la chaîne préconisée par Epic sur votre système.
2. Générer les fichiers de projet à partir de `unreal/PacoUnreal.uproject`, puis compiler la cible **PacoUnrealEditor**. Le fichier n’a pas été compilé par Unreal dans cet environnement.
3. Ouvrir le projet. La carte `Main` n’est pas encore fournie au format binaire `.umap` : elle est créée dans l’éditeur à l’étape suivante.
4. Activer les plugins Python Editor Script et Editor Scripting Utilities si nécessaire. Dans **Tools → Execute Python Script**, exécuter `unreal/Scripts/bootstrap_unreal.py`. Il importe les 21 FBX, le visuel PACO et crée `/Game/Paco/Maps/Main`. Il refuse de remplacer une carte Main existante.
5. Ouvrir Main, lancer **Play**, puis vérifier caméra, matériaux, toucher/souris, puzzle, quiz et sauvegarde. Le code utilise des cubes de repli si un modèle importé manque.
6. Pour Android, installer le SDK/NDK correspondant à UE 5.5, effectuer le cook/package ARM64 et tester sur un appareil réel. Aucun export Android de ce projet n’a été produit ici.

Le HUD et les acteurs sont construits en C++, sans Blueprint obligatoire. L’éclairage mobile par défaut n’active pas Lumen. Le Python d’import est un outil d’éditeur, pas une dépendance du jeu exporté.

## Limites de cette première variante

Les interactions et l’interface restent fonctionnelles et simples. Construct utilise actuellement des dialogues navigateur pour les consignes/résultats. Unreal possède des panneaux natifs. Les animations argile, les déplacements interpolés des pions, les effets de destruction, l’habillage complet des boutons, la musique et les bruitages ne sont pas intégrés à ces deux prototypes. Les images de chargement sont livrées comme ressources ; leur branchement au chargement natif de chaque moteur reste à réaliser. Aucun rendu final, rythme de 60 images/seconde ou comportement Android n’est attesté.

Les modèles et scripts d’import Unreal doivent être validés dans l’éditeur. L’UI Canvas Unreal doit encore recevoir une passe de mise en page, de retour visuel et de contrôle des textes longs sur mobile. Les sauvegardes et la télémétrie n’ont pas de serveur commun. Construct ne sert pas à corriger automatiquement Unreal : chaque moteur a son cycle d’import, de tests et de compilation.

## Vérification reproductible hors éditeur

```sh
node --test tests/*.test.mjs
g++ -std=c++17 -Wall -Wextra -Werror -pedantic -I unreal/Source/PacoUnreal/Public tests/rules_cpp.cpp -o /tmp/paco-rules-test
/tmp/paco-rules-test
python scripts/build_construct.py
python tests/verify_projects.py
```

Les tests du contrôleur Construct utilisent un runtime simulé. Ils ne prouvent pas la compatibilité des API dans l’éditeur. Les tests C++ compilent uniquement `PacoRules.h`, sans en-têtes Unreal ; ils ne prouvent pas la compilation du module Unreal. Voir [le rapport de validation](docs/VALIDATION.md).
