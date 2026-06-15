import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../controllers/search_provider.dart';
import '../controllers/filter_provider.dart';
import '../../../tasks/presentation/controllers/tasks_provider.dart';
import '../../../tasks/presentation/widgets/task_list_view.dart';
import '../../../tasks/presentation/screens/task_detail_screen.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/confetti_service.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _searchController.addListener(() {
      ref.read(searchQueryProvider.notifier).set(_searchController.text);
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchResultsAsync = ref.watch(searchResultsProvider);
    final theme = Theme.of(context);
    final query = _searchController.text;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // ── Hero Search Header ──────────────────────────────────────────
          _SearchHeader(
            controller: _searchController,
            focusNode: _focusNode,
            isDark: isDark,
            onBack: () {
              ref.read(searchQueryProvider.notifier).set('');
              ref
                  .read(activeSearchFilterProvider.notifier)
                  .set(SearchFilter.all);
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
          ),

          // ── Results ──────────────────────────────────────────────────
          Expanded(
            child: searchResultsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (tasks) {
                if (query.isEmpty &&
                    ref.watch(activeSearchFilterProvider) == SearchFilter.all) {
                  return _buildInitialState(theme, isDark);
                }
                if (tasks.isEmpty) {
                  return _buildEmptyState(theme, query);
                }
                return Column(
                  children: [
                    // Results count banner
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 10.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Text(
                              '${tasks.length} result${tasks.length == 1 ? '' : 's'}',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              query.isNotEmpty ? 'for "$query"' : '',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.5),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 250.ms)
                        .slideY(begin: -0.3, end: 0),
                    Expanded(
                      child: TaskListView(
                        tasks: tasks,
                        onToggle: (task) async {
                          final wasCompleted = task.isCompleted;
                          await ref
                              .read(tasksControllerProvider.notifier)
                              .toggleCompletion(task);
                          if (!wasCompleted && context.mounted) {
                            await ConfettiService.notifyTaskCompleted(context);
                          }
                        },
                        onDelete: (task) {
                          ref
                              .read(tasksControllerProvider.notifier)
                              .deleteTask(task.id);
                        },
                        onTap: (task) {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (_) => FractionallySizedBox(
                              heightFactor: 0.85,
                              child: TaskDetailScreen(task: task),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialState(ThemeData theme, bool isDark) {
    final suggestions = [
      (Icons.flag_outlined, 'High Priority', SearchFilter.highPriority),
      (Icons.today_outlined, 'Due Today', SearchFilter.today),
      (Icons.date_range_outlined, 'This Week', SearchFilter.thisWeek),
      (Icons.check_circle_outline_rounded, 'Completed', SearchFilter.completed),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: AppSpacing.lg),
          Text(
            'Quick Filters',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              letterSpacing: 0.8,
              fontWeight: FontWeight.w600,
            ),
          ).animate().fadeIn(delay: 100.ms),
          SizedBox(height: AppSpacing.sm),
          ...suggestions.asMap().entries.map((e) {
            final idx = e.key;
            final (icon, label, filter) = e.value;
            return _QuickFilterTile(
              icon: icon,
              label: label,
              filter: filter,
              delay: Duration(milliseconds: 80 * idx),
              onTap: () {
                HapticFeedback.lightImpact();
                ref.read(activeSearchFilterProvider.notifier).set(filter);
              },
            );
          }),
          SizedBox(height: AppSpacing.xl),
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.travel_explore_outlined,
                  size: 64.sp,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                )
                    .animate(
                        onPlay: (c) => c.repeat(reverse: true), delay: 500.ms)
                    .scaleXY(
                      begin: 1.0,
                      end: 1.07,
                      duration: 2000.ms,
                      curve: Curves.easeInOut,
                    ),
                SizedBox(height: AppSpacing.sm),
                Text(
                  'Type to search your tasks',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 400.ms),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, String query) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100.w,
              height: 100.h,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.07),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 48.sp,
                color: AppColors.primary.withValues(alpha: 0.4),
              ),
            )
                .animate()
                .scale(
                    duration: 500.ms,
                    curve: Curves.elasticOut,
                    begin: const Offset(0.5, 0.5))
                .fadeIn(duration: 300.ms),
            SizedBox(height: AppSpacing.lg),
            Text(
              'No Results Found',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3, end: 0),
            SizedBox(height: AppSpacing.xs),
            Text(
              query.isNotEmpty
                  ? 'Nothing matched "$query". Try a different keyword or clear the filters.'
                  : 'No tasks match the selected filter.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                height: 1.5,
              ),
            ).animate().fadeIn(delay: 300.ms),
            SizedBox(height: AppSpacing.xl),
            OutlinedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                _searchController.clear();
                ref
                    .read(activeSearchFilterProvider.notifier)
                    .set(SearchFilter.all);
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Clear & Reset'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: const StadiumBorder(),
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              ),
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.4, end: 0),
          ],
        ),
      ),
    );
  }
}

// ── Search Header ─────────────────────────────────────────────────────────────
class _SearchHeader extends StatelessWidget {
  const _SearchHeader({
    required this.controller,
    required this.focusNode,
    required this.isDark,
    required this.onBack,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isDark;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topPad = MediaQuery.of(context).padding.top;

    return Container(
      padding:
          EdgeInsets.fromLTRB(AppSpacing.sm, topPad + 8.h, AppSpacing.md, 12.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18181B) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                size: 20.sp,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.75)),
            onPressed: onBack,
            splashRadius: 24.r,
          ),
          Expanded(
            child: Container(
              height: 46.h,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.09)
                      : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  SizedBox(width: 12.w),
                  Icon(Icons.search_rounded,
                      color: AppColors.primary.withValues(alpha: 0.75),
                      size: 20.sp),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      autofocus: false,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search tasks, descriptions…',
                        hintStyle: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.4),
                          fontWeight: FontWeight.normal,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: controller.text.isNotEmpty
                        ? GestureDetector(
                            key: const ValueKey('clear'),
                            onTap: () {
                              HapticFeedback.lightImpact();
                              controller.clear();
                            },
                            child: Container(
                              margin: EdgeInsets.only(right: 8.w),
                              padding: EdgeInsets.all(4.r),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.close_rounded,
                                  size: 14.sp,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.65)),
                            ),
                          )
                        : const SizedBox.shrink(key: ValueKey('empty')),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.4, end: 0);
  }
}

// ── Quick Filter Tile ─────────────────────────────────────────────────────────
class _QuickFilterTile extends ConsumerWidget {
  const _QuickFilterTile({
    required this.icon,
    required this.label,
    required this.filter,
    required this.delay,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final SearchFilter filter;
  final Duration delay;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final activeFilter = ref.watch(activeSearchFilterProvider);
    final isActive = activeFilter == filter;

    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14.r),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: isActive
                    ? AppColors.primary.withValues(alpha: 0.4)
                    : theme.colorScheme.onSurface.withValues(alpha: 0.08),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : theme.colorScheme.onSurface.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    icon,
                    size: 18.sp,
                    color: isActive
                        ? AppColors.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive
                          ? AppColors.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18.sp,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: delay, duration: 300.ms)
        .slideX(begin: 0.15, end: 0, delay: delay, duration: 300.ms);
  }
}
