import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taskflow/core/theme/theme_provider.dart';
import 'package:taskflow/features/onboarding/presentation/controllers/onboarding_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';
import '../controllers/settings_provider.dart';
import '../../../tasks/presentation/controllers/tasks_provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../auth/presentation/controllers/auth_provider.dart';
import '../../../../core/utils/notification_manager.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDarkMode = ref.watch(themeModeProvider);
    final settingsState = ref.watch(settingsProvider);
    final db = ref.watch(databaseProvider);
    final onboardingState = ref.watch(onboardingProvider);
    final currentUser = ref.watch(authProvider);
    final userName = onboardingState.value?.userName ?? 'Productivity Champ';

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          children: [
            // User Profile Card
            Card(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Container(
                      width: 48.w,
                      height: 48.h,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white : Colors.black,
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Center(
                        child: Text(
                          userName.isNotEmpty
                              ? userName.substring(0, 1).toUpperCase()
                              : 'U',
                          style: TextStyle(
                            color: isDark ? Colors.black : Colors.white,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        userName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.edit_outlined,
                        size: 20.sp,
                        color: theme.colorScheme.secondary,
                      ),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        showDialog(
                          context: context,
                          builder: (context) {
                            final controller =
                                TextEditingController(text: userName);
                            return AlertDialog(
                              title: const Text('Edit Name'),
                              content: TextField(
                                controller: controller,
                                decoration:
                                    const InputDecoration(labelText: 'Name'),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    if (controller.text.trim().isNotEmpty) {
                                      await ref
                                          .read(onboardingProvider.notifier)
                                          .updateUserName(
                                              controller.text.trim());
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                      }
                                    }
                                  },
                                  child: const Text('Save'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: AppSpacing.lg),

            // General Section
            Text(
              'GENERAL',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.secondary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Card(
              child: Column(
                children: [
                  _buildSettingItem(
                    context: context,
                    icon: isDarkMode
                        ? Icons.dark_mode_outlined
                        : Icons.light_mode_outlined,
                    title: 'Appearance',
                    trailing: Switch(
                      value: isDarkMode,
                      onChanged: (value) {
                        HapticFeedback.lightImpact();
                        ref.read(themeModeProvider.notifier).toggleTheme();
                      },
                    ),
                  ),
                  Divider(height: 1, indent: 56.w),
                  _buildSettingItem(
                    context: context,
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    trailing: Switch(
                      value: settingsState.notificationsEnabled,
                      onChanged: (value) async {
                        HapticFeedback.lightImpact();
                        if (value) {
                          final granted =
                              await NotificationManager.requestPermissions(
                                  context);
                          if (!granted) return;
                        }
                        ref
                            .read(settingsProvider.notifier)
                            .toggleNotifications(value);
                      },
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.lg),

            // Account & Sync Section
            Text(
              'ACCOUNT & SYNC',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.secondary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Card(
              child: Column(
                children: [
                  if (currentUser != null) ...[
                    _buildSettingItem(
                      context: context,
                      icon: Icons.account_circle_outlined,
                      title: currentUser.email ?? 'Signed In',
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white : Colors.black,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'PREMIUM',
                          style: TextStyle(
                            color: isDark ? Colors.black : Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 10.sp,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                    Divider(height: 1, indent: 56.w),
                    _buildSettingItem(
                      context: context,
                      icon: Icons.sync_rounded,
                      title: 'Sync Database',
                      trailing: TextButton(
                        onPressed: () async {
                          HapticFeedback.lightImpact();
                          await ref.read(syncServiceProvider).sync();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Database synced!')),
                            );
                          }
                        },
                        child: Text(
                          'Sync Now',
                          style: TextStyle(
                            decoration: TextDecoration.underline,
                            decorationColor: theme.colorScheme.secondary
                                .withValues(alpha: 0.5),
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                      ),
                    ),
                    Divider(height: 1, indent: 56.w),
                    _buildSettingItem(
                      context: context,
                      icon: Icons.logout_rounded,
                      title: 'Sign Out',
                      trailing: Icon(Icons.chevron_right,
                          color: theme.colorScheme.secondary),
                      onTap: () async {
                        HapticFeedback.mediumImpact();
                        await ref.read(authProvider.notifier).signOut();
                      },
                    ),
                  ] else ...[
                    _buildSettingItem(
                      context: context,
                      icon: Icons.cloud_off_rounded,
                      title: 'Cloud Backup & Sync',
                      trailing: Switch(
                        value: false,
                        onChanged: (value) {
                          HapticFeedback.lightImpact();
                          _showAuthPromoDialog(
                            context: context,
                            title: 'Enable Cloud Backup?',
                            content: 'To enable cloud backup and synchronize your tasks across devices, please sign in or register for a premium account.',
                            icon: Icons.cloud_upload_rounded,
                            actionLabel: 'Sign In',
                            onAction: () => context.push(AppRoutes.auth),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: AppSpacing.lg),

            // AI Preferences Section
            Text(
              'AI PREFERENCES',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.secondary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Card(
              child: Column(
                children: [
                  _buildSettingItem(
                    context: context,
                    icon: Icons.emoji_events_outlined,
                    title: 'Weekly Performance Wrap',
                    trailing: Icon(Icons.chevron_right,
                        color: theme.colorScheme.secondary),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      if (currentUser == null) {
                        _showAuthPromoDialog(
                          context: context,
                          title: 'Unlock Weekly Wrap',
                          content: 'AI Weekly Performance Wrap is a premium feature. Please sign in or register to unlock weekly summaries.',
                          icon: Icons.emoji_events_outlined,
                          actionLabel: 'Upgrade',
                          onAction: () => context.push(AppRoutes.auth),
                        );
                        return;
                      }
                      context.push(AppRoutes.weeklyReview);
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.lg),

            // Data Section — destructive action demoted to a row, not a full-width CTA
            Text(
              'DATA',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.secondary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.borderLG,
                side: BorderSide(
                  color: AppColors.priorityHigh.withValues(alpha: 0.3),
                  width: 0.5,
                ),
              ),
              child: _buildSettingItem(
                context: context,
                icon: Icons.delete_outline_rounded,
                iconColor: AppColors.priorityHigh,
                title: 'Clear All Data',
                titleColor: AppColors.priorityHigh,
                trailing: Icon(
                  Icons.chevron_right,
                  color: AppColors.priorityHigh.withValues(alpha: 0.6),
                ),
                onTap: () async {
                  HapticFeedback.heavyImpact();
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Clear All Data?'),
                      content: const Text(
                          'This action is irreversible. All tasks and projects will be deleted.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text('Clear',
                              style: TextStyle(color: AppColors.priorityHigh)),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await ref.read(settingsProvider.notifier).clearAllData(db);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('All data cleared!')),
                      );
                    }
                  }
                },
              ),
            ),
            SizedBox(height: AppSpacing.lg),

            // Version Info
            Center(
              child: Text(
                'Version 1.0.0 (Build 1)',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.secondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Widget trailing,
    Color? iconColor,
    Color? titleColor,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: iconColor ?? theme.colorScheme.onSurface.withOpacity(0.8),
              size: 24.sp,
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: titleColor,
                ),
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  void _showAuthPromoDialog({
    required BuildContext context,
    required String title,
    required String content,
    required IconData icon,
    required String actionLabel,
    required VoidCallback onAction,
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
                            onAction();
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
