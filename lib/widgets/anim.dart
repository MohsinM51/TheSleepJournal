import 'package:flutter/material.dart';

/// Fades + lifts its child into place after [delay]. Used to stagger the
/// dashboard cards on page load for a calm, orchestrated reveal.
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final double offset;
  const FadeSlideIn({super.key, required this.child, this.delay = Duration.zero, this.offset = 18});

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
  late final Animation<double> _a = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a,
      builder: (_, child) => Opacity(
        opacity: _a.value,
        child: Transform.translate(offset: Offset(0, (1 - _a.value) * widget.offset), child: child),
      ),
      child: widget.child,
    );
  }
}
