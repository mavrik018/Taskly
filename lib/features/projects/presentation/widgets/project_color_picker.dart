import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';

/// A curated palette of project colors.
const List<String> kProjectColors = [
  '6366F1', // Indigo
  '8B5CF6', // Violet
  'EC4899', // Pink
  'EF4444', // Red
  'F59E0B', // Amber
  '10B981', // Emerald
  '06B6D4', // Cyan
  '3B82F6', // Blue
  'F97316', // Orange
  '84CC16', // Lime
  '6B7280', // Gray
  '14B8A6', // Teal
];

class ProjectColorPicker extends StatelessWidget {
  final String selectedColor;
  final ValueChanged<String> onColorSelected;

  const ProjectColorPicker({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: kProjectColors.map((hex) {
        final isSelected = selectedColor == hex;
        final color = Color(int.parse('FF$hex', radix: 16));
        return GestureDetector(
          onTap: () => onColorSelected(hex),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              color: color,
              borderRadius: AppRadius.borderCircular,
              border: isSelected
                  ? Border.all(color: Colors.white, width: 2.5)
                  : null,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 1,
                      )
                    ]
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : null,
          ),
        );
      }).toList(),
    );
  }
}
