import 'package:flutter/material.dart';
import 'package:sleeptrack/theme/app_theme.dart';

/// The floating bottom pill: calendar (left) · add (center) · home (right).
/// Theme-aware (light pill in light mode, dark in dark) with a clear border and
/// a soft shadow. The active page is shown by a bold/filled icon (no box).
class NavIsland extends StatelessWidget {
  final int activeIndex; // 0 = home, 1 = calendar
  final VoidCallback onHome;
  final VoidCallback onCalendar;
  final VoidCallback onAdd;

  const NavIsland({
    super.key,
    required this.activeIndex,
    required this.onHome,
    required this.onCalendar,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 62,
      margin: const EdgeInsets.symmetric(horizontal: 56),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(31),
        border: Border.all(color: p.outline, width: 1.5),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: p.brightness == Brightness.dark ? 0.4 : 0.14),
              blurRadius: 22,
              offset: const Offset(0, 9)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _NavButton(
            icon: activeIndex == 1 ? Icons.calendar_month_rounded : Icons.calendar_today_outlined,
            active: activeIndex == 1,
            onTap: onCalendar,
          ),
          _NavButton(icon: Icons.add_rounded, size: 30, onTap: onAdd),
          _NavButton(
            icon: activeIndex == 0 ? Icons.home_rounded : Icons.home_outlined,
            active: activeIndex == 0,
            onTap: onHome,
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatefulWidget {
  final IconData icon;
  final bool active;
  final double size;
  final VoidCallback onTap;
  const _NavButton({required this.icon, required this.onTap, this.active = false, this.size = 25});

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton> {
  double _scale = 1;
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.82),
      onTapUp: (_) => setState(() => _scale = 1),
      onTapCancel: () => setState(() => _scale = 1),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        height: 56,
        child: AnimatedScale(
          scale: _scale,
          duration: const Duration(milliseconds: 120),
          child: Icon(
            widget.icon,
            color: p.textPrimary.withValues(alpha: widget.active ? 1 : 0.78),
            size: widget.active ? widget.size + 1 : widget.size,
          ),
        ),
      ),
    );
  }
}
