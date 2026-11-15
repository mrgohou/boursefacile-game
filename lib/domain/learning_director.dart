import 'challenge_catalog.dart';

/// A transparent local statistical director, not an LLM or an investor profile.
/// Updates return a new value; a selected round must freeze its challenge spec.
class LearningProfile {
  LearningProfile({
    this.rounds = 0,
    this.wins = 0,
    this.failures = 0,
    this.failureStreak = 0,
    this.meanTimeRatio = 1,
    this.meanMovesRemainingRatio = 0,
    Map<String, int> quizCorrect = const {},
    Map<String, int> quizWrong = const {},
    Map<String, int> buysByFamily = const {},
    Map<String, int> tradesByCompany = const {},
    this.buys = 0,
    this.sells = 0,
  }) : quizCorrect = Map.unmodifiable(quizCorrect),
       quizWrong = Map.unmodifiable(quizWrong),
       buysByFamily = Map.unmodifiable(buysByFamily),
       tradesByCompany = Map.unmodifiable(tradesByCompany);

  final int rounds, wins, failures, failureStreak, buys, sells;
  final double meanTimeRatio, meanMovesRemainingRatio;
  final Map<String, int> quizCorrect, quizWrong, buysByFamily, tradesByCompany;

  int get mastery {
    if (rounds < 3 || failureStreak >= 2) return 0;
    final success = (wins + 1) / (rounds + 2);
    if (success >= .8 &&
        rounds >= 10 &&
        meanTimeRatio < .65 &&
        meanMovesRemainingRatio > .25) {
      return 3;
    }
    if (success >= .7 &&
        rounds >= 6 &&
        meanTimeRatio < .8 &&
        meanMovesRemainingRatio > .15) {
      return 2;
    }
    return success >= .6 ? 1 : 0;
  }

  /// Unlimited deterministic practice identities; no economy rewards implied.
  int get nextPracticeLevel => 30 + rounds;

  String get recommendedTopic {
    final topics = {...quizCorrect.keys, ...quizWrong.keys};
    if (topics.isNotEmpty) {
      final ranked = topics.toList()
        ..sort((a, b) {
          double confidence(String topic) =>
              ((quizCorrect[topic] ?? 0) + 1) /
              ((quizCorrect[topic] ?? 0) + (quizWrong[topic] ?? 0) + 2);
          final order = confidence(a).compareTo(confidence(b));
          return order == 0 ? a.compareTo(b) : order;
        });
      final first = ranked.first;
      if ((quizWrong[first] ?? 0) > (quizCorrect[first] ?? 0)) return first;
    }
    if (buys >= 3 && buysByFamily.values.any((n) => n / buys >= .75)) {
      return 'Diversification';
    }
    if (sells >= 3) return 'Frais';
    return 'Budget';
  }

  String get explanation => failureStreak >= 2
      ? 'Deux essais difficiles : le prochain entraînement revient au palier de base.'
      : 'Palier $mastery selon tes réussites, le temps et les coups utilisés. Notion proposée : $recommendedTopic.';

  LearningProfile _copy({
    int? rounds,
    int? wins,
    int? failures,
    int? failureStreak,
    double? time,
    double? moves,
    Map<String, int>? correct,
    Map<String, int>? wrong,
    Map<String, int>? families,
    Map<String, int>? companies,
    int? buys,
    int? sells,
  }) => LearningProfile(
    rounds: rounds ?? this.rounds,
    wins: wins ?? this.wins,
    failures: failures ?? this.failures,
    failureStreak: failureStreak ?? this.failureStreak,
    meanTimeRatio: time ?? meanTimeRatio,
    meanMovesRemainingRatio: moves ?? meanMovesRemainingRatio,
    quizCorrect: correct ?? quizCorrect,
    quizWrong: wrong ?? quizWrong,
    buysByFamily: families ?? buysByFamily,
    tradesByCompany: companies ?? tradesByCompany,
    buys: buys ?? this.buys,
    sells: sells ?? this.sells,
  );

