import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/device_service.dart';

/// Interactive celebration confetti burst overlay
class CelebrationEffect {
  static void show(BuildContext context, {Duration duration = const Duration(milliseconds: 2400)}) {
    DeviceService.triggerSuccessHaptic();

    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (ctx) => _ConfettiOverlay(
        duration: duration,
        onFinished: () {
          if (entry.mounted) {
            entry.remove();
          }
        },
      ),
    );

    overlay.insert(entry);
  }
}

class _ConfettiOverlay extends StatefulWidget {
  final Duration duration;
  final VoidCallback onFinished;

  const _ConfettiOverlay({required this.duration, required this.onFinished});

  @override
  State<_ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<_ConfettiOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final math.Random _random = math.Random();

  final List<Color> _colors = const [
    Color(0xFF38BDF8), // Cyan
    Color(0xFF818CF8), // Indigo
    Color(0xFFA855F7), // Purple
    Color(0xFFEC4899), // Pink
    Color(0xFFFBBF24), // Gold / Amber
    Color(0xFF34D399), // Emerald
    Colors.white,
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    // Generate 65 particles bursting from top/center
    for (int i = 0; i < 65; i++) {
      _particles.add(
        _Particle(
          x: 0.5 + (_random.nextDouble() - 0.5) * 0.4,
          y: 0.25 + (_random.nextDouble() - 0.5) * 0.15,
          vx: (_random.nextDouble() - 0.5) * 1.6,
          vy: -_random.nextDouble() * 1.8 - 0.6,
          gravity: 2.2 + _random.nextDouble() * 1.2,
          color: _colors[_random.nextInt(_colors.length)],
          size: 6.0 + _random.nextDouble() * 7.0,
          rotationSpeed: (_random.nextDouble() - 0.5) * 10,
          isCircle: _random.nextBool(),
        ),
      );
    }

    _controller.forward().then((_) => widget.onFinished());
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
        builder: (context, _) {
          return CustomPaint(
            size: MediaQuery.of(context).size,
            painter: _ConfettiPainter(
              progress: _controller.value,
              particles: _particles,
            ),
          );
        },
      ),
    );
  }
}

class _Particle {
  final double x;
  final double y;
  final double vx;
  final double vy;
  final double gravity;
  final Color color;
  final double size;
  final double rotationSpeed;
  final bool isCircle;

  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.gravity,
    required this.color,
    required this.size,
    required this.rotationSpeed,
    required this.isCircle,
  });
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  final List<_Particle> particles;

  _ConfettiPainter({required this.progress, required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress;
    final opacity = (1.0 - t * 0.9).clamp(0.0, 1.0);

    for (final p in particles) {
      final currentX = (p.x + p.vx * t) * size.width;
      final currentY = (p.y + p.vy * t + 0.5 * p.gravity * t * t) * size.height;

      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(currentX, currentY);
      canvas.rotate(t * p.rotationSpeed);

      if (p.isCircle) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
            const Radius.circular(2),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}
