import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../controllers/projects_provider.dart';
import '../widgets/project_card.dart';
import '../widgets/add_project_sheet.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../tasks/presentation/controllers/tasks_provider.dart';
import '../../../tasks/presentation/screens/task_detail_screen.dart';
import '../../../tasks/presentation/widgets/task_list_view.dart';
import '../../../../core/utils/confetti_service.dart';

class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddProjectSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final projectsAsync = ref.watch(projectsStreamProvider);
    final tasksAsync = ref.watch(tasksStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Projects',
          style: theme.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w900,
            color: AppColors.primary,
          ),
        ),
      ),
      body: projectsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (projects) {
          if (projects.isEmpty) {
            return _EmptyProjectsState(onAdd: () => _showAddSheet(context));
          }

          final tasks = tasksAsync.value ?? [];

          return SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Free-tier progress badge
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Text(
                        '${projects.length} / 5 projects',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                      const Spacer(),
                      if (projects.length >= 5)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xxs,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.15),
                            borderRadius: AppRadius.borderCircular,
                            border: Border.all(
                              color: Colors.amber.withOpacity(0.5),
                            ),
                          ),
                          child: Text(
                            'Limit reached',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: Colors.amber[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: projects.length + (projects.length >= 5 ? 1 : 0),
                    padding: EdgeInsets.only(bottom: AppSpacing.xl),
                    itemBuilder: (context, index) {
                      if (index == projects.length) {
                        return const _ProjectLimitCalloutCard();
                      }
                      final project = projects[index];
                      final count = tasks
                          .where((t) => t.projectId == project.id)
                          .length;
                      return ProjectCard(
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
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: projectsAsync.maybeWhen(
        data: (projects) => projects.length >= 5
            ? null
            : FloatingActionButton.extended(
                backgroundColor: AppColors.primary,
                onPressed: () => _showAddSheet(context),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'New Project',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
        orElse: () => null,
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

// ─── Project Limit Callout Card ──────────────────────────────────────────────

class _ProjectLimitCalloutCard extends StatelessWidget {
  const _ProjectLimitCalloutCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.all(AppSpacing.md),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.borderLG,
        side: const BorderSide(color: Colors.amber, width: 1),
      ),
      color: Colors.amber.withOpacity(0.08),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.amber, size: 24),
                SizedBox(width: AppSpacing.sm),
                Text(
                  'Project Capacity Reached',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.amber[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              "To keep your tasks organized, the Free Tier is limited to 5 active projects. "
              "You can manage your current projects, delete ones you no longer need, or upgrade to Pro to unlock unlimited projects.",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.85),
              ),
            ),
          ],
        ),
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
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open_outlined,
              size: 80.sp,
              color: theme.colorScheme.onSurface.withOpacity(0.15),
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              'No Projects Yet',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              'Organize your tasks into projects.\nFree tier: up to 5 projects.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
            SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Create First Project'),
            ),
          ],
        ),
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
                    SizedBox(height: AppSpacing.md),
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
                          color: AppColors.primary,
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
