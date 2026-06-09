import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taskflow/core/theme/theme_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // ── Inline Header ─────────────────────────────────────────────
          SliverPersistentHeader(
            pinned: true,
            delegate: _SettingsHeaderDelegate(isDark: isDark),
          ),

          SliverToBoxAdapter(child: SizedBox(height: AppSpacing.h_sm)),

          // ── PREFERENCES Section ───────────────────────────────────────
          SliverToBoxAdapter(
            child: _SectionLabel(label: 'PREFERENCES').animate().fadeIn(
                duration: 300.ms, delay: 80.ms),
          ),
          SliverToBoxAdapter(child: SizedBox(height: AppSpacing.h_xs)),
          SliverToBoxAdapter(
            child: _SettingsCard(
              isDark: isDark,
              children: [
                _AppearanceRow(
                  isDark: isDark,
                  themeMode: themeMode,
                  onChanged: (newMode) {
                    HapticFeedback.lightImpact();
                    ref.read(themeModeProvider.notifier).setThemeMode(newMode);
                  },
                ),
              ],
            ).animate().fadeIn(duration: 350.ms, delay: 100.ms).slideY(
                  begin: 0.05,
                  end: 0,
                  duration: 350.ms,
                  delay: 100.ms,
                  curve: Curves.easeOutCubic,
                ),
          ),

          SliverToBoxAdapter(child: SizedBox(height: AppSpacing.h_md)),

          // ── SUPPORT Section ───────────────────────────────────────────
          SliverToBoxAdapter(
            child: _SectionLabel(label: 'SUPPORT').animate().fadeIn(
                duration: 300.ms, delay: 160.ms),
          ),
          SliverToBoxAdapter(child: SizedBox(height: AppSpacing.h_xs)),
          SliverToBoxAdapter(
            child: _SettingsCard(
              isDark: isDark,
              children: [
                _SettingsRow(
                  icon: Icons.star_outline_rounded,
                  iconColor: const Color(0xFFF59E0B),
                  label: 'Rate TaskFlow',
                  isDark: isDark,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Thank you for rating!')),
                    );
                  },
                ),
                _HairlineDivider(isDark: isDark),
                _SettingsRow(
                  icon: Icons.chat_bubble_outline_rounded,
                  iconColor: AppColors.primary,
                  label: 'Feedback & Support',
                  isDark: isDark,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Opening support...')),
                    );
                  },
                ),
              ],
            ).animate().fadeIn(duration: 350.ms, delay: 180.ms).slideY(
                  begin: 0.05,
                  end: 0,
                  duration: 350.ms,
                  delay: 180.ms,
                  curve: Curves.easeOutCubic,
                ),
          ),

          SliverToBoxAdapter(child: SizedBox(height: AppSpacing.h_md)),

          // ── ABOUT Section ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _SectionLabel(label: 'ABOUT').animate().fadeIn(
                duration: 300.ms, delay: 240.ms),
          ),
          SliverToBoxAdapter(child: SizedBox(height: AppSpacing.h_xs)),
          SliverToBoxAdapter(
            child: _SettingsCard(
              isDark: isDark,
              children: [
                _SettingsRow(
                  icon: Icons.info_outline_rounded,
                  iconColor: const Color(0xFF6366F1),
                  label: 'Version',
                  isDark: isDark,
                  trailing: _VersionBadge(isDark: isDark),
                ),
              ],
            ).animate().fadeIn(duration: 350.ms, delay: 260.ms).slideY(
                  begin: 0.05,
                  end: 0,
                  duration: 350.ms,
                  delay: 260.ms,
                  curve: Curves.easeOutCubic,
                ),
          ),

          // ── Bottom spacer for nav bar clearance ───────────────────────
          SliverToBoxAdapter(child: SizedBox(height: 120.h)),
        ],
      ),
    );
  }
}

// ─── Settings Sliver Header ──────────────────────────────────────────────────

class _SettingsHeaderDelegate extends SliverPersistentHeaderDelegate {
  final bool isDark;
  const _SettingsHeaderDelegate({required this.isDark});

  @override
  double get minExtent => 60;
  @override
  double get maxExtent => 100;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final t = (shrinkOffset / maxExtent).clamp(0.0, 1.0);
    final isCollapsed = t > 0.5;
    final theme = Theme.of(context);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: overlapsContent ? 16 : 0,
          sigmaY: overlapsContent ? 16 : 0,
        ),
        child: Container(
          color: theme.scaffoldBackgroundColor
              .withOpacity(overlapsContent ? 0.88 : 1.0),
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 6,
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: 10,
          ),
          child: AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            firstChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 26.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.6,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                Text(
                  'Customize your experience',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
            secondChild: Row(
              children: [
                Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
              ],
            ),
            crossFadeState: isCollapsed
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _SettingsHeaderDelegate oldDelegate) =>
      isDark != oldDelegate.isDark;
}

