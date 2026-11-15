# Outils et skills utilisés pour Flutter 0.9

- **UI/UX Pro Max** : skill consulté et CLI installé dans `/workspace/work/skills/ui-ux-pro-max`. Source épinglée : https://github.com/nextlevelbuilder/ui-ux-pro-max-skill/tree/d643997c82e94742dd3bee43210b0198e8bbba3d. Recherche de système graphique, recommandations d’accessibilité et Flutter utilisées. Le modèle de landing page proposé automatiquement n’est pas appliqué au jeu ; conservation de l’interface de jeu, du thème argile, de Nunito, des contrastes et des zones tactiles.
- **Génération d’images** : outil imagegen utilisé pour les deux planches originales, 20 pions et 24 bâtiments. Découpage des cadres à l’affichage avec Canvas et Sprite Flame. Pas de contenu de Township ou Candy Crush repris.
- **Flutter/Dart + Flame** : chaîne déjà installée, utilisée pour les règles, l’interface et le rendu tactile. Aucun changement de moteur.
- **Flutter Test, analyseur Dart, dart format** : tests métier, migrations, échecs de persistance, interface, captures et texte agrandi.
- **JDK 21, SDK Android/build-tools 36.0.0, Gradle, Kotlin** : outils déjà installés et caches existants réutilisés pour l’APK ARM64.
- **apksigner, aapt, Python zipfile/hashlib** : validation du paquet, des actifs embarqués et de la continuité de signature.
- **Git et GitHub CLI** : publication des sources et de l’APK téléchargeable. Aucun certificat privé ou mot de passe de signature n’est ajouté au dépôt.

Aucune installation de plugin externe, abonnement, compte payant, émulateur volumineux ou moteur supplémentaire n’est nécessaire à cette mise à jour Flutter. Les autres skills disponibles, consacrés à des tâches sans rapport, ne sont pas activés.
