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

## Validation de la livraison Flutter 0.6.0

- 56 tests Flutter réussis ; analyse statique sans problème.
- Les 30 plateaux sont résolus par des échanges légaux dans leur budget de coups.
- Reprise du format v3, déblocage de l'étape 7 et sauvegarde/rechargement des 30 étapes. Récompenses uniques et progression séquentielle contrôlées.
- Test widget à 390 dp : chemin de 30 étapes, accès direct à la mission 30, consigne et paramètres 1 670 points / 19 coups. Correction du débordement du compteur sur le chemin.
- APK ARM64 AOT/profile, rendu Android de compatibilité, version 0.6.0 / code 2007, Android API 24 minimum / cible 36, signature de développement conservée.
- Les tests automatisés ne remplacent pas les essais sur téléphone physique ; aucun appareil physique n'a été utilisé pour cette livraison.
