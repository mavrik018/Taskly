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
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: 48.h,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Clean, elegant circular check icon
            Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.05),
                  width: 1.5.w,
                ),
              ),
              child: Icon(
                Icons.check_rounded,
                size: 36.sp,
                color: AppColors.primary,
              ),
            )
                .animate()
                .scale(duration: 400.ms, curve: Curves.easeOutBack)
                .fadeIn(duration: 300.ms),
            SizedBox(height: AppSpacing.lg),

            // Motivational Slogan
            Text(
              'Your space is clear',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 18.sp,
                letterSpacing: -0.2,
              ),
            ).animate().slideY(begin: 0.1, end: 0, delay: 100.ms).fadeIn(),
            SizedBox(height: AppSpacing.xs),

            Text(
              'All tasks completed! Enjoy the clarity.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                fontSize: 13.5.sp,
              ),
            ).animate().slideY(begin: 0.2, end: 0, delay: 180.ms).fadeIn(),
          ],
        ),
      ),
    );
  }
}
