/// Local game rewards only. Collected tokens are souvenirs: their face value is
/// credited once, at collection, and cannot be exchanged a second time.
class CulturalReward {
  const CulturalReward(this.id, this.kind);
  final int id;
  final String kind;
  int get colas => kind == 'quiz5' ? 5 : 0;
  int get cauris => kind == 'quiz10'
      ? 5
      : kind.startsWith('level')
      ? 2
      : 0;
  int get gold => kind.startsWith('level') ? 5 : 0;
  int get crosses => kind == 'level10' ? 1 : 0;
  int get value => colas * 500 + cauris * 1000 + gold * 2000;
  String get rule => switch (kind) {
    'quiz5' => '5 quiz différents réussis au premier essai à la suite',
    'quiz10' => '10 quiz différents réussis au premier essai à la suite',
    'level5' => '5 niveaux consécutifs : puzzle et quiz sans faute',
    _ => '10 niveaux consécutifs : puzzle et quiz sans faute',
  };
  String get label => switch (kind) {
    'quiz5' => '5 colas',
    'quiz10' => '5 cauris',
    'level5' => '2 cauris + 5 pièces d’or',
    _ => '2 cauris + 5 pièces d’or + 1 croix d’Agadez',
  };
  Map<String, dynamic> toJson() => {'id': id, 'kind': kind};
  factory CulturalReward.fromJson(dynamic raw) {
    if (raw is! Map ||
        raw['id'] is! int ||
        raw['id'] < 1 ||
        !const ['quiz5', 'quiz10', 'level5', 'level10'].contains(raw['kind'])) {
      throw const FormatException('Récompense invalide');
    }
    return CulturalReward(raw['id'] as int, raw['kind'] as String);
  }
}

class CulturalRewards {
  CulturalRewards({
    this.quizStreak = 0,
    this.levelStreak = 0,
    this.serial = 0,
    Set<String> seen = const {},
    Set<String> faults = const {},
    Map<int, int> attempts = const {},
    Set<int> cleanPuzzles = const {},
    List<CulturalReward> pending = const [],
    Set<int> claimed = const {},
    this.colas = 0,
    this.cauris = 0,
    this.gold = 0,
    this.crosses = 0,
  }) : seen = Set.unmodifiable(seen),
       faults = Set.unmodifiable(faults),
       attempts = Map.unmodifiable(attempts),
       cleanPuzzles = Set.unmodifiable(cleanPuzzles),
       pending = List.unmodifiable(pending),
       claimed = Set.unmodifiable(claimed);
  final int quizStreak, levelStreak, serial, colas, cauris, gold, crosses;
  final Set<String> seen, faults;
  final Map<int, int> attempts;
  final Set<int> cleanPuzzles, claimed;
  final List<CulturalReward> pending;
  CulturalRewards copy({
    int? quizStreak,
    int? levelStreak,
    int? serial,
    Set<String>? seen,
    Set<String>? faults,
    Map<int, int>? attempts,
    Set<int>? cleanPuzzles,
    List<CulturalReward>? pending,
    Set<int>? claimed,
    int? colas,
    int? cauris,
    int? gold,
    int? crosses,
  }) => CulturalRewards(
    quizStreak: quizStreak ?? this.quizStreak,
    levelStreak: levelStreak ?? this.levelStreak,
    serial: serial ?? this.serial,
    seen: seen ?? this.seen,
    faults: faults ?? this.faults,
    attempts: attempts ?? this.attempts,
    cleanPuzzles: cleanPuzzles ?? this.cleanPuzzles,
    pending: pending ?? this.pending,
    claimed: claimed ?? this.claimed,
    colas: colas ?? this.colas,
    cauris: cauris ?? this.cauris,
    gold: gold ?? this.gold,
    crosses: crosses ?? this.crosses,
  );
  CulturalRewards start(int level) => copy(
    attempts: {...attempts, level: (attempts[level] ?? 0) + 1},
    levelStreak: (attempts[level] ?? 0) > 0 ? 0 : levelStreak,
  );
  CulturalRewards puzzle(int level, bool clean) => copy(
    cleanPuzzles: clean && attempts[level] == 1
        ? {...cleanPuzzles, level}
        : cleanPuzzles,
    levelStreak: clean && attempts[level] == 1 ? levelStreak : 0,
  );
  CulturalRewards quiz(String id, bool correct, {int? campaignLevel}) {
    if (seen.contains(id)) return this;
    if (!correct) {
      return copy(
        quizStreak: 0,
        levelStreak: campaignLevel != null ? 0 : levelStreak,
        faults: {...faults, id},
      );
    }
    final perfect = !faults.contains(id), q = perfect ? quizStreak + 1 : 0;
    final l = campaignLevel == null
        ? levelStreak
        : perfect && cleanPuzzles.contains(campaignLevel)
        ? levelStreak + 1
        : 0;
    var n = serial;
    final gifts = [...pending];
    if (q > 0 && q % 5 == 0) {
      gifts.add(CulturalReward(++n, q % 10 == 0 ? 'quiz10' : 'quiz5'));
    }
    if (campaignLevel != null && l > 0 && l % 5 == 0) {
      gifts.add(CulturalReward(++n, l % 10 == 0 ? 'level10' : 'level5'));
    }
    return copy(
      quizStreak: q,
      levelStreak: l,
      serial: n,
      seen: {...seen, id},
      pending: gifts,
    );
  }

