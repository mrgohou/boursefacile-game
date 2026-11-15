import 'cultural_rewards.dart';
import 'city_growth.dart';
import 'city_placement.dart';
export 'city_placement.dart';
import 'stage_catalog.dart';

import 'company_catalog.dart';
export 'company_catalog.dart';

class PlayerState {
  static const _limit = 1000000000;
  final int cash;
  final int cityStage;
  final CulturalRewards rewards;
  final Map<String, int> holdings, prices;
  final Set<int> completed, answered;
  final Set<String> companyCards;
  final Set<String> ownedPlots;
  final Map<String, String> townBuildings;
  final Set<int> journeyAnswers;
  final Map<String, CityPlacement> placements;
  final bool marketDropped, dividendPaid;
  final List<String> history;

  PlayerState._({
    required this.cash,
    this.cityStage = 0,
    CulturalRewards? rewards,
    required Map<String, int> holdings,
    required Map<String, int> prices,
    required Set<int> completed,
    required Set<int> answered,
    required Set<String> companyCards,
    Set<String> ownedPlots = const {},
    Map<String, String> townBuildings = const {},
    Set<int> journeyAnswers = const {},
    Map<String, CityPlacement> placements = const {},
    required this.marketDropped,
    required this.dividendPaid,
    required List<String> history,
  }) : rewards = rewards ?? CulturalRewards(),
       holdings = Map.unmodifiable(holdings),
       prices = Map.unmodifiable(prices),
       completed = Set.unmodifiable(completed),
       answered = Set.unmodifiable(answered),
       companyCards = Set.unmodifiable(companyCards),
       ownedPlots = Set.unmodifiable(ownedPlots),
       townBuildings = Map.unmodifiable(townBuildings),
       journeyAnswers = Set.unmodifiable(journeyAnswers),
       placements = Map.unmodifiable(placements),
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
    while (level < stageCount &&
        completed.contains(level) &&
        answered.contains(level)) {
      level++;
    }
    return level;
  }

  PlayerState _change({
    int? cash,
    CulturalRewards? rewards,
    Map<String, int>? holdings,
    Map<String, int>? prices,
    Set<int>? completed,
    Set<int>? answered,
    Set<String>? companyCards,
    Set<String>? ownedPlots,
    Map<String, String>? townBuildings,
    Set<int>? journeyAnswers,
    Map<String, CityPlacement>? placements,
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
      cityStage: cityTier,
      rewards: rewards ?? this.rewards,
      holdings: holdings ?? this.holdings,
      prices: prices ?? this.prices,
      completed: completed ?? this.completed,
      answered: answered ?? this.answered,
      companyCards: companyCards ?? this.companyCards,
      ownedPlots: ownedPlots ?? this.ownedPlots,
      townBuildings: townBuildings ?? this.townBuildings,
      journeyAnswers: journeyAnswers ?? this.journeyAnswers,
      placements: placements ?? this.placements,
      marketDropped: marketDropped ?? this.marketDropped,
      dividendPaid: dividendPaid ?? this.dividendPaid,
      history: log.length > 50 ? log.sublist(log.length - 50) : log,
    );
  }

  PlayerState completeLevel(int level, {bool flawless = false}) {
    if (level < 0 || level >= stageCount) {
      throw ArgumentError('Leçon inconnue.');
    }
    if (completed.contains(level)) return this;
    if (level != unlockedLevel) {
      throw StateError('Termine la leçon précédente.');
    }
    return _change(
      cash: cash + 1500,
      rewards: rewards.puzzle(level, flawless),
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
      rewards: rewards.quiz('lesson:$level', true, campaignLevel: level),
      message: 'Notion ${level + 1} comprise.',
    );
  }

  PlayerState startPuzzle(int level) {
    if (level < 0 ||
        level >= stageCount ||
        level != unlockedLevel ||
        completed.contains(level)) {
      return this;
    }
    return _change(
      rewards: rewards.start(level),
      message: 'Tentative puzzle ${level + 1} démarrée.',
    );
  }

  PlayerState recordQuizAttempt(String id, bool correct) {
    if (!RegExp(r'^(lesson:\d+|journey:\d+|knowledge:practical-brvm-\d+)$')
        .hasMatch(id)) {
      throw ArgumentError('Quiz inconnu.');
    }
    // Campaign and journey success is recorded atomically with progression.
    if (correct && !id.startsWith('knowledge:')) return this;
    final r = rewards.quiz(
      id,
      correct,
      campaignLevel: id.startsWith('lesson:')
          ? int.parse(id.split(':').last)
          : null,
    );
    if (identical(r, rewards)) return this;
    return _change(
      rewards: r,
      message: correct ? 'Quiz réussi au premier essai.' : 'Une erreur : la série de quiz repart à zéro, tes acquis restent conservés.',
    );
  }

  PlayerState collectReward(int id) {
    final grant = rewards.pending.where((r) => r.id == id).firstOrNull;
    if (grant == null) throw StateError('Récompense déjà collectée.');
    return _change(
      cash: cash + grant.value,
      rewards: rewards.collect(id),
      message: 'COLLECTER : ${grant.label}, +${grant.value} F jeu.',
    );
  }

  int get pacoScore =>
      answered.length * 100 +
      journeyAnswers.length * 25 +
      rewards.seen.where((id) => id.startsWith('knowledge:')).length * 20;
  int get cityTier =>
      _currentCityTier > cityStage ? _currentCityTier : cityStage;
  int get _currentCityTier =>
      earnedRewards >= 15000 && pacoScore >= 1000 && holdingsValue >= 10000
      ? 2
      : earnedRewards >= 4500 && pacoScore >= 300 && holdingsValue >= 1500
      ? 1
      : 0;

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
      placements: holdings[id] == 1
          ? (Map<String, CityPlacement>.from(placements)..remove(id))
          : placements,
      message:
          'Vente : ${prices[id]} − ${_fee(prices[id]!)} FCFA-jeu de frais.',
    );
  }

  PlayerState placeCompany(String id, String landId, int cell) {
    if (!holdings.containsKey(id) || holdings[id]! <= 0) {
      throw StateError(
        'Achète au moins une part de cette entreprise avant de la placer.',
      );
    }
    final place = CityPlacement.fromJson({'landId': landId, 'cell': cell});
    if (landId != baseCityId && !ownedPlots.contains(landId)) {
      throw StateError('Achète ce terrain avant de le développer.');
    }
    if (placements.entries.any(
      (e) => e.key != id && e.value.siteKey == place.siteKey,
    )) {
      throw StateError('Cet emplacement est déjà occupé.');
    }
    return _change(
      placements: {...placements, id: place},
      message:
          'Entreprise $id placée dans ${cityName(landId)}, emplacement ${cell + 1}.',
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

  int get earnedRewards =>
      completed.length * 1500 +
      journeyAnswers.length * 300 +
      rewards.colas * 500 +
      rewards.cauris * 1000 +
      rewards.gold * 2000;

  PlayerState answerJourney(int cityIndex, int questionIndex) {
    if (cityIndex < 0 ||
        cityIndex >= 15 ||
        questionIndex < 0 ||
        questionIndex >= 3) {
      throw ArgumentError('Question inconnue.');
    }
    final key = cityIndex * 3 + questionIndex;
    if (journeyAnswers.contains(key)) return this;
    // Sequential chapters; all three questions unlock the next destination.
    if (cityIndex > 0 &&
        !List.generate(
          3,
          (i) => (cityIndex - 1) * 3 + i,
        ).every(journeyAnswers.contains)) {
      throw StateError('Termine la destination précédente.');
    }
    return _change(
      cash: cash + 300,
      rewards: rewards.quiz('journey:$key', true),
      journeyAnswers: {...journeyAnswers, key},
      message:
          'Voyage ${cityIndex + 1}, notion ${questionIndex + 1} : +300 FCFA-jeu.',
    );
  }

  PlayerState buyLand(String id) {
    final index = lands.indexWhere((l) => l.id == id);
    if (index < 0) throw ArgumentError('Terrain inconnu.');
    final land = lands[index];
    if (ownedPlots.contains(id)) {
      throw StateError('Ce terrain est déjà acquis.');
    }
    if (index > 0 && !ownedPlots.contains(lands[index - 1].id)) {
      throw StateError('Acquiers d’abord le quartier précédent.');
    }
    if (earnedRewards < land.requiredGains) {
      throw StateError(
        'Gagne encore des récompenses pour débloquer ce quartier.',
      );
    }
    if (cash < land.price) {
      throw StateError('Épargne insuffisante pour ce terrain.');
    }
    return _change(
      cash: cash - land.price,
      ownedPlots: {...ownedPlots, id},
      message: 'Terrain ${land.name} : −${land.price} FCFA-jeu.',
    );
  }

  PlayerState construct(String landId, String buildingId) {
    if (!ownedPlots.contains(landId)) {
      throw StateError('Achète ce terrain avant de construire.');
    }
    if (townBuildings.containsKey(landId)) {
      throw StateError('Un bâtiment occupe déjà ce terrain.');
    }
    final index = townBuildingTypes.indexWhere((b) => b.id == buildingId);
    if (index < 0) throw ArgumentError('Bâtiment inconnu.');
    final building = townBuildingTypes[index];
    if (cash < building.cost) {
      throw StateError('Épargne insuffisante pour construire.');
    }
    return _change(
      cash: cash - building.cost,
      townBuildings: {...townBuildings, landId: buildingId},
      message: 'Construction ${building.name} : −${building.cost} FCFA-jeu.',
    );
  }

  Map<String, dynamic> toJson() => {
    'version': 7,
    'cityStage': cityTier,
    'culturalRewards': rewards.toJson(),
    'placements': {for (final e in placements.entries) e.key: e.value.toJson()},
    'ownedPlots': ownedPlots.toList()..sort(),
    'townBuildings': Map<String, String>.from(townBuildings),
    'journeyAnswers': journeyAnswers.toList()..sort(),
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
      if ((raw['version'] != 1 &&
              raw['version'] != 2 &&
              raw['version'] != 3 &&
              raw['version'] != 4 &&
              raw['version'] != 5 &&
              raw['version'] != 6 &&
              raw['version'] != 7) ||
          raw['cash'] is! int ||
          raw['cash'] < 0 ||
          raw['cash'] > _limit ||
          raw['marketDropped'] is! bool ||
          raw['dividendPaid'] is! bool) {
        throw const FormatException();
      }
      final holdings = Map<String, int>.from(raw['holdings'] as Map);
      final prices = Map<String, int>.from(raw['prices'] as Map);
      final expected = raw['version'] >= 5 ? companies : legacyCompanies;
      if (holdings.length != expected.length ||
          prices.length != expected.length ||
          expected.any(
            (c) =>
                !holdings.containsKey(c.id) ||
                holdings[c.id]! < 0 ||
                holdings[c.id]! > _limit ||
                !prices.containsKey(c.id),
          )) {
        throw const FormatException();
      }
      if (raw['version'] < 5) {
        for (final c in archivedCompanies) {
          holdings[c.id] = 0;
          prices[c.id] = c.price;
        }
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
        final knownIds = expected.map((c) => c.id).toSet();
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
          prices['banque'] != 1500 ||
          archivedCompanies.any((c) => prices[c.id] != c.price)) {
        throw const FormatException();
      }
      Set<int> levels(dynamic value) {
        final list = List<int>.from(value as List);
        final limit = raw['version'] >= 4 ? stageCount : 6;
        if (list.length > limit ||
            list.toSet().length != list.length ||
            list.any((n) => n < 0 || n >= limit)) {
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
      final plots = raw['version'] >= 3
          ? List<String>.from(raw['ownedPlots'] as List)
          : <String>[];
      final buildings = raw['version'] >= 3
          ? Map<String, String>.from(raw['townBuildings'] as Map)
          : <String, String>{};
      final journey = raw['version'] >= 3
          ? List<int>.from(raw['journeyAnswers'] as List)
          : <int>[];
      if (plots.toSet().length != plots.length ||
          plots.any((p) => !lands.any((l) => l.id == p)) ||
          buildings.keys.any((id) => !plots.contains(id)) ||
          buildings.values.any(
            (id) => !townBuildingTypes.any((b) => b.id == id),
          ) ||
          journey.toSet().length != journey.length ||
          journey.any((i) => i < 0 || i >= 45)) {
        throw const FormatException();
      }
      for (var i = 1; i < lands.length; i++) {
        if (plots.contains(lands[i].id) && !plots.contains(lands[i - 1].id)) {
          throw const FormatException();
        }
      }
      for (final q in journey) {
        final city = q ~/ 3;
        if (city > 0 &&
            !List.generate(
              3,
              (i) => (city - 1) * 3 + i,
            ).every(journey.contains)) {
          throw const FormatException();
        }
      }
      final rewardState = raw['version'] >= 7
          ? CulturalRewards.fromJson(raw['culturalRewards'])
          : CulturalRewards(
              seen: {
                ...answered.map((n) => 'lesson:$n'),
                ...journey.map((n) => 'journey:$n'),
              },
            );
      if (raw['version'] >= 7 &&
          (raw['cityStage'] is! int ||
              raw['cityStage'] < 0 ||
              raw['cityStage'] > 2)) {
        throw const FormatException();
      }
      final earned =
          completed.length * 1500 +
          journey.length * 300 +
          rewardState.colas * 500 +
          rewardState.cauris * 1000 +
          rewardState.gold * 2000;
      if (lands.any((l) => plots.contains(l.id) && earned < l.requiredGains)) {
        throw const FormatException();
      }
      final placements = <String, CityPlacement>{};
      if (raw['version'] >= 6) {
        final map = Map<String, dynamic>.from(raw['placements'] as Map);
        final used = <String>{};
        for (final e in map.entries) {
          final place = CityPlacement.fromJson(e.value);
          if (!holdings.containsKey(e.key) ||
              holdings[e.key]! <= 0 ||
              (place.landId != baseCityId && !plots.contains(place.landId)) ||
              !used.add(place.siteKey)) {
            throw const FormatException();
          }
          placements[e.key] = place;
        }
      }
      return PlayerState._(
        cash: raw['cash'] as int,
        cityStage: raw['version'] >= 7 ? raw['cityStage'] as int : 0,
        rewards: rewardState,
        holdings: holdings,
        prices: prices,
        completed: completed,
        answered: answered,
        companyCards: companyCards,
        ownedPlots: plots.toSet(),
        townBuildings: buildings,
        journeyAnswers: journey.toSet(),
        placements: placements,
        marketDropped: dropped,
        dividendPaid: paid,
        history: history,
      );
    } catch (_) {
      throw const FormatException('Sauvegarde PACO invalide.');
    }
  }
}
