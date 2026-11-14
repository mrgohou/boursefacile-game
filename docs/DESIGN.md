# Direction visuelle et ergonomie

Compétence appliquée : UI/UX Pro Max, lue via son SKILL.md cloud. Ses principes d'accessibilité, de hiérarchie, de commandes tactiles et de feedback sont adaptés à Unity ; son guide d'implémentation React Native ne remplace pas la technologie demandée. Les scripts de recherche associés n'étaient pas accessibles via le fournisseur de skill.

## Ville

Caméra orthographique inclinée, toits teal et terre cuite, façades crème, canopées vertes, trottoirs et voies lisibles. La géométrie possède des biseaux, corniches, encadrements, auvents rayés et accessoires propres aux familles : antennes, colonnes, cheminées, panneaux photovoltaïques et caisses de cacao. La palette est partagée pour limiter le nombre de matériaux. Les éléments fixes sont regroupés pour le batching ; les habitants et véhicules restent mobiles.

Le terrain s'étend vers six parcelles à droite du canal. Un tap ouvre la fiche d'achat ou de construction. Les acquis restent accessibles par un bouton explicite, sans nécessiter un geste précis sur le monde. Les routes et emplacements ne sont pas encore repositionnables librement.

## Puzzle

Pièces réellement en 3D : cacao avec feuille et nervures, téléphone et écran, billets empilés, bidon, ampoule et engrenage. Silhouettes distinctes pour ne pas dépendre uniquement de la couleur. Matériaux de glaçage plus brillants que les bâtiments, cavités bleues et plateau violet. Le moteur génère les étapes d'échange, d'annulation, de disparition et de chute ; la vue anime chaque phase sans recalculer les règles au milieu d'une animation.

Les titres de résultat sont des meshes extrudés et biseautés, rendus dans une texture d'interface par une caméra dédiée. Un rebond bref accompagne leur entrée ; l'option Mouvements réduits le désactive avec les particules et les déplacements des habitants. Aucun effet n'allonge le temps autorisé pour accepter un déplacement.

## Interface mobile

Un écran principal sur la ville, quatre entrées en bas : Étapes, Acquis, Cartes, Agrandir. Voyage et réglages sont secondaires. Une seule action principale accompagne la prochaine mission. La consigne et le résultat sont des fenêtres dédiées, avec sortie explicite. L'ouverture d'une aide ne suspend pas le délai.

Le Canvas utilise une largeur de référence de 1080 pixels, safe area du téléphone, contenus défilants et boutons de 144 unités minimum, avec hauteur adaptée aux libellés. Les tailles équivalentes en dp, le texte agrandi et les gestes doivent être mesurés sur les appareils cibles. Le plateau dispose de glissement et de sélection par deux taps ; les commandes Unity restent également navigables au clavier. L'intégration d'un lecteur d'écran Android n'est pas validée et ne doit pas être annoncée comme disponible.

Palette sémantique : texte foncé `#244B50`, surface `#FFF5DF`, achat `#23674D`, vente `#AC4346`, secondaire `#7560AE`. Les couleurs sont accompagnées de libellés. Le HUD se limite au score, au temps et aux coups pendant le puzzle. Les transactions importantes demandent une confirmation du montant et des frais.

## Objectifs de performance à mesurer

Cible de conception 60 images/s sur appareil intermédiaire, avec ombres limitées, shaders URP Lit, matériaux partagés, géométrie compacte et effets courts. Ces valeurs sont des objectifs, pas des mesures. Profiler le nombre de draw calls, la mémoire, le chargement et la fluidité avant d'augmenter la densité de ville. Prévoir une qualité 30 images/s sur les appareils plus modestes après mesure.

Les rendus Blender livrés montrent la géométrie et les matériaux. Le rendu Unity/GLES3 sera différent : lumière indirecte, réflexion, antialiasing et post-traitement doivent être réglés et vérifiés sur téléphone.
