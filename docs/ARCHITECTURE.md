# Architecture Unity

Le projet reste indépendant des branches Flutter et Kotlin.

`PacoApp` charge les données locales, valide la sauvegarde et construit la navigation. Le domaine `Paco.Domain` ne référence pas UnityEngine : il peut être compilé et exécuté dans un processus .NET isolé. Il contient les 30 paramètres de niveau, les leçons, les règles de récompense, les transactions fictives et la progression des quartiers et du Voyage.

`MatchEngine` décide entièrement du résultat d'un échange avant son animation. Ses snapshots restent indépendants du plateau mutable. `PuzzleView` affiche la séquence d'échange, annulation, disparition, chute et éventuel mélange. Un nouveau geste est refusé pendant la résolution d'un tour ; les actions de navigation restent disponibles, mais quitter attend la fin de la combinaison. Le chronomètre ne permet plus d'accepter un mouvement après sa date limite. Une combinaison acceptée à temps peut finir son animation et donner sa victoire.

`RoundClock` reçoit un temps monotone. Android emploie `SystemClock.elapsedRealtime`, qui inclut le temps en veille. Les autres cibles utilisent Stopwatch. Le retour au premier plan recalcule le délai ; la musique, elle, se met en pause. Le jeu ne doit jamais dépendre du nombre de frames pour accorder les secondes.

`Player` valide les invariants et produit une copie lors d'une transaction. `SaveStore` écrit et synchronise un fichier temporaire, puis remplace atomiquement la sauvegarde avec conservation d'un secours. `PacoApp` ne publie le nouveau solde qu'après cette écriture. Une erreur de lecture conserve le fichier pour récupération ; elle ne recrée pas silencieusement un solde initial.

Le codec v4 lit les v1/v2/v3 historiques, limités à six étapes. L'import est un remplacement confirmé, jamais une somme de récompenses ou de portefeuilles. Les trois éditions utilisent des identifiants Android distincts et ne lisent pas automatiquement les fichiers privés des autres applications. Les exemples de tests utilisent uniquement des données synthétiques.

`CityView` instancie les modèles FBX à partir de `world.json`. Les bâtiments du centre-ville sont décoratifs ; les six parcelles supplémentaires reflètent `ownedPlots` et `townBuildings`. Les habitants et véhicules suivent des itinéraires simples sans simulation de trafic. `PacoAssets` partage la palette et renforce le brillant des matériaux de puzzle. Les FBX restent modifiables dans Blender via le générateur livré.

L'éditeur prépare URP, la scène et Android avec `Paco.Editor.ProjectSetup`. Les réglages générés sont des assets Unity et se versionnent après une première ouverture validée. La première génération ne remplace pas une scène existante.

Le backend n'est pas connecté. Les gains restent locaux et ne constituent pas une preuve de récompense pour un serveur. Aucun achat intégré, compte, paiement ou retrait réel n'est créé.
