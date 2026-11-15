import 'dart:math';

import '../domain/challenge_catalog.dart';

enum TurnPhase { swap, revert, clear, fall, shuffle }

class TileMotion {
  const TileMotion(this.type, this.from, this.to);
  final int type;

  /// Negative indices represent new pieces above the board in their column.
  final int from, to;
}

class TurnStep {
  TurnStep(
    this.phase,
    List<int> before,
    List<int> after, {
    List<int> cleared = const [],
    List<TileMotion> motions = const [],
    Map<int, SpecialPiece> specials = const {},
    Set<int> lockedCells = const {},
    this.chain = 0,
    required this.score,
    required this.moves,
  }) : before = List.unmodifiable(before),
       after = List.unmodifiable(after),
       cleared = List.unmodifiable(cleared),
       motions = List.unmodifiable(motions),
       specials = Map.unmodifiable(specials),
       lockedCells = Set.unmodifiable(lockedCells);
  final TurnPhase phase;
  final List<int> before, after, cleared;
  final List<TileMotion> motions;
  final Map<int, SpecialPiece> specials;
  final Set<int> lockedCells;
  final int chain, score, moves;
}

enum SpecialPiece { lightning, goldCoin, goldFuel, silverSickle, truck }

/// Deterministic 9×9 puzzle; a challenge is frozen for the entire round.
class MatchEngine {
  MatchEngine(
    int level, {
    int seed = 4701,
    int mastery = 0,
    ChallengeSpec? specification,
  }) : challenge = specification ?? challengeFor(level, mastery: mastery),
       _random = Random(seed + level * 137) {
    moves = challenge.moves;
    board = _newBoard();
    final candidates = List.generate(cellCount, (i) => i)..shuffle(_random);
    lockedCells.addAll(candidates.take(challenge.locks));
    if (challenge.specialUses > 0) {
      final free = candidates.where((i) => !lockedCells.contains(i)).toList();
      for (var i = 0; i < challenge.specialUses; i++) {
        specials[free[i]] =
            SpecialPiece.values[(level + i) % SpecialPiece.values.length];
      }
    }
    if (_findMove(board) == null) board = _newBoard();
  }
  static const size = 9, cellCount = size * size;
  final Random _random;
  final ChallengeSpec challenge;
  late List<int> board;
  late int moves;
  int invalidMoves = 0;
  int score = 0, perfectMoves = 0, collected = 0, specialUses = 0;
  final Set<int> lockedCells = {};
  final Map<int, SpecialPiece> specials = {};
  List<TurnStep> lastTurn = const [];
  int get target => challenge.score;
  int get locksRemaining => lockedCells.length;
  bool get won =>
      score >= target &&
      locksRemaining == 0 &&
      perfectMoves >= challenge.perfectMoves &&
      collected >= challenge.collectCount &&
      specialUses >= challenge.specialUses;
  bool get lost => moves <= 0 && !won;
  String get objectiveSummary => challenge.objectives.join(' · ');
  List<String> get progress => [
    if (target > 0) '$score / $target points',
    if (challenge.locks > 0)
      '${challenge.locks - locksRemaining} / ${challenge.locks} cadenas',
    if (challenge.perfectMoves > 0)
      '$perfectMoves / ${challenge.perfectMoves} coups parfaits',
    if (challenge.collectCount > 0)
      '$collected / ${challenge.collectCount} ${ChallengeSpec.sectorNames[challenge.collectType]}',
    if (challenge.specialUses > 0)
      '$specialUses / ${challenge.specialUses} spéciaux activés',
  ];
  static bool adjacent(int a, int b) =>
      a >= 0 &&
      b >= 0 &&
      a < cellCount &&
      b < cellCount &&
      (a % size - b % size).abs() + (a ~/ size - b ~/ size).abs() == 1;
  static Set<int> findMatches(List<int> tiles) {
    final result = <int>{};
    for (var y = 0; y < size; y++) {
      for (var x = 0; x < size; x++) {
        final i = y * size + x, v = tiles[i];
        if (v < 0) continue;
        if (x < size - 2 && v == tiles[i + 1] && v == tiles[i + 2]) {
          for (var n = x; n < size && tiles[y * size + n] == v; n++) {
            result.add(y * size + n);
          }
        }
        if (y < size - 2 && v == tiles[i + size] && v == tiles[i + 2 * size]) {
          for (var n = y; n < size && tiles[n * size + x] == v; n++) {
            result.add(n * size + x);
          }
        }
      }
    }
    return result;
  }

