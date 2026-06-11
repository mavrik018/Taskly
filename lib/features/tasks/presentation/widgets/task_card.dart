import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../domain/entities/task.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/rich_text_parser.dart';
import '../../../../core/utils/date_formatter.dart';
import 'swipe_action_wrapper.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const TaskCard({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Priority accent color
    final Color priorityColor = _getPriorityColor(task.priority);
    final bool hasPriority = task.priority < 4;

    return SwipeActionWrapper(
      isCompleted: task.isCompleted,
      onComplete: onToggle,
      onDelete: onDelete,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: task.isCompleted
                  ? (isDark
                      ? AppColors.darkSurface.withOpacity(0.3)
                      : AppColors.lightSurface.withOpacity(0.4))
                  : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 1.0,
              ),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Priority accent stripe (left side)
                  if (hasPriority && !task.isCompleted)
                    Container(
                      width: 4,
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: priorityColor,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(4),
                          bottomRight: Radius.circular(4),
                        ),
                      ),
                    ),

                  // Main content
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.md,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Task content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Priority Label
                                if (hasPriority && !task.isCompleted) ...[
                                  Text(
                                    _getPriorityLabel(task.priority),
                                    style:
                                        theme.textTheme.labelMedium?.copyWith(
                                      color: priorityColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                  SizedBox(height: 4.sp),
                                ],

                                // Title
                                Text(
                                  task.title,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    decoration: task.isCompleted
                                        ? TextDecoration.lineThrough
                                        : null,
                                    color: task.isCompleted
                                        ? theme.textTheme.bodyLarge?.color
                                            ?.withOpacity(0.3)
                                        : theme.textTheme.bodyLarge?.color,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16.sp,
                                  ),
                                ),

                                // Time / Due Date
                                if (task.dueDate != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    '${DateFormatter.formatRelativeDay(task.dueDate!)}, ${DateFormatter.formatTime(task.dueDate!)}${task.dueDate!.hour == 0 && task.dueDate!.minute == 0 ? ' (Anytime)' : ''}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.textTheme.bodySmall?.color
                                          ?.withValues(alpha: 0.4),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // Checkbox button
                          _CheckboxButton(
                            isCompleted: task.isCompleted,
                            onToggle: onToggle,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 1:
        return AppColors.priorityHigh;
      case 2:
        return AppColors.priorityMedium;
      case 3:
        return AppColors.priorityLow;
      default:
        return AppColors.priorityNone;
    }
  }

  String _getPriorityLabel(int priority) {
    switch (priority) {
      case 1:
        return 'High Priority';
      case 2:
        return 'Medium Priority';
      case 3:
        return 'Low Priority';
      default:
        return '';
    }
  }
}

class _CheckboxButton extends StatelessWidget {
  final bool isCompleted;
  final VoidCallback onToggle;

  const _CheckboxButton({
    required this.isCompleted,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onToggle,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isCompleted
                ? (isDark ? Colors.white24 : Colors.black12)
                : (isDark ? Colors.white38 : Colors.black26),
            width: 1.5,
          ),
          color: isCompleted
              ? (isDark ? Colors.white10 : Colors.black.withOpacity(0.05))
              : Colors.transparent,
        ),
        child: isCompleted
            ? Icon(
                Icons.check_rounded,
                size: 16,
                color: isDark ? Colors.white70 : Colors.black87,
              )
            : null,
      ),
    );
  }
}
