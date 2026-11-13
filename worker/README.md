# paco-market (Cloudflare Worker)

Chaque soir de séance (17 h et 19 h, heure d'Abidjan, du lundi au vendredi), lit les cours officiels sur brvm.org
et publie `market_snapshots/latest` (et `market_snapshots/AAAA-MM-JJ`) dans la base Firestore de Bourse Facile.

## Mise en service (une seule fois)

1. Console Firebase → Paramètres du projet → Comptes de service → **Générer une nouvelle clé privée** (fichier JSON).
   Ne jamais l'envoyer par chat ni la mettre sur GitHub.
2. Dans ce dossier :
   ```sh
   npm install
   npx wrangler login
   npx wrangler secret put FIREBASE_SERVICE_ACCOUNT   # coller tout le contenu du fichier JSON
   npx wrangler secret put RUN_TOKEN                  # un mot de passe au choix, pour le déclenchement manuel
   npx wrangler deploy
   ```
3. Test immédiat : `curl -H "x-run-token: <RUN_TOKEN>" https://paco-market.<ton-compte>.workers.dev/run`

## Données

- Cours, cours de la veille, variation : **brvm.org** (pages « Cours des actions » et accueil, mêmes règles que l'app Android).
- Nom, secteur, pays, BPA, dernier dividende : `src/facts.json` (à vérifier avec les rapports annuels et les avis BRVM).
  PER et rendement sont recalculés avec le cours du jour.
- En cas de page modifiée ou incomplète, rien n'est écrit : le jeu garde le dernier instantané valide.
