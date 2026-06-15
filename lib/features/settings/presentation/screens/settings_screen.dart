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
import '../../../../core/utils/notification_manager.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDarkMode = ref.watch(themeModeProvider);
    final settingsState = ref.watch(settingsProvider);
    final db = ref.watch(databaseProvider);
    final onboardingState = ref.watch(onboardingProvider);
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
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Center(
                        child: Text(
                          userName.isNotEmpty
                              ? userName.substring(0, 1).toUpperCase()
                              : 'U',
                          style: TextStyle(
                            color: Colors.white,
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
            SizedBox(height: AppSpacing.md),

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
            SizedBox(height: AppSpacing.md),

            /*
            // Account Section
            Text(
              'ACCOUNT',
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
                    icon: Icons.person_outline,
                    title: 'Personal Information',
                    trailing: Icon(Icons.chevron_right,
                        color: theme.colorScheme.secondary),
                    onTap: () {
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
                                        .updateUserName(controller.text.trim());
                                    if (context.mounted) Navigator.pop(context);
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
                  // Divider(height: 1, indent: 56.w),
                  // _buildSettingItem(
                  //   context: context,
                  //   icon: Icons.subscriptions_outlined,
                  //   title: 'Subscription',
                  //   trailing: Row(
                  //     mainAxisSize: MainAxisSize.min,
                  //     children: [
                  //       Container(
                  //         padding: EdgeInsets.symmetric(
                  //             horizontal: 8.w, vertical: 4.h),
                  //         decoration: BoxDecoration(
                  //           color: AppColors.primary,
                  //           borderRadius: BorderRadius.circular(6.r),
                  //         ),
                  //         child: Text(
                  //           settingsState.subscriptionTier,
                  //           style: TextStyle(
                  //             color: Colors.white,
                  //             fontSize: 10.sp,
                  //             fontWeight: FontWeight.bold,
                  //           ),
                  //         ),
                  //       ),
                  //       SizedBox(width: 4.w),
                  //       Icon(Icons.chevron_right,
                  //           color: theme.colorScheme.secondary),
                  //     ],
                  //   ),
                  //   onTap: () {
                  //     HapticFeedback.lightImpact();
                  //     showDialog(
                  //       context: context,
                  //       builder: (context) {
                  //         return AlertDialog(
                  //           title: const Text('Subscription Plan'),
                  //           content: Column(
                  //             mainAxisSize: MainAxisSize.min,
                  //             children: [
                  //               ListTile(
                  //                 title: const Text('FREE Plan'),
                  //                 subtitle: const Text(
                  //                     'Standard access, up to 5 projects'),
                  //                 leading: Radio<String>(
                  //                   value: 'FREE',
                  //                   groupValue: settingsState.subscriptionTier,
                  //                   onChanged: (value) async {
                  //                     if (value != null) {
                      //                       await ref
                      //                           .read(settingsProvider.notifier)
                      //                           .setSubscriptionTier(value);
                      //                       if (context.mounted)
                      //                         Navigator.pop(context);
                      //                     }
                      //                   },
                      //                 ),
                      //               ),
                      //               ListTile(
                      //                 title: const Text('PRO Plan'),
                      //                 subtitle: const Text(
                      //                     'Unlimited projects & priority support'),
                      //                 leading: Radio<String>(
                      //                   value: 'PRO',
                      //                   groupValue: settingsState.subscriptionTier,
                      //                   onChanged: (value) async {
                      //                     if (value != null) {
                      //                       await ref
                      //                           .read(settingsProvider.notifier)
                      //                           .setSubscriptionTier(value);
                      //                       if (context.mounted)
                      //                         Navigator.pop(context);
                      //                     }
                      //                   },
                      //                 ),
                      //               ),
                      //             ],
                      //           ),
                      //         );
                      //       },
                      //     );
                      //   },
                      // ),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.md),
                */

            // Clear All Data
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.priorityHigh,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.borderLG,
                  ),
                ),
                onPressed: () async {
                  HapticFeedback.heavyImpact();
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Clear All Data?'),
                      content: Text(
                          'This action is irreversible. All tasks and projects will be deleted.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text('Cancel'),
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
                child: Text(
                  'Clear All Data',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
              color: theme.colorScheme.onSurface.withOpacity(0.8),
              size: 24.sp,
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
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
