# Directeur pédagogique adaptatif local

`LearningProfile` est un directeur statistique local transparent, pas un LLM. Aucun appel réseau, clé de modèle, télémétrie distante ou profil financier personnel n’est utilisé. Il adapte les entraînements, pas les cours, les prix, les frais, les récompenses ou la valeur du portefeuille.

Les seules mesures sont le résultat d’une partie, le niveau, la fraction de temps et de coups utilisée, les réponses justes/fausses par notion et les nombres d’achats/ventes par entreprise et famille. Aucun montant investi, revenu, nom, identifiant publicitaire ou donnée de paiement n’est requis. Une moyenne exponentielle des performances et un taux de réussite lissé déterminent un palier de maîtrise entre 0 et 3. Deux échecs successifs ramènent le prochain entraînement au palier de base. Les paramètres d’une partie déjà démarrée doivent rester figés.

La notion recommandée est d’abord une notion avec davantage d’erreurs que de réponses justes. À défaut, des achats concentrés dans une famille proposent une révision de diversification ; plusieurs ventes proposent les frais. Ces rappels généraux ne constituent pas une recommandation d’achat, de vente ou d’allocation réelle.

`nextPracticeLevel` fournit des identités d’entraînement au-delà de 30, sans autoriser de nouvelles récompenses économiques. Le catalogue de défis peut produire ces niveaux de manière déterministe ; la difficulté reste bornée.

Le suivi utilise la clé SharedPreferences distincte `paco.mobile.learning.v1`. Le dépôt économique ne dépend pas de sa disponibilité. Une lecture corrompue ou un échec d’écriture laisse le jeu jouable et expose un message via `lastError`. L’intégration doit annoncer ce suivi local au joueur et offrir sa réinitialisation dans les réglages ; une remise à zéro se fait en sauvegardant un `LearningProfile()` neuf. Aucun effacement des acquis n’est nécessaire.

API : `profile.recordRound(level:..., won:..., elapsedSeconds:..., remainingMoves:...)`, `recordQuiz(topic:..., correct:...)`, `recordTrade(companyId:..., family:..., buy:...)` renvoient un nouveau profil. Persister ensuite avec `LearningRepository.save`; charger au démarrage avec `load`. Ne pas compter deux fois une même partie lors d’une reprise d’écran : enregistrer uniquement son premier résultat définitif.
