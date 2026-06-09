import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taskflow/core/utils/notification_manager.dart';
import '../../domain/entities/task.dart';
import '../controllers/tasks_provider.dart';
import '../../../projects/presentation/controllers/projects_provider.dart';
import '../../../projects/domain/entities/project.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/debounce.dart';
import '../../../../core/utils/rich_text_parser.dart';
import '../../../../core/utils/semantics_service.dart';

class TaskDetailScreen extends ConsumerStatefulWidget {
  final Task? task; // null if creating a new task
  final int?
      initialProjectId; // pre-assign project when creating from project sheet

  const TaskDetailScreen({
    super.key,
    this.task,
    this.initialProjectId,
  });

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  late RichTextEditingController _titleController;
  late TextEditingController _descriptionController;
  late int _priority;
  DateTime? _dueDate;
  int? _projectId;

  int? _editingTaskId; // Tracks the ID of the task being edited
  late Debounce _debounce;

  @override
  void initState() {
    super.initState();
    _editingTaskId = widget.task?.id;
    _priority = widget.task?.priority ?? 4; // Default to Neutral (4)
    _dueDate = widget.task?.dueDate;
    _projectId = widget.task?.projectId ?? widget.initialProjectId;

    _debounce = Debounce(delay: const Duration(milliseconds: 600));

    // Custom controller for styling markdown inline
    _titleController = RichTextEditingController(
      text: widget.task?.title ?? '',
      baseStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    );

    _descriptionController = TextEditingController(
      text: widget.task?.description ?? '',
    );

    // Set up listeners for auto-save
    _titleController.addListener(_saveTaskDebounced);
    _descriptionController.addListener(_saveTaskDebounced);
  }

  @override
  void dispose() {
    _titleController.removeListener(_saveTaskDebounced);
    _descriptionController.removeListener(_saveTaskDebounced);
    _titleController.dispose();
    _descriptionController.dispose();
    _debounce.dispose();
    super.dispose();
  }

  // Debounced auto-save
  void _saveTaskDebounced() {
    _debounce.run(() {
      _saveTask(isDismissing: false);
    });
  }

  // Actual save method
  Future<void> _saveTask({required bool isDismissing}) async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final description = _descriptionController.text.trim();
    final controller = ref.read(tasksControllerProvider.notifier);

