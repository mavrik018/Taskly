import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Custom Painted Zen Illustration
            SizedBox(
              width: 180.w,
              height: 180.w,
              child: CustomPaint(
                painter: _ZenIllustrationPainter(isDark: isDark),
              ),
            )
                .animate()
                .scale(
                  duration: 600.ms,
                  curve: Curves.elasticOut,
                  begin: const Offset(0.3, 0.3),
                )
                .fadeIn(duration: 400.ms),
            SizedBox(height: AppSpacing.lg),

            // Motivational Slogan
            Text(
              'Your Space is Clear',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                fontSize: 20.sp,
                letterSpacing: 0.2,
              ),
            ).animate().slideY(begin: 0.2, end: 0, delay: 150.ms).fadeIn(),
            SizedBox(height: AppSpacing.xs),

            Text(
              'All tasks completed! Enjoy the mental clarity, rest, or plan your next move when you\'re ready.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.8),
                height: 1.55,
                fontSize: 13.sp,
              ),
            ).animate().slideY(begin: 0.3, end: 0, delay: 250.ms).fadeIn(),
          ],
        ),
      ),
    );
  }
}

class _ZenIllustrationPainter extends CustomPainter {
  final bool isDark;

  _ZenIllustrationPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Draw soft sun background
    final sunPaint = Paint()
      ..color = isDark
          ? Colors.amber.withOpacity(0.08)
          : Colors.amber.withOpacity(0.12)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
        Offset(center.dx - 10, center.dy - 10), radius * 0.55, sunPaint);

    // 2. Draw modern abstract hills/waves
    final hillPaint1 = Paint()
      ..color = AppColors.primary.withOpacity(isDark ? 0.15 : 0.08)
      ..style = PaintingStyle.fill;

    final path1 = Path();
    path1.moveTo(0, size.height * 0.7);
    path1.quadraticBezierTo(
      size.width * 0.3,
      size.height * 0.55,
      size.width * 0.6,
      size.height * 0.75,
    );
    path1.quadraticBezierTo(
      size.width * 0.8,
      size.height * 0.85,
      size.width,
      size.height * 0.65,
    );
    path1.lineTo(size.width, size.height);
    path1.lineTo(0, size.height);
    path1.close();
    canvas.drawPath(path1, hillPaint1);

    final hillPaint2 = Paint()
      ..color = Colors.cyan.withOpacity(isDark ? 0.20 : 0.10)
      ..style = PaintingStyle.fill;

    final path2 = Path();
    path2.moveTo(0, size.height * 0.85);
    path2.quadraticBezierTo(
      size.width * 0.45,
      size.height * 0.65,
      size.width * 0.75,
      size.height * 0.8,
    );
    path2.quadraticBezierTo(
      size.width * 0.9,
      size.height * 0.87,
      size.width,
      size.height * 0.78,
    );
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();
    canvas.drawPath(path2, hillPaint2);

    // 3. Draw a gorgeous central floating checkmark
    final checkColor = AppColors.primary;
    final checkPaint = Paint()
      ..color = checkColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.5
      ..strokeCap = StrokeCap.round;

    final checkPath = Path();
    checkPath.moveTo(size.width * 0.38, size.height * 0.46);
    checkPath.lineTo(size.width * 0.47, size.height * 0.55);
    checkPath.lineTo(size.width * 0.66, size.height * 0.34);

    // Checkmark glow effect shadow
    final checkGlow = Paint()
      ..color = checkColor.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14.0
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(checkPath, checkGlow);
    canvas.drawPath(checkPath, checkPaint);

    // 4. Draw small floating elements/particles
    final particlePaint = Paint()
      ..color = Colors.cyanAccent.withOpacity(isDark ? 0.7 : 0.5)
      ..style = PaintingStyle.fill;

    // Small sparkles or diamonds
    _drawSparkle(
        canvas, Offset(size.width * 0.2, size.height * 0.35), 6, particlePaint);
    _drawSparkle(
        canvas, Offset(size.width * 0.8, size.height * 0.45), 8, particlePaint);

    final dotPaint = Paint()
      ..color = checkColor.withOpacity(0.4)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
        Offset(size.width * 0.28, size.height * 0.6), 3.5, dotPaint);
    canvas.drawCircle(
        Offset(size.width * 0.72, size.height * 0.3), 4, dotPaint);
  }

  void _drawSparkle(Canvas canvas, Offset offset, double size, Paint paint) {
    final path = Path();
    path.moveTo(offset.dx, offset.dy - size);
    path.lineTo(offset.dx + size / 2, offset.dy);
    path.lineTo(offset.dx, offset.dy + size);
    path.lineTo(offset.dx - size / 2, offset.dy);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
