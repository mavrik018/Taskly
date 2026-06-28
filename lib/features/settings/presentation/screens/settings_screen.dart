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
import '../../../../core/services/ai_service.dart';
import '../../../../core/utils/notification_manager.dart';

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
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Enable Cloud Backup?'),
                              content: const Text(
                                  'To enable cloud backup and synchronize your tasks across devices, please sign in or register for a premium account.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    context.push(AppRoutes.auth);
                                  },
                                  child: const Text('Sign In / Sign Up'),
                                ),
                              ],
                            ),
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
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Premium Feature'),
                            content: const Text(
                                'AI Weekly Performance Wrap is a premium feature. Please sign in or register to unlock weekly summaries.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  context.push(AppRoutes.auth);
                                },
                                child: const Text('Upgrade'),
                              ),
                            ],
                          ),
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
}
