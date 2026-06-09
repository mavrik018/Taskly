import 'package:flutter/material.dart';
import '../../domain/entities/task.dart';
import 'task_card.dart';
import '../../../../core/theme/app_spacing.dart';

class TaskListView extends StatelessWidget {
  final List<Task> tasks;
  final Function(Task) onToggle;
  final Function(Task) onDelete;
  final Function(Task) onTap;

  const TaskListView({
    super.key,
    required this.tasks,
    required this.onToggle,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.only(bottom: AppSpacing.xxl),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return TaskCard(
          task: task,
          onToggle: () => onToggle(task),
          onDelete: () => onDelete(task),
          onTap: () => onTap(task),
        );
      },
    );
  }
}
