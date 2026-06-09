import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../widgets/empty_state.dart';
import '../widgets/progress_bar.dart';
import '../../../tasks/presentation/controllers/tasks_provider.dart';
import '../../../tasks/domain/entities/task.dart';
import '../../../tasks/presentation/widgets/task_card.dart';
import '../../../tasks/presentation/screens/task_detail_screen.dart';
import '../../../onboarding/presentation/controllers/onboarding_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/utils/confetti_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  bool _isUpcomingExpanded = false;
  late AnimationController _chevronController;
  late Animation<double> _chevronRotation;

  @override
  void initState() {
    super.initState();
    _chevronController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _chevronRotation =
        Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _chevronController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _chevronController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good morning';
    if (hour >= 12 && hour < 17) return 'Good afternoon';
    if (hour >= 17 && hour < 21) return 'Good evening';
    return 'Good night';
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    const weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday'
    ];
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }

  String _getWeekdayName(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = DateTime(date.year, date.month, date.day).difference(today).inDays;
    if (diff == 1) return 'Tomorrow';
    const weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday'
    ];
    return weekdays[date.weekday - 1];
  }

  void _toggleUpcoming() {
    HapticFeedback.lightImpact();
    setState(() => _isUpcomingExpanded = !_isUpcomingExpanded);
    if (_isUpcomingExpanded) {
      _chevronController.forward();
    } else {
      _chevronController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksStreamProvider);
    final onboardingStateAsync = ref.watch(onboardingProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final userName = onboardingStateAsync.value?.userName ?? 'there';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: tasksAsync.when(
        data: (tasks) {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final upcomingLimit = today.add(const Duration(days: 8));

          final todayTasks = tasks.where((t) {
            if (t.dueDate == null) return false;
            final date = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
            final isSameDay = date.isAtSameMomentAs(today);
            final isOverdueIncomplete = date.isBefore(today) && !t.isCompleted;
            return isSameDay || isOverdueIncomplete;
          }).toList();

          final upcomingTasks = tasks.where((t) {
            if (t.dueDate == null) return false;
            final date = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
            return date.isAfter(today) && date.isBefore(upcomingLimit);
          }).toList();

          final completedTodayCount = todayTasks.where((t) => t.isCompleted).length;
          final totalTodayCount = todayTasks.length;
          final progress = totalTodayCount > 0 ? completedTodayCount / totalTodayCount : 0.0;

          final Map<String, List<Task>> upcomingGroups = {};
          for (final task in upcomingTasks) {
            final label = _getWeekdayName(task.dueDate!);
            upcomingGroups.putIfAbsent(label, () => []).add(task);
          }

          return CustomScrollView(
            slivers: [
              // ── Sticky Sliver Header ─────────────────────────────────────
              SliverPersistentHeader(
                pinned: true,
                delegate: _HomeHeaderDelegate(
                  greeting: _getGreeting(),
                  userName: userName,
                  date: _getFormattedDate(),
                  isDark: isDark,
                  onSearch: () {
                    HapticFeedback.lightImpact();
                    context.push(AppRoutes.search);
                  },
                ),
              ),

              SliverToBoxAdapter(child: SizedBox(height: AppSpacing.h_xs)),

              // ── Progress Card ─────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _ProgressCard(
                  progress: progress,
                  completedCount: completedTodayCount,
                  totalCount: totalTodayCount,
                  isDark: isDark,
                ).animate().fadeIn(duration: 350.ms).slideY(
                  begin: 0.06,
                  end: 0,
                  curve: Curves.easeOutCubic,
                  duration: 350.ms,
                ),
              ),

              SliverToBoxAdapter(child: SizedBox(height: AppSpacing.h_md)),

              // ── Today Section Header ──────────────────────────────────────
              SliverToBoxAdapter(
                child: _SectionHeader(
                  label: "TODAY'S TASKS",
                  count: todayTasks.length,
                ).animate().fadeIn(duration: 300.ms, delay: 80.ms),
              ),

              SliverToBoxAdapter(child: SizedBox(height: AppSpacing.h_xs)),

              // ── Today Tasks ───────────────────────────────────────────────
              if (todayTasks.isEmpty)
                const SliverToBoxAdapter(child: EmptyState())
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final task = todayTasks[index];
                      return TaskCard(
                        task: task,
                        onToggle: () async {
                          final wasCompleted = task.isCompleted;
                          await ref
                              .read(tasksControllerProvider.notifier)
                              .toggleCompletion(task);
                          if (!wasCompleted && context.mounted) {
                            await ConfettiService.notifyTaskCompleted(context);
                          }
                        },
                        onDelete: () {
                          ref
                              .read(tasksControllerProvider.notifier)
                              .deleteTask(task.id);
                        },
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (context) => FractionallySizedBox(
                              heightFactor: 0.85,
                              child: TaskDetailScreen(task: task),
                            ),
                          );
                        },
                      ).animate().fadeIn(
                            duration: 300.ms,
                            delay: Duration(milliseconds: 40 * index),
                          );
                    },
                    childCount: todayTasks.length,
                  ),
                ),

              // ── Upcoming Section ──────────────────────────────────────────
              if (upcomingTasks.isNotEmpty) ...[
                SliverToBoxAdapter(child: SizedBox(height: AppSpacing.h_md)),
                SliverToBoxAdapter(
                  child: _SectionHeader(
                    label: 'UPCOMING',
                    count: upcomingTasks.length,
                  ).animate().fadeIn(duration: 300.ms, delay: 120.ms),
                ),
                SliverToBoxAdapter(child: SizedBox(height: AppSpacing.h_xs)),
                // Accordion toggle row
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: GestureDetector(
                      onTap: _toggleUpcoming,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurface
                              : AppColors.lightSurface,
                          borderRadius: AppRadius.borderXL,
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.10),
                                borderRadius: AppRadius.borderMD,
                              ),
                              child: const Icon(
                                Icons.calendar_month_outlined,
                                color: AppColors.primary,
                                size: 16,
                              ),
                            ),
                            SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                '${upcomingTasks.length} upcoming task${upcomingTasks.length == 1 ? '' : 's'}',
                                style: TextStyle(
                                  fontSize: 13.5.sp,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary,
                                ),
                              ),
                            ),
                            RotationTransition(
                              turns: _chevronRotation,
                              child: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 20,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],

              // ── Upcoming Expanded Groups ───────────────────────────────────
              if (_isUpcomingExpanded && upcomingTasks.isNotEmpty)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final label = upcomingGroups.keys.elementAt(index);
                      final groupTasks = upcomingGroups[label] ?? [];

                      return Padding(
                        padding: EdgeInsets.only(top: AppSpacing.h_xs),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(
                                left: AppSpacing.md + 4,
                                bottom: 4,
                              ),
                              child: Text(
                                label.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10.5.sp,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.9,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            ...groupTasks.map((task) => TaskCard(
                                  task: task,
                                  onToggle: () async {
                                    final wasCompleted = task.isCompleted;
                                    await ref
                                        .read(tasksControllerProvider.notifier)
                                        .toggleCompletion(task);
                                    if (!wasCompleted && context.mounted) {
                                      await ConfettiService.notifyTaskCompleted(
                                          context);
                                    }
                                  },
                                  onDelete: () {
                                    ref
                                        .read(tasksControllerProvider.notifier)
                                        .deleteTask(task.id);
                                  },
                                  onTap: () {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      builder: (context) => FractionallySizedBox(
                                        heightFactor: 0.85,
                                        child: TaskDetailScreen(task: task),
                                      ),
                                    );
                                  },
                                )),
                          ],
                        ),
                      ).animate().fadeIn(duration: 250.ms).slideY(
                            begin: 0.05,
                            end: 0,
                            duration: 250.ms,
                            curve: Curves.easeOutCubic,
                          );
                    },
                    childCount: upcomingGroups.keys.length,
                  ),
                ),

              // ── Bottom spacer for FAB clearance ──────────────────────────
              SliverToBoxAdapter(child: SizedBox(height: 120.h)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),

      // ── Premium Pill FAB ─────────────────────────────────────────────────
      floatingActionButton: _PremiumFab(
        onPressed: () {
          HapticFeedback.mediumImpact();
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) => const FractionallySizedBox(
              heightFactor: 0.85,
              child: TaskDetailScreen(),
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

// ─── Sliver Header Delegate ──────────────────────────────────────────────────

class _HomeHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String greeting;
  final String userName;
  final String date;
  final bool isDark;
  final VoidCallback onSearch;

  const _HomeHeaderDelegate({
    required this.greeting,
    required this.userName,
    required this.date,
    required this.isDark,
    required this.onSearch,
  });

  @override
  double get minExtent => 64;
  @override
  double get maxExtent => 112;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final t = (shrinkOffset / maxExtent).clamp(0.0, 1.0);
    final isCollapsed = t > 0.5;
    final theme = Theme.of(context);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: overlapsContent ? 16 : 0,
          sigmaY: overlapsContent ? 16 : 0,
        ),
        child: Container(
          color: theme.scaffoldBackgroundColor.withOpacity(
            overlapsContent ? 0.88 : 1.0,
          ),
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 6,
            bottom: 10,
          ),
          child: AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            firstChild: _buildExpanded(context),
            secondChild: _buildCollapsed(context),
            crossFadeState: isCollapsed
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
          ),
        ),
      ),
    );
  }

  Widget _buildExpanded(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$greeting, $userName 👋',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w400,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
          _ActionButton(
            icon: Icons.search_rounded,
            onTap: onSearch,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsed(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'TaskFlow',
            style: TextStyle(
              fontSize: 17.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: AppColors.primary,
            ),
          ),
          _ActionButton(icon: Icons.search_rounded, onTap: onSearch, isDark: isDark),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _HomeHeaderDelegate oldDelegate) =>
      greeting != oldDelegate.greeting ||
      userName != oldDelegate.userName ||
      isDark != oldDelegate.isDark;
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;

  const _ActionButton({
    required this.icon,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.07)
              : Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isDark
              ? AppColors.darkTextPrimary
              : AppColors.lightTextPrimary,
        ),
      ),
    );
  }
}

