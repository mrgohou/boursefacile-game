# PACO 0.8 — revue UX jeu vidéo

## Commandes en pâte à modeler

Les CTA partagés emploient une silhouette arrondie, une bordure lumineuse, une ombre colorée et une profondeur qui diminue à l'appui. Les libellés Nunito sont renforcés. Les boutons d'achat et de vente gardent leurs couleurs fonctionnelles et leur texte ; aucun état ne dépend de la seule couleur.

`GameAction` conserve son API et utilise désormais InkWell dans un Material : retour d'appui et activation clavier remplacent le geste seul. Les états désactivés ne répondent plus visuellement à un appui. La réduction des animations supprime le changement progressif d'échelle. Les surfaces par défaut et les libellés de navigation prennent en compte le mode sombre.

Les boutons Material restent à 48 dp minimum et grandissent avec leurs libellés. Les tests d'écran compact et de texte agrandi doivent être rejoués après intégration avec les autres modifications. Une ombre n'est pas une preuve de contraste : vérifier les textes sur les surfaces réellement utilisées et sur appareil.

## Plateau 9 × 9

Un écran de 360 dp ne peut pas contenir neuf colonnes de 48 dp : 9 × 48 = 432 dp, avant les marges. Il faut éviter d'annoncer des cases de 48 dp si le plateau est simplement réduit à la largeur de l'écran.

Prévoir un plateau zoomable avec verrouillage du déplacement pendant un échange, un bouton de recentrage et un mode de sélection alternatif. Une sélection par deux taps évite le glissement précis ; une liste de commandes accessibles peut proposer les directions autour de la case choisie. Une loupe ou un zoom doit réellement agrandir les zones de touche, pas uniquement les images. Réserver les gestes de pincement au plateau et les gestes de défilement aux pages de contenu.

## Hiérarchie de partie

Afficher au premier plan trois groupes : objectif principal avec progression, chrono, coups restants. Les objectifs secondaires tiennent dans une ligne défilante ou un panneau consultable. Exemple : « Cadenas 2/6 · Cacao 18/30 ». Le symbole et le nombre doivent accompagner la couleur.

Les consignes restent une fenêtre avant le départ ; montrer les pièces spéciales concernées et un exemple concret de coup parfait. Un coup parfait doit être décrit comme un échange créant un alignement direct d'au moins quatre pièces, si telle est la règle retenue par le moteur. Les cascades ne doivent pas être comptées silencieusement comme des échanges parfaits.

En fin de partie, garder un titre de résultat, le détail des objectifs et deux actions hiérarchisées. La récompense enregistrée doit être confirmée avant de permettre un achat. Les animations de résultat restent brèves et désactivables.

## Ville et pédagogie

Une nouvelle acquisition doit proposer « Placer dans ma ville », puis un choix explicite du quartier et de l'emplacement. Toujours conserver une action Annuler et un accès à Mes propriétés. Les terrains supplémentaires doivent annoncer leur capacité et leur coût avant l'achat. Distinguer les quartiers décoratifs des bâtiments représentatifs des titres détenus.

Un quiz pratique doit présenter une situation, les hypothèses de frais et de risque, puis expliquer le raisonnement. L'adaptation doit être présentée comme un entraînement pédagogique ; elle ne doit pas promettre une stratégie rentable ni recommander automatiquement d'acheter un titre réel. Le joueur doit pouvoir connaître et réinitialiser les données de progression utilisées pour adapter la difficulté.

## Contrôles de livraison

Tester 320/360/390 dp, texte à 200 %, mode sombre, réduction des animations, reprise après arrière-plan et touches clavier. Mesurer séparément l'ergonomie 9 × 9 ; les contrôles de l'ancien plateau 7 × 7 ne valident pas automatiquement le nouveau.
