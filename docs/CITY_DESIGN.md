# Ville PACO — scène mobile

`CityMap` occupe le viewport. Le HUD, la navigation et l’inventaire textuel restent à la charge de l’écran parent. La composition originale utilise nos rendus PACO ; elle ne reproduit pas les références de jeux commerciaux.

## Monde et interactions

Monde 2D de 1 400 × 1 000 unités : îlot de pelouse en diamant, relief de berge, deux routes diagonales, place-fontaine, rivière, pont, parc, bancs et fleurs. Positions fixes en coordonnées isométriques ; éléments interactifs ordonnés par profondeur du point au sol. Les décorations sont vectorielles, les bâtiments WebP sont précalculés : aucun shader ou moteur 3D.

- Télécom Horizon : point au sol `(920, 475)`.
- Cacao des Lagunes : `(560, 515)`.
- Banque Baobab : `(730, 655)`.
- Guichet : bâtiment `services-1`, point d’accès au nord de la place.

Seules les sociétés avec `holdings[id] > 0` affichent un bâtiment acquis, toujours au palier 1. Sinon, une parcelle vide et un panneau « + » ouvrent le guichet de l’entreprise via `onBuildingTap(id)`. Une vente de la dernière part restaure immédiatement la parcelle. Aucune règle de croissance en cinq paliers n’est inventée.

Le guichet central utilise `onGuichetTap`. Le parent doit fournir ce callback pour activer son ouverture. L’image du guichet est un repère de service, pas une participation possédée par le joueur.

## Navigation et vie

`InteractiveViewer` assure glisser et pincer, entre 0,5× et 2,3×. Le cadrage initial et le recentrage visent le centre `(700, 500)` ; un changement de dimensions recadre le monde. Trois commandes de 48 dp proposent agrandir, réduire et recentrer, avec infobulles. Le parent garde ces commandes dégagées de son HUD.

Deux passants utilisent les assets existants. Deux petites voitures vectorielles et des rides d’eau partagent un contrôleur de dix secondes. Le terrain et les bâtiments sont séparés de la couche animée par `RepaintBoundary`. `reducedMotion: true` ou la préférence système d’animation réduite arrêtent le contrôleur ; la scène conserve une pose fixe. Les décorations animées n’interceptent pas les interactions et ne polluent pas le lecteur d’écran.

## Accessibilité et limites

Les bâtiments comportent une alternative sémantique avec le nom, la quantité et l’action ; la propriété n’est pas portée uniquement par une couleur. À l’échelle minimale, les grandes parcelles conservent une cible supérieure à 48 dp. Les labels sont redimensionnables et les images comportent un repli si le chargement échoue. L’inventaire accessible du parent reste l’accès alternatif aux sociétés, indépendant du déplacement sur la carte.

Les fichiers ne sont pas redimensionnés ; le décodage est borné. Le chemin d’un asset ne signifie pas que son pivot ou tous les paliers ont été validés. Les positions ont été composées pour le prototype et devront être contrôlées visuellement sur les petits écrans Android et en grande police.
