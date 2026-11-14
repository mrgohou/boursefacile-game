import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../engine/board.dart' as eng;
import '../game/puzzle_game.dart';
import '../services/audio.dart';
import 'format.dart';
import 'paco.dart';
import 'scope.dart';
import 'stars.dart';

const _labels = {
  'cacao': 'cacao',
  'telephone': 'téléphones',
  'billet': 'billets',
  'bidon': 'bidons',
  'ampoule': 'ampoules',
  'engrenage': 'engrenages',
};

enum _Phase { intro, play, finale, won, lost }

/// Un niveau : objectifs en haut, plateau Flame au centre, Paco en bas (zone du pouce).
class LevelPage extends StatefulWidget {
  const LevelPage({super.key, required this.level});
  final eng.LevelDef level;

  @override
  State<LevelPage> createState() => _LevelPageState();
}

class _LevelPageState extends State<LevelPage> {
  late eng.Progress progress = eng.emptyProgress(widget.level);
  _Phase phase = _Phase.intro;
  int fails = 0;
  int round = 0;
  PuzzleGame? game;
  Offset? dragStart;
  bool dragDone = false;
  int bonus = 0; // coups déjà convertis en épargne pendant la fin de partie
  String? word;
  int wordKey = 0;
  ({double cashGained, String event, bool ago})? reward;

  eng.LevelDef get level => widget.level;

  @override
  void initState() {
    super.initState();
    GameAudio.instance.track(Track.puzzle);
  }

  @override
  void dispose() {
    GameAudio.instance.track(Track.ville);
    super.dispose();
  }

  PuzzleGame _newGame(bool dark) => PuzzleGame(
        level: level,
        dark: dark,
        onRefused: () => HapticFeedback.lightImpact(),
        onWord: (w) => setState(() {
          word = w;
          wordKey++;
        }),
        onSteps: (steps) => setState(() => progress = eng.applySteps(progress, steps)),
        onSettled: _settled,
      );

  Future<void> _settled() async {
    if (eng.isWon(level, progress)) {
      HapticFeedback.mediumImpact();
      final g = GameScope.read(context);
      final r = g.winLevel(level, eng.stars(level, progress), eng.savingsEarned(progress).toDouble());
      setState(() {
        reward = (cashGained: r.cashGained, event: r.event.text, ago: r.ago);
        phase = _Phase.finale;
        word = 'Objectif atteint !';
        wordKey++;
      });
      await game?.finale(progress.movesLeft, (k) => setState(() => bonus = k));
      if (!mounted) return;
      GameAudio.instance.play('win');
      setState(() => phase = _Phase.won);
    } else if (progress.movesLeft <= 0) {
      game?.active = false;
      GameAudio.instance.play('lose');
      setState(() {
        fails++;
        phase = _Phase.lost;
      });
    }
  }

  void _play() {
    GameAudio.instance.play('start');
    game?.active = true;
    setState(() => phase = _Phase.play);
  }