// ─── Settings Card ───────────────────────────────────────────────────────────

class _SettingsCard extends StatelessWidget {
  final bool isDark;
  final List<Widget> children;

  const _SettingsCard({required this.isDark, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: AppRadius.borderXL,
          border: Border.all(
            color: isDark
                ? AppColors.darkBorder
                : AppColors.lightBorder,
            width: 0.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: AppRadius.borderXL,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: children,
          ),
        ),
      ),
    );
  }
}

// ─── Section Label ───────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md + 4, vertical: 0),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5.sp,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.9,
          color: isDark
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary,
        ),
      ),
    );
  }
}

// ─── Hairline Divider ─────────────────────────────────────────────────────────

class _HairlineDivider extends StatelessWidget {
  final bool isDark;
  const _HairlineDivider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 56),
      child: Container(
        height: 0.5,
        color: isDark
            ? AppColors.darkBorder
            : AppColors.lightBorder,
      ),
    );
  }
}

// ─── Settings Row ─────────────────────────────────────────────────────────────

class _SettingsRow extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final bool isDark;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SettingsRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.isDark,
    this.onTap,
    this.trailing,
  });

  @override
  State<_SettingsRow> createState() => _SettingsRowState();
}

class _SettingsRowState extends State<_SettingsRow> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: widget.onTap != null
          ? (_) {
              setState(() => _isPressed = false);
              widget.onTap!();
            }
          : null,
      onTapCancel:
          widget.onTap != null ? () => setState(() => _isPressed = false) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        color: _isPressed
            ? (widget.isDark
                ? Colors.white.withOpacity(0.04)
                : Colors.black.withOpacity(0.03))
            : Colors.transparent,
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: widget.iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(widget.icon, color: widget.iconColor, size: 16),
            ),
            SizedBox(width: AppSpacing.sm),
            // Label
            Expanded(
              child: Text(
                widget.label,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: widget.isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
            ),
            // Trailing
            if (widget.trailing != null)
              widget.trailing!
            else if (widget.onTap != null)
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: widget.isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Appearance Row ───────────────────────────────────────────────────────────

class _AppearanceRow extends StatelessWidget {
  final bool isDark;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onChanged;

  const _AppearanceRow({
    required this.isDark,
    required this.themeMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  themeMode == ThemeMode.light
                      ? Icons.light_mode_rounded
                      : themeMode == ThemeMode.dark
                          ? Icons.dark_mode_rounded
                          : Icons.auto_awesome_rounded,
                  color: AppColors.primary,
                  size: 16,
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Text(
                'Appearance',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.h_sm),
          // Custom segmented control
          Row(
            children: [
              _ThemeSegment(
                value: ThemeMode.system,
                label: 'System',
                icon: Icons.auto_awesome_rounded,
                selected: themeMode == ThemeMode.system,
                isDark: isDark,
                onTap: () => onChanged(ThemeMode.system),
              ),
              SizedBox(width: AppSpacing.xs),
              _ThemeSegment(
                value: ThemeMode.light,
                label: 'Light',
                icon: Icons.light_mode_rounded,
                selected: themeMode == ThemeMode.light,
                isDark: isDark,
                onTap: () => onChanged(ThemeMode.light),
              ),
              SizedBox(width: AppSpacing.xs),
              _ThemeSegment(
                value: ThemeMode.dark,
                label: 'Dark',
                icon: Icons.dark_mode_rounded,
                selected: themeMode == ThemeMode.dark,
                isDark: isDark,
                onTap: () => onChanged(ThemeMode.dark),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ThemeSegment extends StatelessWidget {
  final ThemeMode value;
  final String label;
  final IconData icon;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _ThemeSegment({
    required this.value,
    required this.label,
    required this.icon,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary
                : (isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.04)),
            borderRadius: AppRadius.borderMD,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 16,
                color: selected
                    ? Colors.white
                    : (isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected
                      ? Colors.white
                      : (isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Version Badge ────────────────────────────────────────────────────────────

class _VersionBadge extends StatelessWidget {
  final bool isDark;
  const _VersionBadge({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.07)
            : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'v1.0.0',
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
          color: isDark
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary,
        ),
      ),
    );
  }
}
