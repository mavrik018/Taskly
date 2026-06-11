import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../widgets/empty_state.dart';
import '../../../tasks/presentation/controllers/tasks_provider.dart';
import '../../../tasks/domain/entities/task.dart';
import '../../../tasks/presentation/widgets/task_card.dart';
import '../../../tasks/presentation/screens/task_detail_screen.dart';
import '../../../onboarding/presentation/controllers/onboarding_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/confetti_service.dart';
import '../../../../core/theme/theme_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  bool _isUpcomingExpanded = false;
  late AnimationController _greetingController;

  @override
  void initState() {
    super.initState();
    _greetingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _greetingController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good morning';
    if (hour >= 12 && hour < 17) return 'Good afternoon';
    if (hour >= 17 && hour < 21) return 'Good evening';
    return 'Good night';
  }

  String _getGreetingEmoji() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return '☀️';
    if (hour >= 12 && hour < 17) return '🌤️';
    if (hour >= 17 && hour < 21) return '🌆';
    return '🌙';
  }

  String _getWeekdayName(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff =
        DateTime(date.year, date.month, date.day).difference(today).inDays;
    if (diff == 1) return 'Tomorrow';
    switch (date.weekday) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return 'Upcoming';
    }
  }

  void _openTask(BuildContext context, {Task? task}) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (context) => TaskDetailScreen(task: task),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksStreamProvider);
    final onboardingStateAsync = ref.watch(onboardingProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final userName =
        onboardingStateAsync.value?.userName ?? 'Productivity Champ';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: tasksAsync.when(
        data: (tasks) {
          final activeTasks = tasks.where((t) => !t.isCompleted).toList()
            ..sort((a, b) {
              if (a.dueDate == null && b.dueDate == null) return 0;
              if (a.dueDate == null) return 1;
              if (b.dueDate == null) return -1;
              return a.dueDate!.compareTo(b.dueDate!);
            });

          final completedTasks = tasks.where((t) => t.isCompleted).toList()
            ..sort((a, b) {
              if (a.dueDate == null && b.dueDate == null) return 0;
              if (a.dueDate == null) return 1;
              if (b.dueDate == null) return -1;
              return a.dueDate!.compareTo(b.dueDate!);
            });

          final totalTasksCount = tasks.length;
          final completedTasksCount = completedTasks.length;
          final progress =
              totalTasksCount > 0 ? completedTasksCount / totalTasksCount : 0.0;

          return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ─── Premium App Bar ───────────────────────────────────────
                SliverAppBar(
                  floating: true,
                  snap: true,
                  backgroundColor: theme.scaffoldBackgroundColor,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  centerTitle: true,
                  title: Text(
                    'TaskFlow',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.textTheme.bodyLarge?.color,
                      fontSize: 24.sp,
                      letterSpacing: -0.5,
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: Icon(
                        isDark
                            ? Icons.light_mode_rounded
                            : Icons.dark_mode_rounded,
                      ),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        ref.read(themeModeProvider.notifier).toggleTheme();
                      },
                    ),
                    SizedBox(width: AppSpacing.sm),
                  ],
                ),

                // ─── Hero Greeting ─────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm,
                        AppSpacing.md, AppSpacing.xs),
                    child: _HeroGreetingCard(
                      userName: userName,
                      activeTasks: activeTasks,
                      completedTasks: completedTasks,
                      greeting: _getGreeting(),
                      isDark: isDark,
                      theme: theme,
                    ),
                  ),
                ),

                // ─── Progress Card ─────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md,
                        AppSpacing.md, AppSpacing.lg),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Task Progress',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: theme.textTheme.bodySmall?.color
                                    ?.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${(progress * 100).toInt()}%',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
                            backgroundColor: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ─── Tasks Header ──────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    child: Text(
                      "Tasks",
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 20.sp,
                      ),
                    ),
                  ).animate().fadeIn(duration: 300.ms, delay: 200.ms),
                ),

                // ─── Active Task Items ─────────────────────────────────────
                if (activeTasks.isEmpty && completedTasks.isEmpty)
                  const SliverToBoxAdapter(child: EmptyState())
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final task = activeTasks[index];
                        return TaskCard(
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
                          onTap: () => _openTask(context, task: task),
                        );
                      },
                      childCount: activeTasks.length,
                    ),
                  ),

                // ─── Completed Section ─────────────────────────────────────
                if (completedTasks.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.lg,
                          AppSpacing.md, AppSpacing.sm),
                      child: Text(
                        'COMPLETED',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.textTheme.bodySmall?.color
                              ?.withValues(alpha: 0.4),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final task = completedTasks[index];
                        return TaskCard(
                          task: task,
                          onToggle: () async {
                            await ref
                                .read(tasksControllerProvider.notifier)
                                .toggleCompletion(task);
                          },
                          onDelete: () {
                            ref
                                .read(tasksControllerProvider.notifier)
                                .deleteTask(task.id);
                          },
                          onTap: () => _openTask(context, task: task),
                        );
                      },
                      childCount: completedTasks.length,
                    ),
                  ),
                ],
              ]);
        },
        loading: () => Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 2.5,
          ),
        ),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: _AddTaskFAB(
        onPressed: () => _openTask(context),
      ),
    );
  }
}

// ─── Hero Greeting Card ──────────────────────────────────────────────────────

class _HeroGreetingCard extends StatelessWidget {
  const _HeroGreetingCard({
    required this.userName,
    required this.activeTasks,
    required this.completedTasks,
    required this.greeting,
    required this.isDark,
    required this.theme,
  });

