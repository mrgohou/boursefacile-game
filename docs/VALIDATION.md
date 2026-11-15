# Validation — 15 novembre 2026

## Exécuté

- Node : 7 tests réussis. Catalogue, 30 objectifs et entraînement, 600 plateaux avec cascades, refus des coups interdits, transactions et récompenses uniques, achat séquentiel des terrains, échec de persistance, navigation du contrôleur Construct avec runtime simulé.
- g++ C++17 avec `-Wall -Wextra -Werror -pedantic` : cœur indépendant de puzzle compilé ; 600 plateaux et suites de coups contrôlés.
- Python : JSON, références des objets/scripts/images Construct, archive ZIP, cohérence des trois catalogues, syntaxe du bootstrap Python Unreal, présence des 21 FBX et du descripteur Unreal.
- JavaScript : vérification de syntaxe de `main.js`.

## Non exécuté

- Ouverture ou aperçu Construct, export Construct Android.
- UnrealBuildTool, UnrealHeaderTool, compilation du module C++, import FBX/Python, création réelle du niveau, Play-in-Editor, cook Android.
- Tests tactiles sur appareil, rendu, son, performances ou synchronisation entre éditions.

Les outils des deux éditeurs ne sont pas installés dans cet environnement. La publication concerne exclusivement des sources de prototypes. Les tests indépendants ne remplacent aucune des validations moteur ci-dessus.