// ─── Progress Card ───────────────────────────────────────────────────────────

class _ProgressCard extends StatelessWidget {
  final double progress;
  final int completedCount;
  final int totalCount;
  final bool isDark;

  const _ProgressCard({
    required this.progress,
    required this.completedCount,
    required this.totalCount,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Container(
        padding: EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF1E1B4B),
                    const Color(0xFF1E1B3A),
                  ]
                : [
                    const Color(0xFFEEF2FF),
                    const Color(0xFFF5F3FF),
                  ],
          ),
          borderRadius: AppRadius.borderXL,
          border: Border.all(
            color: AppColors.primary.withOpacity(isDark ? 0.18 : 0.12),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Today's progress",
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.primary.withOpacity(0.75),
                    letterSpacing: 0.2,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$completedCount / $totalCount',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.h_sm),
            ProgressBar(value: progress),
            if (totalCount > 0 && completedCount == totalCount) ...[
              SizedBox(height: AppSpacing.h_xs),
              Row(
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.primary,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'All done! Great work today.',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Section Header ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final int count;

  const _SectionHeader({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md + 2),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.9,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Premium FAB ─────────────────────────────────────────────────────────────

class _PremiumFab extends StatefulWidget {
  final VoidCallback onPressed;
  const _PremiumFab({required this.onPressed});

  @override
  State<_PremiumFab> createState() => _PremiumFabState();
}

class _PremiumFabState extends State<_PremiumFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 130),
      lowerBound: 0.0,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnim = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.reverse(),
      onTapUp: (_) {
        _controller.forward();
        widget.onPressed();
      },
      onTapCancel: () => _controller.forward(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          height: 50.h,
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primaryDark, AppColors.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: AppRadius.borderCircular,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.35),
                blurRadius: 20,
                spreadRadius: -2,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'New Task',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
