import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_routes.dart';
import '../widgets/empty_state.dart';
import '../../../tasks/presentation/controllers/tasks_provider.dart';
import '../../../tasks/domain/entities/task.dart';
import '../../../tasks/presentation/widgets/task_card.dart';
import '../../../tasks/presentation/screens/task_detail_screen.dart';
import '../../../tasks/presentation/widgets/task_breakdown_sheet.dart';
import '../../../../core/services/ai_service.dart';
import '../../../auth/presentation/controllers/auth_provider.dart';
import '../../../onboarding/presentation/controllers/onboarding_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/confetti_service.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/utils/error_mapper.dart';
import '../../../../core/utils/streak_manager.dart';
import '../../../../shared/widgets/premium_promo_dialog.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _dismissedFocusSuggestion = false;
  bool _dismissedRescheduleHelper = false;
  Map<String, dynamic>? _focusSuggestion;
  bool _loadingFocusSuggestion = false;
  bool _reschedulingTasks = false;

  int _streakDays = 1;

  @override
  void initState() {
    super.initState();
    _loadCachedFocusSuggestion();
    _updateContinuousStreak();
  }

  Future<void> _updateContinuousStreak() async {
    final streak = await StreakManager.updateStreak();
    if (mounted) {
      setState(() {
        _streakDays = streak;
      });
    }
  }

  Future<void> _loadCachedFocusSuggestion() async {
    try {
      final cached = await AIService.getCachedFocusSuggestion();
      if (mounted && cached != null) {
        setState(() {
          _focusSuggestion = cached;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadFocusSuggestion() async {
    setState(() {
      _loadingFocusSuggestion = true;
    });

    try {
      final tasks = ref.read(tasksStreamProvider).value ?? [];
      final pending = tasks
          .where((t) => !t.isCompleted)
          .map((t) => {
                'id': t.id,
                'title': t.title,
                'priority': t.priority,
                'dueDate': t.dueDate?.toIso8601String(),
              })
          .toList();

      final suggestion = await AIService.getDailyFocusSuggestions(pending);
      if (mounted) {
        setState(() {
          _focusSuggestion = suggestion;
          _loadingFocusSuggestion = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loadingFocusSuggestion = false);
      }
    }
  }

  Future<void> _rescheduleTasksRealistically(List<Task> overdueTasks) async {
    if (ref.read(authProvider) == null) {
      PremiumPromoDialog.show(
        context: context,
        title: 'Overdue Reschedule Helper',
        content: 'AI Overdue Rescheduling is a premium feature. Please sign in or register to reschedule realistically.',
        icon: Icons.warning_amber_rounded,
      );
      return;
    }

    setState(() {
      _reschedulingTasks = true;
    });
    HapticFeedback.mediumImpact();

    try {
      final mapped = overdueTasks
          .map((t) => {
                'id': t.id,
                'title': t.title,
                'priority': t.priority,
                'dueDate': t.dueDate?.toIso8601String(),
              })
          .toList();

      final resched = await AIService.rescheduleOverdueTasks(mapped);
      final controller = ref.read(tasksControllerProvider.notifier);

      for (final item in resched) {
        final task = overdueTasks.firstWhere((t) => t.id == item['id']);
        final newDate = DateTime.parse(item['newDueDate']);
        await controller
            .updateTaskDetails(task.copyWith(dueDate: () => newDate));
      }

      if (mounted) {
        setState(() {
          _dismissedRescheduleHelper = true;
          _reschedulingTasks = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Overdue tasks rescheduled successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _reschedulingTasks = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorMapper.getAIErrorMessage(e))),
        );
      }
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good morning';
    if (hour >= 12 && hour < 17) return 'Good afternoon';
    if (hour >= 17 && hour < 21) return 'Good evening';
    return 'Good night';
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

  void _breakdownTask(BuildContext context, Task task) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (context) => TaskBreakdownSheet(task: task),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (previous, next) {
      if (next != null && previous == null) {
        _loadFocusSuggestion();
      }
    });

    ref.listen<AsyncValue<List<Task>>>(tasksStreamProvider, (previous, next) {
      if (next is AsyncData<List<Task>>) {
        final prevList = previous?.value;
        final nextList = next.value;
        if (prevList != null) {
          bool hasChanges = false;
          if (prevList.length != nextList.length) {
            hasChanges = true;
          } else {
            for (int i = 0; i < prevList.length; i++) {
              final p = prevList[i];
              final n = nextList.firstWhere((element) => element.id == p.id,
                  orElse: () => p);
              if (n.title != p.title ||
                  n.priority != p.priority ||
                  n.dueDate != p.dueDate ||
                  n.isCompleted != p.isCompleted) {
                hasChanges = true;
                break;
              }
            }
          }
          if (hasChanges) {
            _loadFocusSuggestion();
          }
        }
      }
    });

    final tasksAsync = ref.watch(tasksStreamProvider);
    final onboardingStateAsync = ref.watch(onboardingProvider);
    final currentUser = ref.watch(authProvider);
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
                // ─── Greeting & Streak ──────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm,
                        AppSpacing.md, AppSpacing.xs),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getGreeting(),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.textTheme.bodySmall?.color
                                    ?.withValues(alpha: 0.55),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              userName,
                              style: GoogleFonts.poppins(
                                fontSize: 26.sp,
                                fontWeight: FontWeight.w600,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '$_streakDays',
                              style: GoogleFonts.poppins(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: theme.textTheme.bodyLarge?.color,
                              ),
                            ),
                            const SizedBox(width: 7),
                            Text(
                              'day streak',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.textTheme.bodySmall?.color
                                    ?.withValues(alpha: 0.55),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.04, end: 0),
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

                // ─── AI Premium Suggestions ──────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Column(
                      children: [
                        // Overdue helper card
                        if (!_dismissedRescheduleHelper &&
                            activeTasks
                                .where((t) =>
                                    t.dueDate != null &&
                                    t.dueDate!.isBefore(DateTime.now()))
                                .isNotEmpty &&
                            activeTasks
                                    .where((t) =>
                                        t.dueDate != null &&
                                        t.dueDate!.isBefore(DateTime.now()))
                                    .length >=
                                3)
                          Container(
                            margin: EdgeInsets.only(bottom: AppSpacing.md),
                            padding: EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              // FIX: was a hardcoded dark navy (#1E1E24) in light mode,
                              // rendering a dark card on a white background. Now matches
                              // the Daily Focus card's isDark-aware surface treatment.
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.black.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.15)
                                      : Colors.black.withValues(alpha: 0.1)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.warning_amber_rounded,
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black,
                                            size: 20.sp),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Overdue Helper',
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.close,
                                        size: 18,
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.black54,
                                      ),
                                      onPressed: () => setState(() =>
                                          _dismissedRescheduleHelper = true),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'You have ${activeTasks.where((t) => t.dueDate != null && t.dueDate!.isBefore(DateTime.now())).length} overdue tasks piling up. Let AI reschedule them realistically across the next few days?',
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    color: theme.textTheme.bodyMedium?.color
                                        ?.withValues(alpha: 0.85),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  height: 40,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          isDark ? Colors.white : Colors.black,
                                      foregroundColor:
                                          isDark ? Colors.black : Colors.white,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                    ),
                                    onPressed: _reschedulingTasks
                                        ? null
                                        : () => _rescheduleTasksRealistically(
                                            activeTasks
                                                .where((t) =>
                                                    t.dueDate != null &&
                                                    t.dueDate!.isBefore(
                                                        DateTime.now()))
                                                .toList()),
                                    child: _reschedulingTasks
                                        ? SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                                color: isDark
                                                    ? Colors.black
                                                    : Colors.white,
                                                strokeWidth: 2),
                                          )
                                        : const Text('Reschedule Realistically',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(duration: 400.ms),

                        // Daily focus recommendation card
                        if (!_dismissedFocusSuggestion) ...[
                          if (_focusSuggestion != null)
                            Container(
                              margin: EdgeInsets.only(bottom: AppSpacing.md),
                              padding: EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : Colors.black.withValues(alpha: 0.03),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.15)
                                        : Colors.black.withValues(alpha: 0.1)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          // FIX: was hardcoded Colors.white — invisible
                                          // against this card's near-white background
                                          // in light mode. Now theme-aware.
                                          Icon(Icons.auto_awesome_rounded,
                                              color: isDark
                                                  ? Colors.white
                                                  : Colors.black,
                                              size: 20.sp),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Daily Focus Suggestion',
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: isDark
                                                  ? Colors.white
                                                  : Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.close,
                                          size: 18,
                                          color: isDark
                                              ? Colors.white70
                                              : Colors.black54,
                                        ),
                                        onPressed: () => setState(() =>
                                            _dismissedFocusSuggestion = true),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _focusSuggestion!['message']?.toString() ??
                                        '',
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      height: 1.4,
                                      // FIX: was Colors.white.withOpacity(0.8) — same
                                      // light-mode visibility issue as the icon above.
                                      color: theme.textTheme.bodyMedium?.color
                                          ?.withValues(alpha: 0.85),
                                    ),
                                  ),
                                  if (_focusSuggestion!['task_ids'] != null) ...[
                                    const SizedBox(height: 12),
                                    Column(
                                      children: (_focusSuggestion!['task_ids']
                                              as List<dynamic>)
                                          .map<Widget>((id) {
                                        final parsedId =
                                            int.tryParse(id.toString());
                                        final matchedTask = tasks.firstWhere(
                                          (t) => t.id == parsedId,
                                          orElse: () => Task(
                                              id: -1,
                                              title: '',
                                              priority: 4,
                                              isCompleted: false),
                                        );
                                        if (matchedTask.id == -1 ||
                                            matchedTask.title.isEmpty) {
                                          return const SizedBox.shrink();
                                        }
                                        // Suggested-task pill: monochrome, theme-aware
                                        // fill instead of the old solid purple chip.
                                        return Container(
                                          margin:
                                              const EdgeInsets.only(bottom: 8),
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 14, vertical: 10),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? Colors.white
                                                    .withValues(alpha: 0.08)
                                                : Colors.black
                                                    .withValues(alpha: 0.05),
                                            borderRadius:
                                                BorderRadius.circular(14),
                                            border: Border.all(
                                                color: isDark
                                                    ? Colors.white
                                                        .withValues(alpha: 0.15)
                                                    : Colors.black
                                                        .withValues(alpha: 0.12)),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.auto_awesome_rounded,
                                                color: isDark
                                                    ? Colors.white
                                                        .withValues(alpha: 0.9)
                                                    : Colors.black
                                                        .withValues(alpha: 0.8),
                                                size: 14,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  matchedTask.title,
                                                  style: TextStyle(
                                                    fontSize: 12.sp,
                                                    fontWeight: FontWeight.bold,
                                                    color: isDark
                                                        ? Colors.white.withValues(
                                                            alpha: 0.9)
                                                        : Colors.black.withValues(
                                                            alpha: 0.8),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ],
                              ),
                            )
                          else if (currentUser == null)
                            Container(
                              margin: EdgeInsets.only(bottom: AppSpacing.md),
                              padding: EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : Colors.black.withValues(alpha: 0.03),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.15)
                                        : Colors.black.withValues(alpha: 0.1)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.auto_awesome_rounded,
                                              color: isDark
                                                  ? Colors.white
                                                  : Colors.black,
                                              size: 20.sp),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Daily Focus Suggestion',
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: isDark
                                                  ? Colors.white
                                                  : Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.close,
                                          size: 18,
                                          color: isDark
                                              ? Colors.white70
                                              : Colors.black54,
                                        ),
                                        onPressed: () => setState(() =>
                                            _dismissedFocusSuggestion = true),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Let AI analyze your tasks and suggest the optimal daily focus to keep you productive.',
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      height: 1.4,
                                      color: theme.textTheme.bodyMedium?.color
                                          ?.withValues(alpha: 0.85),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 40,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            isDark ? Colors.white : Colors.black,
                                        foregroundColor:
                                            isDark ? Colors.black : Colors.white,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                      ),
                                      onPressed: () {
                                        PremiumPromoDialog.show(
                                          context: context,
                                          title: 'Daily Focus Suggestion',
                                          content: 'AI Daily Focus Suggestion is a premium feature. Please sign in or register to get focus suggestions.',
                                          icon: Icons.auto_awesome_rounded,
                                        );
                                      },
                                      child: const Text('Suggest Focus',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ]

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
                        final isSuggested = _focusSuggestion != null &&
                            _focusSuggestion!['task_ids'] != null &&
                            (_focusSuggestion!['task_ids'] as List<dynamic>)
                                .map((e) => e.toString())
                                .contains(task.id.toString());
                        return TaskCard(
                          task: task,
                          isSuggested: isSuggested,
                          onToggle: () async {
                            final wasCompleted = task.isCompleted;
                            await ref
                                .read(tasksControllerProvider.notifier)
                                .toggleCompletion(task);
                            if (!wasCompleted && context.mounted) {
                              await ConfettiService.notifyTaskCompleted(
                                  context);
                            }
                            await _updateContinuousStreak();
                          },
                          onDelete: () {
                            ref
                                .read(tasksControllerProvider.notifier)
                                .deleteTask(task.id);
                          },
                          onTap: () => _openTask(context, task: task),
                          onLongPress: () => _breakdownTask(context, task),
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
                        final isSuggested = _focusSuggestion != null &&
                            _focusSuggestion!['task_ids'] != null &&
                            (_focusSuggestion!['task_ids'] as List<dynamic>)
                                .map((e) => e.toString())
                                .contains(task.id.toString());
                        return TaskCard(
                          task: task,
                          isSuggested: isSuggested,
                          onToggle: () async {
                            await ref
                                .read(tasksControllerProvider.notifier)
                                .toggleCompletion(task);
                            await _updateContinuousStreak();
                          },
                          onDelete: () {
                            ref
                                .read(tasksControllerProvider.notifier)
                                .deleteTask(task.id);
                          },
                          onTap: () => _openTask(context, task: task),
                          onLongPress: () => _breakdownTask(context, task),
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
                color: (isDark ? Colors.white : Colors.black)
                    .withValues(alpha: 0.2),
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
