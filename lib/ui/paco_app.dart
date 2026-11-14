import 'dart:async';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../audio/game_audio.dart';
import '../data/player_controller.dart';
import '../data/player_repository.dart';
import '../domain/lessons.dart';
import '../domain/player_state.dart';
import 'city_map.dart';
import 'collection_sheets.dart';
import 'illustrations.dart';
import 'paco_theme.dart';
import 'puzzle_map.dart';
import 'puzzle_page.dart';
export 'puzzle_page.dart' show PuzzlePage;

String money(int value) => value.toString().replaceAllMapped(
  RegExp(r'\B(?=(\d{3})+(?!\d))'),
  (_) => '\u202f',
);
String companyAsset(String id) =>
    'assets/buildings/${switch (id) {
      'cacao' => 'agro',
      'telecom' => 'telecom',
      _ => 'banque',
    }}-1.webp';

class PacoApp extends StatefulWidget {
  const PacoApp({super.key, required this.repository, this.audio});
  final PlayerRepository repository;
  final GameAudio? audio;
  @override
  State<PacoApp> createState() => _PacoAppState();
}

class _PacoAppState extends State<PacoApp> {
  late final GameAudio audio;
  @override
  void initState() {
    super.initState();
    audio = widget.audio ?? PacoAudio();
    // Render the home/loading screen before contacting native audio plugins.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(audio.initialize());
    });
  }

  @override
  void dispose() {
    if (widget.audio == null) audio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'PACO Bourse',
    debugShowCheckedModeBanner: false,
    locale: const Locale('fr'),
    supportedLocales: const [Locale('fr')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: buildPacoTheme(),
    darkTheme: buildPacoTheme(brightness: Brightness.dark),
    home: PacoHome(repository: widget.repository, audio: audio),
  );
}

class PacoHome extends StatefulWidget {
  const PacoHome({super.key, required this.repository, required this.audio});
  final PlayerRepository repository;
  final GameAudio audio;
  @override
  State<PacoHome> createState() => _PacoHomeState();
}

