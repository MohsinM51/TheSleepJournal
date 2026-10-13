import 'package:flutter/material.dart';
import 'package:sleeptrack/theme/app_theme.dart';

/// Rounded surface card with a soft shadow and (in dark mode) a hairline edge.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  const AppCard({super.key, required this.child, this.padding, this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(Gap.cardPad),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(Gap.cardRadius),
        border: Border.all(color: p.outline, width: 1.5),
      ),
      child: child,
    );
    if (onTap == null) return card;
    return GestureDetector(onTap: onTap, behavior: HitTestBehavior.opaque, child: card);
  }
}

/// Small circular tappable button used for theme toggle / settings / nav.
class SoftIconButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final double size;
  final Color? bg;
  const SoftIconButton(
      {super.key, required this.child, required this.onTap, this.size = 44, this.bg});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bg ?? p.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: p.outline, width: 1.5),
        ),
        child: Center(child: child),
      ),
    );
  }
}

class CardTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const CardTitle(this.text, {super.key, this.trailing});
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Row(
      children: [
        Expanded(child: Text(text, style: AppText.cardTitle(p.textPrimary))),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Tiny pill that labels a swatch in chart legends.
class LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final bool ring;
  const LegendDot(this.color, this.label, {super.key, this.ring = false});
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 11,
        height: 11,
        decoration: BoxDecoration(
          color: ring ? Colors.transparent : color,
          shape: BoxShape.circle,
          border: Border.all(color: p.outline, width: ring ? 1.4 : 1),
        ),
      ),
      const SizedBox(width: 6),
      Text(label, style: AppText.tiny(p.textSecondary)),
    ]);
  }
}

/// Single round button that swaps its icon on tap (same idea as the theme
/// toggle) — used to flip a graph between its two series.
class CycleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  const CycleIconButton({super.key, required this.icon, required this.onTap, this.size = 38});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: p.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: p.outline, width: 1.5),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (c, a) =>
              RotationTransition(turns: a, child: FadeTransition(opacity: a, child: c)),
          child: Icon(icon, key: ValueKey(icon), size: 19, color: p.textSecondary),
        ),
      ),
    );
  }
}
