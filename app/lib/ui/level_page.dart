import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../engine/board.dart' as eng;
import '../game/puzzle_game.dart';
import 'format.dart';
import 'paco.dart';
import 'scope.dart';

const _labels = {
  'cacao': 'cacao',
  'telephone': 'téléphones',
  'billet': 'billets',
  'bidon': 'bidons',
  'ampoule': 'ampoules',
  'engrenage': 'engrenages',
};

enum _Phase { intro, play, won, lost }

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
  ({double cashGained, String event, bool ago})? reward;

  eng.LevelDef get level => widget.level;

  PuzzleGame _newGame(bool dark) => PuzzleGame(
        level: level,
        dark: dark,
        onRefused: () => HapticFeedback.lightImpact(),
        onSteps: (steps) => setState(() => progress = eng.applySteps(progress, steps)),
        onSettled: () {
          if (eng.isWon(level, progress)) {
            HapticFeedback.mediumImpact();
            final g = GameScope.read(context);
            final r = g.winLevel(level, eng.stars(level, progress), eng.savingsEarned(progress).toDouble());
            setState(() {
              reward = (cashGained: r.cashGained, event: r.event.text, ago: r.ago);
              phase = _Phase.won;
            });
          } else if (progress.movesLeft <= 0) {
            setState(() {
              fails++;
              phase = _Phase.lost;
            });
          }
        },
      );

  void _retry() => setState(() {
        progress = eng.emptyProgress(level);
        round++;
        game = null;
        phase = _Phase.intro;
      });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final g = game ??= _newGame(dark);
    final s = eng.stars(level, progress);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.close), tooltip: 'Quitter le niveau', onPressed: () => Navigator.pop(context)),
        title: Text('Niveau ${level.index}'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _Hud(level: level, progress: progress),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: GestureDetector(
                      key: ValueKey(round),
                      behavior: HitTestBehavior.opaque,
                      onTapUp: phase == _Phase.play ? (d) => g.tap(d.localPosition) : null,
                      onPanStart: phase == _Phase.play ? (d) => dragStart = d.localPosition : null,
                      onPanEnd: phase == _Phase.play
                          ? (d) {
                              final start = dragStart;
                              dragStart = null;
                              final v = d.velocity.pixelsPerSecond;
                              if (start != null && v.distance > 80) g.swipe(start, v);
                            }
                          : null,
                      child: Semantics(
                        label: 'Plateau du puzzle, ${progress.movesLeft} coups restants',
                        child: GameWidget(game: g),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .55),
              child: SingleChildScrollView(
                child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: switch (phase) {
                _Phase.intro => Padding(
                    key: const ValueKey('intro'),
                    padding: const EdgeInsets.all(16),
                    child: PacoBubble(
                      pose: Pose.expliquer,
                      text: level.pacoBefore,
                      action: 'C’est parti !',
                      onAction: () => setState(() => phase = _Phase.play),
                    ),
                  ),
                _Phase.won => Padding(
                    key: const ValueKey('won'),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('★' * s + '☆' * (3 - s),
                            style: const TextStyle(fontSize: 40, color: Color(0xFFFFC533), letterSpacing: 6),
                            semanticsLabel: '$s étoiles sur 3'),
                        Text('+ ${fcfa(eng.savingsEarned(progress))} FCFA-jeu d’épargne', style: Theme.of(context).textTheme.titleMedium),
                        if (reward != null) Text('Ma Ville : ${reward!.event}', textAlign: TextAlign.center),
                        if (reward?.ago == true) Text('AGO : + ${fcfa(reward!.cashGained)} FCFA-jeu de dividendes'),
                        const SizedBox(height: 12),
                        PacoBubble(
                          pose: s == 3 ? Pose.reussir : Pose.confiance,
                          text: progress.movesLeft > 0
                              ? 'Bravo ! Tes ${progress.movesLeft} coups restants deviennent de l’épargne.'
                              : 'Bravo, objectif atteint ! Garder des coups en réserve, ça rapporte plus.',
                          action: 'Encaisser',
                          onAction: () => Navigator.pop(context),
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
                _Phase.play => const SizedBox(key: ValueKey('play'), height: 8),
              },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Hud extends StatelessWidget {
  const _Hud({required this.level, required this.progress});
  final eng.LevelDef level;
  final eng.Progress progress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Semantics(
            label: '${progress.movesLeft} coups restants',
            child: ExcludeSemantics(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(color: scheme.primary, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    Text('${progress.movesLeft}',
                        style: TextStyle(color: scheme.onPrimary, fontSize: 22, fontWeight: FontWeight.w800)),
                    Text('coups', style: TextStyle(color: scheme.onPrimary, fontSize: 11)),
                  ],
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
          Image.asset('assets/tiles/$tile.webp', width: 26),
          '${(progress.collected[tile] ?? 0).clamp(0, count)}/$count',
          _labels[tile] ?? tile,
        ),
      eng.ScoreObjective(:final target) => (const Icon(Icons.star_rounded, size: 22), '${progress.score.clamp(0, target)}/$target', 'points'),
      eng.UnlockObjective(:final count) => (Image.asset('assets/tiles/cadenas.webp', width: 26), '${progress.unlocked.clamp(0, count)}/$count', 'cadenas'),
    };
    return Semantics(
      label: '$label : $value${done ? ', objectif atteint' : ''}',
      child: ExcludeSemantics(
        child: Chip(
          avatar: icon,
          label: Text(value),
          backgroundColor: done ? Theme.of(context).colorScheme.primaryContainer : null,
        ),
      ),
    );
  }
}
