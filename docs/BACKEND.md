# API connectée — scaffold serveur

Ce service est distinct du mode démo Flutter. **Il n’est pas encore raccordé à Flutter, déployé ou testé en charge.** Les entreprises, prix et FCFA-jeu sont fictifs. Aucun flux de marché réel ni transaction financière réelle.

## Exécuter

Node 22 ou supérieur ; dans `server/` : `npm ci`, `npm test`, puis `npm start`. Port `PORT` (8080 par défaut). `GET /healthz` répond sans Firebase, credentials ni accès réseau. Les autres routes exigent un projet Firebase configuré et des Application Default Credentials valides. Aucun secret ne doit entrer dans Git ou l’image. En hébergement, employer une identité de workload dédiée ; pour le développement local, ADC géré hors dépôt. Le serveur ne fournit aucun mode de contournement Auth/App Check. Les tests utilisent exclusivement des mocks et aucune credential.

Construire l’image depuis `server/` : `docker build -t paco-api .`. L’image s’exécute comme utilisateur `node`, jamais root. Docker n’a pas été exécuté dans cette tâche.

## Contrat HTTP

Chaque requête `/v1/*` exige `Authorization: Bearer <Firebase ID token>` et `X-Firebase-AppCheck: <App Check token>`. Le serveur vérifie la révocation Auth et App Check. L’UID provient exclusivement du token ; aucun UID client n’est accepté. Les UID économiques doivent respecter `[A-Za-z0-9:_-]{1,128}` ; les comptes Firebase avec UID custom hors de ce format sont refusés. Aucun token n’est journalisé. Activer les fournisseurs App Check de production pour les apps autorisées dans le projet Firebase ; ne jamais autoriser de debug token de production.

- `GET /v1/player` initialise atomiquement l’état s’il manque et retourne `{state, prices, simulation:true}`. `state = {version:0,cash:10000,holdings:{cacao:0,telecom:0,banque:0}}`.
- `POST /v1/actions` exige aussi `Idempotency-Key`, UUID unique par intention, et JSON strict : `{ "type":"buy", "companyId":"cacao", "quantity":1, "expectedVersion":0 }`. `type` vaut `buy|sell`, entreprise `cacao|telecom|banque`, quantité exactement 1, version entière de 0 à 1 000 000. Aucun champ supplémentaire. JSON limité à 2 Kio.
- Réponse d’action : `{state,receipt:{type,companyId,quantity,price,fee},replayed:false,simulation:true}`. Prix serveur : cacao 2000, télécom 2500, banque 1500. Frais : 1 %, arrondi supérieur, minimum 25. Achat et vente débitent les frais. Le client n’envoie ni prix ni solde.
- Répéter exactement une action avec la même clé restitue son résultat original (`replayed:true`), même si l’état courant a évolué. Le résultat rejoué n’est donc pas nécessairement le dernier état : relire `/v1/player` avant une nouvelle intention. Réutiliser une clé avec un autre payload, version incluse, produit `409 IDEMPOTENCY_CONFLICT`.
- Sur `409 VERSION_CONFLICT`, relire l’état ; demander confirmation si l’intention change, puis générer une nouvelle clé. Sur résultat réseau incertain, conserver la clé ET le payload, puis réessayer à l’identique.
- Erreurs : `{error:{code}}`, 400 contrat/JSON/clé invalides, 401 authentification ou App Check absent/invalide, 409 conflit/fonds/parts/limite, 413 corps trop volumineux, 415 JSON requis, 429 quota, 503 infrastructure ou état serveur invalide. Aucun détail interne ou jeton renvoyé.

## Autorité et atomicité

Firestore : `users/{uid}/state/main`, `users/{uid}/operations/{uuid}` et `users/{uid}/limits/api`. Une transaction Firestore regroupe vérification de version, contrôle de fonds/parts, frais, changement de solde et enregistrement de l’opération. Les retries Firestore ne produisent aucun effet externe. La clé stocke un SHA-256 canonique du payload et la réponse, sans token. La règle par défaut refuse **toutes les lectures et écritures SDK clientes** ; seul le backend Admin IAM peut accéder aux données.

Le token bucket est persistant, par UID, capacité 30, recharge 30/minute ; il est consommé dans une transaction séparée avant l’opération métier, donc même les conflits métier consomment une unité. Les replays consomment aussi une unité. Les payloads rejetés et requêtes non authentifiées sont arrêtés avant Firestore : prévoir en production une limite de débit à l’entrée (IP/app) contre le trafic abusif ; le quota UID seul ne protège pas les coûts d’authentification. Pas de limiteur en mémoire utilisé comme autorité.

Les reçus d’idempotence ne sont pas automatiquement expirés : définir un budget et une politique de rétention avant production. Supprimer un reçu autorise la réutilisation de sa clé ; la version protège la répétition d’une ancienne action, mais la garantie de restitution de la réponse disparaît après suppression.

## Limites explicites

**Récompenses puzzle désactivées.** Aucune route `completeLevel`, aucun gain accepté du client. Débloquer les récompenses exige un protocole de partie et un validateur de replay serveur avec seed, version de règles, journal de coups, unicité et anti-rejeu. Ce scaffold ne les implémente pas. Pas de scénario, dividende ni classement connecté. Le contrat API simple est autonome ; il ne constitue pas encore un adaptateur du domaine Flutter.

## Mise en production à préparer, sans déploiement automatique

Utiliser un projet/base Firestore dédié au jeu. Les règles Firebase ne limitent pas Firebase Admin : attribuer à l’identité du service seulement les permissions nécessaires pour lire et écrire les documents, et consulter les utilisateurs pour vérifier la révocation Auth. Préférer un rôle IAM personnalisé avec `datastore.entities.get`, `datastore.entities.create`, `datastore.entities.update` et `firebaseauth.users.get`, lié à la base/projet dédié selon les conditions IAM prises en charge. Vérifier ces permissions dans un environnement de staging : ce rôle n’a pas été provisionné ni validé ici. Aucun Owner/Editor, aucune clé de compte de service téléchargée. App Check peut nécessiter une permission/service API supplémentaire selon le runtime ; valider sans élargir à un rôle administrateur. Le service doit disposer des API Auth/App Check/Firestore actives et d’un project ID explicite via la configuration d’environnement du runtime.

Avant ouverture : tests avec émulateur Firestore et vraie concurrence/réessais, Auth révoqué, App Check incorrect/expiré, panne réseau, intégration Flutter, rotation de configuration, surveillance des erreurs et budgets, tests de charge et limites en entrée, sauvegarde et restauration, revue IAM. Les tests inclus vérifient logique, HTTP avec tokens factices et transactions sérialisées en mémoire ; ils ne prouvent pas le comportement Firebase réel. Aucun service payant n’a été déployé.
