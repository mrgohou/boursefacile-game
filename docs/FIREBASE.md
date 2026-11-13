# PACO Bourse × Firebase

Projet Firebase : `third-storm-9w532` (le même que l'app Bourse Facile)
Base Firestore : `ai-studio-bourseclair-8beb427d-785b-41cf-b1ba-358589ed533a`

## 1. Règles Firestore à AJOUTER (ne pas remplacer les règles de l'app)

Dans la console Firebase → Firestore → base `ai-studio-bourseclair-…` → Règles, ajouter ces blocs
à l'intérieur de `match /databases/{database}/documents { … }`, à côté des règles existantes :

```
// PACO Bourse : chaque joueur ne lit et n'écrit que sa propre partie.
match /game_saves/{uid} {
  allow read, write: if request.auth != null && request.auth.uid == uid
    && (request.resource == null || request.resource.data.json.size() < 200000);
}
// Cours du jour : lecture publique, écriture réservée au serveur (Admin SDK).
match /market_snapshots/{id} {
  allow read: if true;
  allow write: if false;
}
```

## 2. Hébergement du jeu (site séparé de l'app)

```sh
npm install -g firebase-tools
firebase login
firebase hosting:sites:create paco-bourse --project third-storm-9w532
npm run build
firebase deploy --only hosting:paco-bourse --project third-storm-9w532
```

Le jeu sera sur https://paco-bourse.web.app. Les domaines `*.web.app` du projet sont déjà autorisés dans
Firebase Auth ; un domaine personnalisé devra être ajouté dans Authentication → Paramètres → Domaines autorisés.

## 3. Cours du jour

Le jeu lit `market_snapshots/latest` :

```json
{ "sessionDate": "2026-11-13", "source": "brvm.org", "companies": [ { "symbol": "SNTS", "name": "…", "sector": "…",
  "family": "telecom", "country": "Sénégal", "price": 4110, "previousClose": 4195, "eps": 185, "per": 22.2,
  "lastDividend": 157.5, "dividendYield": 3.83 } ] }
```

S'il est absent ou incomplet, le jeu utilise l'instantané intégré (`src/data/market-snapshot.json`).
Le programme qui écrit ce document chaque soir reste à choisir : fonction planifiée Firebase (offre Blaze) ou Cloudflare Worker.
