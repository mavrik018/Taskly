import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ProgressBar extends StatefulWidget {
  final double value; // Between 0.0 and 1.0

  const ProgressBar({super.key, required this.value});

  @override
  State<ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<ProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    // Triggers the repeating current flow animation along the track
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(double.infinity, 20),
          painter: _CircuitProgressBarPainter(
            progress: widget.value,
            animationValue: _animationController.value,
            theme: theme,
          ),
        );
      },
    );
  }
}

class _CircuitProgressBarPainter extends CustomPainter {
  final double progress;
  final double animationValue;
  final ThemeData theme;

  _CircuitProgressBarPainter({
    required this.progress,
    required this.animationValue,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final isDark = theme.brightness == Brightness.dark;
    final trackColor = isDark
        ? theme.dividerColor.withOpacity(0.15)
        : theme.dividerColor.withOpacity(0.4);

    final accentColor = AppColors.primary;
    final secondaryAccent = Colors.cyanAccent[400] ?? Colors.cyan;

    final centerY = size.height / 2;
    final startX = 12.0;
    final endX = size.width - 12.0;
    final totalWidth = endX - startX;
    final progressX = startX + totalWidth * progress;

    // 1. Draw background track (circuit trace path)
    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(startX, centerY), Offset(endX, centerY), trackPaint);

    // Background terminals
    final terminalPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(startX, centerY), 6.0, terminalPaint);
    canvas.drawCircle(Offset(endX, centerY), 6.0, terminalPaint);

    // 2. Draw active progress trace with neon glow gradient
    if (progress > 0) {
      final progressPaint = Paint()
        ..shader = ui.Gradient.linear(
          Offset(startX, centerY),
          Offset(progressX, centerY),
          [accentColor, secondaryAccent],
        )
        ..strokeWidth = 5.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      // Outer Glow shadow-like paint
      final glowPaint = Paint()
        ..shader = ui.Gradient.linear(
          Offset(startX, centerY),
          Offset(progressX, centerY),
          [accentColor.withOpacity(0.35), secondaryAccent.withOpacity(0.35)],
        )
        ..strokeWidth = 12.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      canvas.drawLine(
          Offset(startX, centerY), Offset(progressX, centerY), glowPaint);
      canvas.drawLine(
          Offset(startX, centerY), Offset(progressX, centerY), progressPaint);

      // Active start terminal
      final activeTerminalPaint = Paint()
        ..color = accentColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(startX, centerY), 6.0, activeTerminalPaint);

      // 3. Draw animated flow pulse (electricity signal particle running along active progress trace)
      final pulseX = startX + (progressX - startX) * animationValue;

      final pulseGlowPaint = Paint()
        ..color = secondaryAccent.withOpacity(0.65)
        ..style = PaintingStyle.fill;

      final pulsePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(pulseX, centerY), 7.0, pulseGlowPaint);
      canvas.drawCircle(Offset(pulseX, centerY), 3.0, pulsePaint);

      // 4. Draw pulsing current progress endpoint node
      final pulseScale = 1.0 + 0.45 * math.sin(animationValue * 2 * math.pi);

      final endpointGlowPaint = Paint()
        ..color =
            secondaryAccent.withOpacity((0.6 - animationValue).clamp(0.0, 0.6))
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
          Offset(progressX, centerY), 11.0 * pulseScale, endpointGlowPaint);

      final endpointPaint = Paint()
        ..color = secondaryAccent
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(progressX, centerY), 5.5, endpointPaint);
      canvas.drawCircle(Offset(progressX, centerY), 2.5, pulsePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CircuitProgressBarPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.animationValue != animationValue;
  }
}
