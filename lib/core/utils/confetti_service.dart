import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';

class ConfettiService {
  ConfettiService._();

  static const String _completionCountKey = 'tasks_completed_count';

  /// Increments the task completion counter and triggers confetti if a milestone is reached.
  static Future<void> notifyTaskCompleted(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final currentCount = prefs.getInt(_completionCountKey) ?? 0;
    final newCount = currentCount + 1;
    await prefs.setInt(_completionCountKey, newCount);

    // Milestones: 1st task completed, or every 5th task (5, 10, 15, 20...)
    if (newCount == 1 || newCount % 5 == 0) {
      if (context.mounted) {
        showConfetti(context, newCount);
      }
    }
  }

  /// Triggers the full screen confetti particle overlay.
  static void showConfetti(BuildContext context, int milestoneCount) {
    final overlayState = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) {
        return _ConfettiOverlayWidget(
          milestoneCount: milestoneCount,
          onFinished: () {
            entry.remove();
          },
        );
      },
    );

    overlayState.insert(entry);
  }
}

class _ConfettiParticle {
  double x;
  double y;
  double vx;
  double vy;
  double rotation;
  double rotationSpeed;
  double scale;
  Color color;
  bool isCircle;
  double opacity = 1.0;

  _ConfettiParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.rotation,
    required this.rotationSpeed,
    required this.scale,
    required this.color,
    required this.isCircle,
  });

  void update(double dt) {
    x += vx * dt;
    y += vy * dt;
    vy += 950 * dt; // Gravity
    vx *= 0.985;   // Horizontal damping (air resistance)
    vy *= 0.985;   // Vertical damping
    rotation += rotationSpeed * dt;
    if (vy > 0) {
      // Fade out slowly as it falls down
      opacity = (opacity - dt * 0.45).clamp(0.0, 1.0);
    }
  }
}

class _ConfettiOverlayWidget extends StatefulWidget {
  final int milestoneCount;
  final VoidCallback onFinished;

  const _ConfettiOverlayWidget({
    required this.milestoneCount,
    required this.onFinished,
  });

  @override
  State<_ConfettiOverlayWidget> createState() => _ConfettiOverlayWidgetState();
}

class _ConfettiOverlayWidgetState extends State<_ConfettiOverlayWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_ConfettiParticle> _particles = [];
  final math.Random _random = math.Random();
  bool _particlesSpawned = false;

  final List<Color> _palette = [
    Colors.redAccent,
    Colors.blueAccent,
    Colors.greenAccent,
    Colors.yellowAccent,
    Colors.orangeAccent,
    Colors.pinkAccent,
    Colors.purpleAccent,
    Colors.tealAccent,
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _controller.addListener(() {
      setState(() {
        for (final p in _particles) {
          p.update(0.016); // Simulate ~60fps step
        }
      });
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onFinished();
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _spawnParticles(Size size) {
    if (_particlesSpawned) return;
    _particlesSpawned = true;

    // Spawn 80 particles from left cannon and 80 from right cannon
    final totalParticles = 70;

    // Left cannon (bottom-left)
    for (int i = 0; i < totalParticles; i++) {
      final angle = -(_random.nextDouble() * 45 + 30) * math.pi / 180.0; // -30 to -75 deg
      final speed = _random.nextDouble() * 650 + 550;
      _particles.add(
        _ConfettiParticle(
          x: 0,
          y: size.height,
          vx: math.cos(angle) * speed,
          vy: math.sin(angle) * speed,
          rotation: _random.nextDouble() * math.pi * 2,
          rotationSpeed: (_random.nextDouble() * 6 - 3) * math.pi,
          scale: _random.nextDouble() * 0.6 + 0.4,
          color: _palette[_random.nextInt(_palette.length)],
          isCircle: _random.nextBool(),
        ),
      );
    }

    // Right cannon (bottom-right)
    for (int i = 0; i < totalParticles; i++) {
      final angle = -(_random.nextDouble() * 45 + 105) * math.pi / 180.0; // -105 to -150 deg
      final speed = _random.nextDouble() * 650 + 550;
      _particles.add(
        _ConfettiParticle(
          x: size.width,
          y: size.height,
          vx: math.cos(angle) * speed,
          vy: math.sin(angle) * speed,
          rotation: _random.nextDouble() * math.pi * 2,
          rotationSpeed: (_random.nextDouble() * 6 - 3) * math.pi,
          scale: _random.nextDouble() * 0.6 + 0.4,
          color: _palette[_random.nextInt(_palette.length)],
          isCircle: _random.nextBool(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    _spawnParticles(size);

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Particles
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _ConfettiPainter(particles: _particles),
              ),
            ),
          ),
          // Celebratory Text Card in Center
          Align(
            alignment: Alignment.center,
            child: IgnorePointer(
              child: Card(
                elevation: 12,
                shadowColor: Colors.black.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                color: Colors.white.withOpacity(0.95),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 24,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '🎉 Milestone! 🎉',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${widget.milestoneCount} Tasks Completed',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Keep up the amazing momentum!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              )
                  .animate()
                  .scale(
                    duration: 400.ms,
                    curve: Curves.elasticOut,
                    begin: const Offset(0.4, 0.4),
                  )
                  .fadeIn(duration: 250.ms)
                  .then(delay: 2.2.seconds)
                  .fadeOut(duration: 500.ms)
                  .scale(begin: const Offset(1, 1), end: const Offset(0.7, 0.7)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;

  _ConfettiPainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
      if (p.opacity <= 0.0) continue;
      paint.color = p.color.withOpacity(p.opacity);

      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.rotation);

      final w = 15.0 * p.scale;
      final h = 10.0 * p.scale;

      if (p.isCircle) {
        canvas.drawCircle(Offset.zero, w / 2, paint);
      } else {
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: w, height: h), paint);
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
