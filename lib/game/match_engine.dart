import 'dart:math';

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
    this.chain = 0,
    required this.score,
    required this.moves,
  }) : before = List.unmodifiable(before),
       after = List.unmodifiable(after),
       cleared = List.unmodifiable(cleared),
       motions = List.unmodifiable(motions);
  final TurnPhase phase;
  final List<int> before, after, cleared;
  final List<TileMotion> motions;
  final int chain, score, moves;
}

/// Pure, deterministic local puzzle. Connected rewards must be server validated.
class MatchEngine {
  MatchEngine(int level, {int seed = 4701})
    : _random = Random(seed + level * 137),
      moves = 24 - level.clamp(0, 5),
      target = 650 + level.clamp(0, 5) * 140 {
    board = _newBoard();
  }

  static const size = 7;
  final Random _random;
  late List<int> board;
  int score = 0;
  List<TurnStep> lastTurn = const [];
  int moves;
  final int target;
  bool get won => score >= target;
  bool get lost => moves <= 0 && !won;

  static bool adjacent(int a, int b) =>
      a >= 0 &&
      b >= 0 &&
      a < 49 &&
      b < 49 &&
      ((a % 7 - b % 7).abs() + (a ~/ 7 - b ~/ 7).abs() == 1);

  static Set<int> findMatches(List<int> tiles) {
    final result = <int>{};
    for (var y = 0; y < 7; y++) {
      for (var x = 0; x < 7; x++) {
        final i = y * 7 + x;
        if (x < 5 && tiles[i] == tiles[i + 1] && tiles[i] == tiles[i + 2]) {
          var n = x;
          while (n < 7 && tiles[y * 7 + n] == tiles[i]) {
            result.add(y * 7 + n);
            n++;
          }
        }
        if (y < 5 && tiles[i] == tiles[i + 7] && tiles[i] == tiles[i + 14]) {
          var n = y;
          while (n < 7 && tiles[n * 7 + x] == tiles[i]) {
            result.add(n * 7 + x);
            n++;
          }
        }
      }
    }
    return result;
  }

  void _exchange(List<int> tiles, int a, int b) {
    final value = tiles[a];
    tiles[a] = tiles[b];
    tiles[b] = value;
  }

  List<int>? _findMove(List<int> tiles) {
    for (var i = 0; i < 49; i++) {
      for (final j in [i + 1, i + 7]) {
        if (!adjacent(i, j)) continue;
        _exchange(tiles, i, j);
        final valid = findMatches(tiles).isNotEmpty;
        _exchange(tiles, i, j);
        if (valid) return [i, j];
      }
    }
    return null;
  }

  List<int>? hint() => won || lost ? null : _findMove(board);

  List<int> _newBoard() {
    while (true) {
      final tiles = <int>[];
      for (var i = 0; i < 49; i++) {
        final allowed = List.generate(6, (v) => v)
            .where(
              (v) =>
                  !(i % 7 >= 2 && tiles[i - 1] == v && tiles[i - 2] == v) &&
                  !(i >= 14 && tiles[i - 7] == v && tiles[i - 14] == v),
            )
            .toList();
        tiles.add(allowed[_random.nextInt(allowed.length)]);
      }
      if (_findMove(tiles) != null) return tiles;
    }
  }

  bool swap(int a, int b) {
    lastTurn = const [];
    if (won || lost || !adjacent(a, b)) return false;
    final steps = <TurnStep>[];
    final original = [...board];
    _exchange(board, a, b);
    steps.add(
      TurnStep(
        TurnPhase.swap,
        original,
        board,
        motions: [TileMotion(original[a], a, b), TileMotion(original[b], b, a)],
        score: score,
        moves: moves,
      ),
    );
    var matches = findMatches(board);
    if (matches.isEmpty) {
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
        ),
      );
      lastTurn = List.unmodifiable(steps);
      return false;
    }
    moves--;
    var chain = 1;
    while (matches.isNotEmpty) {
      final before = [...board];
      score += matches.length * 30 * min(chain, 3);
      final empty = [...board];
      for (final i in matches) {
        empty[i] = -1;
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
        ),
      );
      final motions = <TileMotion>[];
      for (var x = 0; x < 7; x++) {
        final survivors = <int>[];
        for (var y = 6; y >= 0; y--) {
          if (!matches.contains(y * 7 + x)) survivors.add(y * 7 + x);
        }
        for (var y = 6; y >= 0; y--) {
          final offset = 6 - y, destination = y * 7 + x;
          final source = offset < survivors.length
              ? survivors[offset]
              : x - 7 * (offset - survivors.length + 1);
          final type = source >= 0 ? before[source] : _random.nextInt(6);
          board[destination] = type;
          motions.add(TileMotion(type, source, destination));
        }
      }
      steps.add(
        TurnStep(
          TurnPhase.fall,
          empty,
          board,
          motions: motions,
          chain: chain,
          score: score,
          moves: moves,
        ),
      );
      matches = findMatches(board);
      chain++;
    }
    if (!won && !lost && _findMove(board) == null) {
      final before = [...board];
      board = _newBoard();
      steps.add(
        TurnStep(TurnPhase.shuffle, before, board, score: score, moves: moves),
      );
    }
    lastTurn = List.unmodifiable(steps);
    return true;
  }
}