  LearningProfile recordRound({
    required int level,
    required bool won,
    required int elapsedSeconds,
    required int remainingMoves,
  }) {
    if (level < 0 || elapsedSeconds < 0 || remainingMoves < 0) {
      throw ArgumentError('Mesure de partie invalide.');
    }
    final spec = challengeFor(level, mastery: mastery);
    final time = (elapsedSeconds / spec.seconds).clamp(0.0, 1.0).toDouble();
    final moves = (remainingMoves / spec.moves).clamp(0.0, 1.0).toDouble();
    return _copy(
      rounds: rounds + 1,
      wins: wins + (won ? 1 : 0),
      failures: failures + (won ? 0 : 1),
      failureStreak: won ? 0 : failureStreak + 1,
      time: rounds == 0 ? time : meanTimeRatio * .75 + time * .25,
      moves: rounds == 0 ? moves : meanMovesRemainingRatio * .75 + moves * .25,
    );
  }

  LearningProfile recordQuiz({required String topic, required bool correct}) {
    _name(topic);
    final map = correct ? quizCorrect : quizWrong;
    final updated = {...map, topic: (map[topic] ?? 0) + 1};
    return correct ? _copy(correct: updated) : _copy(wrong: updated);
  }

  LearningProfile recordTrade({
    required String companyId,
    required String family,
    required bool buy,
  }) {
    _name(companyId);
    _name(family);
    return _copy(
      buys: buys + (buy ? 1 : 0),
      sells: sells + (buy ? 0 : 1),
      companies: {
        ...tradesByCompany,
        companyId: (tradesByCompany[companyId] ?? 0) + 1,
      },
      families: buy
          ? {...buysByFamily, family: (buysByFamily[family] ?? 0) + 1}
          : buysByFamily,
    );
  }

  static void _name(String name) {
    if (name.trim().isEmpty || name.length > 100) {
      throw ArgumentError('Identifiant invalide.');
    }
  }

  Map<String, dynamic> toJson() => {
    'version': 1,
    'rounds': rounds,
    'wins': wins,
    'failures': failures,
    'failureStreak': failureStreak,
    'meanTimeRatio': meanTimeRatio,
    'meanMovesRemainingRatio': meanMovesRemainingRatio,
    'quizCorrect': quizCorrect,
    'quizWrong': quizWrong,
    'buysByFamily': buysByFamily,
    'tradesByCompany': tradesByCompany,
    'buys': buys,
    'sells': sells,
  };

  factory LearningProfile.fromJson(Map<String, dynamic> raw) {
    if (raw['version'] != 1) {
      throw const FormatException('Version du suivi inconnue.');
    }
    int number(String key) {
      final n = raw[key];
      if (n is! int || n < 0 || n > 1000000) {
        throw const FormatException('Compteur invalide.');
      }
      return n;
    }

    double ratio(String key) {
      final n = raw[key];
      if (n is! num || !n.isFinite || n < 0 || n > 1) {
        throw const FormatException('Ratio invalide.');
      }
      return n.toDouble();
    }

    Map<String, int> counters(String key) {
      final value = raw[key];
      if (value is! Map || value.length > 128) {
        throw const FormatException('Liste invalide.');
      }
      final result = <String, int>{};
      for (final entry in value.entries) {
        if (entry.key is! String ||
            (entry.key as String).trim().isEmpty ||
            (entry.key as String).length > 100 ||
            entry.value is! int ||
            entry.value < 0 ||
            entry.value > 1000000) {
          throw const FormatException('Compteur invalide.');
        }
        result[entry.key as String] = entry.value as int;
      }
      return result;
    }

    final p = LearningProfile(
      rounds: number('rounds'),
      wins: number('wins'),
      failures: number('failures'),
      failureStreak: number('failureStreak'),
      meanTimeRatio: ratio('meanTimeRatio'),
      meanMovesRemainingRatio: ratio('meanMovesRemainingRatio'),
      quizCorrect: counters('quizCorrect'),
      quizWrong: counters('quizWrong'),
      buysByFamily: counters('buysByFamily'),
      tradesByCompany: counters('tradesByCompany'),
      buys: number('buys'),
      sells: number('sells'),
    );
    if (p.rounds != p.wins + p.failures ||
        p.failureStreak > p.failures ||
        p.buysByFamily.values.fold(0, (a, b) => a + b) != p.buys ||
        p.tradesByCompany.values.fold(0, (a, b) => a + b) != p.buys + p.sells) {
      throw const FormatException('Suivi incohérent.');
    }
    return p;
  }
}