  void _retry() => setState(() {
        progress = eng.emptyProgress(level);
        round++;
        bonus = 0;
        game = null;
        phase = _Phase.intro;
      });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final g = game ??= _newGame(dark);
    final s = eng.stars(level, progress);
    final city = GameScope.of(context).content.cities[level.city - 1];
    final playing = phase == _Phase.play;
    final number = (level.city - 1) * 3 + level.index;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.close), tooltip: 'Quitter le niveau', onPressed: () => Navigator.pop(context)),
        title: Text('Niveau $number · ${city.name}'),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: dark ? const [Color(0xFF12302A), Color(0xFF0C211C)] : const [Color(0xFFEAF8D8), Color(0xFFCBEFE9)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _Hud(level: level, progress: progress, moves: phase == _Phase.finale || phase == _Phase.won ? math.max(0, progress.movesLeft - bonus) : progress.movesLeft),
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: GestureDetector(
                        key: ValueKey(round),
                        behavior: HitTestBehavior.opaque,
                        onTapUp: playing ? (d) => g.tap(d.localPosition) : null,
                        onPanStart: playing
                            ? (d) {
                                dragStart = d.localPosition;
                                dragDone = false;
                                g.press(d.localPosition);
                              }
                            : null,
                        onPanUpdate: playing
                            ? (d) {
                                final start = dragStart;
                                if (start == null || dragDone) return;
                                dragDone = g.drag(start, d.localPosition - start);
                              }
                            : null,
                        onPanEnd: playing ? (_) => g.release() : null,
                        onPanCancel: playing ? g.release : null,
                        child: Semantics(
                          label: 'Plateau du puzzle, ${progress.movesLeft} coups restants. Fais glisser une pièce vers sa voisine pour l’échanger.',
                          child: GameWidget(game: g),
                        ),
                      ),
                    ),
                    if (word != null) Positioned.fill(child: IgnorePointer(child: _WordBurst(key: ValueKey(wordKey), text: word!))),
                  ],
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .55),
                child: SingleChildScrollView(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    transitionBuilder: (child, a) => SlideTransition(
                      position: Tween(begin: const Offset(0, .3), end: Offset.zero).animate(CurvedAnimation(parent: a, curve: Curves.easeOutBack)),
                      child: FadeTransition(opacity: a, child: child),
                    ),
                    child: switch (phase) {
                      _Phase.intro => Padding(
                          key: const ValueKey('intro'),
                          padding: const EdgeInsets.all(16),
                          child: PacoBubble(pose: Pose.expliquer, text: level.pacoBefore, action: 'C’est parti !', onAction: _play),
                        ),
                      _Phase.won => Padding(
                          key: const ValueKey('won'),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _StarsReveal(count: s),
                              Text('+ ${fcfa(eng.savingsEarned(progress))} FCFA-jeu d’épargne', style: Theme.of(context).textTheme.titleMedium),
                              if (reward != null) Text('Ma Ville : ${reward!.event}', textAlign: TextAlign.center),
                              if (reward?.ago == true) Text('AGO : + ${fcfa(reward!.cashGained)} FCFA-jeu de dividendes'),
                              const SizedBox(height: 12),
                              PacoBubble(
                                pose: s == 3 ? Pose.reussir : Pose.confiance,
                                text: progress.movesLeft > 0
                                    ? 'Bravo ! Tes ${progress.movesLeft} coups restants sont devenus de l’épargne.'
                                    : 'Bravo, objectif atteint ! Garder des coups en réserve, ça rapporte plus.',
                                action: 'Encaisser',
                                onAction: () {
                                  GameAudio.instance.play('coin');
                                  Navigator.pop(context);
                                },
                              ),
                            ],
                          ),
                        ),
                      _Phase.lost => Padding(
                          key: const ValueKey('lost'),
                          padding: const EdgeInsets.all(16),
                          child: PacoBubble(
                            pose: fails >= 2 ? Pose.reflechir : Pose.reconfort,
                            text: fails >= 2 ? level.pacoHint : 'Presque ! On réessaie ? Tu ne perds rien, chaque essai t’entraîne.',
                            action: 'Rejouer',
                            onAction: _retry,
                          ),
                        ),
                      _Phase.play || _Phase.finale => const SizedBox(key: ValueKey('play'), height: 8),
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Grand mot qui jaillit au centre du plateau (« Super ! », « Dividende ! »…).
class _WordBurst extends StatelessWidget {
  const _WordBurst({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: text,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 1100),
        builder: (context, t, _) {
          final pop = Curves.elasticOut.transform(math.min(1, t * 2.2));
          final fade = t < .7 ? 1.0 : (1 - t) / .3;
          return Opacity(
            opacity: fade.clamp(0, 1),
            child: Transform.translate(
              offset: Offset(0, -30 * t),
              child: Transform.scale(
                scale: .3 + .7 * pop,
                child: Center(
                  child: Stack(
                    children: [
                      Text(
                        text,
                        style: TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w800,
                          foreground: Paint()
                            ..style = PaintingStyle.stroke
                            ..strokeWidth = 8
                            ..color = const Color(0xFF103C30),
                        ),
                      ),
                      Text(text, style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w800, color: Color(0xFFD1F88C))),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Les étoiles apparaissent une à une, avec un tintement.
class _StarsReveal extends StatefulWidget {
  const _StarsReveal({required this.count});
  final int count;

  @override
  State<_StarsReveal> createState() => _StarsRevealState();
}

class _StarsRevealState extends State<_StarsReveal> {
  int shown = 0;

  @override
  void initState() {
    super.initState();
    _next();
  }

  Future<void> _next() async {
    for (var i = 0; i < widget.count; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 280));
      if (!mounted) return;
      GameAudio.instance.play('star');
      setState(() => shown = i + 1);
    }
  }

  @override
  Widget build(BuildContext context) => Semantics(
        label: '${widget.count} étoile${widget.count > 1 ? 's' : ''} sur 3',
        child: ExcludeSemantics(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 3; i++)
                AnimatedScale(
                  scale: i < shown ? 1 : (i < widget.count ? .4 : 1),
                  duration: const Duration(milliseconds: 380),
                  curve: Curves.elasticOut,
                  child: Icon(i < shown ? Icons.star_rounded : Icons.star_outline_rounded, size: 52, color: const Color(0xFFE0A100)),
                ),
            ],
          ),
        ),
      );
}

class _Hud extends StatelessWidget {
  const _Hud({required this.level, required this.progress, required this.moves});
  final eng.LevelDef level;
  final eng.Progress progress;
  final int moves;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final low = moves <= 3;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          Semantics(
            label: '$moves coups restants',
            child: ExcludeSemantics(
              child: TweenAnimationBuilder<double>(
                key: ValueKey(moves),
                tween: Tween(begin: 1.25, end: 1),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                builder: (context, sc, child) => Transform.scale(scale: sc, child: child),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: low ? scheme.error : scheme.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text('$moves', style: TextStyle(color: low ? scheme.onError : scheme.onPrimary, fontSize: 24, fontWeight: FontWeight.w800)),
                      Text('coups', style: TextStyle(color: low ? scheme.onError : scheme.onPrimary, fontSize: 11)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [for (final o in level.objectives) _objChip(context, o)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _objChip(BuildContext context, eng.Objective o) {
    final done = eng.objectiveDone(o, progress);
    final (Widget icon, String value, String label) = switch (o) {
      eng.CollectObjective(:final tile, :final count) => (
          Image.asset('assets/tiles/$tile.webp', width: 28),
          '${(progress.collected[tile] ?? 0).clamp(0, count)}/$count',
          _labels[tile] ?? tile,
        ),
      eng.ScoreObjective(:final target) => (const Icon(Icons.star_rounded, size: 22), '${progress.score.clamp(0, target)}/$target', 'points'),
      eng.UnlockObjective(:final count) => (Image.asset('assets/tiles/cadenas.webp', width: 28), '${progress.unlocked.clamp(0, count)}/$count', 'cadenas'),
    };
    return Semantics(
      label: '$label : $value${done ? ', objectif atteint' : ''}',
      child: ExcludeSemantics(
        child: TweenAnimationBuilder<double>(
          key: ValueKey(value),
          tween: Tween(begin: 1.18, end: 1),
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutBack,
          builder: (context, sc, child) => Transform.scale(scale: sc, child: child),
          child: Chip(
            avatar: done ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary) : icon,
            label: Text(value),
            backgroundColor: done ? Theme.of(context).colorScheme.primaryContainer : null,
          ),
        ),
      ),
    );
  }
}
