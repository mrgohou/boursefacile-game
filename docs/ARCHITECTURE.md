# Architecture de l'édition Kotlin

## Isolation de la version Flutter

Projet Android autonome à la racine : il ne fait pas appel au SDK Flutter, au backend de la démo Flutter ni à une bibliothèque Unity. Les versions précédentes restent dans leurs branches existantes. L'identifiant Android de cette édition est distinct pour éviter le remplacement silencieux des données.

Le code Kotlin implémente les mêmes invariants économiques, seuils de quartiers et budgets de puzzle. Le générateur aléatoire est celui de Kotlin : une grille ne doit pas être attendue identique à la grille Dart. Les données persistées ne comprennent pas les pièces d'une partie en cours. Une rotation conserve le ViewModel ; une fermeture de processus ramène à la ville, sans crédit de victoire fictif.

## Couche domaine

`Player` porte l'état de progression. Chaque action retourne un nouvel état validé : récompense unique, progression séquentielle, solde borné, portefeuille connu, frais, propriété des terrains, construction sur terrain libre, seuils de gains et cohérence des cartes. La démonstration de dividende conserve la valeur totale en ajustant simultanément cash et cours.

`PuzzleEngine` gère les alignements et la gravité. `Frame` et `Motion` décrivent les échanges, retours de coups invalides, effacements et chutes. Une tentative invalide ne consomme pas de coup. Les cascades résolues restent distinctes du rythme de leur affichage. Le chrono utilise `SystemClock.elapsedRealtime`, insensible aux changements de date du téléphone. Une permutation déjà résolue gagnante avant le délai ne perd pas sa victoire à cause de l'animation.

## Données et orchestration

`PacoViewModel` expose un `StateFlow<UiState>`. Il contrôle navigation, partie active, chrono, sérialisation des mutations par `Mutex` et annulation des tâches de partie. `PlayerRepository` effectue un commit SharedPreferences sur IO. En cas d'erreur, le modèle observable ne reçoit pas l'achat. Les gagnants sont persistés dès la résolution, indépendamment du bouton choisi ensuite.

`PlayerCodec` lit les formats PACO connus v1/v2/v3/v4. Il refuse les types et prix incohérents, les constructions orphelines et les doubles identifiants. L'UI demande confirmation avant de remplacer la progression par un import. Le format peut servir de base d'échange, mais il faut un export explicite depuis l'autre application ; Android isole les sauvegardes selon l'identifiant du package. L'APK compagnon ne contient pas les données de ses joueurs.

## Présentation et cycle de vie

Compose Material 3 et Canvas rendent l'ensemble des écrans. Les six sprites sectoriels sont préchargés ; le bouton de démarrage attend leur disponibilité. Chaque case du plateau expose aussi une action sémantique accessible. Les boutons sont libellés et ne se distinguent pas uniquement par leur couleur. Les contenus longs et les dialogues défilent, avec cibles tactiles d'au moins 48 dp. Le réglage de durée des animations Android est respecté.

Les assets décodés sont conservés en mémoire de composition. Les villes utilisent un terrain précalculé et des sprites ; aucun moteur 3D lourd n'est requis. L'audio est indépendant des règles et ne bloque pas le jeu. `MainActivity` coupe/reprend l'ambiance et réconcilie le délai au retour au premier plan.

## Extension future

Un compte connecté nécessite un dépôt distant authentifié et autoritaire : les soldes locaux ne sont pas des preuves de gain serveur. Les 45 niveaux à collectes/cadenas du catalogue compagnon demandent leurs mécaniques dédiées avant activation. Cette alpha fournit une base Kotlin native jouable ; la publication store exige une signature et des essais sur les téléphones cibles.
