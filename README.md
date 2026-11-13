# PACO Bourse — v0 (prototype)

Jeu de lancement de **Bourse Facile** : on aligne des tuiles pour épargner, on investit dans de vraies entreprises de la BRVM, et Paco l'éléphant explique la bourse ville après ville.

> Version de test. Monnaie fictive (FCFA-jeu), aucun argent réel, aucun conseil d'investissement.

## Lancer

```sh
npm install
npm run dev       # http://localhost:5173
npm test          # moteur du puzzle + équilibrage des 45 niveaux
npm run build
```

## Contenu de ce prototype

- **Puzzle match-3** (Phaser) : grille 7×7, tuiles des secteurs (cacao, téléphone, billet, bidon, ampoule, engrenage), spéciales **Dividende** (4 alignées), **AGO** (L/T), **Diversif** (5 alignées), cadenas **Frais** (villes 10+).
- **15 villes × 3 niveaux** générés par `scripts/gen-levels.mjs` → `src/data/levels.json`.
- **Paco** : intro de ville, objectif avant chaque niveau, bilan, astuce après 2 échecs.
- **Progression** : étoiles, épargne (1 500 + 150 par coup restant), titres, ville suivante à 5 étoiles sur 9.
- **Sons et musique** synthétisés (Web Audio), bouton couper le son.
- Sauvegarde locale (Firebase viendra ensuite).

## Structure

- `src/engine/` : logique pure du puzzle + tests (`balance.test.ts` fait jouer un robot sur chaque niveau).
- `src/game/PuzzleScene.ts` : rendu Phaser et animations.
- `src/components/` : écrans React (niveau, Paco).
- `src/data/` : villes, niveaux.
- `public/paco/`, `public/tiles/` : visuels.

## Prochaines étapes

Ma Ville (bâtiments = entreprises, vrais cours), guichet SGI, cartes, quiz de Paco, Score PACO, comptes Firebase, instantané quotidien brvm.org.

Conception complète : GDD v0 dans le projet « Jeu PACO Bourse Facile ».
