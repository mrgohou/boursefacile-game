# Marché Flutter 0.7.0

45 entreprises de `assets/companion/market-snapshot.json` deviennent des titres achetables et revendables. Nom, symbole, pays, secteur, famille graphique et cours sont repris exactement de cette archive du 13/11/2026. Les cours sont fixes dans cette simulation hors ligne et exprimés en FCFA-jeu ; ils ne constituent pas un flux de marché actuel. Les BPA, PER et dividendes de l’archive ne sont pas utilisés pour promettre un rendement ou distribuer des revenus.

Le guichet permet la recherche. Les acquisitions alimentent Mes propriétés, la valeur totale et les cartes permanentes. Les visuels utilisent la famille de chaque entreprise parmi les sept familles disponibles. Les frais restent de 1 %, avec minimum 25 FCFA-jeu. Les trois titres pédagogiques historiques sont conservés avec leurs identifiants et leurs scénarios de baisse/dividende.

La sauvegarde v5 contient 48 positions possibles. Les versions v1 à v4 conservent leurs trois positions historiques et reçoivent les 45 nouvelles quantités à zéro, sans création de cash, de cartes ou de récompenses. Les cours et identifiants sont contrôlés à la lecture. Les anciennes éditions Kotlin/Unity et les anciennes APK Flutter ne lisent pas le nouveau format v5 ; il n’y a pas de synchronisation automatique.

L’archive avait déjà exclu ORAC (rapprochement erroné avec Oragroup), SAFC et BBGC (données manquantes). Aucun cours n’est inventé pour ces trois entrées : les 45 valeurs exploitables du catalogue précédent sont toutes intégrées.

Les tests comparent les 45 cours à la source, exécutent achat/vente/sauvegarde de tous les titres, vérifient les frais, les cartes permanentes et la migration sans enrichissement, puis exercent la recherche par symbole. Les tests existants de progression et d’économie restent applicables. Aucun test sur téléphone physique n’est annoncé.
