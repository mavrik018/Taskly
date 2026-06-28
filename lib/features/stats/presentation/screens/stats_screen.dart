import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../tasks/presentation/controllers/tasks_provider.dart';
import '../../../../core/services/ai_service.dart';
import '../../../../core/theme/app_spacing.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../auth/presentation/controllers/auth_provider.dart';
import '../../../../core/utils/error_mapper.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  int _streakDays = 0;

  @override
  void initState() {
    super.initState();
    _loadStreakDays();
  }

  Future<void> _loadStreakDays() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _streakDays = prefs.getInt('streak_continuous_count') ?? 0;
        });
      }
    } catch (e) {
      debugPrint("Error loading streak: $e");
    }
  }

  static const List<String> _monthAbbrevs = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  Color _heatmapCellColor(int count, bool isDark) {
    if (count == 0) {
      return isDark
          ? Colors.white.withOpacity(0.06)
          : Colors.black.withOpacity(0.05);
    } else if (count == 1) {
      return isDark
          ? Colors.white.withOpacity(0.25)
          : Colors.black.withOpacity(0.2);
    } else if (count == 2) {
      return isDark
          ? Colors.white.withOpacity(0.55)
          : Colors.black.withOpacity(0.5);
    }
    return isDark
        ? Colors.white.withOpacity(0.9)
        : Colors.black.withOpacity(0.85);
  }

  Widget _buildOverviewCard(
      String label, String value, Color valueColor, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 8.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161618) : const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.04)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 11.sp,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? Colors.white.withOpacity(0.4)
                  : Colors.black.withOpacity(0.45),
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityRow(
      String label, int count, int total, Color color, bool isDark) {
    final double percentage = total > 0 ? count / total : 0.0;
    final textColor = isDark ? Colors.white : Colors.black;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8.w,
                    height: 8.h,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              Text(
                count.toString(),
                style: GoogleFonts.poppins(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: textColor.withOpacity(0.5),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(10.r),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 8.h,
              backgroundColor: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.07),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tasksAsync = ref.watch(tasksStreamProvider);
    final currentUser = ref.watch(authProvider);

    final scaffoldBg = isDark ? Colors.black : Colors.white;
    final cardBg = isDark ? const Color(0xFF161618) : const Color(0xFFF5F5F7);
    final cardBorder = isDark
        ? Colors.white.withOpacity(0.04)
        : Colors.black.withOpacity(0.05);
    final primaryText = isDark ? Colors.white : Colors.black;
    final mutedText =
        isDark ? Colors.white.withOpacity(0.4) : Colors.black.withOpacity(0.45);
    final accentMono = isDark ? Colors.white : Colors.black;
    final onAccentMono = isDark ? Colors.black : Colors.white;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Stats',
          style: GoogleFonts.poppins(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: primaryText,
          ),
        ),
      ),
      body: SafeArea(
        child: tasksAsync.when(
          data: (tasks) {
            final completedTasks = tasks.where((t) => t.isCompleted).toList();

            // Calculations for summary stats
            final now = DateTime.now();

            // Completed this month — using completedAt for accuracy
            final completedThisMonthCount = completedTasks.where((t) {
              final ca = t.completedAt;
              return ca != null && ca.month == now.month && ca.year == now.year;
            }).length;
            // Fallback: for tasks completed before this column existed (completedAt == null),
            // they won't count in month — but new completions will be accurate.

            // On-time rate: (tasks with dueDate - overdue-not-completed) / tasks with dueDate
            final tasksWithDueDate =
                tasks.where((t) => t.dueDate != null).toList();
            final overdueNotCompleted = tasksWithDueDate
                .where((t) => !t.isCompleted && t.dueDate!.isBefore(now))
                .length;
            final double simpleOnTimeRate = tasksWithDueDate.isEmpty
                ? 1.0
                : (tasksWithDueDate.length - overdueNotCompleted) /
                    tasksWithDueDate.length;

            // ── Heatmap data ────────────────────────────────────────────
            final Map<String, int> completionCounts = {};
            for (var task in completedTasks) {
              final ca = task.completedAt;
              if (ca != null) {
                final dateKey =
                    "${ca.year}-${ca.month.toString().padLeft(2, '0')}-${ca.day.toString().padLeft(2, '0')}";
                completionCounts[dateKey] =
                    (completionCounts[dateKey] ?? 0) + 1;
              }
            }

            const int weekCount = 16;
            // Normalize to midnight so date-key comparisons line up exactly
            // and don't drift due to leftover time-of-day components.
            final today = DateTime(now.year, now.month, now.day);
            // Monday-start week (DateTime.weekday: Mon=1 ... Sun=7), matching
            // the M T W T F S S row order rendered below.
            final daysSinceMonday = today.weekday - 1;
            final currentWeekStart =
                today.subtract(Duration(days: daysSinceMonday));
            // weekCount - 1 because currentWeekStart IS one of the weeks —
            // previously this subtracted 15*7 while generating 16 columns,
            // an off-by-one-week mismatch.
            final startDate =
                currentWeekStart.subtract(Duration(days: (weekCount - 1) * 7));

            // Priority breakdown: completed tasks by priority vs total tasks per priority
            final highTasks = tasks.where((t) => t.priority == 1).length;
            final mediumTasks = tasks.where((t) => t.priority == 2).length;
            final lowTasks = tasks.where((t) => t.priority == 3).length;
            final completedHigh =
                completedTasks.where((t) => t.priority == 1).length;
            final completedMedium =
                completedTasks.where((t) => t.priority == 2).length;
            final completedLow =
                completedTasks.where((t) => t.priority == 3).length;

            return RefreshIndicator(
              onRefresh: () async {
                await _loadStreakDays();
              },
              child: ListView(
                padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                physics: const BouncingScrollPhysics(),
                children: [
                  // Overview Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                          child: _buildOverviewCard(
                              'This\nMonth',
                              completedThisMonthCount.toString(),
                              primaryText,
                              isDark)),
                      SizedBox(width: 8.w),
                      Expanded(
                          child: _buildOverviewCard('Day\nStreak',
                              '$_streakDays', const Color(0xFF2EC4B6), isDark)),
                      SizedBox(width: 8.w),
                      Expanded(
                          child: _buildOverviewCard(
                              'On-time\nRate',
                              '${(simpleOnTimeRate * 100).toStringAsFixed(0)}%',
                              primaryText,
                              isDark)),
                    ],
                  ).animate().fadeIn(duration: 300.ms),

                  SizedBox(height: AppSpacing.lg),

                  // ACTIVITY Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ACTIVITY',
                        style: GoogleFonts.poppins(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: mutedText,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        '${completedTasks.length} tasks done',
                        style: GoogleFonts.poppins(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.white.withOpacity(0.5)
                              : Colors.black.withOpacity(0.55),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.sm),

                  // ── Heatmap Card (fixed) ──────────────────────────────
                  Container(
                    padding: EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          reverse: true, // open scrolled to most recent week
                          child: Row(
                            // mainAxisSize.min + per-column padding replaces
                            // spaceBetween, which doesn't behave predictably
                            // inside an unbounded horizontal scroll child.
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: List.generate(weekCount, (col) {
                              final weekFirstDay =
                                  startDate.add(Duration(days: col * 7));
                              // Show a month label only on the first week
                              // that falls within a new month.
                              final isFirstWeekOfMonth = weekFirstDay.day <= 7;

                              return Padding(
                                padding: EdgeInsets.only(right: 6.w),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      height: 14.h,
                                      child: isFirstWeekOfMonth
                                          ? Text(
                                              _monthAbbrevs[
                                                  weekFirstDay.month - 1],
                                              style: GoogleFonts.poppins(
                                                fontSize: 9.sp,
                                                fontWeight: FontWeight.w500,
                                                color: mutedText,
                                              ),
                                            )
                                          : null,
                                    ),
                                    ...List.generate(7, (row) {
                                      final date = startDate
                                          .add(Duration(days: col * 7 + row));
                                      final isFuture = date.isAfter(today);
                                      final dateKey =
                                          "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
                                      final count = isFuture
                                          ? 0
                                          : (completionCounts[dateKey] ?? 0);

                                      return Container(
                                        width: 14.w,
                                        height: 14.h,
                                        margin: EdgeInsets.only(bottom: 4.h),
                                        decoration: BoxDecoration(
                                          color: isFuture
                                              ? Colors.transparent
                                              : _heatmapCellColor(
                                                  count, isDark),
                                          borderRadius:
                                              BorderRadius.circular(3.r),
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              );
                            }),
                          ),
                        ),
                        SizedBox(height: 12.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'Less',
                              style: GoogleFonts.poppins(
                                fontSize: 10.sp,
                                color: mutedText,
                              ),
                            ),
                            SizedBox(width: 4.w),
                            ...List.generate(4, (i) {
                              return Container(
                                width: 10.w,
                                height: 10.h,
                                margin: EdgeInsets.symmetric(horizontal: 2.w),
                                decoration: BoxDecoration(
                                  color: _heatmapCellColor(i, isDark),
                                  borderRadius: BorderRadius.circular(2.r),
                                ),
                              );
                            }),
                            SizedBox(width: 4.w),
                            Text(
                              'More',
                              style: GoogleFonts.poppins(
                                fontSize: 10.sp,
                                color: mutedText,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 350.ms),

                  SizedBox(height: AppSpacing.lg),

                  // BY PRIORITY Header
                  Text(
                    'BY PRIORITY',
                    style: GoogleFonts.poppins(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: mutedText,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: AppSpacing.sm),

                  // Priority progress bars card
                  Container(
                    padding: EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Column(
                      children: [
                        _buildPriorityRow(
                            'High',
                            completedHigh,
                            highTasks > 0 ? highTasks : 1,
                            const Color(0xFFF05454),
                            isDark),
                        _buildPriorityRow(
                            'Medium',
                            completedMedium,
                            mediumTasks > 0 ? mediumTasks : 1,
                            const Color(0xFFFFB800),
                            isDark),
                        _buildPriorityRow(
                            'Low',
                            completedLow,
                            lowTasks > 0 ? lowTasks : 1,
                            const Color(0xFF2EC4B6),
                            isDark),
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) =>
              Center(child: Text('Error loading stats: $err')),
        ),
      ),
    );
  }
}
