import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../tasks/presentation/controllers/tasks_provider.dart';
import '../../../../core/services/ai_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/error_mapper.dart';

class WeeklyReviewScreen extends ConsumerStatefulWidget {
  const WeeklyReviewScreen({super.key});

  @override
  ConsumerState<WeeklyReviewScreen> createState() => _WeeklyReviewScreenState();
}

class _WeeklyReviewScreenState extends ConsumerState<WeeklyReviewScreen> {
  String _summary = '';
  bool _loading = false;
  String? _error;
  DateTime? _generatedTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCachedSummary();
    });
  }

  Future<void> _loadCachedSummary() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('last_weekly_review');
      final timeStr = prefs.getString('last_weekly_review_time');

      if (cached != null && timeStr != null) {
        final generatedTime = DateTime.parse(timeStr);
        final now = DateTime.now();

        if (AIService.isSameCalendarWeek(generatedTime, now)) {
          setState(() {
            _summary = cached;
            _generatedTime = generatedTime;
            _loading = false;
          });
          return;
        }
      }
      setState(() {
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Failed to load cached summary.';
      });
    }
  }

  Future<void> _generateWeeklyReview() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final tasks = ref.read(tasksStreamProvider).value ?? [];
      final now = DateTime.now();
      final oneWeekAgo = now.subtract(const Duration(days: 7));

      final completedTasks = tasks
          .where((t) {
            if (!t.isCompleted) return false;
            final compareDate = t.completedAt ?? t.dueDate;
            return compareDate != null && compareDate.isAfter(oneWeekAgo);
          })
          .map((t) => {
                'title': t.title,
                'priority': t.priority,
              })
          .toList();

      final overdueTasks = tasks
          .where((t) =>
              !t.isCompleted && t.dueDate != null && t.dueDate!.isBefore(now))
          .map((t) => {
                'title': t.title,
                'priority': t.priority,
              })
          .toList();

      final summary =
          await AIService.getWeeklyReviewSummary(completedTasks, overdueTasks);

      if (mounted) {
        setState(() {
          _summary = summary;
          _generatedTime = now;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        final cleanMsg = ErrorMapper.getAIErrorMessage(e);
        setState(() {
          _error = cleanMsg;
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = isDark ? Colors.white : Colors.black;
    final onAccent = isDark ? Colors.black : Colors.white;
    final cardColor = isDark
        ? Colors.white.withOpacity(0.06)
        : Colors.black.withOpacity(0.04);

    return Scaffold(
      body: Stack(
        children: [
          // Background soft monochrome glow
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withOpacity(0.05),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        onPressed: () => context.pop(),
                      ),
                      Text(
                        'Weekly Wrap-up',
                        style: GoogleFonts.poppins(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(
                          width: 48), // Spacer to balance back button
                    ],
                  ),
                  SizedBox(height: AppSpacing.lg),

                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          // Trophy icon
                          Container(
                            padding: EdgeInsets.all(24.r),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: cardColor,
                            ),
                            child: Icon(
                              Icons.emoji_events_rounded,
                              size: 64.sp,
                              color: Colors.amber,
                            ),
                          ).animate().scale(
                              duration: 400.ms, curve: Curves.easeOutBack),
                          SizedBox(height: AppSpacing.md),

                          Text(
                            "You're making great progress!",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: AppSpacing.lg),

                          // Summary box — flat card, matches app-wide surface style
                          Container(
                            padding: EdgeInsets.all(AppSpacing.lg),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(20.r),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.black.withOpacity(0.08),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.auto_awesome_rounded,
                                        color: accent, size: 20.sp),
                                    SizedBox(width: 8.w),
                                    Text(
                                      'AI Weekly Summary',
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: AppSpacing.md),
                                if (_loading)
                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 24.0),
                                      child: Column(
                                        children: [
                                          CircularProgressIndicator(
                                              color: accent),
                                          SizedBox(height: 12.h),
                                          Text(
                                            'Analyzing your week...',
                                            style: TextStyle(
                                              fontSize: 13.sp,
                                              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                else if (_error != null)
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        _error!,
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontSize: 14.sp,
                                          height: 1.4,
                                        ),
                                      ),
                                      if (!_error!.contains('already generated')) ...[
                                        SizedBox(height: 12.h),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: accent,
                                            foregroundColor: onAccent,
                                            elevation: 0,
                                            padding: EdgeInsets.symmetric(vertical: 12.h),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12.r),
                                            ),
                                          ),
                                          onPressed: _generateWeeklyReview,
                                          child: const Text('Retry'),
                                        ),
                                      ],
                                    ],
                                  )
                                else if (_summary.isEmpty)
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        'Ready for your weekly wrap-up?',
                                        style: TextStyle(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.bold,
                                          color: theme.textTheme.bodyLarge?.color,
                                        ),
                                      ),
                                      SizedBox(height: 8.h),
                                      Text(
                                        'Generate a personalized AI summary of your productivity, achievements, and focus areas over the last 7 days.',
                                        style: TextStyle(
                                          fontSize: 13.sp,
                                          color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                                          height: 1.4,
                                        ),
                                      ),
                                      SizedBox(height: 16.h),
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                                        decoration: BoxDecoration(
                                          color: accent.withOpacity(0.05),
                                          borderRadius: BorderRadius.circular(10.r),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.calendar_today_rounded, size: 14.sp, color: accent.withOpacity(0.7)),
                                            SizedBox(width: 8.w),
                                            Text(
                                              'Period: ${DateFormat.yMMMd().format(DateTime.now().subtract(const Duration(days: 7)))} – ${DateFormat.yMMMd().format(DateTime.now())}',
                                              style: TextStyle(
                                                fontSize: 12.sp,
                                                fontWeight: FontWeight.w500,
                                                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(height: 20.h),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: accent,
                                          foregroundColor: onAccent,
                                          elevation: 0,
                                          padding: EdgeInsets.symmetric(vertical: 14.h),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(14.r),
                                          ),
                                        ),
                                        onPressed: _generateWeeklyReview,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.auto_awesome_rounded, size: 18.sp),
                                            SizedBox(width: 8.w),
                                            Text(
                                              'Generate Summary',
                                              style: TextStyle(
                                                fontSize: 15.sp,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (_generatedTime != null)
                                        Container(
                                          margin: EdgeInsets.only(bottom: 12.h),
                                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                                          decoration: BoxDecoration(
                                            color: accent.withOpacity(0.05),
                                            borderRadius: BorderRadius.circular(10.r),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.calendar_today_rounded, size: 14.sp, color: accent.withOpacity(0.7)),
                                              SizedBox(width: 8.w),
                                              Text(
                                                'Period: ${DateFormat.yMMMd().format(_generatedTime!.subtract(const Duration(days: 7)))} – ${DateFormat.yMMMd().format(_generatedTime!)}',
                                                style: TextStyle(
                                                  fontSize: 12.sp,
                                                  fontWeight: FontWeight.w500,
                                                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      Text(
                                        _summary,
                                        style: TextStyle(
                                          fontSize: 15.sp,
                                          height: 1.45,
                                          color: theme.textTheme.bodyLarge?.color
                                              ?.withOpacity(0.9),
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ).animate().fadeIn(duration: 400.ms, delay: 200.ms),

                          SizedBox(height: AppSpacing.lg),

                          // Weekly Tip — flat card, no gradient
                          Container(
                            padding: EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.lightbulb_outline_rounded,
                                    color: accent.withOpacity(0.85)),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Text(
                                    "Tip: Schedule focused blocks on your calendar for the coming week to tackle high-priority items.",
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w500,
                                      color: theme.textTheme.bodyMedium?.color
                                          ?.withOpacity(0.85),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(duration: 450.ms, delay: 350.ms),
                        ],
                      ),
                    ),
                  ),

                  // Action Button — solid monochrome, no gradient
                  Container(
                    height: 56.h,
                    margin: EdgeInsets.only(top: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(20.r),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withOpacity(0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                      ),
                      onPressed: () => context.pop(),
                      child: Text(
                        'Start New Week',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: onAccent,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
