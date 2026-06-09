import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../domain/entities/project.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';

class ProjectCard extends StatelessWidget {
  final Project project;
  final int taskCount;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const ProjectCard({
    super.key,
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
    final color = _projectColor;

    return Dismissible(
      key: ValueKey('project_${project.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        margin: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.12),
          borderRadius: AppRadius.borderLG,
        ),
        child: const Icon(Icons.delete_outline, color: Colors.red),
      ),
      confirmDismiss: (_) async {
        return await _confirmDelete(context);
      },
      onDismissed: (_) => onDelete(),
      child: Card(
        margin: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.borderLG,
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                // Color tinted icon box
                Container(
                  width: 46.w,
                  height: 46.w,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: AppRadius.borderMD,
                  ),
                  child: Icon(
                    _projectIcon,
                    color: color,
                    size: 22.sp,
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                // Name & task count
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.name,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: AppSpacing.xxs),
                      Text(
                        '$taskCount ${taskCount == 1 ? 'task' : 'tasks'}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                // Color accent strip on the right
                Container(
                  width: 4.w,
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: AppRadius.borderCircular,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          icon: const Icon(
            Icons.warning_amber_rounded,
            color: Colors.redAccent,
            size: 40,
          ),
          title: Text(
            'Delete Project?',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Deleting "${project.name}" will also permanently remove all of its associated tasks. This action cannot be undone.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
            ),
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () {
                Navigator.of(ctx).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () {
                Navigator.of(ctx).pop(true);
              },
              child: const Text('Delete Permanently'),
            ),
          ],
        );
      },
    );
  }
}
