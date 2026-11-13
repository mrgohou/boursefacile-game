// Ma Ville : la simulation d'investissement (GDD §4–6). Portage de src/engine/city.ts.
import 'board.dart' show Rng;

enum Family { banque, telecom, agro, distribution, industrie, energie, services }

const familyLabels = {
  Family.banque: 'Banque',
  Family.telecom: 'Télécoms',
  Family.agro: 'Agro',
  Family.distribution: 'Distribution',
  Family.industrie: 'Industrie',
  Family.energie: 'Énergie et eau',
  Family.services: 'Services',
};

class Company {
  const Company({
    required this.symbol,
    required this.name,
    required this.sector,
    required this.family,
    required this.country,
    required this.price,
    this.previousClose,
    this.eps,
    this.per,
    this.lastDividend,
    this.dividendYield,
  });

  factory Company.fromJson(Map<String, dynamic> j) => Company(
        symbol: j['symbol'] as String,
        name: j['name'] as String,
        sector: j['sector'] as String,
        family: Family.values.byName(j['family'] as String),
        country: j['country'] as String,
        price: (j['price'] as num).toDouble(),
        previousClose: (j['previousClose'] as num?)?.toDouble(),
        eps: (j['eps'] as num?)?.toDouble(),
        per: (j['per'] as num?)?.toDouble(),
        lastDividend: (j['lastDividend'] as num?)?.toDouble(),
        dividendYield: (j['dividendYield'] as num?)?.toDouble(),
      );

  final String symbol, name, sector, country;
  final Family family;
  final double price; // vrai cours de clôture (référence)
  final double? previousClose, eps, per, lastDividend, dividendYield;
}

class Holding {
  const Holding({required this.qty, required this.cost, required this.since});
  factory Holding.fromJson(Map<String, dynamic> j) =>
      Holding(qty: j['qty'] as int, cost: (j['cost'] as num).toDouble(), since: j['since'] as int);
  final int qty;
  final double cost; // total payé, frais compris
  final int since; // séance d'achat
  Map<String, dynamic> toJson() => {'qty': qty, 'cost': cost, 'since': since};
}

class EventCard {
  const EventCard(this.id, this.family, this.move, this.text);
  final String id;
  final Family? family; // null = tout le marché
  final double move;
  final String text;
}

const feeRate = 0.01, feeMin = 50.0;
const agoEvery = 10, hourglass = 3;

const events = <EventCard>[
  EventCard('cacao', Family.agro, 0.05, 'Bonne récolte de cacao : l’agro-industrie sourit.'),
  EventCard('pluie', Family.agro, -0.04, 'Pluies trop fortes : les récoltes prennent du retard.'),
  EventCard('reseau', Family.telecom, -0.04, 'Panne réseau géante : les télécoms tremblent.'),
  EventCard('abonnes', Family.telecom, 0.04, 'Des millions de nouveaux abonnés au mobile money !'),
  EventCard('credit', Family.banque, 0.03, 'Les banques prêtent plus aux entreprises.'),
  EventCard('impayes', Family.banque, -0.03, 'Des clients remboursent en retard : prudence chez les banques.'),
  EventCard('usine', Family.industrie, 0.05, 'Une nouvelle usine ouvre : l’industrie embauche.'),
  EventCard('panne', Family.industrie, -0.04, 'Pénurie de pièces : les machines ralentissent.'),
  EventCard('carburant', Family.distribution, -0.03, 'Le prix du carburant monte : les distributeurs gagnent moins.'),
  EventCard('fetes', Family.distribution, 0.04, 'Période de fêtes : les magasins sont pleins.'),
  EventCard('barrage', Family.energie, 0.03, 'Un nouveau barrage produit plus d’électricité.'),
  EventCard('calme', null, 0.0, 'Journée calme à la BRVM. Rien ne presse.'),
  EventCard('optimisme', null, 0.015, 'Bonne humeur générale : la BRVM-C monte un peu.'),
  EventCard('prudence', null, -0.015, 'Les investisseurs hésitent : la BRVM-C baisse un peu.'),
];

class CityState {
  const CityState({
    required this.seance,
    required this.prices,
    required this.holdings,
    this.dividends = 0,
    this.invested = 0,
    this.quickSales = 0,
    this.lastEventId,
    this.lastAgoSeance,
    this.lastAgoAmount = 0,
  });

  factory CityState.fresh(List<Company> companies) =>
      CityState(seance: 0, prices: {for (final c in companies) c.symbol: c.price}, holdings: const {});

