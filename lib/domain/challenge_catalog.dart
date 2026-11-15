/// Original PACO level-design rules. No network, profiling service, or rewards
/// generated from untrusted client input. Pick once when a round starts.
class ChallengeSpec {
  const ChallengeSpec({
    required this.score,
    required this.moves,
    required this.seconds,
    required this.locks,
    required this.perfectMoves,
    required this.collectType,
    required this.collectCount,
    required this.specialUses,
    required this.themeIndex,
  });

  /// Zero means that the challenge is the only winning objective.
  final int score;
  final int moves, seconds, locks, perfectMoves;

  /// Sector index 0..5, or -1 when collection is not an objective.
  final int collectType;
  final int collectCount, specialUses;

  /// Stable level identity, deliberately not reduced modulo the campaign size.
  final int themeIndex;

  static const sectorNames = [
    'cacao',
    'téléphones',
    'liasses de billets',
    'bidons',
    'ampoules',
    'engrenages',
  ];

  List<String> get objectives => [
    if (score > 0) 'Atteins $score points',
    if (locks > 0) 'Débloque $locks cadenas',
    if (perfectMoves > 0)
      'Réalise $perfectMoves coups parfaits : aligne au moins 4 pions lors d’un échange',
    if (collectCount > 0)
      'Récolte $collectCount pions ${sectorNames[collectType]}',
    if (specialUses > 0) 'Active $specialUses pions spéciaux',
  ];

  String get instruction =>
      '${objectives.join(' · ')}. $moves coups maximum, $seconds secondes.';
}

/// Six recurring teaching patterns, with increasing campaign tiers. Levels
/// beyond 30 remain reproducible and bounded instead of exhausting a list.
///
/// `mastery` is a coarse local practice tier (0..3). It may increase difficulty
/// only between rounds; do not alter a running round or its deadline.
ChallengeSpec challengeFor(int level, {int mastery = 0}) {
  if (level < 0) throw ArgumentError.value(level, 'level');
  final practice = mastery.clamp(0, 3);
  final chapter = (level ~/ 6).clamp(0, 10);
  final pattern = level % 6;
  final nominalScore = 3600 + chapter * 700 + pattern * 250;
  final combined = chapter.isOdd || pattern == 4 || pattern == 5;
  final score = pattern == 0 || combined
      ? nominalScore + (nominalScore * practice ~/ 10)
      : 0;
  final locks = pattern == 1 || pattern == 5 ? (chapter >= 2 ? 6 : 4) : 0;
  final perfectMoves = pattern == 3 ? 7 : 0;
  final collectCount = pattern == 2 || pattern == 5 ? 30 : 0;
  final specialUses = pattern == 4 ? (chapter >= 3 ? 3 : 2) : 0;
  final moves =
      ((perfectMoves > 0
                  ? 40
                  : pattern == 5
                  ? 38
                  : 34) -
              practice)
          .clamp(24, 40);
  final seconds =
      ((perfectMoves > 0 || pattern == 5 ? 180 : 120 + chapter * 10) -
              practice * 5)
          .clamp(90, 180);
  return ChallengeSpec(
    score: score,
    moves: moves,
    seconds: seconds,
    locks: locks,
    perfectMoves: perfectMoves,
    collectType: collectCount > 0 ? (level ~/ 6 + pattern) % 6 : -1,
    collectCount: collectCount,
    specialUses: specialUses,
    themeIndex: level,
  );
}
