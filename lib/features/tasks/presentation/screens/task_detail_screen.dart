import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:taskflow/core/utils/notification_manager.dart';
import '../../domain/entities/task.dart';
import '../controllers/tasks_provider.dart';
import '../../../projects/presentation/controllers/projects_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/debounce.dart';
import '../../../../core/utils/semantics_service.dart';
import '../../../../core/services/ai_service.dart';
import '../../../../core/utils/error_mapper.dart';
import '../../../auth/presentation/controllers/auth_provider.dart';
import '../../../../shared/widgets/premium_promo_dialog.dart';

class TaskDetailScreen extends ConsumerStatefulWidget {
  final Task? task;
  final int? initialProjectId;

  const TaskDetailScreen({
    super.key,
    this.task,
    this.initialProjectId,
  });

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen>
    with SingleTickerProviderStateMixin {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late int _priority;
  DateTime? _dueDate;
  int? _projectId;

  int? _editingTaskId;
  late Debounce _debounce;
  late AnimationController _sheetController;

  // AI Smart Parser State Fields
  String? _parsedTitle;
  DateTime? _parsedDueDate;
  int? _parsedPriority;
  String? _parsedTime;
  bool _isParsing = false;
  late Debounce _parseDebounce;

  bool _showSmartParser = false;
  late TextEditingController _smartParserController;

  @override
  void initState() {
    super.initState();
    _editingTaskId = widget.task?.id;
    _priority = widget.task?.priority ?? 4;
    _dueDate = widget.task?.dueDate;
    _projectId = widget.task?.projectId ?? widget.initialProjectId;

    _debounce = Debounce(delay: const Duration(milliseconds: 600));
    _parseDebounce = Debounce(delay: const Duration(milliseconds: 1000));
    _smartParserController = TextEditingController();

    _titleController = TextEditingController(
      text: widget.task?.title ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.task?.description ?? '',
    );

    _titleController.addListener(_saveTaskDebounced);
    _titleController.addListener(_onTitleChanged);
    _descriptionController.addListener(_saveTaskDebounced);

    _sheetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
  }

  @override
  void dispose() {
    _titleController.removeListener(_saveTaskDebounced);
    _titleController.removeListener(_onTitleChanged);
    _descriptionController.removeListener(_saveTaskDebounced);
    _titleController.dispose();
    _descriptionController.dispose();
    _smartParserController.dispose();
    _debounce.dispose();
    _parseDebounce.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  void _onTitleChanged() {
    final text = _titleController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _parsedTitle = null;
        _isParsing = false;
      });
      return;
    }
    // Only parse if text contains potential trigger words (like tomorrow, at, pm, etc.)
    final lower = text.toLowerCase();
    final hasKeywords = lower.contains('tomorrow') ||
        lower.contains('today') ||
        lower.contains('at') ||
        lower.contains('pm') ||
        lower.contains('am') ||
        lower.contains('urgent') ||
        lower.contains('asap') ||
        lower.contains('priority') ||
        lower.contains('high') ||
        lower.contains('monday') ||
        lower.contains('tuesday') ||
        lower.contains('wednesday') ||
        lower.contains('thursday') ||
        lower.contains('friday') ||
        lower.contains('saturday') ||
        lower.contains('sunday');

    if (ref.read(authProvider) == null || !hasKeywords) return;

    setState(() {
      _isParsing = true;
    });

    _parseDebounce.run(() async {
      try {
        final result = await AIService.parseTaskTitle(text);
        if (mounted && _titleController.text.trim() == text) {
          setState(() {
            _parsedTitle = result['title'];
            _parsedDueDate = result['dueDate'] != null
                ? DateTime.parse(result['dueDate'])
                : null;
            _parsedPriority = result['priority'];
            _parsedTime = result['time'];
            _isParsing = false;
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() => _isParsing = false);
        }
      }
    });
  }

  void _applyParsedData() {
    if (_parsedTitle == null) return;
    setState(() {
      _titleController.text = _parsedTitle!;
      if (_parsedDueDate != null) {
        DateTime finalDate = _parsedDueDate!;
        if (_parsedTime != null) {
          final parts = _parsedTime!.split(':');
          finalDate = DateTime(
            _parsedDueDate!.year,
            _parsedDueDate!.month,
            _parsedDueDate!.day,
            int.parse(parts[0]),
            int.parse(parts[1]),
          );
        }
        _dueDate = finalDate;
      }
      if (_parsedPriority != null) {
        _priority = _parsedPriority!;
      }
      _parsedTitle = null;
    });
    HapticFeedback.mediumImpact();
  }