  factory CityState.fromJson(Map<String, dynamic> j) => CityState(
        seance: j['seance'] as int,
        prices: (j['prices'] as Map).map((k, v) => MapEntry(k as String, (v as num).toDouble())),
        holdings: (j['holdings'] as Map).map((k, v) => MapEntry(k as String, Holding.fromJson((v as Map).cast()))),
        dividends: (j['dividends'] as num?)?.toDouble() ?? 0,
        invested: (j['invested'] as num?)?.toDouble() ?? 0,
        quickSales: j['quickSales'] as int? ?? 0,
        lastEventId: j['lastEventId'] as String?,
        lastAgoSeance: j['lastAgoSeance'] as int?,
        lastAgoAmount: (j['lastAgoAmount'] as num?)?.toDouble() ?? 0,
      );

  final int seance;
  final Map<String, double> prices;
  final Map<String, Holding> holdings;
  final double dividends, invested;
  final int quickSales;
  final String? lastEventId;
  final int? lastAgoSeance;
  final double lastAgoAmount;

  EventCard? get lastEvent => lastEventId == null ? null : events.firstWhere((e) => e.id == lastEventId);

  CityState copyWith({
    int? seance,
    Map<String, double>? prices,
    Map<String, Holding>? holdings,
    double? dividends,
    double? invested,
    int? quickSales,
    String? lastEventId,
    int? lastAgoSeance,
    double? lastAgoAmount,
  }) =>
      CityState(
        seance: seance ?? this.seance,
        prices: prices ?? this.prices,
        holdings: holdings ?? this.holdings,
        dividends: dividends ?? this.dividends,
        invested: invested ?? this.invested,
        quickSales: quickSales ?? this.quickSales,
        lastEventId: lastEventId ?? this.lastEventId,
        lastAgoSeance: lastAgoSeance ?? this.lastAgoSeance,
        lastAgoAmount: lastAgoAmount ?? this.lastAgoAmount,
      );

  Map<String, dynamic> toJson() => {
        'seance': seance,
        'prices': prices,
        'holdings': holdings.map((k, v) => MapEntry(k, v.toJson())),
        'dividends': dividends,
        'invested': invested,
        'quickSales': quickSales,
        'lastEventId': lastEventId,
        'lastAgoSeance': lastAgoSeance,
        'lastAgoAmount': lastAgoAmount,
      };
}

double fee(double amount) => (amount * feeRate).roundToDouble() < feeMin ? feeMin : (amount * feeRate).roundToDouble();

double buyCost(CityState s, String symbol, int qty) {
  final gross = s.prices[symbol]! * qty;
  return gross + fee(gross);
}

({CityState state, double cash})? buy(CityState s, String symbol, int qty, double cash) {
  final total = buyCost(s, symbol, qty);
  if (qty <= 0 || total > cash) return null;
  final h = s.holdings[symbol];
  final holdings = {...s.holdings}
    ..[symbol] = h == null
        ? Holding(qty: qty, cost: total, since: s.seance)
        : Holding(qty: h.qty + qty, cost: h.cost + total, since: h.since);
  return (state: s.copyWith(holdings: holdings, invested: s.invested + total), cash: cash - total);
}

({CityState state, double cash, double gain})? sell(CityState s, String symbol, int qty, double cash) {
  final h = s.holdings[symbol];
  if (h == null || qty <= 0 || qty > h.qty) return null;
  final gross = s.prices[symbol]! * qty;
  final proceeds = gross - fee(gross);
  final costPart = h.cost / h.qty * qty;
  final holdings = {...s.holdings};
  // Vendre fait perdre la croissance accumulée : le bâtiment repart de zéro.
  if (qty == h.qty) {
    holdings.remove(symbol);
  } else {
    holdings[symbol] = Holding(qty: h.qty - qty, cost: h.cost - costPart, since: s.seance);
  }
  final quick = s.seance - h.since < 5 ? 1 : 0;
  return (
    state: s.copyWith(holdings: holdings, quickSales: s.quickSales + quick),
    cash: cash + proceeds,
    gain: (proceeds - costPart).roundToDouble(),
  );
}

/// Taille du bâtiment (1 à 5) : 10 / 25 / 50 / 100 séances de détention.
int buildingLevel(CityState s, String symbol) {
  final h = s.holdings[symbol];
  if (h == null) return 0;
  final held = s.seance - h.since;
  return held >= 100 ? 5 : held >= 50 ? 4 : held >= 25 ? 3 : held >= 10 ? 2 : 1;
}

int seancesToAgo(CityState s) => agoEvery - (s.seance % agoEvery);

int familyCount(CityState s, List<Company> companies, Family f) =>
    s.holdings.keys.where((sym) => _find(companies, sym)?.family == f).length;

