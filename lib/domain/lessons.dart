class Lesson {
  final String title, topic, description, question, explanation, task;
  final List<String> options;
  final int answer;
  const Lesson({
    required this.title,
    required this.topic,
    required this.description,
    required this.question,
    required this.options,
    required this.answer,
    required this.explanation,
    required this.task,
  });
}

const lessons = <Lesson>[
  Lesson(
    title: 'Bienvenue à PACO',
    topic: 'Épargner',
    description: 'Dans cette démo, les entreprises et les FCFA-jeu sont fictifs. Résoudre un puzzle rapporte une récompense une seule fois.',
    question: 'Les FCFA-jeu sont-ils de l’argent réel ?',
    options: [
      'Oui, on peut les retirer',
      'Non, ils servent à apprendre',
      'Oui, à la banque',
    ],
    answer: 1,
    explanation: 'Aucun argent réel ne circule dans cette simulation.',
    task: 'Réussis le puzzle, puis réponds à Paco.',
  ),
  Lesson(
    title: 'Une petite part',
    topic: 'Action',
    description: 'Une action représente une part du capital d’une entreprise. Ici, tu peux acheter des parts d’entreprises inventées avec ton épargne fictive.',
    question: 'Une action représente…',
    options: [
      'Une part du capital d’une entreprise',
      'Un revenu garanti',
      'Un prêt sans risque',
    ],
    answer: 0,
    explanation: 'Détenir une action comporte des risques. Sa valeur peut monter ou baisser.',
    task: 'Après le quiz, découvre le guichet et achète une part si tu le souhaites.',
  ),
  Lesson(
    title: 'Le prix peut baisser',
    topic: 'Risque',
    description: 'Le cours est le prix d’une action. Notre scénario fait baisser le cacao de 300 FCFA-jeu par part. Cette baisse est inventée.',
    question: 'Quand le cours baisse, une part détenue…',
    options: [
      'Disparaît',
      'Vaut moins au prix du marché',
      'Garantit un bénéfice futur',
    ],
    answer: 1,
    explanation: 'La part reste détenue, mais sa valeur de marché baisse. Une remontée n’est pas garantie.',
    task: 'Après le quiz, déclenche la baisse fictive et observe ton portefeuille.',
  ),
  Lesson(
    title: 'Plusieurs entreprises',
    topic: 'Diversification',
    description: 'Répartir ses placements entre plusieurs entreprises et secteurs réduit la dépendance à un seul. Cela ne supprime pas tous les risques.',
    question: 'Diversifier permet surtout de…',
    options: [
      'Supprimer toute perte possible',
      'Garantir un dividende',
      'Réduire la dépendance à une seule entreprise',
    ],
    answer: 2,
    explanation: 'Plusieurs placements peuvent aussi baisser ensemble. La diversification ne garantit pas un gain.',
    task: 'Compare les trois entreprises fictives au guichet.',
  ),
  Lesson(
    title: 'Un revenu, pas un cadeau',
    topic: 'Dividende',
    description: 'Un dividende distribue une partie des bénéfices ou réserves. Il n’est pas garanti. Ici, le cacao verse une seule fois 100 FCFA-jeu par part et son cours baisse simultanément de 100.',
    question: 'Dans notre exemple, au versement du dividende…',
    options: [
      'La valeur totale augmente automatiquement',
      'Le cours est garanti',
      'Le cash augmente et le cours s’ajuste : le total reste égal',
    ],
    answer: 2,
    explanation: 'Notre exemple isole le détachement : +100 en cash et −100 sur chaque part. Sur un vrai marché, d’autres variations peuvent intervenir.',
    task: 'Après la baisse, détiens au moins une part de cacao puis verse le dividende fictif.',
  ),
  Lesson(
    title: 'Prendre du recul',
    topic: 'Frais et bilan',
    description: 'Acheter et vendre coûte ici 1 % du montant, arrondi au supérieur, avec un minimum de 25 FCFA-jeu par ordre. Ces tarifs sont inventés.',
    question: 'Acheter puis revendre immédiatement au même cours…',
    options: [
      'Fait perdre le montant des frais',
      'Rapporte toujours de l’argent',
      'Annule les frais',
    ],
    answer: 0,
    explanation: 'Même sans variation de cours, les deux opérations ont des frais. Compare le cash et la valeur des parts pour faire le bilan.',
    task: 'Observe ton bilan final : cash + valeur des parts = valeur totale.',
  ),
];
