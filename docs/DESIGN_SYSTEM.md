# PACO Bourse — système visuel mobile

## Intention

Une ville calme, des décisions lisibles et un guide accueillant pour les familles. La simulation et les entreprises sont fictives. Le graphisme ne promet ni gain réel ni rendement.

`buildPacoTheme()` fournit Material 3. Utiliser les rôles de `Theme.of(context).colorScheme` et de `textTheme` dans les écrans ; éviter les couleurs de texte codées directement. Aucun téléchargement de police ou d'illustration : police native et dessins vectoriels Flutter.

## Palette et contraste

| Usage | Valeur |
| --- | --- |
| Forêt, identité et actions en thème clair | `#163C32` |
| Citron, accent et conteneurs secondaires | `#D9EE83` |
| Crème, fond clair | `#F6F7F2` |

Texte blanc sur forêt, forêt sur citron et forêt sur crème sont les associations prévues. Le citron sur blanc ne convient pas au texte courant. Les tons secondaires, bordures et états proviennent de `ColorScheme.fromSeed`. Vérifier tout nouveau couple, en particulier le texte atténué : cible WCAG AA de 4,5:1 pour le texte courant et 3:1 pour les composants et grands textes.

Le thème sombre s'obtient avec `buildPacoTheme(brightness: Brightness.dark)`. Il utilise des surfaces sombres et des actions citron avec texte forêt. Respecter les couleurs `onSurface`, `onPrimary` et `onSecondaryContainer` ; ne pas réutiliser mécaniquement un fond ou un texte du thème clair.

## Composition et interaction

- Marges d'écran de 16 à 24 dp ; cartes arrondies de 20 dp et espacement courant de 8, 16 ou 24 dp.
- Zone tactile minimale de **48 × 48 dp**. Le thème applique ce minimum aux boutons ; toute carte cliquable et toute interaction de puzzle doit le conserver. Une illustration de carte peut être plus petite, sa zone interactive non.
- Placer les contenus et commandes sous `SafeArea`, y compris les écrans de jeu. La navigation Material 3 garde ses libellés visibles. Tenir compte du clavier via `MediaQuery.viewInsetsOf(context)`.
- Présenter les montants avec une unité explicite « FCFA-jeu ». Une hausse, une baisse, une sélection ou une erreur comporte un texte, une icône ou une forme en plus de sa couleur.
- Les titres restent mesurés (21 à 30 sp). Ne jamais bloquer `TextScaler`, imposer un `maxLines: 1` à une consigne essentielle, ni enfermer du texte dans une hauteur fixe. Tester les petits écrans et une échelle de texte de 200 %, avec défilement et passage en colonne si nécessaire.
- Expliquer les états désactivés par un texte adjacent. Ajouter un libellé sémantique et une infobulle aux boutons à icône seuls. Conserver un focus visible pour clavier et technologies d'assistance.

## Illustrations natives

`PacoMascot(size: 112)` représente Paco. `CityIllustration(height: 180, ownedSectors: 0)` représente trois bâtiments ; `ownedSectors` est borné à 0–3. Les bâtiments détenus portent aussi un drapeau, pour éviter une distinction par couleur seule. Ces images ne constituent pas un tableau de portefeuille : les noms, quantités et montants doivent exister en texte séparément.

Chaque widget fournit **une seule alternative sémantique** avec `excludeSemantics: true`. Si l'image est décorative et qu'un texte adjacent exprime déjà exactement son contenu, l'appelant peut l'envelopper dans `ExcludeSemantics` pour éviter une répétition au lecteur d'écran. Les dessins sont originaux, transparents, sans assets externes, et ne dépendent pas du réseau.

## Mouvement, son et reprise

Les illustrations sont statiques. Pour les futures animations, respecter `MediaQuery.disableAnimationsOf(context)` : supprimer les déplacements et les répétitions, conserver une confirmation immédiate lisible. Éviter les flashs. Une information sonore possède un équivalent visuel ; les commandes sonores restent explicites.

Une reprise après interruption doit afficher l'état sauvegardé et demander une action explicite avant une nouvelle partie. Ne pas annoncer une synchronisation sécurisée dans la démo locale.

## Vérification avant intégration

Tester thèmes clair/sombre, TalkBack et VoiceOver, navigation clavier, texte à 200 %, orientations et petits écrans, zones système, clavier ouvert, contraste des nouveaux composants et interactions de 48 dp. Les tests de rendu doivent inclure les montants longs et les messages d'erreur multilignes.
