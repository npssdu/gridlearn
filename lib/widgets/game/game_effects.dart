import 'dart:math';

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Sacude su hijo cada vez que [shakes] aumenta (para los errores).
class Shake extends StatefulWidget {
  const Shake({super.key, required this.shakes, required this.child});

  final int shakes;
  final Widget child;

  @override
  State<Shake> createState() => _ShakeState();
}

class _ShakeState extends State<Shake> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 420));

  @override
  void didUpdateWidget(Shake oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shakes != oldWidget.shakes) _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final t = _controller.value;
        final dx = sin(t * pi * 5) * 9 * (1 - t);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
    );
  }
}

/// Aparece con un pequeño rebote.
class PopIn extends StatelessWidget {
  const PopIn({super.key, required this.child, this.duration = const Duration(milliseconds: 260)});

  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.85, end: 1),
      duration: duration,
      curve: Curves.easeOutBack,
      builder: (context, value, child) => Opacity(
        opacity: value.clamp(0.0, 1.0),
        child: Transform.scale(scale: value, child: child),
      ),
      child: child,
    );
  }
}

/// Lluvia de fichas de colores (las de la paleta del logo) para celebrar.
class Confetti extends StatefulWidget {
  const Confetti({super.key, this.pieces = 48, this.seed = 7});

  final int pieces;
  final int seed;

  @override
  State<Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<Confetti> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..forward();
  late final List<_Piece> _pieces;

  static const _colors = [
    AppColors.sky,
    AppColors.amber,
    AppColors.teal,
    AppColors.orange,
    AppColors.periwinkle,
    AppColors.rose,
  ];

  @override
  void initState() {
    super.initState();
    final random = Random(widget.seed);
    _pieces = List.generate(widget.pieces, (i) {
      return _Piece(
        x: random.nextDouble(),
        delay: random.nextDouble() * 0.45,
        size: 8 + random.nextDouble() * 8,
        sway: 0.02 + random.nextDouble() * 0.05,
        phase: random.nextDouble() * pi * 2,
        spin: (random.nextDouble() - 0.5) * 8,
        color: _colors[i % _colors.length],
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          size: Size.infinite,
          painter: _ConfettiPainter(_pieces, _controller.value),
        ),
      ),
    );
  }
}

class _Piece {
  const _Piece({
    required this.x,
    required this.delay,
    required this.size,
    required this.sway,
    required this.phase,
    required this.spin,
    required this.color,
  });

  final double x, delay, size, sway, phase, spin;
  final Color color;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.pieces, this.t);

  final List<_Piece> pieces;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in pieces) {
      final progress = ((t - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (progress <= 0) continue;
      final x = (p.x + sin(progress * pi * 3 + p.phase) * p.sway) * size.width;
      final y = -20 + progress * (size.height + 40);
      final fade = progress > 0.8 ? (1 - progress) / 0.2 : 1.0;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(progress * p.spin);
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size),
        Radius.circular(p.size * 0.28),
      );
      canvas.drawRRect(rect, Paint()..color = p.color.withValues(alpha: fade));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) => oldDelegate.t != t;
}
