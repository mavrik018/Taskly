import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taskflow/core/theme/app_colors.dart';
import 'package:taskflow/core/theme/app_spacing.dart';
import '../../domain/entities/task.dart';
import '../controllers/tasks_provider.dart';
import '../../../../core/services/ai_service.dart';
import '../../../../core/utils/error_mapper.dart';

class TaskBreakdownSheet extends ConsumerStatefulWidget {
  final Task task;

  const TaskBreakdownSheet({super.key, required this.task});

  @override
  ConsumerState<TaskBreakdownSheet> createState() => _TaskBreakdownSheetState();
}

class _TaskBreakdownSheetState extends ConsumerState<TaskBreakdownSheet> {
  List<String> _subtasks = [];
  final List<bool> _checked = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBreakdown();
  }

  Future<void> _loadBreakdown() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final list = await AIService.breakDownTask(widget.task.title);
      if (mounted) {
        setState(() {
          _subtasks = list;
          _checked.assignAll(List.generate(list.length, (index) => true));
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = ErrorMapper.getAIErrorMessage(e);
          _loading = false;
        });
      }
    }
  }

  Future<void> _addSelected() async {
    HapticFeedback.mediumImpact();
    setState(() => _loading = true);

    final controller = ref.read(tasksControllerProvider.notifier);

    for (int i = 0; i < _subtasks.length; i++) {
      if (_checked[i]) {
        await controller.addTask(
          title: _subtasks[i],
          priority: widget.task.priority,
          projectId: widget.task.projectId,
          dueDate: widget.task.dueDate, // carry over same project/date settings
        );
      }
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subtasks added successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground, // 👈 real color here
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip
          .antiAlias, // keeps ink splashes clipped to the rounded top corners
      child: Container(
        padding: EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: theme.dividerColor.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),

            Text(
              'Break Down Task',
              style: GoogleFonts.poppins(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'AI will generate actionable steps for: "${widget.task.title}"',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
              ),
            ),
            SizedBox(height: AppSpacing.md),

            if (_loading && _subtasks.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      const CircularProgressIndicator(color: Color(0xFF9B7CFF)),
                      SizedBox(height: 12.h),
                      const Text('Analyzing and breaking task down...',
                          style: TextStyle(fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
              )
            else if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red))
            else ...[
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: 280.h),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _subtasks.length,
                  itemBuilder: (context, index) {
                    return CheckboxListTile(
                      activeColor: const Color(0xFF9B7CFF),
                      title: Text(
                        _subtasks[index],
                        style: TextStyle(
                            fontSize: 14.sp, fontWeight: FontWeight.w600),
                      ),
                      value: _checked[index],
                      onChanged: (val) {
                        setState(() {
                          _checked[index] = val ?? false;
                        });
                      },
                    );
                  },
                ),
              ),
              SizedBox(height: AppSpacing.md),
              Container(
                height: 56.h,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9B7CFF), Color(0xFF6C5CE7)],
                  ),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                  ),
                  onPressed: _loading ? null : _addSelected,
                  child: _loading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'Add Selected Steps (${_checked.where((c) => c).length})',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

extension ListAssignAll<T> on List<T> {
  void assignAll(Iterable<T> iterable) {
    clear();
    addAll(iterable);
  }
}
