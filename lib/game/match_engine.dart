import 'dart:math';

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
    if (won || lost || !adjacent(a, b)) return false;
    _exchange(board, a, b);
    var matches = findMatches(board);
    if (matches.isEmpty) {
      _exchange(board, a, b);
      return false;
    }
    moves--;
    var chain = 1;
    while (matches.isNotEmpty) {
      score += matches.length * 30 * min(chain, 3);
      for (var x = 0; x < 7; x++) {
        final column = <int>[];
        for (var y = 6; y >= 0; y--) {
          final i = y * 7 + x;
          if (!matches.contains(i)) column.add(board[i]);
        }
        for (var y = 6; y >= 0; y--) {
          final offset = 6 - y;
          board[y * 7 + x] = offset < column.length
              ? column[offset]
              : _random.nextInt(6);
        }
      }
      matches = findMatches(board);
      chain++;
    }
    if (!won && !lost && _findMove(board) == null) board = _newBoard();
    return true;
  }
}
