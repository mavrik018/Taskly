import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taskflow/features/projects/domain/entities/project.dart';
import '../controllers/projects_provider.dart';
import '../widgets/add_project_sheet.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../tasks/presentation/controllers/tasks_provider.dart';
import '../../../tasks/presentation/screens/task_detail_screen.dart';
import '../../../tasks/presentation/widgets/task_list_view.dart';
import '../../../../core/utils/confetti_service.dart';

class ProjectsScreen extends ConsumerStatefulWidget {
  const ProjectsScreen({super.key});

  @override
  ConsumerState<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends ConsumerState<ProjectsScreen> {
  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddProjectSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final projectsAsync = ref.watch(projectsStreamProvider);
    final tasksAsync = ref.watch(tasksStreamProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: projectsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (projects) {
          final tasks = tasksAsync.value ?? [];
          final activeTasksCount = tasks.where((t) => !t.isCompleted).length;

          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
          final endOfWeek = startOfWeek.add(const Duration(days: 7));
          final tasksThisWeekCount = tasks.where((t) {
            if (t.isCompleted || t.dueDate == null) return false;
            return t.dueDate!.isAfter(
                    startOfWeek.subtract(const Duration(microseconds: 1))) &&
                t.dueDate!.isBefore(endOfWeek);
          }).length;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              /*
              // App Bar
              SliverAppBar(
                floating: true,
                snap: true,
                backgroundColor: theme.scaffoldBackgroundColor,
                elevation: 0,
                scrolledUnderElevation: 0,
                centerTitle: true,
                title: Text(
                  'Projects',
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
              */

              // Status Overview
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg, vertical: AppSpacing.h_md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'STATUS OVERVIEW',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.textTheme.bodySmall?.color
                              ?.withOpacity(0.5),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      AppSpacing.heightSM,
                      Row(
                        // Aligns the bottom of the large number with the bottom of the text/badge column
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '$activeTasksCount',
                            style: theme.textTheme.displayLarge?.copyWith(
                              fontWeight: FontWeight
                                  .w600, // W600 gives a cleaner, more modern bold look
                              fontSize: 48
                                  .sp, // Bumped up from 36 to contrast nicely with the labels
                              height:
                                  1.0, // Removes extra vertical padding inherent to large fonts
                              letterSpacing: -1.0,
                            ),
                          ),
                          AppSpacing.widthSM,
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Active',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  height: 1.2,
                                ),
                              ),
                              AppSpacing.heightXXS,
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8.w,
                                    vertical: 4.h), // Better badge padding
                                decoration: BoxDecoration(
                                  // Swapped to a subtle green or explicit adaptive color for a status vibe
                                  color: isDark
                                      ? Colors.green.withOpacity(0.15)
                                      : Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(
                                      6.r), // A softer look than a full capsule
                                ),
                                child: Text(
                                  '+$tasksThisWeekCount this week',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: isDark
                                        ? Colors.greenAccent
                                        : Colors.green[800],
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11.sp,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Projects Grid
              if (projects.isEmpty)
                SliverToBoxAdapter(
                  child:
                      _EmptyProjectsState(onAdd: () => _showAddSheet(context)),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg, vertical: AppSpacing.h_lg),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16.w,
                      mainAxisSpacing: 16.h,
                      childAspectRatio: 1.1,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index == projects.length) {
                          if (projects.length >= 5) {
                            return const SizedBox.shrink();
                          }
                          return _NewProjectCard(
                              onTap: () => _showAddSheet(context));
                        }

                        final project = projects[index];
                        final count = tasks
                            .where((t) => t.projectId == project.id)
                            .length;

                        return _ProjectCard(
                          project: project,
                          taskCount: count,
                          onTap: () => _showProjectTasks(
                            context,
                            ref,
                            project.id,
                            project.name,
                          ),
                          onDelete: () {
                            ref
                                .read(projectsControllerProvider.notifier)
                                .deleteProject(project.id);
                          },
                        );
                      },
                      childCount:
                          projects.length + (projects.length < 5 ? 1 : 0),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _showProjectTasks(
    BuildContext context,
    WidgetRef ref,
    int projectId,
    String projectName,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProjectTasksSheet(
        projectId: projectId,
        projectName: projectName,
      ),
    );
  }
}

// ─── Project Card ─────────────────────────────────────────────────────────────

class _ProjectCard extends StatelessWidget {
  final Project project;
  final int taskCount;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ProjectCard({
    required this.project,
    required this.taskCount,
    required this.onTap,
    required this.onDelete,
  });

