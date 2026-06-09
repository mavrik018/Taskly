import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../controllers/projects_provider.dart';
import '../widgets/project_color_picker.dart';
import '../widgets/project_icon_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';

class AddProjectSheet extends ConsumerStatefulWidget {
  const AddProjectSheet({super.key});

  @override
  ConsumerState<AddProjectSheet> createState() => _AddProjectSheetState();
}

class _AddProjectSheetState extends ConsumerState<AddProjectSheet> {
  final _nameController = TextEditingController();
  String _selectedColor = kProjectColors.first;
  String? _selectedIcon;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Color get _accentColor {
    try {
      return Color(int.parse('FF$_selectedColor', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a project name')),
      );
      return;
    }

    setState(() => _isSaving = true);

    await ref.read(projectsControllerProvider.notifier).addProject(
          name: name,
          colorHex: _selectedColor,
          iconName: _selectedIcon,
        );

    if (!mounted) return;

    final state = ref.read(projectsControllerProvider);
    if (state.errorMessage != null) {
      setState(() => _isSaving = false);
      _showLimitDialog(state.errorMessage!);
      ref.read(projectsControllerProvider.notifier).clearError();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _showLimitDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Project Limit Reached'),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: AppSpacing.lg + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
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
            SizedBox(height: AppSpacing.lg),

            // Header with preview icon
            Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 48.w,
                  height: 48.w,
                  decoration: BoxDecoration(
                    color: _accentColor.withOpacity(0.15),
                    borderRadius: AppRadius.borderMD,
                  ),
                  child: Icon(
                    _selectedIcon != null
                        ? kProjectIcons
                            .firstWhere(
                              (e) => e['key'] == _selectedIcon,
                              orElse: () => kProjectIcons.first,
                            )['icon'] as IconData
                        : Icons.folder_outlined,
                    color: _accentColor,
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'New Project',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: AppSpacing.lg),

            // Name field
            TextField(
              controller: _nameController,
              autofocus: true,
              style: theme.textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Project name',
                filled: true,
                fillColor: theme.cardColor,
                border: OutlineInputBorder(
                  borderRadius: AppRadius.borderLG,
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(Icons.title_outlined, color: _accentColor),
              ),
            ),

            SizedBox(height: AppSpacing.lg),

            // Color picker
            Text('Color', style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            )),
            SizedBox(height: AppSpacing.sm),
            ProjectColorPicker(
              selectedColor: _selectedColor,
              onColorSelected: (hex) => setState(() => _selectedColor = hex),
            ),

            SizedBox(height: AppSpacing.lg),

            // Icon picker
            Text('Icon', style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            )),
            SizedBox(height: AppSpacing.sm),
            ProjectIconPicker(
              selectedIcon: _selectedIcon,
              accentColorHex: _selectedColor,
              onIconSelected: (icon) => setState(() => _selectedIcon = icon),
            ),

            SizedBox(height: AppSpacing.xl),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 52.h,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _accentColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.borderLG,
                  ),
                ),
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Create Project',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
