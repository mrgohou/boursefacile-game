// Écran d'accueil : la ville du joueur en plein écran, façon city-builder.
// En haut : titre et progression, épargne, séance. En bas : le dock à portée du pouce.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../engine/city.dart';
import '../../services/audio.dart';
import '../../services/game_state.dart';
import '../brand_theme.dart';
import '../cards_tab.dart';
import '../format.dart';
import '../market_pages.dart';
import '../paco.dart';
import '../route_page.dart';
import '../scope.dart';
import '../settings_tab.dart';
import '../welcome.dart';
import 'city_layout.dart';
import 'city_map.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _view = TransformationController();
  bool _paco = false;

  @override
  void initState() {
    super.initState();
    GameAudio.instance.track(Track.ville);
  }

  @override
  void dispose() {
    _view.dispose();
    super.dispose();
  }

  Future<void> _open(Widget page) async {
    GameAudio.instance.play('tap', volume: .5);
    HapticFeedback.selectionClick();
    setState(() => _paco = false);
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  void _recenter(Size size) => _view.value = CityMap.focus(size, plaza.center.translate(0, 40), .5);

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    if (!game.seenIntro.contains(0)) return const Welcome();
    final open = game.cityUnlocked(2);
    final size = MediaQuery.sizeOf(context);
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: ColoredBox(
              color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF173B4A) : const Color(0xFF8ED6EA),
              child: CityMap(
                controller: _view,
                onPlaza: () => _open(const SgiPage()),
                onPlot: (p) {
                  GameAudio.instance.play('tap', volume: .5);
                  showCompanySheet(context, p.company!);
                },
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _ProfileBadge(game: game, onTap: () => _open(const ProfilePage()))),
                      const SizedBox(width: 8),
                      _SavingsChip(amount: game.savings),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _SeanceChip(city: game.city),
                ],
              ),
            ),
          ),
          Positioned(
            right: 12,
            bottom: 132,
            child: Column(
              children: [
                _RoundButton(
                  tooltip: 'Recentrer la ville',
                  onTap: () => _recenter(size),
                  child: const Icon(Icons.center_focus_strong_outlined),
                ),
                const SizedBox(height: 12),
                _RoundButton(
                  tooltip: 'Demander conseil à Paco',
                  size: 64,
                  onTap: () {
                    GameAudio.instance.play('select', volume: .6);
                    setState(() => _paco = !_paco);
                  },
                  child: ClipOval(child: Image.asset('assets/paco/accueil.webp', fit: BoxFit.cover, alignment: Alignment.topCenter)),
                ),
              ],
            ),
          ),
          if (_paco)
            Positioned(
              left: 12,
              right: 88,
              bottom: 132,
              child: GestureDetector(
                onTap: () => setState(() => _paco = false),
                child: PacoBubble(pose: Pose.expliquer, size: 0, text: _pacoText(game, open)),
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: _Dock(
                marketOpen: open,
                cardsCount: game.cards.length,
                onProperties: () => _open(const PropertiesPage()),
                onCards: () => _open(const CardsPage()),
                onPlay: () => _open(const RoutePage()),
                onSgi: () => _open(const SgiPage()),
                onMe: () => _open(const ProfilePage()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _pacoText(GameState game, bool open) {
    if (!open) return marketLockedText;
    final tip = pacoTip(game.city, game.companies, game.citiesDone);
    return tip?.text ?? 'Chaque partie gagnée fait avancer la bourse d’une séance. Touche un bâtiment pour voir ton entreprise.';
  }
}

/// Titre du joueur et progression vers le titre suivant.
(String?, double) nextTitle(GameState g) {
  final d = g.citiesDone;
  if (d < 4) return ('Actionnaire Moyen', d / 4);
  if (d < 9) return ('Investisseur Patient', (d - 4) / 5);
  if (d < 15) return ('GOAT de la BRVM', (d - 9) / 6 * .7);
  if (g.score < goatScore) return ('GOAT de la BRVM', .7 + .3 * g.score / goatScore);
  return (null, 1);
}

class _ProfileBadge extends StatelessWidget {
  const _ProfileBadge({required this.game, required this.onTap});
  final GameState game;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (next, progress) = nextTitle(game);
    return Semantics(
      button: true,
      label: '${game.title}, Score PACO ${game.score}${next == null ? '' : ', prochain titre : $next'}',
      child: ExcludeSemantics(
        child: Material(
          color: scheme.surface.withValues(alpha: .94),
          elevation: 2,
          borderRadius: BorderRadius.circular(28),
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Brand.lime,
                    child: Text('${game.citiesDone}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Brand.ink)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(game.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(value: progress, minHeight: 6),
                        ),
                        const SizedBox(height: 2),
                        Text('Score PACO ${game.score}', style: Theme.of(context).textTheme.labelSmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SavingsChip extends StatelessWidget {
  const _SavingsChip({required this.amount});
  final double amount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Épargne : ${fcfa(amount)} FCFA-jeu',
      child: ExcludeSemantics(
        child: Material(
          color: scheme.surface.withValues(alpha: .94),
          elevation: 2,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/tiles/billet.webp', width: 32),
                const SizedBox(width: 6),
                TweenAnimationBuilder<double>(
                  tween: Tween(end: amount),
                  duration: const Duration(milliseconds: 700),
                  builder: (context, v, _) => Text(fcfa(v), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SeanceChip extends StatelessWidget {
  const _SeanceChip({required this.city});
  final CityState city;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final toAgo = seancesToAgo(city);
    return Material(
      color: scheme.primary.withValues(alpha: .92),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(
          'Séance ${city.seance} · AGO dans $toAgo${toAgo <= hourglass ? ' ⏳' : ''}',
          style: TextStyle(color: scheme.onPrimary, fontWeight: FontWeight.w700, fontSize: 12),
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.tooltip, required this.onTap, required this.child, this.size = 52});
  final String tooltip;
  final VoidCallback onTap;
  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: Material(
          color: scheme.surface,
          shape: CircleBorder(side: BorderSide(color: scheme.primary, width: 2)),
          elevation: 3,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox.square(dimension: size, child: Center(child: child)),
          ),
        ),
      ),
    );
  }
}

class _Dock extends StatelessWidget {
  const _Dock({
    required this.marketOpen,
    required this.cardsCount,
    required this.onProperties,
    required this.onCards,
    required this.onPlay,
    required this.onSgi,
    required this.onMe,
  });
  final bool marketOpen;
  final int cardsCount;
  final VoidCallback onProperties, onCards, onPlay, onSgi, onMe;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      child: SizedBox(
        height: 108,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              height: 80,
              decoration: BoxDecoration(
                color: scheme.surface.withValues(alpha: .96),
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 10, offset: Offset(0, 3))],
              ),
              child: Row(
                children: [
                  _DockItem(icon: Icons.holiday_village_outlined, label: 'Propriétés', onTap: onProperties),
                  _DockItem(icon: Icons.style_outlined, label: 'Cartes', onTap: onCards, badge: cardsCount > 0 ? '$cardsCount' : null),
                  const Expanded(child: SizedBox()),
                  _DockItem(icon: Icons.account_balance_outlined, label: 'Guichet', onTap: onSgi, locked: !marketOpen),
                  _DockItem(icon: Icons.person_outline, label: 'Moi', onTap: onMe),
                ],
              ),
            ),
            Positioned(
              bottom: 8,
              child: Semantics(
                button: true,
                label: 'Jouer : la route des 15 villes',
                child: ExcludeSemantics(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Material(
                        color: Brand.lime,
                        shape: const CircleBorder(side: BorderSide(color: Brand.ink, width: 3)),
                        elevation: 6,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: onPlay,
                          child: const SizedBox.square(dimension: 76, child: Icon(Icons.play_arrow_rounded, size: 52, color: Brand.ink)),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text('Jouer', style: TextStyle(fontWeight: FontWeight.w800, color: scheme.onSurface)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DockItem extends StatelessWidget {
  const _DockItem({required this.icon, required this.label, required this.onTap, this.badge, this.locked = false});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? badge;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Semantics(
        button: true,
        label: locked ? '$label, verrouillé' : label,
        child: ExcludeSemantics(
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Badge(
                  isLabelVisible: badge != null || locked,
                  label: locked ? const Icon(Icons.lock, size: 10) : Text(badge ?? ''),
                  child: Icon(icon, size: 28, color: locked ? scheme.onSurfaceVariant : scheme.primary),
                ),
                const SizedBox(height: 4),
                Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: scheme.onSurface)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
