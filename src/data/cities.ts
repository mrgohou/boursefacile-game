// Les 15 villes = 15 chapitres = 15 leçons de l'app (GDD §7).
// Paco : 2 phrases max, jamais « achète / vends » une vraie action, jamais de reproche.

export interface City {
  n: number;
  name: string;
  country: string;
  notion: string;
  /** tuile vedette de la ville (spécialité locale) */
  featured: 'cacao' | 'telephone' | 'billet' | 'bidon' | 'ampoule' | 'engrenage';
  pacoIntro: string;
  retiens: string;
}

export const CITIES: City[] = [
  { n: 1, name: 'Abidjan', country: "Côte d'Ivoire", notion: 'La BRVM', featured: 'cacao',
    pacoIntro: "Bienvenue à Abidjan, siège de la BRVM ! C'est la bourse commune des 8 pays de l'UEMOA.",
    retiens: 'Une seule bourse, 8 pays, une seule monnaie : le franc CFA.' },
  { n: 2, name: 'Dakar', country: 'Sénégal', notion: "L'action", featured: 'telephone',
    pacoIntro: "À Dakar, on découvre l'action. Une action, c'est un petit morceau d'une entreprise.",
    retiens: "Avoir une action, c'est être un peu propriétaire de l'entreprise." },
  { n: 3, name: 'Cotonou', country: 'Bénin', notion: 'Le prix qui change', featured: 'billet',
    pacoIntro: 'Regarde les passants : plus il y a d acheteurs, plus le prix monte.',
    retiens: "Beaucoup d'acheteurs : le prix monte. Beaucoup de vendeurs : il baisse." },
  { n: 4, name: 'Lomé', country: 'Togo', notion: 'Comment on gagne', featured: 'bidon',
    pacoIntro: 'On peut gagner de deux façons : en revendant plus cher, ou grâce aux dividendes.',
    retiens: 'Gain total = plus-value + dividendes.' },
  { n: 5, name: 'Ouagadougou', country: 'Burkina Faso', notion: 'Dividende et rendement', featured: 'telephone',
    pacoIntro: "Le dividende, c'est une part du bénéfice que l'entreprise partage avec ses actionnaires.",
    retiens: 'Le rendement dit combien de pièces tu reçois pour 100 posées.' },
  { n: 6, name: 'Bamako', country: 'Mali', notion: 'Le BPA', featured: 'engrenage',
    pacoIntro: 'Le cœur du bâtiment, c est le bénéfice par action. Vert, l entreprise gagne de l argent.',
    retiens: 'BPA = bénéfice de l entreprise ÷ nombre d actions.' },
  { n: 7, name: 'Niamey', country: 'Niger', notion: 'Le PER', featured: 'ampoule',
    pacoIntro: 'Le PER répond à une question : en combien d années le bénéfice rembourse ton action ?',
    retiens: 'PER 9 = 9 ans. Si le cœur est rouge, le PER ne se calcule pas.' },
  { n: 8, name: 'Bissau', country: 'Guinée-Bissau', notion: 'La SGI', featured: 'billet',
    pacoIntro: 'Pour acheter une action, on passe par une SGI : c est le guichet officiel de la bourse.',
    retiens: 'Pas de SGI, pas d achat : elle est ton intermédiaire agréé.' },
  { n: 9, name: 'Saint-Louis', country: 'Sénégal', notion: 'Le 1er ordre', featured: 'telephone',
    pacoIntro: 'Tu peux acheter au prix du jour, ou fixer ton prix maximum et attendre.',
    retiens: 'Un ordre, c est une consigne donnée à ta SGI.' },
  { n: 10, name: 'Porto-Novo', country: 'Bénin', notion: 'Les frais', featured: 'billet',
    pacoIntro: 'Chaque achat et chaque vente coûtent des frais. Attention aux cadenas !',
    retiens: 'Acheter et revendre sans arrêt, ça vide la tirelire.' },
  { n: 11, name: 'Kara', country: 'Togo', notion: 'La diversification', featured: 'cacao',
    pacoIntro: 'Une ville avec plusieurs secteurs résiste mieux aux tempêtes.',
    retiens: 'Ne mets pas toutes tes pièces dans le même panier.' },
  { n: 12, name: 'Bobo-Dioulasso', country: 'Burkina Faso', notion: 'Le fractionnement', featured: 'cacao',
    pacoIntro: 'Une grosse part peut devenir plusieurs petites. La valeur totale ne change pas.',
    retiens: 'Sonatel a divisé ses actions par 10 : plus de parts, même valeur.' },
  { n: 13, name: 'Ségou', country: 'Mali', notion: 'Les dates de dividende', featured: 'engrenage',
    pacoIntro: 'Pour toucher le dividende, il faut avoir l action avant la date de détachement.',
    retiens: 'Regarde le sablier : après la date, c est trop tard pour cette année.' },
  { n: 14, name: 'Zinder', country: 'Niger', notion: "L'épargne régulière", featured: 'ampoule',
    pacoIntro: 'Un peu chaque mois, ça grandit comme une boule de neige.',
    retiens: 'La régularité et le temps travaillent pour toi.' },
  { n: 15, name: 'Abidjan-Plateau', country: "Côte d'Ivoire", notion: 'Ta stratégie', featured: 'billet',
    pacoIntro: 'La grande finale ! Construis une ville équilibrée et patiente.',
    retiens: 'Patience + diversification valent mieux qu un coup de chance.' },
];