  static bool _hasFour(List<int> tiles) {
    for (var y = 0; y < size; y++) {
      for (var x = 0; x < size; x++) {
        final i = y * size + x;
        if (x <= size - 4 &&
            List.generate(4, (n) => tiles[i + n]).every((v) => v == tiles[i])) {
          return true;
        }
        if (y <= size - 4 &&
            List.generate(
              4,
              (n) => tiles[i + n * size],
            ).every((v) => v == tiles[i])) {
          return true;
        }
      }
    }
    return false;
  }

  void _exchange(List<int> tiles, int a, int b) {
    final v = tiles[a];
    tiles[a] = tiles[b];
    tiles[b] = v;
  }

  List<int>? _findMove(List<int> tiles) {
    List<int>? best;
    var bestRank = -1;
    for (var i = 0; i < cellCount; i++) {
      for (final j in [i + 1, i + size]) {
        if (!adjacent(i, j) ||
            lockedCells.contains(i) ||
            lockedCells.contains(j)) {
          continue;
        }
        _exchange(tiles, i, j);
        final matches = findMatches(tiles);
        final special = specials.containsKey(i) || specials.containsKey(j);
        if (matches.isNotEmpty || special) {
          var rank = matches.length;
          if (special) rank += specialUses < challenge.specialUses ? 500 : 20;
          if (perfectMoves < challenge.perfectMoves && _hasFour(tiles)) {
            rank += 400;
          }
          rank +=
              matches.where((n) => tiles[n] == challenge.collectType).length *
              (collected < challenge.collectCount ? 20 : 0);
          rank +=
              lockedCells
                  .where(
                    (n) =>
                        matches.contains(n) ||
                        matches.any((m) => adjacent(n, m)),
                  )
                  .length *
              100;
          if (rank > bestRank) {
            bestRank = rank;
            best = [i, j];
          }
        }
        _exchange(tiles, i, j);
      }
    }
    return best;
  }

  List<int>? hint() => won || lost ? null : _findMove(board);
  List<int> _newBoard() {
    for (var attempt = 0; attempt < 1000; attempt++) {
      final tiles = <int>[];
      for (var i = 0; i < cellCount; i++) {
        final allowed = List.generate(6, (v) => v)
            .where(
              (v) =>
                  !(i % size >= 2 && tiles[i - 1] == v && tiles[i - 2] == v) &&
                  !(i >= size * 2 &&
                      tiles[i - size] == v &&
                      tiles[i - size * 2] == v),
            )
            .toList();
        tiles.add(allowed[_random.nextInt(allowed.length)]);
      }
      if (_findMove(tiles) != null) return tiles;
    }
    throw StateError('Impossible de préparer un plateau jouable.');
  }

  Set<int> _blast(int index, SpecialPiece kind, int type) {
    switch (kind) {
      case SpecialPiece.lightning:
        return {for (var x = 0; x < size; x++) index ~/ size * size + x};
      case SpecialPiece.goldCoin:
        return {
          for (var i = 0; i < cellCount; i++)
            if (board[i] == type) i,
        };
      case SpecialPiece.goldFuel:
        return {
          for (var i = 0; i < cellCount; i++)
            if ((i % size - index % size).abs() <= 1 &&
                (i ~/ size - index ~/ size).abs() <= 1)
              i,
        };
      case SpecialPiece.silverSickle:
        return {for (var y = 0; y < size; y++) y * size + index % size};
      case SpecialPiece.truck:
        return {
          for (var i = 0; i < cellCount; i++)
            if ((i ~/ size - index ~/ size).abs() <= 1) i,
        };
    }
  }

