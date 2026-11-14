# Alpha 0.2.0 — Ville et puzzles animés

- La ville remplace le tableau de bord à l'accueil. Carte isométrique déplaçable et zoomable, routes, rivière, pont, végétation, véhicules et passants.
- Quatre accès permanents : Propriétés, Mes cartes, Jouer, Guichet. Les acquisitions affichent le bâtiment correspondant ; les cartes d'entreprise restent dans la collection après une vente.
- Parcours de six puzzles ; glissement d'une tuile vers sa voisine ou sélection par deux taps. Échanges, retour des coups invalides, disparition, gravité, remplissage et cascades animés ; saisie bloquée pendant la résolution.
- Deux boucles musicales et neuf bruitages synthétisés originaux, interrupteurs indépendants, pause en arrière-plan et mode mouvements réduits.
- Migration des sauvegardes v1 vers v2 avec conservation des avoirs et de la progression. Enregistrement des victoires dès leur validation.

## Validation

Analyse statique sans erreur ; tests du moteur, gestes, chronologie d'animation, invariants économiques, migration, collections et interfaces compactes avec texte à 200 %. Captures Flutter natives inspectées à 390 × 844 dp. APK Android ARM64 de développement ; essais sur téléphone physique encore nécessaires pour valider le confort tactile et l'audio selon l'appareil.

## Limites

Démo locale, entreprises et monnaie fictives. Aucun service financier connecté. Trois secteurs possédables ; les paliers graphiques supérieurs ne constituent pas encore un mécanisme d'amélioration. Les inspirations de jeux concernent l'organisation et les interactions ; les ressources PACO et les sons sont propres au projet.
