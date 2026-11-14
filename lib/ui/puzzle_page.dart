import 'dart:async';
import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:material_ui/material_ui.dart';

import '../audio/game_audio.dart';
import '../domain/lessons.dart';
import '../game/paco_game.dart';
import 'illustrations.dart';
import 'game_chrome.dart';

class PuzzlePage extends StatefulWidget {
  const PuzzlePage({
    super.key,
    required this.level,
    this.audio,
    this.onCompleted,
  });
  final int level;
  final GameAudio? audio;
  final Future<bool> Function()? onCompleted;
  @override
  State<PuzzlePage> createState() => _PuzzlePageState();
}

class _PuzzlePageState extends State<PuzzlePage> with WidgetsBindingObserver {
  PacoGame? game;
  late final GameAudio audio;
  final stats = ValueNotifier<(int, int, int)>((0, 24, 650));
  bool won = false, lost = false;
  bool _winSaving = false, _winSaved = false;
  int attempt = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    audio = widget.audio ?? SilentGameAudio();
    if (widget.audio == null) unawaited(audio.initialize());
    unawaited(audio.setScene('puzzle'));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    game ??= createGame();
  }

  PacoGame createGame() => PacoGame(
    level: widget.level,
    reducedMotion: MediaQuery.disableAnimationsOf(context),
    onAudio: (event, chain) => audio.play(event, chain: math.max(1, chain)),
    onUpdate: (score, moves, target) {
      if (mounted) stats.value = (score, moves, target);
    },
    onWin: () {
      if (mounted) {
        setState(() => won = true);
        unawaited(_saveWin());
      }
    },
    onLose: () {
      if (mounted) setState(() => lost = true);
    },
  );
  Future<void> _saveWin() async {
    if (_winSaving || _winSaved) return;
    setState(() => _winSaving = true);
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
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      game?.resumeEngine();
    } else {
      game?.pauseEngine();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    stats.dispose();
    if (widget.audio == null) audio.dispose();
    super.dispose();
  }

  void retry() => setState(() {
    attempt++;
    won = false;
    lost = false;
    game = createGame();
  });
  void help() => unawaited(
    showDialog<void>(
      context: context,
      builder: (dc) => AlertDialog(
        title: Text(lessons[widget.level].topic),
        content: SingleChildScrollView(
          child: Text(
            '${lessons[widget.level].description}\n\n${lessons[widget.level].task}\n\nGlisse une tuile vers une case voisine, ou touche deux cases voisines. Une permutation sans alignement revient en place sans consommer de coup.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dc),
            child: const Text('C’est parti'),
          ),
        ],
      ),
    ),
  );

  Widget accessibleGrid() => ValueListenableBuilder<int>(
    valueListenable: game!.revision,
    builder: (context, revision, child) => Column(
      children: [
        for (var y = 0; y < 7; y++)
          Expanded(
            child: Row(
              children: [
                for (var x = 0; x < 7; x++)
                  Expanded(
                    child: Semantics(
                      button: true,
                      selected: game!.selectedTile == y * 7 + x,
                      label:
                          'Ligne ${y + 1}, colonne ${x + 1}, ${PacoGame.symbolNames[game!.tileType(y * 7 + x)]}${game!.isHinted(y * 7 + x) ? ', indice' : ''}',
                      onTap: won || lost || game!.isAnimating
                          ? null
                          : () => game!.selectTile(y * 7 + x),
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
      final side = math.max(344.0, constraints.maxWidth);
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
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF8D68C4), Color(0xFF4B3680)],
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
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(width: side, height: side, child: frame),
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
                value.$1 >= value.$3 * (i + 1) / 3
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
              value: (value.$1 / value.$3).clamp(0, 1),
              minHeight: 14,
              color: const Color(0xFFFFB530),
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            '${value.$1} / ${value.$3} points',
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

  Widget result() => Card.filled(
    color: const Color(0xFFFDF8E6),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Semantics(
            liveRegion: true,
            child: Text(
              won ? 'Bien joué !' : 'On réessaie ?',
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(color: const Color(0xFF7551B5)),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            won
                ? (_winSaving
                      ? 'Ta réussite est en cours d’enregistrement.'
                      : _winSaved
                      ? 'Première réussite : 1 500 FCFA-jeu. Rejouer permet de s’entraîner.'
                      : 'La sauvegarde a échoué. Réessaie de l’enregistrer.')
                : 'Tu ne perds ni épargne ni progression.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF594D70)),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _winSaving
                ? null
                : won
                ? (_winSaved ? () => Navigator.pop(context, true) : _saveWin)
                : retry,
            icon: Icon(
              won ? Icons.arrow_forward_rounded : Icons.refresh_rounded,
            ),
            label: Text(
              _winSaving
                  ? 'Enregistrement…'
                  : won
                  ? (_winSaved
                        ? 'Comprendre avec Paco'
                        : 'Réessayer l’enregistrement')
                  : 'Réessayer',
            ),
          ),
        ],
      ),
    ),
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
                  lessons[widget.level].topic,
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(color: const Color(0xFF4B3478)),
                ),
                const Text(
                  'Aligne au moins 3 symboles.',
                  style: TextStyle(color: Color(0xFF594D70)),
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
        const SizedBox(height: 10),
        GamePanel(
          color: const Color(0xFFFFF2CB),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: scorePanel(),
          ),
        ),
        const SizedBox(height: 16),
        board(),
        const SizedBox(height: 16),
        if (won || lost) result() else actions,
        const SizedBox(height: 14),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            'Glisse une pièce vers sa voisine. Deux taps fonctionnent aussi.\nFCFA-jeu fictifs · aucun argent réel.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF68547F), fontSize: 12),
          ),
        ),
      ],
    );
    return Scaffold(
      backgroundColor: const Color(0xFFF1E9FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF1E9FB),
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
