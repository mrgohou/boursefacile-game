# PACO Flutter 0.8.0 — défis, quartiers et identité

## Livré

- Match-3 9 × 9 (81 cases), objectifs de score reconfigurés, budgets de 24–40 coups et 90–180 secondes suivant le niveau et le palier. Les défis peuvent être autonomes ou combinés au score : quatre/six cadenas, trente pièces d’une catégorie, sept alignements directs d’au moins quatre pièces, activation de spéciaux.
- Cinq effets spéciaux : éclair (ligne), pièce en or (catégorie), bidon en or (zone), faucille en argent (récolte), camion (ligne et colonne). Création, activation, chaînes et remappage par gravité sont calculés dans le moteur, pas seulement illustrés. Les alignements de deux triples simultanés ne comptent pas comme un coup parfait.
- Objectifs et compteurs visibles, consigne en fenêtre, graphismes de plateau colorés selon l’identité du niveau, effets lumineux de disparition, bruitage de pose après la chute, musique et réglages séparés. Les pions restent les visuels argile pré-rendus du projet ; ce n’est pas un rendu 3D Unreal.
- Sur téléphone étroit, les cases conservent 48 dp et deux boutons déplacent horizontalement la vue. Les glissements sur les pièces restent réservés aux échanges ; la vue du plateau n’intercepte pas ces gestes. Sur écran plus large, les neuf colonnes apparaissent ensemble.
- Les 48 titres du guichet, dont les 45 entreprises historiques, peuvent être placés et déplacés. Centre gratuit et 16 emplacements par quartier acquis, occupation et propriété contrôlées, plusieurs bâtiments par terrain. La dernière vente libère le site et conserve la carte de collection.
- Sauvegarde v6 compatible en lecture v1 à v5. Solde, positions, cartes et acquis conservés ; les placements arrivent vides lors d’une migration. Les trois placements pédagogiques historiques restent visibles en l’absence d’un choix explicite.
- Trente quiz de campagne reparamétrés à partir de notions pragmatiques et base de 40 exercices originaux, avec explication et action pédagogique. Accès depuis les réglages ; les exercices recommandés sont priorisés selon le suivi local.
- Directeur statistique local : réussites, échecs, temps, coups, erreurs de quiz et répartition des achats/ventes. Paliers bornés, choisis avant la partie, pas de modification du chronomètre en cours. Entraînements générés après la campagne, sans crédits économiques supplémentaires. Suivi distinct des acquis, réinitialisable ; pas de LLM ni de transmission du comportement à un serveur.
- Nouvelle icône Android avec Paco, fond bleu ciel et pièce d’or ; déclinaisons de densité et icône adaptative. Écran de chargement portrait repris du visuel fourni : « PACO bourse facile » au-dessus de Paco et « apprendre la bourse » en dessous, sur fond bleu ciel. CTA avec bord et profondeur argile.

## Sources et limites explicites

FluxBourse et l’article Drimify ont été consultés. Les questions PACO sont originales, et la banque complète de FluxBourse n’est pas republiée faute de conditions de redistribution établies. Un bouton Android ouvre le quiz original ; voir `assets/knowledge/sources.json`. Les explications concernent les bases générales, pas une recommandation d’achat adaptée à une personne.

Le moteur de l’APK reste Flutter/Flame. Unreal Editor, Construct 3 et un document Figma connecté ne sont pas disponibles ici. Aucun de ces outils n’est annoncé comme intégré. Godot, sous licence MIT vérifiée, est l’alternative ouverte proposée pour une future édition 3D. Un replay JSON et son validateur GDScript exécuté avec Godot 4.6.3 sont fournis ; ce contrôle structurel ne constitue pas un deuxième moteur complet.

## Validation

- 79 tests Flutter réussis dans une suite complète ; tests ciblés supplémentaires de l’audio de pose et des captures de widgets réels.
- Tests du moteur 9 × 9, des cadenas, des cinq spéciaux, de la collecte, des coups parfaits directs, des objectifs conjoints et des snapshots ; tests du placement, des migrations et du suivi pédagogique.
- Une simulation préliminaire de 30 niveaux × 3 graines a obtenu 85 victoires en 90 parties avec un indice glouton. Les cinq échecs épuisent le budget, sans blocage moteur. Cela ne mesure pas la difficulté humaine ; le réglage devra être affiné lors d’essais avec des joueurs. Certaines parties centrées sur le score peuvent rester courtes.
- Captures réelles Flutter dans `docs/screenshots-0.8/`, icône source dans `assets/branding/paco-icon.png`.
- Compilation Android ARM64 AOT/profile, rendu de compatibilité conservé. Signature de développement stable. Aucun essai sur téléphone physique ni mesure de performances GPU n’est revendiqué.

Les éditions Kotlin et Unity ne sont pas modifiées par cette livraison et ne lisent pas la sauvegarde Flutter v6. Éviter un retour à une ancienne APK après mise à jour.
