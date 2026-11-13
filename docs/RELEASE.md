# Compilation et publication

## Développement Android

Installer le SDK Android avec Android Studio, choisir un téléphone/émulateur et exécuter :

```sh
flutter doctor -v
flutter pub get --enforce-lockfile
flutter test
flutter build apk --debug --split-per-abi --target-platform android-arm64
```

Cette alpha cible Android ARM64 (ABI filtrée explicitement). Ce paquet est un build de développement. Les icônes et l'identifiant `com.example.paco_bourse` sont provisoires.

## Release Android

Remplacer l'identifiant et la marque de lancement, puis gérer un keystore privé hors du dépôt. La configuration Gradle lit `android/key.properties` (ignoré par Git) contenant `storeFile`, `storePassword`, `keyAlias`, `keyPassword`. `storeFile` désigne le chemin de votre keystore. Ne jamais transmettre ces valeurs en chat ni les committer.

```sh
flutter build appbundle --release
```

Une tâche Release sans fichier de signature échoue explicitement. Vérifier ensuite le bundle sur la piste interne Play Console avec le Firebase de staging et Play Integrity, lorsque ces services seront raccordés.

## iOS

Sur macOS : installer Xcode, ses composants, ouvrir `ios/Runner.xcworkspace`, choisir le bundle identifier et l'équipe de signature. Exécuter les tests sur simulateur puis appareil. App Attest et les paramètres Firebase restent à configurer avant l'accès connecté. Aucun profil de signature n'est fourni.

## Conditions d'ouverture externe

- Validation humaine des contenus pédagogiques et des droits des assets.
- Tests physiques Android modestes / iPhone, veille/reprise, grandes polices, TalkBack/VoiceOver et basse connectivité.
- Raccordement et tests de l'API, révocation d'accès, conflits et sauvegarde/restauration.
- Mesures mémoire, fluidité, consommation et charge serveur.
- Signature de production, politique de confidentialité et règles applicables au public adolescent.
