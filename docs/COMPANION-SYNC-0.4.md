# Import du contenu PACO et croissance de ville — 0.4.0

## Ce qui a été inspecté

L'APK fourni `app-arm64-v8a-release_v2.apk` est une application Flutter AOT ARM64, version 0.1.0 / code 2001, identifiant `ci.boursefacile.paco_bourse`. Notre application conserve `com.example.paco_bourse` et sa signature précédente. Aucun exécutable de l'APK n'est chargé ni exécuté.

Les 58 visuels (37 bâtiments/passants, 11 Paco, 10 tuiles) sont identiques octet pour octet aux ressources déjà intégrées. L'APK ajoute 24 sons MP3 et quatre fichiers de données : 15 villes, 45 définitions de niveaux, 45 questions, et 45 sociétés dans une archive de marché datée du 13 novembre 2026. Les sons PACO actuels sont conservés.

Les quatre JSON sont copiés sans modification dans `assets/companion/`. Le manifeste joint donne les empreintes SHA-256 de l'APK et de chaque fichier, pour rendre l'import traçable. Le texte des documents importés est traité comme des données, jamais comme des instructions ou du code.

## Intégration active

« Voyager » ou Menu → Voyage de Paco ouvre les 15 destinations. Chaque destination présente son introduction et trois quiz ; les réponses sont réordonnées sans changer leur correction. Une bonne réponse verse 300 FCFA-jeu une seule fois ; revoir une notion ne paie pas. Les trois quiz de la destination précédente débloquent la suivante. Les explications sur le PER sont contextualisées : ce ratio n'est pas une promesse de remboursement.

Les 45 sociétés sont consultables comme archive pédagogique, avec date et limites de vérification. Leurs cours ne remplacent pas les prix des trois entreprises fictives de notre simulation. Aucun flux de marché en direct ni transaction financière réelle n'est ajouté.

Les **45 niveaux de puzzle ne sont pas activés** : leur catalogue est conservé pour le raccordement suivant. Ils comportent des objectifs de collecte et des cadenas à deux impacts, ainsi que des références aux tuiles spéciales Dividende/AGO. Le moteur actuel reste le parcours de six puzzles à score ; convertir silencieusement les objectifs aurait changé les règles du jeu fourni. L'APK compilée ne livre pas les sources de son moteur. Un port fidèle demande ces sources ou une réimplémentation testée des mécaniques.

## Synchronisation et données personnelles

Ceci est une reprise de contenu hors ligne, pas une synchronisation de comptes. Un APK ne contient pas les sauvegardes du téléphone ; Android isole les données des deux identifiants d'application. Aucun compte, jeton ou endpoint de synchronisation commun n'est disponible dans ce livrable. Ne pas désinstaller l'autre application pour essayer de transférer ses données.

Pour une synchronisation entre les applications, il faut un export explicite de progression de l'autre appli, ou son code source/API. Définir alors des identifiants stables (ex. `c1-l1` pour un niveau et `1:0` pour un quiz), un format d'échange versionné, une règle de fusion sans double récompense et un service authentifié autoritaire si des comptes sont connectés. Ne pas fusionner des soldes en les additionnant et ne pas lire les répertoires privés d'une autre application.

## Boucle de croissance

Les gains cumulés sont calculés depuis les réussites enregistrées : 1 500 par premier puzzle de base et 300 par première réponse du Voyage. Acheter/vendre des actions ne fait pas progresser ce compteur. Le cash de départ ne contourne pas les seuils.

| Quartier | Récompenses cumulées requises | Prix terrain |
|---|---:|---:|
| Les Rives | 1 500 | 1 000 |
| Le Verger | 3 000 | 1 500 |
| Le Marché | 4 500 | 2 200 |
| Les Ateliers | 6 000 | 3 000 |
| Les Lumières | 9 000 | 4 000 |
| Le Grand Jardin | 12 000 | 5 000 |

Les quartiers s'acquièrent dans l'ordre, un seul achat par terrain. Un terrain reçoit un bâtiment au choix parmi sept familles, de 500 à 1 800 FCFA-jeu, payé séparément. Les bâtiments et terrains sont permanents et visibles sur la carte et dans Mes propriétés. Ils n'impliquent ni actions détenues, ni revenus garantis. Les routes d'extension apparaissent avec les terrains acquis. Tous les quartiers et même les constructions les plus chères sont accessibles avec les gains finis disponibles.

Toutes les mutations passent par le contrôleur sérialisé : le paiement et la propriété sont enregistrés ensemble avant affichage. Un échec de sauvegarde ne publie pas l'achat. Sauvegarde v3, lecture v1/v2 conservée sans effacer soldes, actions, cartes ou progression existante.