  Future<void> _runExplicitSmartParse() async {
    if (ref.read(authProvider) == null) {
      PremiumPromoDialog.show(
        context: context,
        title: 'Smart Task Parser',
        content: 'Natural language parsing is a premium feature. Please sign in or register to parse details instantly.',
        icon: Icons.bolt_rounded,
      );
      return;
    }

    final text = _smartParserController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isParsing = true;
    });

    try {
      final result = await AIService.parseTaskTitle(text);
      if (mounted) {
        setState(() {
          _titleController.text = result['title'] ?? '';
          if (result['dueDate'] != null) {
            DateTime parsedDate = DateTime.parse(result['dueDate']);
            if (result['time'] != null) {
              final parts = result['time'].split(':');
              parsedDate = DateTime(
                parsedDate.year,
                parsedDate.month,
                parsedDate.day,
                int.parse(parts[0]),
                int.parse(parts[1]),
              );
            }
            _dueDate = parsedDate;
          }
          if (result['priority'] != null) {
            _priority = result['priority'];
          }
          _isParsing = false;
          _showSmartParser = false;
          _smartParserController.clear();
        });
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AI parsed and applied details successfully!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Color(0xFF9B7CFF),
          ),
        );
        _saveTask(isDismissing: false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isParsing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorMapper.getAIErrorMessage(e))),
        );
      }
    }
  }

  void _saveTaskDebounced() {
    _debounce.run(() => _saveTask(isDismissing: false));
  }

  Future<void> _saveTask({required bool isDismissing}) async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final description = _descriptionController.text.trim();
    final controller = ref.read(tasksControllerProvider.notifier);

    if (_editingTaskId == null) {
      final newId = await controller.addTask(
        title: title,
        description: description.isEmpty ? null : description,
        dueDate: _dueDate,
        priority: _priority,
        projectId: _projectId,
      );
      if (newId != null) {
        setState(() => _editingTaskId = newId);
        AppSemanticsService.announce('Task created');
      }
    } else {
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
      if (isDismissing) AppSemanticsService.announce('Task updated');
    }
  }

  Future<void> _selectDueDate(BuildContext context) async {
    HapticFeedback.lightImpact();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    DateTime initialDate = _dueDate ?? now;
    if (initialDate.isBefore(today)) initialDate = today;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365 * 5)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppColors.primary,
              ),
        ),
        child: child!,
      ),
    );

    if (pickedDate != null) {
      if (!context.mounted) return;
      await NotificationManager.requestPermissions(context);
      if (!context.mounted) return;

      final initialTime = _dueDate != null
          ? TimeOfDay.fromDateTime(_dueDate!)
          : TimeOfDay.fromDateTime(now);

      final pickedTime = await showTimePicker(
        context: context,
        initialTime: initialTime,
        builder: (context, child) => Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primary,
                ),
          ),
          child: child!,
        ),
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
        final compareDate =
            DateTime(pickedDate.year, pickedDate.month, pickedDate.day);
        if (compareDate.isAtSameMomentAs(today)) {
          finalDateTime = now.add(const Duration(hours: 1));
        } else {
          finalDateTime =
              DateTime(pickedDate.year, pickedDate.month, pickedDate.day, 9, 0);
        }
      }

      setState(() => _dueDate = finalDateTime);
      _saveTask(isDismissing: false);
    }
  }

  void _updatePriority(int level) {
    HapticFeedback.lightImpact();
    setState(() => _priority = level);
    _saveTask(isDismissing: false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final projectsAsync = ref.watch(projectsStreamProvider);
    final projects = projectsAsync.value ?? [];
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          _debounce.dispose();
          await _saveTask(isDismissing: true);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Sheet Header ───────────────────────────────────────────
            _SheetHeader(),

            // ── Scrollable Body ────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                    AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Title and Subtitle ────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _editingTaskId != null
                                    ? 'Edit Task'
                                    : 'New Task',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 28.sp,
                                  color: theme.textTheme.bodyLarge?.color,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Capture what needs to be done.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.textTheme.bodySmall?.color
                                      ?.withOpacity(0.7),
                                  fontSize: 14.sp,
                                ),
                              ),
                            ],
                          ),
                          if (_editingTaskId == null)
                            IconButton(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                setState(() {
                                  _showSmartParser = !_showSmartParser;
                                });
                              },
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _showSmartParser
                                      ? const Color(0xFF9B7CFF).withOpacity(0.2)
                                      : Colors.transparent,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF9B7CFF)
                                        .withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.auto_awesome_rounded,
                                  color: Color(0xFF9B7CFF),
                                  size: 20,
                                ),
                              ),
                              tooltip: 'Smart Add with AI',
                            ),
                        ],
                      ),
                    ),

                    if (_showSmartParser && _editingTaskId == null)
                      Container(
                        margin: const EdgeInsets.only(top: 8, bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF9B7CFF).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF9B7CFF).withOpacity(0.25),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.auto_awesome_rounded,
                                    color: Color(0xFF9B7CFF), size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  'AI Smart Parser',
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF9B7CFF),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _smartParserController,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: theme.textTheme.bodyLarge?.color,
                              ),
                              decoration: InputDecoration(
                                hintText:
                                    'e.g., Buy groceries tomorrow at 5pm high priority',
                                hintStyle: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w500,
                                  color: theme.textTheme.bodySmall?.color
                                      ?.withOpacity(0.4),
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              maxLines: null,
                              keyboardType: TextInputType.multiline,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _showSmartParser = false;
                                      _smartParserController.clear();
                                    });
                                  },
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(
                                      color: theme.textTheme.bodySmall?.color
                                          ?.withOpacity(0.6),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF9B7CFF),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  onPressed: _isParsing
                                      ? null
                                      : _runExplicitSmartParse,
                                  child: _isParsing
                                      ? const SizedBox(
                                          width: 12,
                                          height: 12,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(
                                          'Parse & Apply',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12.sp,
                                          ),
                                        ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                    // ── Title Input ────────────────────────────────────────
                    SizedBox(height: 16),
                    TextField(
                      controller: _titleController,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Task Title',
                        hintStyle: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                          color: theme.textTheme.bodySmall?.color
                              ?.withOpacity(0.4),
                        ),
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.black.withOpacity(0.04),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 18),
                      ),
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      autofocus: widget.task == null,
                    ),

                    if (_isParsing)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, left: 8.0),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Color(0xFF9B7CFF)),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'AI is parsing sentence...',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (_parsedTitle != null &&
                        _parsedTitle != _titleController.text.trim())
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: GestureDetector(
                          onTap: _applyParsedData,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF9B7CFF).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color:
                                      const Color(0xFF9B7CFF).withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.auto_awesome_rounded,
                                    color: Color(0xFF9B7CFF), size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'AI Suggestion: "$_parsedTitle"'
                                    '${_parsedDueDate != null ? ' · Due ' + DateFormatter.formatRelativeDay(_parsedDueDate!) : ''}'
                                    '${_parsedPriority != null ? ' · Priority: ' + (_parsedPriority == 1 ? 'High' : _parsedPriority == 2 ? 'Medium' : _parsedPriority == 3 ? 'Low' : 'None') : ''}',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF9B7CFF),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Apply',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF6C5CE7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // ── Description Input ─────────────────────────────────
                    SizedBox(height: 12),
                    TextField(
                      controller: _descriptionController,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        color:
                            theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Add a description...',
                        hintStyle: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                          color: theme.textTheme.bodySmall?.color
                              ?.withOpacity(0.4),
                        ),
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.black.withOpacity(0.04),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 18),
                      ),
                      maxLines: 4,
                      minLines: 2,
                    ),

                    // ── Project Section ───────────────────────────────────
                    SizedBox(height: 24),
                    Text(
                      'PROJECT',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color:
                            theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                        letterSpacing: 1.2,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: projects.map((proj) {
                        Color projColor;
                        try {
                          projColor =
                              Color(int.parse('FF${proj.colorHex}', radix: 16));
                        } catch (_) {
                          projColor = AppColors.primary;
                        }
                        final isSelected = _projectId == proj.id;
                        return _ProjectChip(
                          label: proj.name,
                          color: projColor,
                          isSelected: isSelected,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            setState(() => _projectId = proj.id);
                            _saveTask(isDismissing: false);
                          },
                        );
                      }).toList(),
                    ),

                    // ── Priority Section ──────────────────────────────────
                    SizedBox(height: 24),
                    Text(
                      'PRIORITY',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color:
                            theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                        letterSpacing: 1.2,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _PriorityChip(
                            label: 'High',
                            color: AppColors.priorityHigh,
                            isSelected: _priority == 1,
                            onTap: () {
                              _updatePriority(1);
                            },
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: _PriorityChip(
                            label: 'Med',
                            color: AppColors.priorityMedium,
                            isSelected: _priority == 2,
                            onTap: () {
                              _updatePriority(2);
                            },
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: _PriorityChip(
                            label: 'Low',
                            color: AppColors.priorityLow,
                            isSelected: _priority == 3,
                            onTap: () {
                              _updatePriority(3);
                            },
                          ),
                        ),
                      ],
                    ),

                    // ── Due Date Section ──────────────────────────────────
                    SizedBox(height: 24),
                    Text(
                      'DUE DATE',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color:
                            theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                        letterSpacing: 1.2,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: 12),
                    if (_dueDate != null)
                      GestureDetector(
                        onTap: () => _selectDueDate(context),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 18),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.05)
                                : Colors.black.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: theme.dividerColor.withOpacity(0.5),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: theme.dividerColor.withOpacity(0.3),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.calendar_today_rounded,
                                  size: 22,
                                  color: theme.textTheme.bodyLarge?.color,
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      DateFormatter.formatRelativeDay(
                                          _dueDate!),
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w600,
                                        color: theme.textTheme.bodyLarge?.color,
                                      ),
                                    ),
                                    Text(
                                      'Scheduled for ${_dueDate!.hour.toString().padLeft(2, '0')}:${_dueDate!.minute.toString().padLeft(2, '0')}',
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w500,
                                        color: theme.textTheme.bodySmall?.color
                                            ?.withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.edit_rounded,
                                size: 24,
                                color: AppColors.primary,
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: () => _selectDueDate(context),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 18),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.05)
                                : Colors.black.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: theme.dividerColor.withOpacity(0.5),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: theme.dividerColor.withOpacity(0.3),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.calendar_today_rounded,
                                  size: 22,
                                  color: theme.textTheme.bodyLarge?.color
                                      ?.withOpacity(0.5),
                                ),
                              ),
                              SizedBox(width: 16),
                              Text(
                                'Add due date',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w500,
                                  color: theme.textTheme.bodySmall?.color
                                      ?.withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // ── Create Button ─────────────────────────────────────
                    SizedBox(height: 32),
                    _SaveButton(
                      isNew: widget.task == null,
                      onSave: () async {
                        final title = _titleController.text.trim();
                        if (title.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Please enter a task title'),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                          return;
                        }
                        await _saveTask(isDismissing: true);
                        if (context.mounted) context.pop();
                      },
                    ),

                    SizedBox(height: bottomInset + AppSpacing.md),
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

// ─── Sheet Header ─────────────────────────────────────────────────────────────

class _SheetHeader extends StatelessWidget {
  const _SheetHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          width: 40,
          height: 5,
          decoration: BoxDecoration(
            color: theme.dividerColor.withOpacity(0.4),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        SizedBox(height: 8),
      ],
    );
  }
}

