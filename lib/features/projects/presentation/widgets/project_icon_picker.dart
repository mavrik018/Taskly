import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';

/// Available icon options for projects.
const List<Map<String, dynamic>> kProjectIcons = [
  {'key': 'work', 'icon': Icons.work_outline, 'label': 'Work'},
  {'key': 'personal', 'icon': Icons.person_outline, 'label': 'Personal'},
  {'key': 'shopping', 'icon': Icons.shopping_bag_outlined, 'label': 'Shopping'},
  {'key': 'health', 'icon': Icons.favorite_border, 'label': 'Health'},
  {'key': 'finance', 'icon': Icons.account_balance_outlined, 'label': 'Finance'},
  {'key': 'travel', 'icon': Icons.flight_outlined, 'label': 'Travel'},
  {'key': 'education', 'icon': Icons.school_outlined, 'label': 'Education'},
  {'key': 'fitness', 'icon': Icons.fitness_center_outlined, 'label': 'Fitness'},
  {'key': 'home', 'icon': Icons.home_outlined, 'label': 'Home'},
  {'key': 'creative', 'icon': Icons.palette_outlined, 'label': 'Creative'},
];

class ProjectIconPicker extends StatelessWidget {
  final String? selectedIcon;
  final String accentColorHex;
  final ValueChanged<String?> onIconSelected;

  const ProjectIconPicker({
    super.key,
    required this.selectedIcon,
    required this.accentColorHex,
    required this.onIconSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color accentColor;
    try {
      accentColor = Color(int.parse('FF$accentColorHex', radix: 16));
    } catch (_) {
      accentColor = const Color(0xFF6366F1);
    }

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: kProjectIcons.map((entry) {
        final key = entry['key'] as String;
        final icon = entry['icon'] as IconData;
        final label = entry['label'] as String;
        final isSelected = selectedIcon == key;

        return GestureDetector(
          onTap: () => onIconSelected(isSelected ? null : key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 56.w,
            height: 64.h,
            decoration: BoxDecoration(
              color: isSelected
                  ? accentColor.withOpacity(0.15)
                  : theme.colorScheme.surface,
              borderRadius: AppRadius.borderMD,
              border: Border.all(
                color: isSelected ? accentColor : theme.dividerColor,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 22.sp,
                  color: isSelected
                      ? accentColor
                      : theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                SizedBox(height: AppSpacing.xxs),
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontSize: 9.sp,
                    color: isSelected ? accentColor : null,
                    fontWeight: isSelected ? FontWeight.w600 : null,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