  CulturalRewards collect(int id) {
    final r = pending.where((r) => r.id == id).firstOrNull;
    if (r == null || claimed.contains(id)) {
      throw StateError('Récompense déjà collectée ou inconnue.');
    }
    return copy(
      pending: pending.where((r) => r.id != id).toList(),
      claimed: {...claimed, id},
      colas: colas + r.colas,
      cauris: cauris + r.cauris,
      gold: gold + r.gold,
      crosses: crosses + r.crosses,
    );
  }

  Map<String, dynamic> toJson() => {
    'quizStreak': quizStreak,
    'levelStreak': levelStreak,
    'serial': serial,
    'seen': seen.toList()..sort(),
    'faults': faults.toList()..sort(),
    'attempts': {for (final e in attempts.entries) '${e.key}': e.value},
    'cleanPuzzles': cleanPuzzles.toList()..sort(),
    'pending': pending.map((r) => r.toJson()).toList(),
    'claimed': claimed.toList()..sort(),
    'colas': colas,
    'cauris': cauris,
    'gold': gold,
    'crosses': crosses,
  };
  factory CulturalRewards.fromJson(dynamic raw) {
    if (raw is! Map) throw const FormatException('Récompenses invalides');
    int n(String k) {
      final v = raw[k];
      if (v is! int || v < 0 || v > 1000000) throw const FormatException();
      return v;
    }

    Set<T> unique<T>(dynamic v) {
      final l = List<T>.from(v as List);
      if (l.length > 1000 || l.toSet().length != l.length) {
        throw const FormatException();
      }
      return l.toSet();
    }

    final seen = unique<String>(raw['seen']),
        faults = unique<String>(raw['faults']);
    if ([...seen, ...faults].any(
      (v) =>
          !RegExp(r'^(lesson:\d+|journey:\d+|knowledge:practical-brvm-\d+)$')
              .hasMatch(v),
    )) {
      throw const FormatException();
    }
    final attempts = {
      for (final e in (raw['attempts'] as Map).entries)
        int.parse(e.key as String): e.value as int,
    };
    final clean = unique<int>(raw['cleanPuzzles']);
    final claimed = unique<int>(raw['claimed']), serial = n('serial');
    final pending = (raw['pending'] as List)
        .map(CulturalReward.fromJson)
        .toList();
    if (attempts.entries.any(
          (e) => e.key < 0 || e.key >= 30 || e.value < 1 || e.value > 1000000,
        ) ||
        clean.any((v) => attempts[v] != 1) ||
        claimed.any((v) => v < 1 || v > serial) ||
        pending.any((r) => r.id > serial || claimed.contains(r.id)) ||
        pending.map((r) => r.id).toSet().length != pending.length) {
      throw const FormatException();
    }
    return CulturalRewards(
      quizStreak: n('quizStreak'),
      levelStreak: n('levelStreak'),
      serial: serial,
      seen: seen,
      faults: faults,
      attempts: attempts,
      cleanPuzzles: clean,
      pending: pending,
      claimed: claimed,
      colas: n('colas'),
      cauris: n('cauris'),
      gold: n('gold'),
      crosses: n('crosses'),
    );
  }
}
