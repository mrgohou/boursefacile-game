import 'package:material_ui/material_ui.dart';

/// Shared toy-like surfaces: lit top edge, colored depth, clear ink contrast.
class GamePanel extends StatelessWidget {
  const GamePanel({
    super.key,
    required this.child,
    this.color = const Color(0xFFFFF9E9),
    this.radius = 20,
  });
  final Widget child;
  final Color color;
  final double radius;
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final surface = dark && color == const Color(0xFFFFF9E9)
        ? Theme.of(context).colorScheme.surfaceContainerHigh
        : color;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(surface, Colors.white, dark ? .08 : .35)!,
            surface,
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: dark ? .16 : .9),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? .28 : .12),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Color.lerp(surface, Colors.black, .22)!,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

class GameAction extends StatefulWidget {
  const GameAction({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.primary = false,
  });
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool primary;
  @override
  State<GameAction> createState() => _GameActionState();
}

class _GameActionState extends State<GameAction> {
  bool pressed = false;
  @override
  Widget build(BuildContext context) {
    final primary = widget.primary;
    final enabled = widget.onTap != null;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final color = primary ? const Color(0xFFFECE42) : const Color(0xFFFDF4D9);
    return Semantics(
      button: true,
      label: widget.label,
      enabled: widget.onTap != null,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: widget.onTap,
          onHighlightChanged: enabled
              ? (value) => setState(() => pressed = value)
              : null,
          child: AnimatedScale(
            scale: enabled && pressed ? .97 : 1,
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 150),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: primary ? 68 : 58,
                  height: primary ? 68 : 58,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color.lerp(color, Colors.white, .4)!, color],
                    ),
                    borderRadius: BorderRadius.circular(19),
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: primary
                            ? const Color(0xFFC08722)
                            : const Color(0xFFB8A478),
                        offset: Offset(0, pressed ? 1 : 4),
                      ),
                      const BoxShadow(
                        color: Color(0x33234752),
                        blurRadius: 10,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.icon,
                    size: primary ? 38 : 29,
                    color: !enabled
                        ? const Color(0xFF7A7A71)
                        : primary
                        ? const Color(0xFF68400C)
                        : const Color(0xFF246481),
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: dark
                        ? const Color(0xFFF5F1E7)
                        : const Color(0xFF223C4B),
                    shadows: dark
                        ? const []
                        : const [
                            Shadow(color: Colors.white, blurRadius: 8),
                            Shadow(color: Colors.white, blurRadius: 3),
                          ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
