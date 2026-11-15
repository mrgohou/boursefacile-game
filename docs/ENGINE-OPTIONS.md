# Outils et moteurs : décisions de cette livraison

Le moteur effectivement livré dans l’APK reste Flutter + Flame, en Dart. Les modèles argile existants sont des images pré-rendues ; l’interface et les effets sont rendus en 2.5D. Aucun moteur Unreal ou Construct 3 n’est embarqué.

## Alternative ouverte à étudier

Godot est l’alternative retenue pour une éventuelle édition 3D ouverte : moteur 2D/3D, éditeur de scènes, animation, shaders, export Android et licence MIT. La licence a été vérifiée dans le dépôt officiel https://github.com/godotengine/godot/blob/master/LICENSE.txt. Godot 4.6.3 est disponible dans cet environnement. Les objectifs de performance devront être mesurés sur les appareils cibles, et une migration de moteur reste un projet distinct.

GDevelop est une option ouverte intéressante pour une conception 2D plus visuelle. Bevy est une alternative Rust pour une équipe très technique. Ces options ne remplacent pas automatiquement l’architecture ou les sauvegardes du jeu actuel. Le terme « Unity Spark » ne définit pas ici un format de projet transférable ; la comparaison porte sur des moteurs de création et d’exécution.

## Construct 3 et Unreal Engine

Construct 3 est un outil distinct soumis à ses conditions d’utilisation ; il ne peut pas corriger directement du code Flutter/Flame. Aucun éditeur Construct 3 ou projet autorisé n’est connecté ici. Une passerelle de scénarios JSON est fournie dans `docs/interop/reference-replay.json` pour comparer ultérieurement une implémentation secondaire : grille, échanges, états, scores et budgets de coups. Aucun runtime Construct n’est annoncé comme intégré.

Unreal Editor et ses outils de rendu ne sont pas disponibles dans les outils ou l’environnement de cette session. Le système de design Flutter a été retravaillé avec la compétence UI/UX Pro Max et le spécialiste UX ; l’icône a été générée à partir de la référence de Paco. Aucun document Figma connecté n’a été modifié. Une vraie intégration Unreal implique une production 3D et des vérifications supplémentaires ; elle n’est pas simulée par une capture ou une image générée.

Le validateur GDScript livré peut vérifier la cohérence structurelle d’un replay avec un moteur indépendant. Il ne reproduit pas les règles complètes du Match-3 et ne prouve ni la parité d’un second moteur ni l’absence de bugs.
