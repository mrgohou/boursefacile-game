import 'package:material_ui/material_ui.dart';

import '../domain/cultural_rewards.dart';
import 'cultural_art.dart';
import 'game_chrome.dart';

class RewardDialog extends StatefulWidget {
  const RewardDialog({
    super.key,
    required this.reward,
    required this.onCollect,
  });
  final CulturalReward reward;
  final Future<bool> Function() onCollect;
  @override
  State<RewardDialog> createState() => _RewardDialogState();
}

class _RewardDialogState extends State<RewardDialog> {
  bool saving = false;
  String? error;
  @override
  Widget build(BuildContext context) {
    final r = widget.reward;
    final motion = MediaQuery.disableAnimationsOf(context);
    final panel = GamePanel(
      color: const Color(0xFFFFF2D4),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Récompense gagnée !',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                children: [
                  if (r.colas > 0)
                    CulturalArt(index: 12, size: 85, label: '${r.colas} colas'),
                  if (r.cauris > 0)
                    CulturalArt(
                      index: 0,
                      size: 85,
                      label: '${r.cauris} cauris',
                    ),
                  if (r.gold > 0)
                    CulturalArt(
                      index: 14,
                      size: 85,
                      label: '${r.gold} pièces d’or',
                    ),
                  if (r.crosses > 0)
                    const CulturalArt(
                      index: 10,
                      size: 85,
                      label: 'Croix d’Agadez',
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                r.label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text('Bravo ! ${r.rule}.', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text(
                '+${r.value} F jeu crédités en collectant. Les objets restent dans tes acquis. La croix d’Agadez est un trophée.',
                textAlign: TextAlign.center,
              ),
              if (error != null)
                Text(
                  error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        setState(() => saving = true);
                        final ok = await widget.onCollect();
                        if (!context.mounted) return;
                        if (ok) {
                          Navigator.pop(context, true);
                        } else {
                          setState(() {
                            saving = false;
                            error = 'Collecte non enregistrée. Réessaie : ton gain reste disponible.';
                          });
                        }
                      },
                child: Text(saving ? 'Enregistrement…' : 'COLLECTER'),
              ),
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(context, false),
                child: const Text('Plus tard'),
              ),
            ],
          ),
        ),
      ),
    );
    return PopScope(
      canPop: !saving,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: motion ? 1 : .8, end: 1),
          duration: Duration(milliseconds: motion ? 0 : 450),
          curve: Curves.easeOutBack,
          builder: (context, scale, child) =>
              Transform.scale(scale: scale, child: child),
          child: panel,
        ),
      ),
    );
  }
}
