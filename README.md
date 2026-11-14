# PACO Bourse — nouveau projet mobile

Socle indépendant Flutter + Flame pour un jeu pédagogique destiné aux adolescents et adultes débutants. Android prioritaire ; projet iOS inclus. Aucune application existante n'a été modifiée.

## Lancer

Flutter **3.50.0** / Dart **3.14.0**, versions repérées dans `.fvmrc`. Utiliser un SDK Android installé et un téléphone ou émulateur.

```sh
flutter pub get --enforce-lockfile
flutter run
```

Sur macOS avec Xcode et un simulateur iOS : `flutter run -d <simulateur>`. La compilation iOS nécessite macOS et Xcode.

## Refonte graphique 0.3.0

Ville tropicale illustrée, commandes en relief, typographie Nunito embarquée et puzzle violet/or : voir `docs/DESIGN-0.3.md` et les captures dans `docs/screenshots/`. Le démarrage Android AOT avec rendu de compatibilité est conservé.

## Ce qui fonctionne

- Accueil sur une ville isométrique : déplacement et zoom tactiles, bâtiments acquis, routes, rivière, passants et véhicules animés.
- Accès direct aux propriétés, cartes de collection permanentes, parcours de puzzles et guichet.
- Six puzzles 7×7 en Dart/Flame : glissement tactile ou deux taps, échanges animés, chutes, cascades, particules, indice et mélange.
- Deux musiques originales et neuf bruitages ; réglages indépendants et pause en arrière-plan.
- Six questions pédagogiques ; seule la réussite du puzzle et de sa question débloque l'étape suivante.
- Trois entreprises inventées, achats/ventes fictifs, frais, baisse et démonstration de dividende.
- Sauvegarde locale v2 compatible v1 ; cartes conservées après vente, victoire enregistrée dès sa validation, remise à zéro confirmée.
- UI testée à 360 dp et à 320 dp avec texte à 200 %. Plateau avec cibles d'au moins 48 dp et actions sémantiques par tuile.

**Le démarrage est explicitement une démo locale.** Pas de compte Firebase, synchronisation, argent réel ou classement. Les données locales ne constituent jamais une preuve de gain pour un serveur.

## Backend préparé, non connecté

`server/` contient une API Node/Express pour Cloud Run, avec Firebase Auth et App Check obligatoires, transactions Firestore, versions, idempotence et quota persistant par utilisateur. Les écritures Firestore directes depuis les clients sont interdites.

L'API ne reçoit pas de score client comme preuve de récompense. Le protocole de validation serveur des puzzles reste à implémenter avant tout crédit connecté. Son état économique minimal est distinct du modèle complet de la démo ; **ne pas connecter ces deux modèles sans adaptateur et migration**.

Aucun projet cloud n'a été créé, aucune ressource facturée déployée et aucun secret ajouté. Voir `docs/BACKEND.md` et `docs/ARCHITECTURE.md`.

## Contrôles

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
cd server
npm ci
npm test
npm audit --omit=dev
```

Le workflow `.github/workflows/verify.yml` prépare aussi un APK de développement sur un runner disposant du SDK Android. Il n'effectue aucun déploiement.

## Identité et publication

Le namespace `com.example.paco_bourse` est un **identifiant provisoire**, à remplacer avant l'enregistrement Firebase et les stores. Les icônes des plateformes restent celles du template Flutter. Les builds Android release exigent une signature propre ; aucune signature debug ne sert par défaut à une release. Voir `docs/RELEASE.md`.

## Visuels fournis

Les planches partagées dans la conversation définissent la direction : bâtiments isométriques en volume doux, Paco vert, tuiles illustrées et UI claire à accents citron. Le catalogue `assets/catalog.json` prépare leur intégration. 58 exports WebP originaux ont été retrouvés dans le dépôt existant et copiés sans modification : bâtiments, poses de Paco et tuiles. Le plateau utilise les six tuiles sectorielles ; l’interface utilise Paco et les trois bâtiments du portefeuille. Les cinq paliers sont disponibles comme assets mais leur règle de croissance n’est pas encore activée. Voir `docs/ASSETS.md`.

## Organisation

- `lib/domain/` : règles pures, leçons, invariants et formats de sauvegarde.
- `lib/game/` : moteur déterministe et rendu Flame.
- `lib/data/` : contrat de dépôt local et contrôleur sérialisant les mutations.
- `lib/ui/` : écrans, thème et illustrations provisoires.
- `server/` : API protégée, règles et tests.
- `docs/` : architecture, design, assets, validation et prochaines étapes.
- `AGENTS.md` : règles communes de contribution humaine et sous-agents.
