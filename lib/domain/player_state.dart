class Company {
  final String id, name, sector;
  final int price, colorValue;
  const Company({
    required this.id,
    required this.name,
    required this.sector,
    required this.price,
    required this.colorValue,
  });
}

const companies = <Company>[
  Company(
    id: 'cacao',
    name: 'Cacao des Lagunes',
    sector: 'Agroalimentaire',
    price: 2000,
    colorValue: 0xFFAC6B39,
  ),
  Company(
    id: 'telecom',
    name: 'Télécom Horizon',
    sector: 'Télécommunications',
    price: 2500,
    colorValue: 0xFF477DD2,
  ),
  Company(
    id: 'banque',
    name: 'Banque Baobab',
    sector: 'Banque',
    price: 1500,
    colorValue: 0xFF537D45,
  ),
];

class PlayerState {
  static const _limit = 1000000000;
  final int cash;
  final Map<String, int> holdings, prices;
  final Set<int> completed, answered;
  final Set<String> companyCards;
  final bool marketDropped, dividendPaid;
  final List<String> history;

  PlayerState._({
    required this.cash,
    required Map<String, int> holdings,
    required Map<String, int> prices,
    required Set<int> completed,
    required Set<int> answered,
    required Set<String> companyCards,
    required this.marketDropped,
    required this.dividendPaid,
    required List<String> history,
  }) : holdings = Map.unmodifiable(holdings),
       prices = Map.unmodifiable(prices),
       completed = Set.unmodifiable(completed),
       answered = Set.unmodifiable(answered),
       companyCards = Set.unmodifiable(companyCards),
       history = List.unmodifiable(history);

  factory PlayerState.initial() => PlayerState._(
    cash: 10000,
    holdings: {for (final c in companies) c.id: 0},
    prices: {for (final c in companies) c.id: c.price},
    completed: {},
    answered: {},
    companyCards: {},
    marketDropped: false,
    dividendPaid: false,
    history: [],
  );

  int get holdingsValue =>
      companies.fold(0, (sum, c) => sum + holdings[c.id]! * prices[c.id]!);
  int get totalValue => cash + holdingsValue;
  int get unlockedLevel {
    var level = 0;
    while (level < 6 && completed.contains(level) && answered.contains(level)) {
      level++;
    }
    return level;
  }

  PlayerState _change({
    int? cash,
    Map<String, int>? holdings,
    Map<String, int>? prices,
    Set<int>? completed,
    Set<int>? answered,
    Set<String>? companyCards,
    bool? marketDropped,
    bool? dividendPaid,
    required String message,
  }) {
    final log = [...history, message];
    final nextCash = cash ?? this.cash;
    if (nextCash < 0 || nextCash > _limit) {
      throw StateError('Limite de la simulation atteinte.');
    }
    return PlayerState._(
      cash: nextCash,
      holdings: holdings ?? this.holdings,
      prices: prices ?? this.prices,
      completed: completed ?? this.completed,
      answered: answered ?? this.answered,
      companyCards: companyCards ?? this.companyCards,
      marketDropped: marketDropped ?? this.marketDropped,
      dividendPaid: dividendPaid ?? this.dividendPaid,
      history: log.length > 50 ? log.sublist(log.length - 50) : log,
    );
  }

  PlayerState completeLevel(int level) {
    if (level < 0 || level >= 6) throw ArgumentError('Leçon inconnue.');
    if (completed.contains(level)) return this;
    if (level != unlockedLevel) {
      throw StateError('Termine la leçon précédente.');
    }
    return _change(
      cash: cash + 1500,
      completed: {...completed, level},
      message: 'Puzzle ${level + 1} : +1 500 FCFA-jeu.',
    );
  }

  PlayerState answerLesson(int level) {
    if (!completed.contains(level)) {
      throw StateError('Réussis le puzzle avant le quiz.');
    }
    if (answered.contains(level)) return this;
    return _change(
      answered: {...answered, level},
      message: 'Notion ${level + 1} comprise.',
    );
  }

  int _fee(int amount) => (amount + 99) ~/ 100 < 25 ? 25 : (amount + 99) ~/ 100;
  void _checkTrade(String id) {
    if (!prices.containsKey(id)) throw ArgumentError('Entreprise inconnue.');
    if (!answered.contains(1)) {
      throw StateError('Termine la leçon sur les actions.');
    }
  }

  PlayerState buy(String id) {
    _checkTrade(id);
    final cost = prices[id]! + _fee(prices[id]!);
    if (cash < cost) throw StateError('Épargne insuffisante, frais compris.');
    return _change(
      cash: cash - cost,
      holdings: {...holdings, id: holdings[id]! + 1},
      companyCards: {...companyCards, id},
      message:
          'Achat : ${prices[id]} + ${_fee(prices[id]!)} FCFA-jeu de frais.',
    );
  }

