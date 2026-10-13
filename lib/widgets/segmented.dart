import 'package:flutter/material.dart';
import 'package:sleeptrack/theme/app_theme.dart';

class SegmentItem {
  final IconData? icon;
  final String? label;
  const SegmentItem({this.icon, this.label});
}

/// Compact segmented control with a sliding thumb. Used for the Week/30-day
/// switch and the two graph icon-toggles. The thumb animates between segments.
class Segmented extends StatelessWidget {
  final List<SegmentItem> items;
  final int index;
  final ValueChanged<int> onChanged;
  final double height;

  const Segmented({
    super.key,
    required this.items,
    required this.index,
    required this.onChanged,
    this.height = 38,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    const inset = 3.0;
    final thumbColor = p.brightness == Brightness.light ? Colors.white : const Color(0xFF34373B);
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: p.surfaceAlt,
        borderRadius: BorderRadius.circular(height / 2),
        border: Border.all(color: p.outline, width: 1.5),
      ),
      // LayoutBuilder lives INSIDE the border so c.maxWidth is the inner content
      // width — otherwise the thumb (sized to the outer width) overflows the edge.
      child: LayoutBuilder(builder: (context, c) {
        final segW = c.maxWidth / items.length;
        return Stack(children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            left: index * segW + inset,
            top: inset,
            bottom: inset,
            width: segW - inset * 2,
            child: Container(
              decoration: BoxDecoration(
                color: thumbColor,
                borderRadius: BorderRadius.circular(height / 2),
                border: Border.all(color: p.outline, width: 1),
              ),
            ),
          ),
          Row(
            children: List.generate(items.length, (i) {
              final active = i == index;
              final color = active ? p.textPrimary : p.textFaint;
              final it = items[i];
              return Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(i),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 220),
                      style: AppText.label(color),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (it.icon != null) Icon(it.icon, size: 18, color: color),
                          if (it.icon != null && it.label != null) const SizedBox(width: 6),
                          if (it.label != null) Text(it.label!),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ]);
      }),
    );
  }
}
