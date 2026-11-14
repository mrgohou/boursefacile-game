# PACO 0.3 — Direction artistique

## Intention

Conserver la navigation ville / propriétés / cartes / puzzles, avec une présentation de jeu casual chaleureux. Les références Township et Candy Crush guident la composition, la profondeur, les retours et la lisibilité ; aucun de leurs éléments graphiques n'est intégré.

## Système visuel

- Ville : jardin tropical original illustré en volume, cacao, palmiers, cultures, eau turquoise, fontaine et allées pavées. Les bâtiments interactifs restent des éléments distincts de la carte, avec leur état de propriété réel. Aucun bâtiment décoratif n'est présenté comme acquis.
- Commandes : surfaces crème éclairées, bord blanc fin, ombre courte colorée, accents bleu et or. Un seul bouton principal, Jouer. Menu et ressources restent en haut ; inventaires et action principale en bas.
- Puzzle : fond lavande dégradé, plateau violet contrasté, symboles sectoriels brillants, score et coups regroupés dans une plaque crème, étoiles dorées et encouragements originaux.
- Typographie : Nunito variable embarquée, licence OFL conservée. Poids 600–900 pour les niveaux de lecture. Texte financier et pédagogique redimensionnable.
- Rythme : grille d'espacement 4/8 dp, rayons 16–22 dp, commandes d'au moins 48 dp, effets de pression 150 ms, mode sans animations respecté. Aucun changement de logique économique ni ajout de vies limitées ou de monétisation.

## Ergonomie et performance

Carte déplaçable et zoomable avec commandes visibles ; informations détaillées accessibles dans les fiches. Le cadrage initial garde les trois secteurs dans le champ. Le terrain est une image originale précalculée, séparée des éléments animés et des zones tactiles ; aucune scène 3D lourde n'est ajoutée. Images mises en cache et animations isolées. Les réglages audio, la reprise, les sauvegardes et le démarrage AOT/Skia de compatibilité sont conservés.

## Ressources

- Terrain original généré pour PACO avec image_gen ; ce fond ne contient ni texte ni commandes. Les véhicules, passants et bâtiments sont rendus séparément.
- Les 58 WebP PACO existants et les 11 sons originaux sont conservés.
- Font Nunito : Google Fonts, SIL Open Font License, `assets/fonts/OFL.txt`.
- Revue ergonomique selon le skill UI/UX Pro Max, adaptée à Flutter plutôt qu'à son exemple React Native.
