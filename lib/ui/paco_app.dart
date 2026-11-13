import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:material_ui/material_ui.dart';

import '../data/player_controller.dart';
import '../data/player_repository.dart';
import '../domain/lessons.dart';
import '../domain/player_state.dart';
import '../game/paco_game.dart';
import 'paco_theme.dart';
import 'illustrations.dart';

String money(int value) => value.toString().replaceAllMapped(
  RegExp(r'\B(?=(\d{3})+(?!\d))'),
  (_) => '\u202f',
);

class PacoApp extends StatelessWidget {
  const PacoApp({super.key, required this.repository});
  final PlayerRepository repository;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'PACO Bourse',
    debugShowCheckedModeBanner: false,
    locale: const Locale('fr'),
    supportedLocales: const [Locale('fr')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: buildPacoTheme(),
    darkTheme: buildPacoTheme(brightness: Brightness.dark),
    home: PacoHome(repository: repository),
  );
}

class PacoHome extends StatefulWidget {
  const PacoHome({super.key, required this.repository});
  final PlayerRepository repository;
  @override
  State<PacoHome> createState() => _PacoHomeState();
}

class _PacoHomeState extends State<PacoHome> {
  late final PlayerController controller;
  int page = 0;
  @override
  void initState() {
    super.initState();
    controller = PlayerController(widget.repository);
    controller.load();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<bool> change(PlayerState Function(PlayerState) action) async {
    try {
      return await controller.change(action);
    } on StateError catch (e) {
      message(e.message.toString());
    } catch (_) {
      message(
        'La sauvegarde a échoué. Aucun changement n’a été validé. Réessaie.',
      );
    }
    return false;
  }

  Future<void> openLesson(int index) async {
    final s = controller.state;
    if (controller.busy || index > s.unlockedLevel) return;
    if (s.completed.contains(index) && !s.answered.contains(index)) {
      await quiz(index);
      return;
    }
    final won = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => PuzzlePage(level: index)));
    if (!mounted || won != true) return;
    if (await change((s) => s.completeLevel(index))) {
      if (mounted) {
        await quiz(index);
        if (mounted &&
            controller.state.answered.contains(index) &&
            [1, 2, 4].contains(index)) {
          setState(() => page = 1);
        }
      }
    }
  }

  Future<void> quiz(int index) async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => QuizSheet(
        index: index,
        onAnswer: () => change((s) => s.answerLesson(index)),
      ),
    );
  }

  Future<void> reset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recommencer la démo ?'),
        content: const Text(
          'Le portefeuille et la progression enregistrés sur cet appareil seront remplacés. Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Conserver'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Recommencer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await controller.reset();
      if (mounted) setState(() => page = 0);
    } catch (_) {
      message('Impossible de remplacer la sauvegarde. Réessaie.');
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      final s = controller.state;
      return Scaffold(
        appBar: AppBar(
          title: const Text('PACO Bourse'),
          actions: [
            IconButton(
              tooltip: 'À propos de cette démo',
              icon: const Icon(Icons.info_outline),
              onPressed: () => showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Apprendre avant d’investir'),
                  content: const SingleChildScrollView(
                    child: Text(
                      'Prototype pédagogique indépendant. Entreprises, monnaie et transactions fictives. Aucun achat réel ni conseil financier personnalisé.\n\nLa progression est stockée uniquement sur cet appareil. Aucun compte, classement ou service cloud n’est connecté. Effacer les données de l’application efface cette progression.',
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Compris'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: controller.loading
              ? const Center(child: CircularProgressIndicator())
              : controller.error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.save_outlined, size: 48),
                        const SizedBox(height: 16),
                        Text(controller.error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: controller.busy ? null : controller.load,
                          child: const Text('Réessayer'),
                        ),
                        TextButton(
                          onPressed: controller.busy ? null : reset,
                          child: const Text('Réinitialiser avec confirmation'),
                        ),
                      ],
                    ),
                  ),
                )
              : Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 860),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                          child: Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            spacing: 16,
                            runSpacing: 6,
                            children: [
                              const Chip(
                                avatar: Icon(Icons.science_outlined, size: 18),
                                label: Text('Démo locale · argent fictif'),
                              ),
                              Chip(
                                avatar: const Icon(
                                  Icons.savings_outlined,
                                  size: 18,
                                ),
                                label: Text('${money(s.cash)} FCFA-jeu'),
                              ),
                            ],
                          ),
                        ),
                        if (controller.busy)
                          const LinearProgressIndicator(minHeight: 2),
                        Expanded(
                          child: SingleChildScrollView(
                            key: PageStorageKey(page),
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                            child: switch (page) {
                              0 => adventure(s),
                              1 => city(s),
                              _ => journal(s),
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: page,
          onDestinationSelected: controller.busy
              ? null
              : (i) => setState(() => page = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.explore_outlined),
              selectedIcon: Icon(Icons.explore),
              label: 'Aventure',
            ),
            NavigationDestination(
              icon: Icon(Icons.location_city_outlined),
              selectedIcon: Icon(Icons.location_city),
              label: 'Ma ville',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book),
              label: 'Carnet',
            ),
          ],
        ),
      );
    },
  );

  Widget adventure(PlayerState s) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card.filled(
          color: colors.primaryContainer,
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LES FONDATIONS',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 10),
                Text(
                  'Fais grandir ta ville.\nEt tes connaissances.',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Un puzzle, une découverte et un pas de plus. Sans argent réel, à ton rythme.',
                ),
                CityIllustration(
                  height: 160,
                  ownedSectors: s.holdings.values.where((v) => v > 0).length,
                  ownedCompanyIds: s.holdings.entries
                      .where((e) => e.value > 0)
                      .map((e) => e.key)
                      .toList(),
                ),
                FilledButton.icon(
                  onPressed: controller.busy
                      ? null
                      : () => openLesson(math.min(s.unlockedLevel, 5)),
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(
                    s.unlockedLevel == 0
                        ? 'Commencer'
                        : s.unlockedLevel == 6
                        ? 'Rejouer pour s’entraîner'
                        : 'Continuer l’aventure',
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Ton parcours découverte',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text('${s.unlockedLevel} / 6 étapes explorées'),
        const SizedBox(height: 10),
        LinearProgressIndicator(
          value: s.unlockedLevel / 6,
          semanticsLabel:
              'Progression pédagogique, ${s.unlockedLevel} étapes sur 6',
        ),
        const SizedBox(height: 18),
        for (var i = 0; i < lessons.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card.outlined(
              margin: EdgeInsets.zero,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                leading: CircleAvatar(
                  backgroundColor: i > s.unlockedLevel
                      ? colors.surfaceContainerHighest
                      : colors.secondaryContainer,
                  child: i > s.unlockedLevel
                      ? Icon(Icons.lock_outline, color: colors.onSurfaceVariant)
                      : s.answered.contains(i)
                      ? Icon(Icons.check, color: colors.onSecondaryContainer)
                      : Text('${i + 1}'),
                ),
                title: Text(lessons[i].title),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    i > s.unlockedLevel
                        ? 'Termine l’étape précédente pour débloquer.'
                        : s.completed.contains(i) && !s.answered.contains(i)
                        ? 'Puzzle réussi · question à découvrir'
                        : lessons[i].topic,
                  ),
                ),
                trailing: i > s.unlockedLevel
                    ? null
                    : const Icon(Icons.chevron_right),
                enabled: i <= s.unlockedLevel && !controller.busy,
                onTap: i > s.unlockedLevel ? null : () => openLesson(i),
              ),
            ),
          ),
        const SizedBox(height: 8),
        pacoTip(
          s.unlockedLevel == 6
              ? 'Les bases sont posées. Explore ta ville et reviens sur les notions dans ton carnet.'
              : 'Tu peux te tromper et recommencer. Une question comprise débloque la suite.',
        ),
      ],
    );
  }

  Widget pacoTip(String text) => Card.filled(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PacoMascot(size: 64),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Un mot de Paco',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 6),
                Text(text),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget city(PlayerState s) {
    final canTrade = s.answered.contains(1) && !controller.busy;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ta ville, tes décisions.',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        const Text(
          'Les trois entreprises sont inventées. Les prix suivent un scénario pédagogique.',
        ),
        CityIllustration(
          height: 180,
          ownedSectors: s.holdings.values.where((n) => n > 0).length,
          ownedCompanyIds: s.holdings.entries
              .where((e) => e.value > 0)
              .map((e) => e.key)
              .toList(),
        ),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            metric('Participations', '${money(s.holdingsValue)} FCFA-jeu'),
            metric('Valeur totale', '${money(s.totalValue)} FCFA-jeu'),
            metric(
              'Secteurs détenus',
              '${s.holdings.values.where((n) => n > 0).length} / 3',
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Valeur totale = épargne + participations, avant frais de vente.',
        ),
        const SizedBox(height: 24),
        Text('Le guichet', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          canTrade
              ? 'Dans cette démo : frais de 1 %, minimum 25 FCFA-jeu par opération.'
              : 'Termine les deux premières étapes pour ouvrir le guichet.',
        ),
        const SizedBox(height: 16),
        for (final c in companies)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Card.outlined(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          c.id == 'cacao'
                              ? Icons.eco_outlined
                              : c.id == 'telecom'
                              ? Icons.cell_tower
                              : Icons.account_balance_outlined,
                          color: Color(c.colorValue),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            c.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(c.sector),
                    const SizedBox(height: 14),
                    Text(
                      '${money(s.prices[c.id]!)} FCFA-jeu / part',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${s.holdings[c.id]} part(s) détenue(s) · frais ${fee(s.prices[c.id]!)}',
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        FilledButton(
                          onPressed:
                              canTrade &&
                                  s.cash >=
                                      s.prices[c.id]! + fee(s.prices[c.id]!)
                              ? () => change((s) => s.buy(c.id))
                              : null,
                          child: Text(
                            'Acheter 1 · ${money(s.prices[c.id]! + fee(s.prices[c.id]!))}',
                          ),
                        ),
                        OutlinedButton(
                          onPressed: canTrade && s.holdings[c.id]! > 0
                              ? () => change((s) => s.sell(c.id))
                              : null,
                          child: Text(
                            'Vendre 1 · ${money(s.prices[c.id]! - fee(s.prices[c.id]!))}',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 10),
        Text(
          'Le laboratoire de Paco',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        const Text(
          'Chaque événement se produit une seule fois. Il ne prédit aucun marché réel.',
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed:
              !controller.busy && s.answered.contains(2) && !s.marketDropped
              ? () => change((s) => s.dropMarket())
              : null,
          icon: Icon(s.marketDropped ? Icons.check : Icons.trending_down),
          label: Text(
            s.marketDropped
                ? 'Baisse déjà observée'
                : 'Observer la baisse fictive',
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed:
              !controller.busy &&
                  s.answered.contains(4) &&
                  s.marketDropped &&
                  !s.dividendPaid &&
                  s.holdings['cacao']! > 0
              ? () => change((s) => s.payDividend())
              : null,
          icon: Icon(s.dividendPaid ? Icons.check : Icons.payments_outlined),
          label: Text(
            s.dividendPaid
                ? 'Dividende déjà démontré'
                : 'Démontrer le dividende',
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Dividende : après la cinquième question, observe la baisse et détiens une part de cacao. Le jeu regroupe détachement et paiement : −100 sur le cours et +100 d’épargne par part. La valeur totale ne change pas à cet instant.',
        ),
        const SizedBox(height: 20),
        pacoTip(
          'Diversifier réduit certaines dépendances. Cela ne supprime ni les risques ni la possibilité de perdre.',
        ),
      ],
    );
  }

  int fee(int p) => math.max(25, (p + 99) ~/ 100);
  Widget metric(String label, String value) => Card.filled(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          const SizedBox(height: 6),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    ),
  );

  Widget journal(PlayerState s) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Ton carnet', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 8),
      const Text(
        'Retrouve les notions explorées. Ce parcours n’est pas une certification financière.',
      ),
      const SizedBox(height: 20),
      for (var i = 0; i < lessons.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Card.outlined(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        s.answered.contains(i)
                            ? Icons.check_circle_outline
                            : Icons.lock_outline,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          lessons[i].topic,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    s.answered.contains(i)
                        ? lessons[i].explanation
                        : 'Cette notion se découvre pendant l’aventure.',
                  ),
                  if (s.completed.contains(i))
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: TextButton(
                        onPressed: controller.busy ? null : () => quiz(i),
                        child: const Text('Revoir la question'),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      const SizedBox(height: 16),
      Text('Historique local', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 12),
      if (s.history.isEmpty)
        const Text('Tes premiers mouvements apparaîtront ici.'),
      for (final entry in s.history.reversed.take(20))
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text('• $entry'),
        ),
      const SizedBox(height: 24),
      OutlinedButton.icon(
        onPressed: controller.busy ? null : reset,
        icon: const Icon(Icons.restart_alt),
        label: const Text('Recommencer la démo'),
      ),
      const SizedBox(height: 16),
      const Text(
        'Sauvegarde sur cet appareil uniquement. Aucun compte cloud connecté.',
      ),
    ],
  );
}

class PuzzlePage extends StatefulWidget {
  const PuzzlePage({super.key, required this.level});
  final int level;
  @override
  State<PuzzlePage> createState() => _PuzzlePageState();
}

class _PuzzlePageState extends State<PuzzlePage> with WidgetsBindingObserver {
  PacoGame? game;
  final stats = ValueNotifier<(int, int, int)>((0, 24, 650));
  bool won = false, lost = false;
  int attempt = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    game ??= createGame();
  }

  PacoGame createGame() => PacoGame(
    level: widget.level,
    reducedMotion: MediaQuery.disableAnimationsOf(context),
    onUpdate: (score, moves, target) => stats.value = (score, moves, target),
    onWin: () {
      if (mounted) setState(() => won = true);
    },
    onLose: () {
      if (mounted) setState(() => lost = true);
    },
  );
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
    super.dispose();
  }

  Widget puzzleBoard() => LayoutBuilder(
    builder: (context, constraints) {
      final side = math.max(336.0, constraints.maxWidth);
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: side,
          height: side,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                ExcludeSemantics(
                  child: GameWidget<PacoGame>(
                    key: ValueKey(attempt),
                    game: game!,
                  ),
                ),
                Positioned.fill(
                  child: ValueListenableBuilder<int>(
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
                                          'Ligne ${y + 1}, colonne ${x + 1}, ${PacoGame.symbolNames[game!.engine.board[y * 7 + x]]}${game!.isHinted(y * 7 + x) ? ', indice' : ''}',
                                      onTap: won || lost
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
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Puzzle ${widget.level + 1} / 6')),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  lessons[widget.level].title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(lessons[widget.level].description),
                const SizedBox(height: 12),
                const Text(
                  'Touche deux cases voisines pour aligner au moins 3 symboles identiques. Un échange sans alignement ne coûte aucun coup.',
                ),
                const SizedBox(height: 16),
                ValueListenableBuilder<(int, int, int)>(
                  valueListenable: stats,
                  builder: (context, v, _) => Semantics(
                    liveRegion: true,
                    label: 'Score ${v.$1} sur ${v.$3}, ${v.$2} coups restants',
                    child: ExcludeSemantics(
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          Chip(label: Text('Score : ${v.$1} / ${v.$3}')),
                          Chip(label: Text('${v.$2} coups restants')),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                puzzleBoard(),
                const SizedBox(height: 16),
                if (won)
                  Card.filled(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Icon(Icons.celebration_outlined, size: 32),
                          const SizedBox(height: 10),
                          Semantics(
                            liveRegion: true,
                            child: Text(
                              'Puzzle réussi !',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'La première réussite rapporte 1 500 FCFA-jeu. Rejouer permet de s’entraîner.',
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Comprendre avec Paco'),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (lost)
                  Card.filled(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Semantics(
                            liveRegion: true,
                            child: const Text(
                              'Un nouvel essai ? Tu ne perds ni épargne ni progression.',
                            ),
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: () {
                              setState(() {
                                attempt++;
                                won = false;
                                lost = false;
                                game = createGame();
                              });
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Réessayer'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: () => game?.hint(),
                    icon: const Icon(Icons.lightbulb_outline),
                    label: const Text('Montrer un échange possible'),
                  ),
                const SizedBox(height: 16),
                const Text(
                  'Le puzzle fonctionne sans connexion. Aucun argent réel n’est en jeu.',
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class QuizSheet extends StatefulWidget {
  const QuizSheet({super.key, required this.index, required this.onAnswer});
  final int index;
  final Future<bool> Function() onAnswer;
  @override
  State<QuizSheet> createState() => _QuizSheetState();
}

class _QuizSheetState extends State<QuizSheet> {
  int? selected;
  bool submitted = false, saving = false, success = false;
  @override
  Widget build(BuildContext context) {
    final l = lessons[widget.index];
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Une idée à emporter',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                tooltip: 'Fermer et reprendre plus tard',
                onPressed: saving ? null : () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(l.question, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          RadioGroup<int>(
            groupValue: selected,
            onChanged: (value) {
              if (saving || success) return;
              setState(() {
                selected = value;
                submitted = false;
              });
            },
            child: Column(
              children: [
                for (var i = 0; i < l.options.length; i++)
                  RadioListTile<int>(
                    value: i,
                    title: Text(l.options[i]),
                    contentPadding: EdgeInsets.zero,
                  ),
              ],
            ),
          ),
          if (submitted)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Semantics(
                liveRegion: true,
                child: Text(
                  (success ? 'Bien compris. ' : 'Reprenons ensemble. ') +
                      l.explanation,
                ),
              ),
            ),
          if (success)
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Continuer'),
            )
          else
            FilledButton(
              onPressed: selected == null || saving
                  ? null
                  : () async {
                      if (selected != l.answer) {
                        setState(() => submitted = true);
                        return;
                      }
                      setState(() => saving = true);
                      final saved = await widget.onAnswer();
                      if (mounted) {
                        setState(() {
                          saving = false;
                          submitted = saved;
                          success = saved;
                        });
                      }
                    },
              child: Text(saving ? 'Enregistrement…' : 'Vérifier ma réponse'),
            ),
          const SizedBox(height: 12),
          const Text(
            'Tu peux réessayer sans pénalité. La bonne réponse débloque l’étape suivante.',
          ),
        ],
      ),
    );
  }
}
