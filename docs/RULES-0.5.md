# Règles de partie — 0.5.0

## Chrono et difficulté

| Niveau | Objectif de points | Coups maximum | Temps |
|---|---:|---:|---:|
| 1 | 650 | 24 | 60 s |
| 2 | 790 | 23 | 60 s |
| 3 | 930 | 22 | 70 s (+10) |
| 4 | 1 070 | 21 | 75 s (+15) |
| 5 | 1 210 | 20 | 75 s (+15) |
| 6 | 1 350 | 19 | 90 s (+30) |

La consigne apparaît dans une fenêtre à l'ouverture de chaque tentative et après Rejouer. Le plateau n'accepte aucun geste avant « C’est parti ». Le chrono démarre à ce clic, une fois le plateau chargé. Consigne et explications gestuelles ne sont plus affichées sous le plateau. L'aide reste accessible à la demande.

Le délai continue pendant l'aide et les passages en arrière-plan. Au retour à l'application, l'échéance est contrôlée avant de reprendre le moteur. Les entrées sont également contrôlées au moment du geste : le délai de rafraîchissement du chrono ne permet pas de jouer après zéro.

L'objectif doit être atteint avant l'échéance et avant épuisement des coups. La résolution d'un échange valide est atomique : si un échange accepté avant l'échéance atteint l'objectif, la fin de son animation ne peut pas retirer la victoire. À la fin, les entrées, le moteur et le chrono sont arrêtés. Une seule issue et une seule récompense sont possibles.

## Fenêtres de résultat

- Victoire : « GAGNE » en lettres arrondies avec extrusion, lumière et ombres donnant un relief argile, au-dessus de la carte de résultat. Enregistrement immédiat et bouton vers la notion pédagogique.
- Défaite : « PAS DE CHANCE », raison de la fin (temps ou coups), bouton Rejouer.
- Les deux issues proposent Menu principal. Ce bouton revient à la ville ; après une victoire, il ne force pas l'ouverture du quiz. La notion reste disponible ensuite et la victoire enregistrée est conservée.
- Le titre effectue un rebond élastique unique de 850 ms. L'animation est supprimée en mode de réduction des mouvements ; la mise en relief reste visible. Le texte est natif, net et accessible à toutes les densités, sans image de titre figée.
- Les fenêtres ont un contenu défilant pour les petits écrans et le texte agrandi. Elles ne se ferment pas sur un toucher accidentel du fond.

## Acquis et transactions

Depuis Mes propriétés, toucher une entreprise ouvre son détail. Le bouton vert « Acheter plus » apparaît lorsqu'au moins une part est détenue ; sans part, il affiche « Acheter une part ». Le bouton rouge « Vendre » cède une part à la fois. Libellés et icônes distinguent aussi les actions, indépendamment de la couleur.

Le coût d'achat et le produit net de vente après frais sont affichés. Les restrictions de progression, de solde et de propriété sont conservées. Les terrains et constructions restent distincts des parts d'entreprise et ne sont pas mis en vente par ce bouton.

## Vérification

Tests du démarrage différé, de l'expiration, du refus de geste tardif, du rejeu, d'une victoire avant échéance, de l'enregistrement unique et du retour à l'accueil. Parcours réel Acheter plus / Vendre vérifié avec couleurs distinctes et comptabilisation des frais. Les autres tests de ville, catalogue et sauvegardes restent inclus. Validation sur téléphone physique à compléter.
