# 0.2.1 — Compatibilité au démarrage

Signalement : écran blanc sur un téléphone après installation de l'alpha 0.2.0. Aucun journal Android ni modèle d'appareil disponible au moment de la correction ; la cause matérielle exacte n'est pas confirmée.

Changements :
- APK en mode profile/AOT, exécutable autonome compilé à l'avance, à la place de l'APK debug/JIT précédente.
- Rendu Skia/OpenGL à la place d'Impeller/Vulkan sur Android pour éviter les incompatibilités de pilotes au démarrage.
- Défaut reproduit en test : le constructeur du stockage natif pouvait lever une erreur avant `runApp` si le plugin n’était pas disponible. Construction différée dans la lecture protégée, avec écran d’erreur récupérable.
- Création des lecteurs audio différée ; initialisation après la première image Flutter. Les préférences et l'audio ne doivent pas empêcher l'affichage de la ville.
- Délai de 15 secondes pour lire la sauvegarde : en cas de blocage, affichage de l'erreur et possibilité de réessayer, sans écrasement des données existantes.
- Numéro Android incrémenté ; signature de test conservée pour une mise à jour sans désinstallation.

Vérification : tests du démarrage avec les plugins audio absents et du stockage bloqué, suite de tests fonctionnels et analyse statique. Pas d'appareil Android physique ni d'émulateur disponible ; confirmation sur le téléphone concerné nécessaire. Le mode profile est une distribution de test, pas une publication store.
