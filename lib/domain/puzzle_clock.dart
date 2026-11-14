import 'stage_catalog.dart';

/// Active rounds use a deadline, so backgrounding never grants extra seconds.
int puzzleSeconds(int level) => stageSpecs[level].seconds;

class PuzzleClock {
  PuzzleClock(this.seconds, {DateTime Function()? now})
    : _now = now ?? DateTime.now;
  final int seconds;
  final DateTime Function() _now;
  DateTime? _deadline;
  bool get started => _deadline != null;
  void start() => _deadline ??= _now().add(Duration(seconds: seconds));
  int get remaining {
    if (_deadline == null) return seconds;
    final ms = _deadline!.difference(_now()).inMilliseconds;
    return ms <= 0 ? 0 : ((ms + 999) ~/ 1000).clamp(0, seconds);
  }
}