  PlayerState sell(String id) {
    _checkTrade(id);
    if (holdings[id]! < 1) throw StateError('Tu ne possèdes pas cette part.');
    return _change(
      cash: cash + prices[id]! - _fee(prices[id]!),
      holdings: {...holdings, id: holdings[id]! - 1},
      message:
          'Vente : ${prices[id]} − ${_fee(prices[id]!)} FCFA-jeu de frais.',
    );
  }

  PlayerState dropMarket() {
    if (marketDropped) return this;
    if (!answered.contains(2)) {
      throw StateError('Termine la leçon sur le risque.');
    }
    return _change(
      marketDropped: true,
      prices: {...prices, 'cacao': prices['cacao']! - 300},
      message: 'Scénario fictif : cacao −300 FCFA-jeu par part.',
    );
  }

  PlayerState payDividend() {
    if (dividendPaid) return this;
    if (!answered.contains(4) || !marketDropped) {
      throw StateError(
        'Termine la leçon et observe la baisse avant le dividende.',
      );
    }
    if (holdings['cacao']! < 1) {
      throw StateError('Détiens au moins une part de cacao.');
    }
    final dividend = holdings['cacao']! * 100;
    return _change(
      cash: cash + dividend,
      dividendPaid: true,
      prices: {...prices, 'cacao': prices['cacao']! - 100},
      message: 'Dividende fictif : +$dividend en cash ; cours −100 par part.',
    );
  }

  Map<String, dynamic> toJson() => {
    'version': 2,
    'companyCards': companyCards.toList()..sort(),
    'cash': cash,
    'holdings': Map<String, int>.from(holdings),
    'prices': Map<String, int>.from(prices),
    'completed': completed.toList()..sort(),
    'answered': answered.toList()..sort(),
    'marketDropped': marketDropped,
    'dividendPaid': dividendPaid,
    'history': List<String>.from(history),
  };

  factory PlayerState.fromJson(Map<String, dynamic> raw) {
    try {
      if ((raw['version'] != 1 && raw['version'] != 2) ||
          raw['cash'] is! int ||
          raw['cash'] < 0 ||
          raw['cash'] > _limit ||
          raw['marketDropped'] is! bool ||
          raw['dividendPaid'] is! bool) {
        throw const FormatException();
      }
      final holdings = Map<String, int>.from(raw['holdings'] as Map);
      final prices = Map<String, int>.from(raw['prices'] as Map);
      if (holdings.length != 3 ||
          prices.length != 3 ||
          companies.any(
            (c) =>
                !holdings.containsKey(c.id) ||
                holdings[c.id]! < 0 ||
                holdings[c.id]! > _limit ||
                !prices.containsKey(c.id),
          )) {
        throw const FormatException();
      }
      final Set<String> companyCards;
      if (raw['version'] == 1) {
        // Legacy saves have no identifiable sold-company history. Recover only
        // cards proven by current ownership; never guess from history strings.
        companyCards = {
          for (final c in companies)
            if (holdings[c.id]! > 0) c.id,
        };
      } else {
        final cards = List<String>.from(raw['companyCards'] as List);
        final knownIds = companies.map((c) => c.id).toSet();
        if (cards.length > companies.length ||
            cards.toSet().length != cards.length ||
            cards.any((id) => !knownIds.contains(id))) {
          throw const FormatException();
        }
        companyCards = cards.toSet();
        if (companies.any(
          (c) => holdings[c.id]! > 0 && !companyCards.contains(c.id),
        )) {
          throw const FormatException();
        }
      }
      final dropped = raw['marketDropped'] as bool;
      final paid = raw['dividendPaid'] as bool;
      if (prices['cacao'] != 2000 - (dropped ? 300 : 0) - (paid ? 100 : 0) ||
          prices['telecom'] != 2500 ||
          prices['banque'] != 1500) {
        throw const FormatException();
      }
      Set<int> levels(dynamic value) {
        final list = List<int>.from(value as List);
        if (list.length > 6 ||
            list.toSet().length != list.length ||
            list.any((n) => n < 0 || n >= 6)) {
          throw const FormatException();
        }
        return list.toSet();
      }

      final completed = levels(raw['completed']);
      final answered = levels(raw['answered']);
      if (!completed.containsAll(answered)) throw const FormatException();
      for (final n in completed) {
        if (n > 0 && !answered.contains(n - 1)) throw const FormatException();
      }
      if ((dropped && !answered.contains(2)) ||
          (paid && (!dropped || !answered.contains(4)))) {
        throw const FormatException();
      }
      if (holdings.values.any((n) => n > 0) && !answered.contains(1)) {
        throw const FormatException();
      }
      final history = List<String>.from(raw['history'] as List);
      if (history.length > 50 || history.any((s) => s.length > 500)) {
        throw const FormatException();
      }
      return PlayerState._(
        cash: raw['cash'] as int,
        holdings: holdings,
        prices: prices,
        completed: completed,
        answered: answered,
        companyCards: companyCards,
        marketDropped: dropped,
        dividendPaid: paid,
        history: history,
      );
    } catch (_) {
      throw const FormatException('Sauvegarde PACO invalide.');
    }
  }
}
