# Architecture de départ

## Décision

Flutter 3.50.0 et Flame 1.38.2 pour le client. Material Design 3 utilise le paquet officiel Flutter `material_ui` 1.11.0, car les imports Material historiques du SDK 3.50 sont dépréciés. Dépendances résolues verrouillées dans `pubspec.lock`. Les widgets suivent la langue française et le mode clair/sombre du téléphone.

Pas de moteur 3D temps réel : les références 3D sont destinées à devenir des rendus précalculés. Cela limite le coût mémoire et GPU sur les appareils modestes.

## Deux frontières explicites

La démo exécute ses règles dans `PlayerState` et enregistre un unique document JSON local. `PlayerController` refuse une deuxième mutation pendant une écriture. Si l'écriture échoue, l'état affiché n'est pas crédité. Une sauvegarde illisible n'est pas écrasée silencieusement.

Le service connecté, non raccordé à la démo, est autoritaire sur son propre état économique. Chaque requête est authentifiée et attestée. Une clé d'idempotence et son empreinte d'action empêchent la répétition d'un même achat. Une version optimiste détecte les modifications simultanées. L'état et son reçu sont écrits dans une même transaction Firestore.

Ne jamais transférer le solde local vers le serveur comme valeur de confiance. Il faudra un adaptateur de contrat, une stratégie de migration et une politique de conflit explicites.

## Charge simultanée

- Aucun appel réseau par déplacement de tuile.
- Documents par utilisateur : absence de compteur global écrit à chaque partie.
- Quota persistant partagé entre instances Cloud Run ; pas de compteur de sécurité en mémoire seulement.
- Une transaction en conflit peut être rejouée par Firestore ; son callback ne doit pas émettre de notifications ou d'effet externe.
- Idempotence limitée au périmètre de l'utilisateur et vérification de l'empreinte du payload.
- Corps JSON bornés et actions strictement autorisées ; erreurs sans jetons ni données confidentielles.

Une forte charge sur un même compte reste limitée par son document transactionnel et le quota : elle doit être refusée proprement, pas présentée comme une capacité illimitée. La montée en charge globale dépend des quotas, de la région, de la concurrence Cloud Run, des coûts et d'une protection à l'entrée. Des tests de staging sont requis avant toute capacité annoncée.

## Avant le mode connecté

1. Choisir les identifiants d'application définitifs, la région et le projet Firebase indépendant.
2. Configurer Auth, Play Integrity / App Attest et les règles de traitement des profils mineurs.
3. Unifier le contrat d'état et son versionnement entre API et Flutter.
4. Émettre des identifiants de parties et des graines côté serveur ; définir expiration et preuve de fin de partie.
5. Implémenter la relecture serveur du journal de mouvements avec un générateur pseudo-aléatoire spécifié et des fixtures communes. Le `Random` Dart actuel ne constitue pas un contrat de relecture Node.
6. Créditer les récompenses de manière atomique avec une première réussite unique.
7. Ajouter une file locale d'actions autorisées, reconnexion, changement d'appareil et politique de conflit.
8. Exécuter les tests de charge, de reprise, de règles et d'autorisation sur de vrais services de staging.
