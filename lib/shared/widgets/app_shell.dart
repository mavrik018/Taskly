import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/notification_manager.dart';
import '../../features/tasks/presentation/controllers/tasks_provider.dart';
import '../../features/tasks/presentation/screens/task_detail_screen.dart';

class AppShell extends ConsumerStatefulWidget {
  final Widget child;

  const AppShell({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with SingleTickerProviderStateMixin {
  late AnimationController _navAnimController;

  @override
  void initState() {
    super.initState();
    _navAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationManager.init(ref);
    });
  }

  @override
  void dispose() {
    _navAnimController.dispose();
    super.dispose();
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/projects')) return 1;
    if (location.startsWith('/settings')) return 2;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    HapticFeedback.selectionClick();
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/projects');
        break;
      case 2:
        context.go('/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final selectedIndex = _calculateSelectedIndex(context);

    // Listen to notification tap events and launch the deep-linked detail sheet
    ref.listen<int?>(notificationTapProvider, (previous, next) async {
      if (next != null) {
        ref.read(notificationTapProvider.notifier).set(null);
        final repository = ref.read(taskRepositoryProvider);
        final task = await repository.getTaskById(next);
        if (task != null && context.mounted) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) => FractionallySizedBox(
              heightFactor: 0.85,
              child: TaskDetailScreen(task: task),
            ),
          );
        }
      }
    });

    return Scaffold(
      body: widget.child,
      extendBody: true,
      bottomNavigationBar: _PremiumNavBar(
        selectedIndex: selectedIndex,
        isDark: isDark,
        theme: theme,
        onTap: (index) => _onItemTapped(index, context),
      ),
    );
  }
}

// ─── Premium Floating Nav Bar ───────────────────────────────────────────────

class _PremiumNavBar extends StatelessWidget {
  final int selectedIndex;
  final bool isDark;
  final ThemeData theme;
  final ValueChanged<int> onTap;

  const _PremiumNavBar({
    required this.selectedIndex,
    required this.isDark,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: 24.h,
        top: 8.h,
      ),
      child: ClipRRect(
        borderRadius: AppRadius.borderXXL,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: 66.h,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurface.withOpacity(0.85)
                  : Colors.white.withOpacity(0.88),
              borderRadius: AppRadius.borderXXL,
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.07)
                    : Colors.black.withOpacity(0.06),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.4)
                      : Colors.black.withOpacity(0.10),
                  blurRadius: 32,
                  spreadRadius: -4,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.06),
                  blurRadius: 24,
                  spreadRadius: -2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.check_circle_outline_rounded,
                  activeIcon: Icons.check_circle_rounded,
                  label: 'Tasks',
                  index: 0,
                  selectedIndex: selectedIndex,
                  isDark: isDark,
                  onTap: onTap,
                ),
                _NavItem(
                  icon: Icons.folder_outlined,
                  activeIcon: Icons.folder_rounded,
                  label: 'Projects',
                  index: 1,
                  selectedIndex: selectedIndex,
                  isDark: isDark,
                  onTap: onTap,
                ),
                _NavItem(
                  icon: Icons.tune_outlined,
                  activeIcon: Icons.tune_rounded,
                  label: 'Settings',
                  index: 2,
                  selectedIndex: selectedIndex,
                  isDark: isDark,
                  onTap: onTap,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int selectedIndex;
  final bool isDark;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.selectedIndex,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _opacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    if (widget.index == widget.selectedIndex) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(_NavItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index == widget.selectedIndex) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.index == widget.selectedIndex;

    return GestureDetector(
      onTap: () => widget.onTap(widget.index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return SizedBox(
            width: 80.w,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Active capsule background
                FadeTransition(
                  opacity: _opacityAnim,
                  child: ScaleTransition(
                    scale: _scaleAnim,
                    child: Container(
                      width: 60.w,
                      height: 38.h,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(
                          widget.isDark ? 0.18 : 0.10,
                        ),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                    ),
                  ),
                ),
                // Icon + label column
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        isSelected ? widget.activeIcon : widget.icon,
                        key: ValueKey(isSelected),
                        color: isSelected
                            ? AppColors.primary
                            : (widget.isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary),
                        size: 22.sp,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: isSelected
                            ? AppColors.primary
                            : (widget.isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary),
                        letterSpacing: 0.1,
                      ),
                      child: Text(widget.label),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