class _PacoHomeState extends State<PacoHome> {
  late final PlayerController controller;
  late final Listenable updates;
  @override
  void initState() {
    super.initState();
    controller = PlayerController(widget.repository);
    updates = Listenable.merge([controller, widget.audio]);
    unawaited(controller.load());
    unawaited(widget.audio.setScene('city'));
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
    if (controller.busy || index > controller.state.unlockedLevel) return;
    if (controller.state.completed.contains(index) &&
        !controller.state.answered.contains(index)) {
      await quiz(index);
      return;
    }
    await widget.audio.setScene('puzzle');
    if (!mounted) return;
    var completedThisRun = false;
    final won = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PuzzlePage(
          level: index,
          audio: widget.audio,
          onCompleted: () async {
            completedThisRun = await change((s) => s.completeLevel(index));
            return completedThisRun;
          },
        ),
      ),
    );
    unawaited(widget.audio.setScene('city'));
    if (!mounted || (won != true && !completedThisRun)) return;
    if (completedThisRun || await change((s) => s.completeLevel(index))) {
      if (mounted) await quiz(index);
    }
  }

  Future<void> quiz(int index) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => QuizSheet(
        index: index,
        onAnswer: () async {
          final ok = await change((s) => s.answerLesson(index));
          if (ok) widget.audio.play('ui');
          return ok;
        },
      ),
    );
  }

  Future<void> sheet(Widget Function(BuildContext, PlayerState) builder) async {
    widget.audio.play('ui');
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sc) => SizedBox(
        height: MediaQuery.sizeOf(sc).height * .92,
        child: AnimatedBuilder(
          animation: updates,
          builder: (_, _) => builder(sc, controller.state),
        ),
      ),
    );
  }

  Future<void> puzzleMap() async {
    widget.audio.play('ui');
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (mc) => PuzzleMapPage(
          state: controller.state,
          onLevelTap: (i) {
            Navigator.pop(mc);
            unawaited(openLesson(i));
          },
        ),
      ),
    );
  }

  void properties() => unawaited(
    sheet(
      (sc, s) => PropertiesSheet(
        state: s,
        onCompanyTap: (id) {
          Navigator.pop(sc);
          company(id);
        },
        onOpenGuichet: () {
          Navigator.pop(sc);
          guichet();
        },
      ),
    ),
  );
  void cards() => unawaited(
    sheet(
      (sc, s) => CompanyCardsSheet(
        state: s,
        onCompanyTap: (id) {
          Navigator.pop(sc);
          company(id);
        },
      ),
    ),
  );
  void company(String id) => unawaited(
    sheet(
      (sc, s) => scrollSheet(
        sc,
        companies.firstWhere((c) => c.id == id).name,
        companyContent(s, id),
      ),
    ),
  );
  void guichet() => unawaited(
    sheet((sc, s) => scrollSheet(sc, 'Le guichet', guichetContent(s))),
  );
  void history() => unawaited(
    sheet(
      (sc, s) => scrollSheet(
        sc,
        'Mon carnet',
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Retrouve tes décisions et les notions explorées. La monnaie et les entreprises sont fictives.',
            ),
            const SizedBox(height: 20),
            for (final h in s.history.reversed)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text('• $h'),
              ),
            if (s.history.isEmpty)
              const Text('Tes premiers mouvements apparaîtront ici.'),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: controller.busy ? null : reset,
              icon: const Icon(Icons.restart_alt),
              label: const Text('Recommencer la démo'),
            ),
          ],
        ),
      ),
    ),
  );
  Future<void> reset() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (dc) => AlertDialog(
        title: const Text('Recommencer la démo ?'),
        content: const Text(
          'Le portefeuille, les cartes et la progression sur cet appareil seront remplacés.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dc, false),
            child: const Text('Conserver'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dc, true),
            child: const Text('Recommencer'),
          ),
        ],
      ),
    );
    if (yes != true) return;
    try {
      await controller.reset();
      if (mounted) message('Ta nouvelle aventure commence.');
    } catch (_) {
      message('Impossible de sauvegarder. Réessaie.');
    }
  }

  void menu() => unawaited(
    sheet(
      (sc, s) => scrollSheet(
        sc,
        'Menu de Paco',
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: PacoMascot(size: 100, pose: 'expliquer')),
            SwitchListTile.adaptive(
              title: const Text('Musique'),
              subtitle: const Text('Ambiance de la ville et des puzzles'),
              value: widget.audio.musicEnabled,
              onChanged: (v) => unawaited(widget.audio.setMusicEnabled(v)),
            ),
            SwitchListTile.adaptive(
              title: const Text('Bruitages'),
              subtitle: const Text('Échanges, cascades et récompenses'),
              value: widget.audio.sfxEnabled,
              onChanged: (v) => unawaited(widget.audio.setSfxEnabled(v)),
            ),
            if (!widget.audio.ready)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Audio en préparation ou indisponible sur cet appareil. Le jeu reste jouable sans son.',
                ),
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.menu_book_outlined),
              title: const Text('Mon carnet'),
              onTap: () {
                Navigator.pop(sc);
                history();
              },
            ),
            ListTile(
              leading: const Icon(Icons.map_outlined),
              title: const Text('Parcours de puzzles'),
              onTap: () {
                Navigator.pop(sc);
                unawaited(puzzleMap());
              },
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Déplace la ville avec un doigt. Pince pour zoomer, ou utilise les boutons de zoom et de recentrage.\n\nDans les puzzles, glisse une tuile vers une voisine. Deux taps fonctionnent aussi.\n\nDémo locale · FCFA-jeu fictifs · aucun achat réel. La sauvegarde reste sur cet appareil. Les animations suivent le réglage de réduction des mouvements du téléphone.',
              ),
            ),
          ],
        ),
      ),
    ),
  );
  Widget scrollSheet(BuildContext sc, String title, Widget content) => SafeArea(
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 12, 10),
          child: Row(
            children: [
              Expanded(
                child: Text(title, style: Theme.of(sc).textTheme.headlineSmall),
              ),
              IconButton(
                tooltip: 'Fermer',
                onPressed: () => Navigator.pop(sc),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
            child: content,
          ),
        ),
      ],
    ),
  );
  int fee(int p) => math.max(25, (p + 99) ~/ 100);
  Widget companyContent(PlayerState s, String id) {
    final c = companies.firstWhere((c) => c.id == id),
        price = s.prices[id]!,
        cost = price + fee(price),
        held = s.holdings[id]!;
    final can = s.answered.contains(1) && !controller.busy;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Image.asset(
            companyAsset(id),
            height: 170,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 12),
        Chip(label: Text(c.sector)),
        const Text('Entreprise fictive · portefeuille simulé'),
        const SizedBox(height: 18),
        Text(
          '${money(price)} FCFA-jeu / part',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 6),
        Text('$held part(s) détenue(s) · épargne ${money(s.cash)} FCFA-jeu'),
        const SizedBox(height: 12),
        if (s.companyCards.contains(id))
          const Chip(
            avatar: Icon(Icons.check, size: 16),
            label: Text('Carte dans ma collection'),
          ),
        const SizedBox(height: 12),
        Text(
          'Acheter une part : ${money(price)} + ${fee(price)} de frais = ${money(cost)} FCFA-jeu.',
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton.icon(
              onPressed: can && s.cash >= cost
                  ? () async {
                      if (await change((s) => s.buy(id))) {
                        widget.audio.play('win');
                        message(
                          'Une part acquise ! Retrouve le bâtiment dans ta ville.',
                        );
                      }
                    }
                  : null,
              icon: const Icon(Icons.add_home_outlined),
              label: const Text('Acquérir une part'),
            ),
            OutlinedButton(
              onPressed: can && held > 0
                  ? () => change((s) => s.sell(id))
                  : null,
              child: Text('Vendre 1 · ${money(price - fee(price))}'),
            ),
          ],
        ),
        if (!s.answered.contains(1))
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Termine les deux premières étapes pour ouvrir les échanges.',
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    unawaited(puzzleMap());
                  },
                  child: const Text('Découvrir les actions'),
                ),
              ],
            ),
          ),
        const SizedBox(height: 20),
        const Text(
          'Une action est une participation dans une entreprise. Son prix peut monter ou baisser et aucun revenu n’est garanti. Dans PACO, tout est simulé.',
        ),
      ],
    );
  }

  Widget guichetContent(PlayerState s) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Trois entreprises pour expérimenter. Les prix sont scénarisés ; ils ne suivent pas un marché réel.',
      ),
      const SizedBox(height: 20),
      for (final c in companies)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Card.outlined(
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: Image.asset(companyAsset(c.id), width: 64),
              title: Text(c.name),
              subtitle: Text(
                '${money(s.prices[c.id]!)} FCFA-jeu · ${s.holdings[c.id]} part(s)',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(context);
                company(c.id);
              },
            ),
          ),
        ),
      const SizedBox(height: 14),
      Text(
        'Le laboratoire de Paco',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 10),
      const Text(
        'Des scénarios uniques pour comprendre le risque et le dividende.',
      ),
      const SizedBox(height: 12),
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
          s.dividendPaid ? 'Dividende déjà démontré' : 'Démontrer le dividende',
        ),
      ),
      const SizedBox(height: 12),
      const Text(
        'Pour la démonstration du dividende, termine la cinquième étape, observe la baisse et détiens une part de cacao. Le cours s’ajuste de −100 et l’épargne de +100 par part : aucun gain instantané de valeur totale.',
      ),
    ],
  );

  Widget hudPanel(Widget child) => Material(
    elevation: 3,
    shadowColor: const Color(0x3322482D),
    color: Theme.of(context).colorScheme.surfaceContainerLow,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(22),
      side: const BorderSide(color: Color(0x55FFFFFF), width: 2),
    ),
    child: child,
  );
  Widget dockButton(
    String label,
    IconData icon,
    VoidCallback action, {
    bool primary = false,
  }) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          elevation: primary ? 7 : 3,
          color: primary
              ? const Color(0xFF225A3C)
              : Theme.of(context).colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(primary ? 25 : 19),
            side: BorderSide(
              color: primary
                  ? const Color(0xFFECF8A3)
                  : const Color(0xFFDCE6CD),
              width: 2,
            ),
          ),
          child: SizedBox(
            width: primary ? 66 : 56,
            height: primary ? 66 : 56,
            child: Icon(
              icon,
              size: primary ? 33 : 26,
              color: primary
                  ? const Color(0xFFECF8A3)
                  : Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Color(0xFF163C32),
            shadows: [Shadow(color: Colors.white, blurRadius: 5)],
          ),
        ),
      ],
    );
    return Expanded(
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: GestureDetector(
          key: ValueKey('dock-$label'),
          behavior: HitTestBehavior.opaque,
          onTap: controller.busy ? null : action,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: content,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: updates,
    builder: (context, _) {
      final s = controller.state;
      return Scaffold(
        backgroundColor: const Color(0xFFDDECCE),
        body: controller.loading
            ? const Center(child: CircularProgressIndicator())
            : controller.error != null
            ? SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(controller.error!),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: controller.load,
                          child: const Text('Réessayer'),
                        ),
                        TextButton(
                          onPressed: controller.busy ? null : reset,
                          child: const Text('Réinitialiser avec confirmation'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : Stack(
                children: [
                  Positioned.fill(
                    child: MediaQuery.withClampedTextScaling(
                      minScaleFactor: 1,
                      maxScaleFactor: 1.15,
                      child: CityMap(
                        state: s,
                        onBuildingTap: company,
                        onGuichetTap: guichet,
                        reducedMotion: MediaQuery.disableAnimationsOf(context),
                        controlsBottomInset:
                            MediaQuery.sizeOf(context).height > 700 ? 210 : 170,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: hudPanel(
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 9,
                                      ),
                                      child: Row(
                                        children: [
                                          const PacoMascot(size: 42),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Ma ville',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleMedium,
                                                ),
                                                Text(
                                                  '${s.answered.length}/6 notions',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .labelSmall,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                hudPanel(
                                  IconButton(
                                    tooltip: 'Menu et options',
                                    onPressed: menu,
                                    icon: const Icon(Icons.menu_rounded),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: hudPanel(
                                    InkWell(
                                      borderRadius: BorderRadius.circular(22),
                                      onTap: guichet,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 9,
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.savings_rounded,
                                              color: Color(0xFFB78423),
                                              size: 21,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                '${money(s.cash)} FCFA-jeu',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelLarge,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                if (MediaQuery.textScalerOf(context).scale(14) <
                                    21) ...[
                                  const SizedBox(width: 12),
                                  const Icon(
                                    Icons.cloud_off_rounded,
                                    size: 16,
                                    color: Color(0xFF34583E),
                                  ),
                                  const SizedBox(width: 5),
                                  const Text(
                                    'Fictif',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF34583E),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (controller.busy)
                              const Padding(
                                padding: EdgeInsets.only(top: 6),
                                child: LinearProgressIndicator(minHeight: 3),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (MediaQuery.sizeOf(context).height > 700 &&
                                MediaQuery.textScalerOf(context).scale(14) < 20)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: GestureDetector(
                                  onTap: () => unawaited(puzzleMap()),
                                  child: hudPanel(
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        8,
                                        8,
                                        14,
                                        8,
                                      ),
                                      child: Row(
                                        children: [
                                          const PacoMascot(
                                            size: 52,
                                            pose: 'expliquer',
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              s.unlockedLevel == 0
                                                  ? 'Ta ville commence ici. Joue pour découvrir ta première participation.'
                                                  : s.holdings.values.every(
                                                      (v) => v == 0,
                                                    )
                                                  ? 'Le guichet t’attend. Une première part donne vie à ton bâtiment.'
                                                  : 'Touche un bâtiment pour voir tes parts, ou poursuis l’aventure.',
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall,
                                            ),
                                          ),
                                          const Icon(
                                            Icons.chevron_right_rounded,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                dockButton(
                                  'Propriétés',
                                  Icons.cottage_rounded,
                                  properties,
                                ),
                                dockButton(
                                  'Mes cartes',
                                  Icons.style_rounded,
                                  cards,
                                ),
                                dockButton(
                                  'Jouer',
                                  Icons.play_arrow_rounded,
                                  () => unawaited(puzzleMap()),
                                  primary: true,
                                ),
                                dockButton(
                                  'Guichet',
                                  Icons.storefront_rounded,
                                  guichet,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      );
    },
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
