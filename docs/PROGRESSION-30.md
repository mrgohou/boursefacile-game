# Parcours de 30 étapes

Les deux éditions proposent 30 puzzles et 30 leçons, répartis en cinq chapitres de six étapes. Les six étapes initiales conservent leurs objectifs et leurs récompenses. Les étapes 7 à 30 ajoutent 24 quiz sur le budget, les frais, la liquidité, les ordres, les indicateurs et le risque.

Le fichier `assets/progression/stages.json` (sous `app/src/main/` en Kotlin) constitue le catalogue partagé : identifiant stable, objectif, coups, secondes et quiz. Les deux fichiers JSON sont identiques. Exécuter `python3 scripts/generate_progression.py`, puis le formateur de la plateforme, après une modification du catalogue. Les tests vérifient la cohérence des paramètres générés avec le JSON.

Le moteur conserve six types de pièces sur un plateau 7 × 7. Chaque étape a un objectif propre et une graine déterministe. La difficulté progresse à l'intérieur de chaque chapitre, puis reprend plus doucement au chapitre suivant. Le budget reste de 19 à 24 coups, avec 60, 70, 75 ou 90 secondes. Les tests résolvent les 30 plateaux par des échanges légaux dans leur budget de coups ; ils ne garantissent pas la réussite de chaque joueur dans le temps imparti.

Une victoire rapporte une seule fois 1 500 FCFA-jeu ; la bonne réponse au quiz débloque l'étape suivante. Rejouer ne permet pas de cumuler les récompenses. Les gains peuvent financer les terrains et les bâtiments existants. Aucun changement du prix des terrains ou des règles de transaction.

## Sauvegardes

La sauvegarde v4 accepte les étapes 0 à 29. Les formats v1/v2/v3 restent lisibles avec leurs six étapes historiques ; une ancienne sauvegarde ayant terminé les six étapes débloque immédiatement la septième, sans crédit supplémentaire. Solde, portefeuille, cartes, terrains, constructions et quiz de voyage sont conservés. Les anciennes versions de l'application ne savent pas lire le format v4 : éviter de revenir à une ancienne APK après mise à jour.

L'édition Flutter ouvre la prochaine étape via le bouton « Continuer » sur le chemin. L'édition Kotlin positionne la liste sur l'étape courante. Les consignes, chronomètres, résultats et retours au menu s'appliquent à l'ensemble des 30 étapes.

Les 45 définitions du catalogue compagnon restent des références distinctes, et ne sont pas converties en puzzles jouables par cette mise à jour. Les 15 destinations et 45 quiz du Voyage restent disponibles séparément.

Toutes les monnaies et entreprises sont fictives. Les éditions Flutter et Kotlin possèdent chacune leur sauvegarde locale.
