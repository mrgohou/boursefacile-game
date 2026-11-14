# Validation de l'édition Unity 0.1.0

## Exécuté dans cette livraison

- **13 scénarios de tests C# réussis** sur le domaine réel, compilé avec Roslyn et exécuté sur .NET 8. Les 30 étapes sont résolues pour cinq graines chacune, soit 150 résolutions. Ce contrôle vérifie le budget de coups, pas le temps de réflexion d'un joueur humain.
- Séquentialité, absence de récompenses répétées, sauvegarde v4 et lecture v1/v2/v3, tableaux de gravité, transactions avec frais, cartes permanentes, six terrains, constructions, dividende sans création de valeur au détachement, délai et récupération depuis le fichier de secours.
- Quarante-cinq récompenses de Voyage gagnées, rejouées sans double crédit et sauvegardées. Les données comprennent 15 destinations et 45 questions ; les trois questions sur le PER ont été reformulées.
- Compilation C# de compatibilité des fichiers Domain et Runtime contre des DLL de référence Unity 2021.3.33 et uGUI 2018.3, avec les références .NET 8. **Ce n'est pas une compilation du projet par Unity 6.** Les avertissements CS0649 concernent des champs remplis par désérialisation JSON. Les sources Editor et les tests Unity ne sont pas inclus dans ce contrôle de compatibilité.
- Validation de présence et du format binaire des 21 modèles FBX, des onze WAV, des catalogues et des six parcelles ; vérification des noms d'assemblies explicites.
- Génération et inspection de deux rendus Blender 4.3.2 / Cycles de la géométrie livrée, après correction des arêtes de toiture et des matériaux de glaçage. Les aperçus ne sont pas des captures Unity et ne démontrent pas un rendu Android.

## Non exécuté

- Import des assets et résolution effective des packages par Unity 6000.0.62f1.
- Compilation des scripts Editor dans Unity, préparation du pipeline et de la scène, quatre tests EditMode et un test PlayMode fournis.
- Exécution réelle du jeu Unity, rendu URP, rendu des lettres 3D dans leur texture d'interface, audio, tactile et vie du processus sur Android.
- Compilation IL2CPP, signature et installation d'un APK Unity ; essais GPU, mémoire, cadence et batterie sur téléphone.
- Mesures des cibles tactiles en dp, du texte agrandi, du pincement et de la safe area sur différents appareils ; lecture d'écran Android.
- Exécution du workflow GitHub Actions. L'accès aux secrets Actions du dépôt renvoie HTTP 403 avec l'intégration disponible ; aucune licence n'a été lue ou utilisée.

Le poste dispose de Blender et d'un compilateur C# installé pour les vérifications, mais d'aucun éditeur Unity ni d'une licence Unity activée. **Aucun APK Unity n'est fourni ou annoncé comme compilé.**

## Vérification à effectuer dans l'éditeur

Ouvrir le projet avec la version indiquée, laisser les imports finir, lancer PACO > Préparer le projet, puis les tests EditMode et PlayMode. Vérifier particulièrement l'échelle et l'orientation des FBX, le pipeline et les variantes de shader retenues, l'alpha du titre 3D, le calcul des hauteurs de cartes, l'import JSON confirmé, le glissement et les interruptions Android. Compiler ensuite un APK avec le support Android et une licence active.

Les réglages de performance restent des objectifs. Le contenu est une première base 3D de taille limitée ; il ne reproduit pas l'ensemble de la simulation agricole et urbaine de Township, ni les boosters et milliers de niveaux d'un grand Match-3 commercial.