  bool swap(int a, int b) {
    lastTurn = const [];
    if (won ||
        lost ||
        !adjacent(a, b) ||
        lockedCells.contains(a) ||
        lockedCells.contains(b)) {
      if (!won && !lost && adjacent(a, b)) invalidMoves++;
      return false;
    }
    final steps = <TurnStep>[];
    final original = [...board];
    final sa = specials.remove(a), sb = specials.remove(b);
    if (sa != null) specials[b] = sa;
    if (sb != null) specials[a] = sb;
    _exchange(board, a, b);
    steps.add(
      TurnStep(
        TurnPhase.swap,
        original,
        board,
        motions: [TileMotion(original[a], a, b), TileMotion(original[b], b, a)],
        score: score,
        moves: moves,
        specials: specials,
        lockedCells: lockedCells,
      ),
    );
    var matches = findMatches(board);
    final directFour = _hasFour(board);
    if (sa == null && sb == null && matches.isEmpty) {
      invalidMoves++;
      final changed = [...board];
      _exchange(board, a, b);
      steps.add(
        TurnStep(
          TurnPhase.revert,
          changed,
          board,
          motions: [TileMotion(changed[a], a, b), TileMotion(changed[b], b, a)],
          score: score,
          moves: moves,
          specials: specials,
          lockedCells: lockedCells,
        ),
      );
      lastTurn = List.unmodifiable(steps);
      return false;
    }
    moves--;
    if (directFour) perfectMoves++;
    if (sa != null) matches.add(b);
    if (sb != null) matches.add(a);
    int? createAt;
    SpecialPiece? created;
    if (directFour && sa == null && sb == null) {
      createAt = matches.contains(b) ? b : matches.first;
      created =
          SpecialPiece.values[(perfectMoves - 1) % SpecialPiece.values.length];
    }
    var chain = 1;
    while (matches.isNotEmpty && chain <= 100) {
      final before = [...board];
      final fired = <int>{};
      bool expanded = true;
      while (expanded) {
        expanded = false;
        for (final index in matches.toList()) {
          final kind = specials[index];
          if (kind != null && fired.add(index)) {
            matches.addAll(_blast(index, kind, board[index]));
            specialUses++;
            expanded = true;
          }
        }
      }
      // Padlocks are attached to cells. Matching on or beside one removes it.
      lockedCells.removeWhere(
        (n) => matches.contains(n) || matches.any((m) => adjacent(n, m)),
      );
      for (final i in fired) {
        specials.remove(i);
      }
      if (createAt != null && chain == 1) {
        matches.remove(createAt);
        specials[createAt] = created!;
      }
      if (challenge.collectType >= 0) {
        collected += matches
            .where((i) => before[i] == challenge.collectType)
            .length;
      }
      score += matches.length * 100 * min(chain, 3);
      final empty = [...board];
      for (final i in matches) {
        empty[i] = -1;
        specials.remove(i);
      }
      steps.add(
        TurnStep(
          TurnPhase.clear,
          before,
          empty,
          cleared: matches.toList(),
          chain: chain,
          score: score,
          moves: moves,
          specials: specials,
          lockedCells: lockedCells,
        ),
      );
      final motions = <TileMotion>[];
      final nextSpecials = <int, SpecialPiece>{};
      for (var x = 0; x < size; x++) {
        final survivors = <int>[];
        for (var y = size - 1; y >= 0; y--) {
          if (!matches.contains(y * size + x)) survivors.add(y * size + x);
        }
        for (var y = size - 1; y >= 0; y--) {
          final offset = size - 1 - y, to = y * size + x;
          final from = offset < survivors.length
              ? survivors[offset]
              : x - size * (offset - survivors.length + 1);
          final type = from >= 0 ? before[from] : _random.nextInt(6);
          board[to] = type;
          motions.add(TileMotion(type, from, to));
          if (specials.containsKey(from)) nextSpecials[to] = specials[from]!;
        }
      }
      specials
        ..clear()
        ..addAll(nextSpecials);
      steps.add(
        TurnStep(
          TurnPhase.fall,
          empty,
          board,
          motions: motions,
          chain: chain,
          score: score,
          moves: moves,
          specials: specials,
          lockedCells: lockedCells,
        ),
      );
      matches = findMatches(board);
      chain++;
    }
    if (matches.isNotEmpty || (!won && !lost && _findMove(board) == null)) {
      final before = [...board];
      board = _newBoard();
      steps.add(
        TurnStep(
          TurnPhase.shuffle,
          before,
          board,
          score: score,
          moves: moves,
          specials: specials,
          lockedCells: lockedCells,
        ),
      );
    }
    lastTurn = List.unmodifiable(steps);
    return true;
  }
}
