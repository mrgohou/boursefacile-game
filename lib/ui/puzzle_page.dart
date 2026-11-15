import 'dart:async';
import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:material_ui/material_ui.dart';

import '../audio/game_audio.dart';
import '../domain/lessons.dart';
import '../domain/challenge_catalog.dart';
import '../domain/puzzle_clock.dart';
import 'clay_heading.dart';
import '../game/paco_game.dart';
import 'illustrations.dart';
import 'game_chrome.dart';

class PuzzlePage extends StatefulWidget {
  const PuzzlePage({
    super.key,
    required this.level,
    this.audio,
    this.onCompleted,
    this.now,
    this.mastery = 0,
    this.onFinished,
  });
  final int level;
  final int mastery;
  final void Function(bool won, int seconds, int moves)? onFinished;
  final DateTime Function()? now;
  final GameAudio? audio;
  final Future<bool> Function()? onCompleted;
  @override
  State<PuzzlePage> createState() => _PuzzlePageState();
}

class _PuzzlePageState extends State<PuzzlePage> with WidgetsBindingObserver {
  PacoGame? game;
  final _boardScroll = ScrollController();
  late final GameAudio audio;
  final stats = ValueNotifier<(int, int, int)>((0, 24, 650));
  bool won = false, lost = false;
  bool _winSaving = false, _winSaved = false;
  int attempt = 0;
  int _lastShown = 0;
  late PuzzleClock clock;
  Timer? _timer;
  bool _started = false, _instructionOpen = false, _resultOpen = false;
  bool _timedOut = false;
  final _dialogRevision = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    audio = widget.audio ?? SilentGameAudio();
    if (widget.audio == null) unawaited(audio.initialize());
    unawaited(audio.setScene('puzzle'));
    clock = PuzzleClock(
      challengeFor(widget.level, mastery: widget.mastery).seconds,
      now: widget.now,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(instructions(initial: true));
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    game ??= createGame();
  }

  PacoGame createGame() =>
      PacoGame(
          level: widget.level,
          mastery: widget.mastery,
          reducedMotion: MediaQuery.disableAnimationsOf(context),
          canAcceptInput: () =>
              _started && !won && !lost && clock.remaining > 0,
          onAudio: (event, chain) =>
              audio.play(event, chain: math.max(1, chain)),
          onUpdate: (score, moves, target) {
            if (mounted) stats.value = (score, moves, target);
          },
          onWin: () => finish(true),
          onLose: () => finish(false),
        )
        ..inputEnabled = false
        ..pauseEngine();

  void tick() {
    if (!mounted || !_started || won || lost) return;
    if (clock.remaining == 0) {
      // A move accepted before the deadline resolves atomically in the engine.
      // If that move achieved the goal, its remaining animation cannot steal it.
      final achieved = game!.engine.won;
      audio.play(achieved ? 'win' : 'lose');
      finish(achieved, timeout: !achieved);
    } else if (clock.remaining != _lastShown) {
      setState(() => _lastShown = clock.remaining);
    }
  }

  void finish(bool success, {bool timeout = false}) {
    if (!mounted || won || lost) return;
    _timer?.cancel();
    setState(() {
      won = success;
      lost = !success;
      _timedOut = timeout;
    });
    if (game != null) {
      stats.value = (
        game!.engine.score,
        game!.engine.moves,
        game!.engine.target,
      );
    }
    widget.onFinished?.call(
      success,
      clock.seconds - clock.remaining,
      game!.engine.moves,
    );
    game?.endRound();
    if (success) unawaited(_saveWin());
    unawaited(showResult());
  }

  Future<void> startRound() async {
    if (!mounted || won || lost || _started) return;
    if (!game!.isLoaded) await game!.loaded;
    if (!mounted || won || lost) return;
    setState(() {
      _started = true;
      clock.start();
    });
    game!.inputEnabled = true;
    game!.resumeEngine();
    _timer = Timer.periodic(const Duration(milliseconds: 250), (_) => tick());
  }