Company? _find(List<Company> list, String sym) {
  for (final c in list) {
    if (c.symbol == sym) return c;
  }
  return null;
}

/// Une séance passe (1 puzzle réussi = 1 séance).
({CityState state, double cashGained, EventCard event, bool ago}) advance(CityState s, List<Company> companies, int seed) {
  final r = Rng(seed + s.seance * 7919);
  final event = events[(r.next() * events.length).floor()];
  final prices = <String, double>{};
  for (final c in companies) {
    final p = s.prices[c.symbol] ?? c.price;
    final noise = (r.next() - 0.5) * 0.03;
    final pull = (c.price - p) / c.price * 0.2;
    var move = noise + pull;
    if (event.family == null || event.family == c.family) {
      final shield = event.move < 0 && familyCount(s, companies, c.family) >= 2 ? 0.5 : 1.0;
      move += event.move * shield;
    }
    final next = (p * (1 + move)).clamp(c.price * 0.85, c.price * 1.15);
    prices[c.symbol] = next.roundToDouble() < 1 ? 1 : next.roundToDouble();
  }
  final seance = s.seance + 1;
  var cash = 0.0;
  var ago = false;
  var lastAgoSeance = s.lastAgoSeance;
  var lastAgoAmount = s.lastAgoAmount;
  if (seance % agoEvery == 0) {
    ago = true;
    for (final MapEntry(key: sym, value: h) in s.holdings.entries) {
      final div = _find(companies, sym)?.lastDividend;
      if (div == null || div == 0) continue;
      if (seance - h.since >= hourglass) cash += (div * h.qty).roundToDouble();
    }
    lastAgoSeance = seance;
    lastAgoAmount = cash;
  }
  return (
    state: s.copyWith(
      seance: seance,
      prices: prices,
      dividends: s.dividends + cash,
      lastEventId: event.id,
      lastAgoSeance: lastAgoSeance,
      lastAgoAmount: lastAgoAmount,
    ),
    cashGained: cash,
    event: event,
    ago: ago,
  );
}

double portfolioValue(CityState s) =>
    s.holdings.entries.fold(0.0, (v, e) => v + (s.prices[e.key] ?? 0) * e.value.qty);

/// Score PACO sur 1 000 : 35 % valeur · 25 % dividendes · 25 % diversification · 15 % régularité.
int scorePaco(CityState s, List<Company> companies, int daysPlayed) {
  final value = portfolioValue(s);
  final costHeld = s.holdings.values.fold(0.0, (v, h) => v + h.cost);
  final ratio = costHeld > 0 ? value / costHeld : 1.0;
  final sValue = ((ratio - 0.85) / 0.3).clamp(0.0, 1.0);
  final sDiv = s.invested > 0 ? (s.dividends / (s.invested * 0.08)).clamp(0.0, 1.0) : 0.0;
  final fams = s.holdings.keys.map((k) => _find(companies, k)?.family).whereType<Family>().toSet();
  final sDivers = (fams.length / 7).clamp(0.0, 1.0);
  final sReg = ((daysPlayed / 7).clamp(0.0, 1.0) - s.quickSales * 0.1).clamp(0.0, 1.0);
  if (s.holdings.isEmpty && s.dividends == 0) return (sReg * 150).round();
  return (350 * sValue + 250 * sDiv + 250 * sDivers + 150 * sReg).round();
}

enum TipKind { empty, quickSales, ago, oneFamily }

/// Paco contextuel (GDD §8). Jamais « achète / vends » : il explique.
({TipKind kind, String text})? pacoTip(CityState s, List<Company> companies, int citiesDone) {
  final fams = s.holdings.keys.map((k) => _find(companies, k)?.family).whereType<Family>().toSet();
  if (s.holdings.isEmpty) {
    return (kind: TipKind.empty, text: 'Ta ville est vide. Au guichet SGI, tu peux acheter une part d’une vraie entreprise de la BRVM.');
  }
  if (s.quickSales >= 3) {
    return (kind: TipKind.quickSales, text: 'Tu revends souvent. Chaque vente coûte des frais, et ton bâtiment perd sa croissance.');
  }
  final toAgo = seancesToAgo(s);
  if (toAgo <= hourglass) {
    return (
      kind: TipKind.ago,
      text: 'AGO dans $toAgo séance${toAgo > 1 ? 's' : ''} ! Seules les parts gardées avant le sablier touchent le dividende.'
    );
  }
  if (fams.length == 1 && citiesDone >= 3) {
    return (kind: TipKind.oneFamily, text: 'Toutes tes parts sont dans le même secteur. Une seule mauvaise nouvelle peut tout toucher.');
  }
  return null;
}
