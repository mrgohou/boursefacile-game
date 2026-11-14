# Origine des ressources

- Les 21 FBX sont des géométries originales créées par `scripts/build_art.py` : huit bâtiments dont une maison et sept types constructibles, deux végétaux, voiture, habitant, fontaine, six pièces et deux titres 3D. Les variantes de façade, de toit et les détails sont générés dans Blender, puis exportés pour Unity.
- Les deux PNG de `docs/previews/` sont des rendus Cycles des mêmes modèles. Il n'y a pas d'assets de Township ou de Candy Crush dans le projet.
- Les onze WAV sont les musiques et bruitages déjà présents dans le projet PACO Flutter, repris sans modification.
- Nunito et sa licence OFL proviennent des ressources PACO existantes. La licence est conservée dans `Resources/Fonts/Nunito-OFL.txt`.
- Le catalogue de 30 étapes est identique à celui des éditions Flutter et Kotlin. Les six leçons historiques sont renseignées dans `lessons.json` et les 24 suivantes y sont reprises du catalogue.
- Le Voyage est issu des données déjà extraites de l'APK fourni par l'utilisateur. Le PER est reformulé ; les réponses sont tournées de manière déterministe pour éviter que la bonne réponse soit toujours en première position.

Les DLL de référence employées pour les contrôles C# et le compilateur sont externes au projet et ne sont pas redistribués avec les sources. Unity résout ses dépendances via son manifeste et son éditeur.