  final String userName;
  final List<Task> activeTasks;
  final List<Task> completedTasks;
  final String greeting;
  final bool isDark;
  final ThemeData theme;

  String get _subline {
    final total = activeTasks.length;
    final done = completedTasks.length;
    if (total == 0 && done == 0) {
      return 'Your schedule is clear, a great time to plan ahead.';
    }
    if (done == 0) return 'Let\'s make progress, one task at a time.';
    if (total == 0) return 'All done! Enjoy the rest of your day.';
    return '$done task${done == 1 ? '' : 's'} completed. Keep the momentum going!';
  }

  IconData get _greetingIcon {
    final g = greeting.toLowerCase();
    if (g.contains('morning')) return Icons.wb_sunny_rounded;
    if (g.contains('afternoon')) return Icons.wb_cloudy_rounded;
    if (g.contains('evening')) return Icons.nights_stay_rounded;
    return Icons.bedtime_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = AppColors.primary;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1.0.w,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: isDark ? 0.15 : 0.09),
            blurRadius: 28,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date + greeting pill row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('EEEE, MMMM d')
                          .format(DateTime.now())
                          .toUpperCase(),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.textTheme.bodySmall?.color
                            ?.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                        fontSize: 10.sp,
                      ),
                    ),
                    const Spacer(),

                    // Greeting icon pill
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
                      decoration: BoxDecoration(
                        color:
                            accentColor.withValues(alpha: isDark ? 0.12 : 0.08),
                        borderRadius: BorderRadius.circular(30.r),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _greetingIcon,
                            size: 14.sp,
                            color: accentColor,
                          ),
                          SizedBox(width: 5.w),
                          Text(
                            greeting,
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: accentColor,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 100.ms, duration: 400.ms)
                        .scaleXY(begin: 0.92, end: 1.0),
                  ],
                ),

                SizedBox(height: 16.h),

                Text(
                  'Hello, $userName',
                  style: GoogleFonts.poppins(
                    fontSize: 26.sp,
                    fontWeight: FontWeight.w400,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 150.ms, duration: 450.ms)
                    .slideY(begin: 0.05, end: 0),

                SizedBox(height: 8.h),

                // Sub-line
                Text(
                  _subline,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodySmall?.color
                        ?.withValues(alpha: 0.65),
                    fontSize: 13.5.sp,
                    height: 1.45,
                  ),
                ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

                SizedBox(height: 20.h),

                // Stats row
                _StatsRow(
                  activeTasks: activeTasks,
                  completedTasks: completedTasks,
                  accentColor: accentColor,
                  theme: theme,
                  isDark: isDark,
                )
                    .animate()
                    .fadeIn(delay: 270.ms, duration: 400.ms)
                    .slideY(begin: 0.08, end: 0),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.04, end: 0);
  }
}

// ─── Stats Row ───────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.activeTasks,
    required this.completedTasks,
    required this.accentColor,
    required this.theme,
    required this.isDark,
  });

  final List<Task> activeTasks;
  final List<Task> completedTasks;
  final Color accentColor;
  final ThemeData theme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final total = activeTasks.length + completedTasks.length;

    return Row(
      children: [
        _StatChip(
          label: 'Active',
          value: '${activeTasks.length}',
          color: accentColor,
          isDark: isDark,
          theme: theme,
        ),
        SizedBox(width: 8.w),
        _StatChip(
          label: 'Completed',
          value: '${completedTasks.length}',
          color: Colors.green,
          isDark: isDark,
          theme: theme,
        ),
        SizedBox(width: 8.w),
        _StatChip(
          label: 'Total',
          value: '$total',
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          isDark: isDark,
          theme: theme,
          subtle: true,
        ),
      ],
    );
  }
}

// ─── Stat Chip ───────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
    required this.theme,
    this.subtle = false,
  });

  final String label;
  final String value;
  final Color color;
  final bool isDark;
  final ThemeData theme;
  final bool subtle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 7.5.h),
      decoration: BoxDecoration(
        color: subtle
            ? (isDark ? AppColors.darkSurface : AppColors.lightSurface)
            : color.withValues(alpha: isDark ? 0.12 : 0.09),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: subtle
              ? (isDark ? AppColors.darkBorder : AppColors.lightBorder)
              : color.withValues(alpha: isDark ? 0.25 : 0.2),
          width: 1.w,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: subtle
                  ? theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.75)
                  : color,
              height: 1,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w500,
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.55),
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Premium FAB ─────────────────────────────────────────────────────────────

class _AddTaskFAB extends StatefulWidget {
  final VoidCallback onPressed;

  const _AddTaskFAB({required this.onPressed});

  @override
  State<_AddTaskFAB> createState() => _AddTaskFABState();
}

class _AddTaskFABState extends State<_AddTaskFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      lowerBound: 0.92,
      upperBound: 1.0,
      value: 1.0,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnim = _controller;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ScaleTransition(
      scale: _scaleAnim,
      child: GestureDetector(
        onTapDown: (_) => _controller.reverse(),
        onTapUp: (_) {
          _controller.forward();
          widget.onPressed();
        },
        onTapCancel: () => _controller.forward(),
        child: Container(
          height: 60,
          width: 60,
          decoration: BoxDecoration(
            color: isDark ? Colors.white : Colors.black,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            Icons.add_rounded,
            color: isDark ? Colors.black : Colors.white,
            size: 32,
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: 300.ms)
        .slideY(begin: 0.3, end: 0);
  }
}
