import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../domain/entities/task.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';
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

  Color _priorityColor(int priority) {
    switch (priority) {
      case 1:
        return AppColors.priorityHigh;
      case 2:
        return AppColors.priorityMedium;
      case 3:
        return AppColors.priorityLow;
      default:
        return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accentColor =
        task.priority < 4 ? _priorityColor(task.priority) : AppColors.primary;

    return SwipeActionWrapper(
      isCompleted: task.isCompleted,
      onComplete: onToggle,
      onDelete: onDelete,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xxs + 1,
        ),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: AppRadius.borderXL,
              border: Border.all(
                color: task.isCompleted
                    ? (isDark
                        ? AppColors.darkBorder.withOpacity(0.4)
                        : AppColors.lightBorder.withOpacity(0.5))
                    : (isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder),
                width: 0.5,
              ),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Priority left accent bar
                  if (!task.isCompleted && task.priority < 4)
                    Container(
                      width: 3,
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(AppRadius.xl),
                          bottomLeft: Radius.circular(AppRadius.xl),
                        ),
                      ),
                    ),
                  // Check button
                  Padding(
                    padding: EdgeInsets.only(
                      left: (!task.isCompleted && task.priority < 4) ? 8 : 4,
                      right: 4,
                    ),
                    child: Center(
                      child: IconButton(
                        onPressed: onToggle,
                        splashRadius: 20,
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 36, minHeight: 36),
                        icon: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            task.isCompleted
                                ? Icons.check_circle_rounded
                                : Icons.circle_outlined,
                            key: ValueKey(task.isCompleted),
                            color: task.isCompleted
                                ? AppColors.primary.withOpacity(0.55)
                                : (isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary),
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Task content
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: AppSpacing.sm,
                        bottom: AppSpacing.sm,
                        right: AppSpacing.md,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Text.rich(
                            TextSpan(
                              children: RichTextParser.parse(
                                task.title,
                                TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.1,
                                  decoration: task.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: task.isCompleted
                                      ? (isDark
                                              ? AppColors.darkTextPrimary
                                              : AppColors.lightTextPrimary)
                                          .withOpacity(0.38)
                                      : (isDark
                                          ? AppColors.darkTextPrimary
                                          : AppColors.lightTextPrimary),
                                ),
                              ),
                            ),
                          ),
                          // Description
                          if (task.description != null &&
                              task.description!.isNotEmpty) ...[
                            SizedBox(height: 3.h),
                            Text(
                              task.description!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: task.isCompleted
                                    ? (isDark
                                            ? AppColors.darkTextSecondary
                                            : AppColors.lightTextSecondary)
                                        .withOpacity(0.4)
                                    : (isDark
                                            ? AppColors.darkTextSecondary
                                            : AppColors.lightTextSecondary)
                                        .withOpacity(0.85),
                                height: 1.4,
                              ),
                            ),
                          ],
                          // Metadata chips row
                          if (task.dueDate != null || task.priority < 4) ...[
                            SizedBox(height: AppSpacing.h_xs),
                            Row(
                              children: [
                                if (task.priority < 4) ...[
                                  _PriorityChip(
                                    priority: task.priority,
                                    isCompleted: task.isCompleted,
                                  ),
                                  SizedBox(width: AppSpacing.xxs + 2),
                                ],
                                if (task.dueDate != null)
                                  _DueDateChip(
                                    task: task,
                                    isDark: isDark,
                                  ),
                              ],
                            ),
                          ],
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
}

class _PriorityChip extends StatelessWidget {
  final int priority;
  final bool isCompleted;

  const _PriorityChip({required this.priority, required this.isCompleted});

  @override
  Widget build(BuildContext context) {
    final String label;
    final Color color;
    switch (priority) {
      case 1:
        label = 'High';
        color = AppColors.priorityHigh;
        break;
      case 2:
        label = 'Med';
        color = AppColors.priorityMedium;
        break;
      case 3:
        label = 'Low';
        color = AppColors.priorityLow;
        break;
      default:
        return const SizedBox.shrink();
    }

    final effectiveColor = isCompleted ? color.withOpacity(0.35) : color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: effectiveColor.withOpacity(0.10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: effectiveColor.withOpacity(0.25), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: effectiveColor,
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}

class _DueDateChip extends StatelessWidget {
  final Task task;
  final bool isDark;

  const _DueDateChip({required this.task, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final dateText =
        '${DateFormatter.formatRelativeDay(task.dueDate!)}${task.dueDate!.hour == 0 && task.dueDate!.minute == 0 ? '' : ' · ${DateFormatter.formatTime(task.dueDate!)}'}';

    final color = task.isCompleted
        ? (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)
            .withOpacity(0.4)
        : AppColors.primary.withOpacity(0.80);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.schedule_rounded, size: 11, color: color),
        const SizedBox(width: 3),
        Text(
          dateText,
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}
