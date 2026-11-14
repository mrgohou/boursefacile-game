# Vérification Android native

La version Kotlin est vérifiée indépendamment du projet Flutter.

## Tests automatiques

Quatorze tests JVM couvrent les plateaux stables et jouables, les échanges invalides sans pénalité, les cascades et leur gravité, les limites de déplacement, les temps de partie, les récompenses uniques, les frais, les acquisitions permanentes, les constructions, le budget total, les dividendes et les migrations JSON. Ils exécutent le véritable moteur Kotlin, résolvent les 30 étapes par des échanges légaux et vérifient la migration du parcours historique vers les 30 étapes avec récompenses uniques.

Cinq tests Robolectric avec rendu graphique Android natif (API 35) démarrent la véritable MainActivity et son ViewModel :

1. Chargement de ville, ouverture du niveau, consigne, lancement, expiration du délai, résultat PAS DE CHANCE et retour à l'accueil.
2. Détention d'une action, affichage Acheter plus / Vendre, achat puis vente avec frais et carte conservée.
3. Achat d'un terrain, construction puis validation d'un quiz importé dans la même économie ; un second passage ne crédite pas une seconde récompense.
4. Résolution d'un vrai plateau par ses actions accessibles, résultat GAGNE, sauvegarde avant retour au menu et conservation de la victoire.

5. Import d'une progression de 29 étapes, accès direct à la mission 30, vérification de ses 1 670 points / 90 secondes / 19 coups, expiration et retour sans récompense.

Les captures sont issues des vues Android via leur Canvas natif. Les fenêtres de dialogue sont capturées séparément ; leur transparence extérieure n'est pas un fond noir ajouté au jeu. Aucun rendu Flutter n'est utilisé pour ces aperçus.

## Compilation et analyse

Commandes : `:app:testDebugUnitTest`, `:app:lintDebug`, `:app:assembleDebug`. Les rapports Gradle et Lint donnent les résultats exacts. Les recommandations de mise à jour de dépendances et d'API peuvent rester des avertissements ; aucune erreur Lint n'est acceptée pour cette livraison.

L'APK est contrôlée : identifiant Android, version minimale et cible, signature, ressources PACO, absence de `libflutter.so`, de `flutter_assets`, de classes Flutter/Unity et de moteur WebView de substitution. L'édition est autonome et jouable hors ligne.

## Limites de cette validation

Robolectric est une simulation Android sur JVM, pas un téléphone physique ni un émulateur matériel complet. L'audio réel, les performances GPU, les gestes sur différents écrans et les interruptions système doivent encore être validés sur les téléphones cibles. Les essais de clavier/export/import, de grandes polices et d'accessibilité matérielle méritent une campagne dédiée avant publication store.