  Color get _projectColor {
    try {
      final hex = project.colorHex.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF6366F1);
    }
  }

  IconData get _projectIcon {
    return _iconMap[project.iconName] ?? Icons.folder_outlined;
  }

  static const Map<String, IconData> _iconMap = {
    'work': Icons.work_outline,
    'personal': Icons.person_outline,
    'shopping': Icons.shopping_bag_outlined,
    'health': Icons.favorite_border,
    'finance': Icons.account_balance_outlined,
    'travel': Icons.flight_outlined,
    'education': Icons.school_outlined,
    'fitness': Icons.fitness_center_outlined,
    'home': Icons.home_outlined,
    'creative': Icons.palette_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = _projectColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: AppRadius.borderXL,
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1.0.w,
          ),
        ),
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              _projectIcon,
              color: color,
              size: 28.sp,
            ),
            AppSpacing.heightXS,
            Text(
              project.name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              children: [
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: AppRadius.borderLG,
                  ),
                  child: Text(
                    '$taskCount tasks',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () => onDelete(),
                  child: Icon(Icons.delete,
                      size: 20.sp, color: Colors.red.shade600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── New Project Card ─────────────────────────────────────────────────────────

class _NewProjectCard extends StatelessWidget {
  final VoidCallback onTap;

  const _NewProjectCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: AppRadius.borderXL,
          border: Border.all(
            color: isDark ? Colors.white24 : Colors.black12,
            width: 1.5.w,
            style: BorderStyle.solid,
          ),
        ),
        padding: EdgeInsets.all(16.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_outline,
              color: isDark ? Colors.white24 : Colors.black26,
              size: 40.sp,
            ),
            AppSpacing.heightSM,
            Text(
              'New Project',
              style: theme.textTheme.labelLarge?.copyWith(
                color: isDark ? Colors.white54 : Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Free Tier Limit Banner ───────────────────────────────────────────────────

class _FreeTierLimitBanner extends StatelessWidget {
  final int projectsLength;

  const _FreeTierLimitBanner({required this.projectsLength});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: AppRadius.borderLG,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1.0.w,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.layers_outlined,
            color: isDark ? Colors.white54 : Colors.black54,
          ),
          AppSpacing.widthSM,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Free Tier Limit',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  '$projectsLength / 5 projects',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: isDark ? Colors.white : Colors.black,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              'Upgrade',
              style: TextStyle(
                color: isDark ? Colors.black : Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyProjectsState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyProjectsState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 48.h),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open_outlined,
            size: 80.sp,
            color: theme.textTheme.bodySmall?.color?.withOpacity(0.15),
          ),
          AppSpacing.heightMD,
          Text(
            'No Projects Yet',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          AppSpacing.heightXS,
          Text(
            'Organize your tasks into projects.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
          AppSpacing.heightXL,
          GestureDetector(
            onTap: onAdd,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: isDark ? Colors.white : Colors.black,
                borderRadius: BorderRadius.circular(24.r),
              ),
              child: Text(
                'Create First Project',
                style: TextStyle(
                  color: isDark ? Colors.black : Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Project Tasks Bottom Sheet ───────────────────────────────────────────────

class _ProjectTasksSheet extends ConsumerWidget {
  final int projectId;
  final String projectName;

  const _ProjectTasksSheet({
    required this.projectId,
    required this.projectName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tasksAsync = ref.watch(projectTasksStreamProvider(projectId));

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppRadius.xxl),
            ),
          ),
          child: Column(
            children: [
              // Handle + header
              Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: 40.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: theme.dividerColor,
                          borderRadius: AppRadius.borderCircular,
                        ),
                      ),
                    ),
                    AppSpacing.heightMD,
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            projectName,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          color: isDark ? Colors.white : Colors.black,
                          onPressed: () {
                            Navigator.pop(context);
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              builder: (_) => FractionallySizedBox(
                                heightFactor: 0.85,
                                child: TaskDetailScreen(
                                  task: null,
                                  initialProjectId: projectId,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Task list
              Expanded(
                child: tasksAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (tasks) {
                    if (tasks.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: EdgeInsets.all(AppSpacing.lg),
                          child: Text(
                            'No tasks in this project yet.\nTap + to add one.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          ),
                        ),
                      );
                    }
                    return TaskListView(
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
                        Navigator.pop(context);
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => FractionallySizedBox(
                            heightFactor: 0.85,
                            child: TaskDetailScreen(task: task),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