  Future<void> showResult() async {
    if (_resultOpen) return;
    _resultOpen = true;
    // Never stack a result behind the help/instruction route.
    if (_instructionOpen) {
      _instructionOpen = false;
      Navigator.of(context).pop(false);
    }
    final action = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dc) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClayHeading(won: won),
                const SizedBox(height: 22),
                GamePanel(
                  color: const Color(0xFFFFF1D4),
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: ValueListenableBuilder<int>(
                      valueListenable: _dialogRevision,
                      builder: (context, revision, child) => Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          PacoMascot(
                            size: 95,
                            pose: won ? 'reussir' : 'reconfort',
                          ),
                          const SizedBox(height: 12),
                          Text(
                            won
                                ? 'Objectif atteint !'
                                : _timedOut
                                ? 'Le temps est écoulé.'
                                : 'Tu n’as plus de coups.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            won
                                ? (_winSaving
                                      ? 'Enregistrement de ta réussite…'
                                      : _winSaved
                                      ? (widget.level >= lessons.length
                                            ? 'Entraînement terminé. Le suivi pédagogique est mis à jour localement ; aucun crédit de monnaie ni nouvelle carte de campagne.'
                                            : 'Ta réussite est enregistrée. Retrouve Paco pour valider la notion. La récompense de première victoire n’est versée qu’une fois.')
                                      : 'Enregistrement impossible. Réessaie avant de continuer.')
                                : 'Tu conserves ton épargne et tes acquis. Prêt pour une nouvelle tentative ?',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 18),
                          if (won)
                            FilledButton.icon(
                              onPressed: _winSaving
                                  ? null
                                  : _winSaved
                                  ? () => Navigator.pop(dc, 'lesson')
                                  : _saveWin,
                              icon: Icon(
                                _winSaved
                                    ? Icons.school_rounded
                                    : Icons.save_outlined,
                              ),
                              label: Text(
                                _winSaving
                                    ? 'Enregistrement…'
                                    : _winSaved
                                    ? (widget.level >= lessons.length
                                          ? 'Terminer l’entraînement'
                                          : 'Comprendre avec Paco')
                                    : 'Réessayer l’enregistrement',
                              ),
                            )
                          else
                            FilledButton.icon(
                              onPressed: () => Navigator.pop(dc, 'retry'),
                              icon: const Icon(Icons.replay_rounded),
                              label: const Text('Rejouer'),
                            ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: _winSaving
                                ? null
                                : () => Navigator.pop(dc, 'home'),
                            icon: const Icon(Icons.home_rounded),
                            label: const Text('Menu principal'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    _resultOpen = false;
    if (!mounted) return;
    if (action == 'retry') {
      retry();
    } else {
      Navigator.pop(context, action == 'lesson');
    }
  }

  Future<void> _saveWin() async {
    if (_winSaving || _winSaved) return;
    setState(() => _winSaving = true);
    _dialogRevision.value++;
    var saved = false;
    try {
      saved = widget.onCompleted == null || await widget.onCompleted!();
    } catch (_) {
      saved = false;
    }
    if (mounted) {
      setState(() {
        _winSaving = false;
        _winSaved = saved;
      });
      _dialogRevision.value++;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      tick();
      if (_started && !won && !lost) game?.resumeEngine();
    } else {
      game?.pauseEngine();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _dialogRevision.dispose();
    _boardScroll.dispose();
    stats.dispose();
    if (widget.audio == null) audio.dispose();
    super.dispose();
  }

  void retry() {
    _timer?.cancel();
    setState(() {
      attempt++;
      won = false;
      lost = false;
      _winSaving = false;
      _winSaved = false;
      _timedOut = false;
      _started = false;
      clock = PuzzleClock(
        challengeFor(widget.level, mastery: widget.mastery).seconds,
        now: widget.now,
      );
      game = createGame();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(instructions(initial: true));
    });
  }

  void help() => unawaited(instructions());
  Future<void> instructions({bool initial = false}) async {
    if (!mounted || _instructionOpen || won || lost) return;
    _instructionOpen = true;
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dc) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: Text(
            'Mission ${widget.level + 1} · ${lessons[widget.level % lessons.length].topic}',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(child: PacoMascot(size: 85, pose: 'expliquer')),
                Text(
                  '${game!.engine.objectiveSummary} · ${clock.seconds} secondes · ${game!.engine.moves} coups maximum.',
                ),
                const SizedBox(height: 12),
                const Text(
                  'Spéciaux : éclair = ligne, pièce en or = catégorie, bidon en or = explosion, faucille en argent = récolte, camion = ligne et colonne. Échange un spécial avec une case voisine pour l’activer.',
                ),
                const SizedBox(height: 12),
                const Text(
                  'Glisse une pièce vers une voisine pour aligner au moins 3 symboles. Tu peux aussi toucher deux cases voisines. Un échange sans alignement revient en place sans utiliser de coup.',
                ),
                const SizedBox(height: 12),
                Text(
                  initial
                      ? 'Le chrono démarre quand tu touches « C’est parti ». Ensuite, il continue même si tu quittes temporairement l’application ou relis cette consigne.'
                      : 'Le chrono continue pendant la lecture de cette aide.',
                ),
              ],
            ),
          ),
          actions: [
            if (initial)
              TextButton(
                onPressed: () {
                  _instructionOpen = false;
                  Navigator.pop(dc, false);
                  Navigator.pop(context, false);
                },
                child: const Text('Menu principal'),
              ),
            FilledButton(
              onPressed: () {
                _instructionOpen = false;
                Navigator.pop(dc, true);
                if (initial) unawaited(startRound());
              },
              child: Text(initial ? 'C’est parti' : 'Reprendre'),
            ),
          ],
        ),
      ),
    );
  }

  Widget accessibleGrid() => ValueListenableBuilder<int>(
    valueListenable: game!.revision,
    builder: (context, revision, child) => Column(
      children: [
        for (var y = 0; y < 9; y++)
          Expanded(
            child: Row(
              children: [
                for (var x = 0; x < 9; x++)
                  Expanded(
                    child: Semantics(
                      button: true,
                      selected: game!.selectedTile == y * 9 + x,
                      label:
                          'Ligne ${y + 1}, colonne ${x + 1}, ${PacoGame.symbolNames[game!.tileType(y * 9 + x)]}${game!.isHinted(y * 9 + x) ? ', indice' : ''}',
                      onTap: !_started || won || lost || game!.isAnimating
                          ? null
                          : () => game!.selectTile(y * 9 + x),
                      child: const SizedBox.expand(),
                    ),
                  ),
              ],
            ),
          ),
      ],
    ),
  );

  Widget board() => LayoutBuilder(
    builder: (context, constraints) {
      final side = math.max(444.0, constraints.maxWidth);
      final surface = Stack(
        children: [
          ExcludeSemantics(
            child: GameWidget<PacoGame>(key: ValueKey(attempt), game: game!),
          ),
          Positioned.fill(child: accessibleGrid()),
        ],
      );
      final frame = Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              HSLColor.fromAHSL(
                1,
                (widget.level * 47.0 + 265) % 360,
                .42,
                .62,
              ).toColor(),
              HSLColor.fromAHSL(
                1,
                (widget.level * 47.0 + 265) % 360,
                .4,
                .28,
              ).toColor(),
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFFFE8A0), width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x4425483D),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: surface,
        ),
      );
      return Column(
        children: [
          SingleChildScrollView(
            controller: _boardScroll,
            physics: const NeverScrollableScrollPhysics(),
            scrollDirection: Axis.horizontal,
            child: SizedBox(width: side, height: side, child: frame),
          ),
          if (side > constraints.maxWidth)
            Row(
              children: [
                IconButton.filledTonal(
                  tooltip: 'Voir les colonnes de gauche',
                  onPressed: () => _boardScroll.animateTo(
                    0,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                  ),
                  icon: const Icon(Icons.chevron_left),
                ),
                const Expanded(
                  child: Text(
                    'Plateau 9 × 9 · déplacer la vue',
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'Voir les colonnes de droite',
                  onPressed: () => _boardScroll.animateTo(
                    _boardScroll.position.maxScrollExtent,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                  ),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
        ],
      );
    },
  );

  Widget soundControls() => AnimatedBuilder(
    animation: audio,
    builder: (context, child) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: audio.musicEnabled
              ? 'Couper la musique'
              : 'Activer la musique',
          onPressed: () =>
              unawaited(audio.setMusicEnabled(!audio.musicEnabled)),
          icon: Icon(
            audio.musicEnabled
                ? Icons.music_note_rounded
                : Icons.music_off_rounded,
          ),
        ),
        IconButton(
          tooltip: audio.sfxEnabled
              ? 'Couper les bruitages'
              : 'Activer les bruitages',
          onPressed: () => unawaited(audio.setSfxEnabled(!audio.sfxEnabled)),
          icon: Icon(
            audio.sfxEnabled
                ? Icons.volume_up_rounded
                : Icons.volume_off_rounded,
          ),
        ),
      ],
    ),
  );

  Widget scorePanel() => ValueListenableBuilder<(int, int, int)>(
    valueListenable: stats,
    builder: (context, value, child) {
      final moves = Container(
        constraints: const BoxConstraints(minWidth: 78),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF7551B5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white, width: 3),
        ),
        child: Column(
          children: [
            const Text(
              'COUPS',
              style: TextStyle(
                color: Color(0xFFFFE899),
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              '${value.$2}',
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
      final progress = Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              3,
              (i) => Icon(
                (value.$3 > 0 && value.$1 >= value.$3 * (i + 1) / 3) ||
                        (game?.engine.won ?? false)
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                color: const Color(0xFFC4942D),
                size: 25,
              ),
            ),
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: LinearProgressIndicator(
              value: value.$3 > 0
                  ? (value.$1 / value.$3).clamp(0, 1)
                  : (game?.engine.won ?? false)
                  ? 1
                  : 0,
              minHeight: 14,
              color: const Color(0xFFFFB530),
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            value.$3 > 0
                ? '${value.$1} / ${value.$3} points'
                : '${value.$1} points bonus · réussis le défi',
            style: const TextStyle(
              color: Color(0xFF594D70),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
      return Semantics(
        liveRegion: true,
        label: 'Score ${value.$1} sur ${value.$3}, ${value.$2} coups restants',
        child: ExcludeSemantics(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              children: [
                moves,
                const SizedBox(width: 12),
                Expanded(child: progress),
              ],
            ),
          ),
        ),
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    final header = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          PacoMascot(
            size: 48,
            pose: won
                ? 'reussir'
                : lost
                ? 'reconfort'
                : 'confiance',
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lessons[widget.level % lessons.length].topic,
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(color: const Color(0xFF4B3478)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    final actions = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.tonalIcon(
              onPressed: () => game?.hint(),
              icon: const Icon(Icons.lightbulb_outline_rounded),
              label: const Text('Un indice'),
            ),
          ),
          const SizedBox(width: 12),
          IconButton.filledTonal(
            tooltip: 'Comprendre la notion',
            onPressed: help,
            icon: const Icon(Icons.menu_book_rounded),
          ),
        ],
      ),
    );
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        ValueListenableBuilder<int>(
          valueListenable: game!.revision,
          builder: (context, _, child) => Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              game!.engine.progress.join(' · '),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
        const SizedBox(height: 10),
        GamePanel(
          color: const Color(0xFFFFF2CB),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: scorePanel(),
          ),
        ),
        const SizedBox(height: 16),
        Semantics(
          liveRegion: clock.remaining <= 10,
          child: GamePanel(
            color: clock.remaining <= 10
                ? const Color(0xFFFFD8D3)
                : const Color(0xFFE5F4FF),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Temps restant : ${clock.remaining ~/ 60}:${(clock.remaining % 60).toString().padLeft(2, '0')}',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        AbsorbPointer(absorbing: !_started || won || lost, child: board()),
        const SizedBox(height: 16),
        if (!won && !lost) actions,
        const SizedBox(height: 14),
      ],
    );
    return Scaffold(
      backgroundColor: const Color(0xFFF1E9FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF1E9FB),
        leading: IconButton(
          tooltip: 'Menu principal',
          onPressed: () => Navigator.pop(context, false),
          icon: const Icon(Icons.home_rounded),
        ),
        title: Text('Niveau ${widget.level + 1}'),
        actions: [
          soundControls(),
          IconButton(
            tooltip: 'La notion de Paco',
            onPressed: help,
            icon: const Icon(Icons.help_outline_rounded),
          ),
        ],
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF1E9FB), Color(0xFFDDD5F7), Color(0xFFE6F5FF)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 28),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: content,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