// ─── Project Chip ─────────────────────────────────────────────────────────────

class _ProjectChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ProjectChip({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? color
              : isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.04),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? color : theme.dividerColor.withOpacity(0.5),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? (isDark ? Colors.black : Colors.white)
                : theme.textTheme.bodyLarge?.color,
            fontWeight: FontWeight.w600,
            fontSize: 14.sp,
          ),
        ),
      ),
    );
  }
}

// ─── Priority Chip ────────────────────────────────────────────────────────────

class _PriorityChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _PriorityChip({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.15)
              : isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.04),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? color : theme.dividerColor.withOpacity(0.5),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? color
                    : theme.textTheme.bodyLarge?.color?.withOpacity(0.7),
                fontWeight: FontWeight.w600,
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Save Button ──────────────────────────────────────────────────────────────

class _SaveButton extends StatefulWidget {
  final bool isNew;
  final VoidCallback onSave;

  const _SaveButton({required this.isNew, required this.onSave});

  @override
  State<_SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends State<_SaveButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 120),
        lowerBound: 0.95,
        upperBound: 1.0,
        value: 1.0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return ScaleTransition(
      scale: _controller,
      child: GestureDetector(
        onTapDown: (_) => _controller.reverse(),
        onTapUp: (_) {
          _controller.forward();
          widget.onSave();
        },
        onTapCancel: () => _controller.forward(),
        child: Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF9B7CFF), const Color(0xFF6C5CE7)]
                  : [const Color(0xFF9B7CFF), const Color(0xFF6C5CE7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color:
                    (isDark ? const Color(0xFF9B7CFF) : const Color(0xFF9B7CFF))
                        .withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.isNew ? Icons.add_task_rounded : Icons.check_rounded,
                  color: Colors.white,
                  size: 26,
                ),
                const SizedBox(width: 10),
                Text(
                  widget.isNew ? 'Create Task' : 'Save Changes',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
