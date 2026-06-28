import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:taskflow/core/routing/app_routes.dart';

class PremiumPromoDialog {
  static void show({
    required BuildContext context,
    required String title,
    required String content,
    required IconData icon,
    String actionLabel = 'Upgrade',
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: EdgeInsets.symmetric(horizontal: 28.w),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF151516) : Colors.white,
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(
              color: isDark ? const Color(0xFF2B2B2C) : const Color(0xFFE4E4E7),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 26.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Styled Icon at the top
              Container(
                width: 58.r,
                height: 58.r,
                decoration: BoxDecoration(
                  color: const Color(0xFF7C6FF0).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF7C6FF0).withValues(alpha: 0.24),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFFB3A9FF),
                  size: 26.r,
                ),
              ).animate().scale(
                    duration: 400.ms,
                    curve: Curves.easeOutBack,
                  ),
              SizedBox(height: 18.h),
              // Title
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 19.sp,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF18181B),
                  letterSpacing: -0.4,
                ),
              ),
              SizedBox(height: 10.h),
              // Content
              Text(
                content,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.w500,
                  color: isDark ? const Color(0xFF8A8A8E) : const Color(0xFF71717A),
                  height: 1.5,
                ),
              ),
              SizedBox(height: 24.h),
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                          side: BorderSide(
                            color: isDark ? const Color(0xFF2E2E30) : const Color(0xFFE4E4E7),
                          ),
                        ),
                        backgroundColor: isDark ? const Color(0xFF1D1D1E) : const Color(0xFFF4F4F5),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFFCFCFD0) : const Color(0xFF52525B),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B7FF5), Color(0xFF6A5BD8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14.r),
                          onTap: () {
                            Navigator.pop(context);
                            context.push(AppRoutes.auth);
                          },
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 14.h),
                              child: Text(
                                actionLabel,
                                style: GoogleFonts.inter(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