    if (_editingTaskId == null) {
      // First save (Create Task)
      final newId = await controller.addTask(
        title: title,
        description: description.isEmpty ? null : description,
        dueDate: _dueDate,
        priority: _priority,
        projectId: _projectId,
      );
      if (newId != null) {
        setState(() {
          _editingTaskId = newId;
        });
        AppSemanticsService.announce('Task created');
      }
    } else {
      // Subsequent save (Update Task)
      await controller.updateTaskDetails(
        Task(
          id: _editingTaskId!,
          title: title,
          description: description.isEmpty ? null : description,
          dueDate: _dueDate,
          priority: _priority,
          projectId: _projectId,
          isCompleted: widget.task?.isCompleted ?? false,
        ),
      );
      if (isDismissing) {
        AppSemanticsService.announce('Task details updated');
      }
    }
  }

  void _toggleFormat(String symbol) {
    HapticFeedback.lightImpact();
    final text = _titleController.text;
    final selection = _titleController.selection;
    final start = selection.start;
    final end = selection.end;

    if (start < 0 || end < 0) {
      final cursor = start >= 0 ? start : text.length;
      final newText =
          '${text.substring(0, cursor)}$symbol$symbol${text.substring(cursor)}';
      _titleController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: cursor + symbol.length),
      );
    } else {
      // Text selected, wrap the text in formatting tags
      final selectedText = text.substring(start, end);
      final newText =
          '${text.substring(0, start)}$symbol$selectedText$symbol${text.substring(end)}';
      _titleController.value = TextEditingValue(
        text: newText,
        selection: TextSelection(
          baseOffset: start,
          extentOffset: end + symbol.length * 2,
        ),
      );
    }
    _saveTaskDebounced();
  }

  void _clearFormatting() {
    HapticFeedback.lightImpact();
    final text = _titleController.text;
    final cleanText = text
        .replaceAll('**', '')
        .replaceAll('*', '')
        .replaceAll('_', '')
        .replaceAll('~', '');
    _titleController.value = TextEditingValue(
      text: cleanText,
      selection: TextSelection.collapsed(offset: cleanText.length),
    );
    _saveTaskDebounced();
  }

  Future<void> _selectDueDate(BuildContext context) async {
    HapticFeedback.lightImpact();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    DateTime initialDate = _dueDate ?? now;
    if (initialDate.isBefore(today)) {
      initialDate = today;
    }

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365 * 5)),
    );

    if (pickedDate != null) {
      if (!context.mounted) return;

      // Request notifications permission since a due date is being set
      await NotificationManager.requestPermissions(context);

      if (!context.mounted) return;
      
      final initialTime = _dueDate != null 
          ? TimeOfDay.fromDateTime(_dueDate!) 
          : TimeOfDay.fromDateTime(now);

      final pickedTime = await showTimePicker(
        context: context,
        initialTime: initialTime,
      );

      DateTime finalDateTime;
      if (pickedTime != null) {
        finalDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      } else {
        // Default to a future time if no time is picked
        final compareDate = DateTime(pickedDate.year, pickedDate.month, pickedDate.day);
        if (compareDate.isAtSameMomentAs(today)) {
          // If today, set to 1 hour from now
          finalDateTime = now.add(const Duration(hours: 1));
        } else {
          // If future, default to 9:00 AM
          finalDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            9,
            0,
          );
        }
      }

      setState(() {
        _dueDate = finalDateTime;
      });
      _saveTask(isDismissing: false);
    }
  }

  void _setQuickDate(DateTime? date) async {
    HapticFeedback.lightImpact();
    if (date != null) {
      if (context.mounted) {
        await NotificationManager.requestPermissions(context);
      }
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final compareDate = DateTime(date.year, date.month, date.day);
      
      if (compareDate.isAtSameMomentAs(today)) {
        // If today, set to 1 hour from now so it is in the future
        date = now.add(const Duration(hours: 1));
      } else if (compareDate.difference(today).inDays == 1) {
        // If tomorrow, default to tomorrow at 9:00 AM
        date = DateTime(date.year, date.month, date.day, 9, 0);
      }
    }
    setState(() {
      _dueDate = date;
    });
    _saveTask(isDismissing: false);
  }

  Future<void> _selectProject(
      BuildContext context, List<Project> projects) async {
    HapticFeedback.lightImpact();
    final selected = await showModalBottomSheet<Project?>(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Text(
                  'Select Project',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(),
              if (projects.isEmpty)
                Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    'No projects available. Go to Projects tab to create one.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ...projects.map((proj) {
                Color projColor;
                try {
                  projColor = Color(int.parse('FF${proj.colorHex}', radix: 16));
                } catch (_) {
                  projColor = AppColors.primary;
                }
                return ListTile(
                  leading: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: projColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  title: Text(proj.name),
                  onTap: () => Navigator.pop(context, proj),
                );
              }),
              SizedBox(height: AppSpacing.md),
            ],
          ),
        );
      },
    );

    if (selected != null) {
      setState(() {
        _projectId = selected.id;
      });
      _saveTask(isDismissing: false);
    }
  }

  void _updatePriority(int level) {
    HapticFeedback.lightImpact();
    setState(() {
      _priority = level;
    });
    _saveTask(isDismissing: false);
  }

  Widget _buildPriorityButton(int level, ThemeData theme) {
    final String label;
    final Color color;
    switch (level) {
      case 1:
        label = 'High 🔴';
        color = AppColors.priorityHigh;
        break;
      case 2:
        label = 'Medium 🟡';
        color = AppColors.priorityMedium;
        break;
      case 3:
        label = 'Low 🟢';
        color = AppColors.priorityLow;
        break;
      case 4:
      default:
        label = 'Neutral';
        color = Colors.grey;
    }

    final isSelected = _priority == level;

    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            backgroundColor: isSelected ? color.withOpacity(0.15) : null,
            side: BorderSide(
              color: isSelected ? color : theme.dividerColor,
              width: isSelected ? 2 : 1,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.borderMD,
            ),
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
          ),
          onPressed: () => _updatePriority(level),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? color : theme.textTheme.bodyMedium?.color,
              fontWeight: isSelected ? FontWeight.bold : null,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final projectsAsync = ref.watch(projectsStreamProvider);
    final projects = projectsAsync.value ?? [];
    final currentProject =
        projects.where((p) => p.id == _projectId).firstOrNull;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          // Cancel debounce and force immediate save when dismissing
          _debounce.dispose();
          await _saveTask(isDismissing: true);
        }
      },
      child: Material(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xxl),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // Handle bar + Title
            Padding(
              padding: EdgeInsets.only(
                top: AppSpacing.md,
                left: AppSpacing.md,
                right: AppSpacing.md,
              ),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.dividerColor,
                        borderRadius: AppRadius.borderCircular,
                      ),
                    ),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _editingTaskId == null ? 'Create Task' : 'Edit Task',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_editingTaskId != null)
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: AppColors.priorityHigh),
                          onPressed: () {
                            HapticFeedback.heavyImpact();
                            ref
                                .read(tasksControllerProvider.notifier)
                                .deleteTask(_editingTaskId!);
                            AppSemanticsService.announce('Task deleted');
                            context.pop();
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title Field
                    TextField(
                      controller: _titleController,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'What needs to be done?',
                        border: InputBorder.none,
                      ),
                      maxLines: 1,
                      autofocus: widget.task == null,
                    ),

                    // Title Formatting Toolbar
                    Container(
                      margin: EdgeInsets.only(bottom: AppSpacing.md),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: AppRadius.borderMD,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.format_bold, size: 20),
                            tooltip: 'Bold',
                            onPressed: () => _toggleFormat('**'),
                          ),
                          IconButton(
                            icon: const Icon(Icons.format_italic, size: 20),
                            tooltip: 'Italic',
                            onPressed: () => _toggleFormat('*'),
                          ),
                          IconButton(
                            icon: const Icon(Icons.format_underlined, size: 20),
                            tooltip: 'Underline',
                            onPressed: () => _toggleFormat('_'),
                          ),
                          IconButton(
                            icon: const Icon(Icons.format_strikethrough,
                                size: 20),
                            tooltip: 'Strikethrough',
                            onPressed: () => _toggleFormat('~'),
                          ),
                          const VerticalDivider(width: 8, thickness: 1),
                          IconButton(
                            icon: const Icon(Icons.format_clear, size: 20),
                            tooltip: 'Clear formatting',
                            onPressed: _clearFormatting,
                          ),
                        ],
                      ),
                    ),

                    // Description Field
                    TextField(
                      controller: _descriptionController,
                      style: theme.textTheme.bodyLarge,
                      decoration: const InputDecoration(
                        hintText: 'Add description...',
                        border: InputBorder.none,
                      ),
                      maxLines: 4,
                    ),
                    const Divider(),
                    AppSpacing.heightSM,

                    // Quick Due Date Picker Row
                    Text('Due Date', style: theme.textTheme.labelLarge),
                    AppSpacing.heightXS,
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      children: [
                        ActionChip(
                          avatar: const Icon(Icons.today_outlined, size: 16),
                          label: const Text('Today'),
                          onPressed: () => _setQuickDate(DateTime.now()),
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.wb_sunny_outlined, size: 16),
                          label: const Text('Tomorrow'),
                          onPressed: () => _setQuickDate(
                              DateTime.now().add(const Duration(days: 1))),
                        ),
                        ActionChip(
                          avatar:
                              const Icon(Icons.date_range_outlined, size: 16),
                          label: const Text('Custom'),
                          onPressed: () => _selectDueDate(context),
                        ),
                        if (_dueDate != null)
                          ActionChip(
                            avatar: const Icon(Icons.close,
                                size: 16, color: Colors.red),
                            label: const Text('Remove',
                                style: TextStyle(color: Colors.red)),
                            onPressed: () => _setQuickDate(null),
                          ),
                      ],
                    ),
                    if (_dueDate != null) ...[
                      AppSpacing.heightXS,
                      Text(
                        'Scheduled for: ${DateFormatter.formatRelativeDay(_dueDate!)}${_dueDate!.hour == 0 && _dueDate!.minute == 0 ? "" : " at ${_dueDate!.hour.toString().padLeft(2, "0")}:${_dueDate!.minute.toString().padLeft(2, "0")}"}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],

                    AppSpacing.heightMD,

                    // Project Picker Tile
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.folder_outlined),
                      title: Text(
                        currentProject == null
                            ? 'No Project'
                            : currentProject.name,
                      ),
                      trailing: _projectId != null
                          ? IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                setState(() {
                                  _projectId = null;
                                });
                                _saveTask(isDismissing: false);
                              },
                            )
                          : const Icon(Icons.chevron_right),
                      onTap: () => _selectProject(context, projects),
                    ),

                    // Priority Selector
                    AppSpacing.heightMD,
                    Text('Priority', style: theme.textTheme.labelLarge),
                    AppSpacing.heightXS,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        for (int level = 1; level <= 4; level++)
                          _buildPriorityButton(level, theme),
                      ],
                    ),
                    AppSpacing.heightLG,

                    // Confirm / Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.borderMD,
                          ),
                          elevation: 2,
                        ),
                        onPressed: () async {
                          final title = _titleController.text.trim();
                          if (title.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter a task title'),
                              ),
                            );
                            return;
                          }
                          
                          // Save immediate (dismissing: true cancels debounce and saves immediately)
                          await _saveTask(isDismissing: true);
                          if (context.mounted) {
                            context.pop();
                          }
                        },
                        child: Text(
                          widget.task == null ? 'Add Task' : 'Save Changes',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                        height: AppSpacing.xl +
                            MediaQuery.of(context).viewInsets.bottom),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
