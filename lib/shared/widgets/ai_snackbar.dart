import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Unified, styled snackbar for AI feature feedback.
/// Monochrome black/white theme that adapts to light and dark mode,
/// with a distinct (but still monochrome) treatment for error/cooldown states.
class AISnackBar {
  AISnackBar._();

  static void showUsage({
    required BuildContext context,
    required String featureName,
    required String actionLabel,
    required int remaining,
    required int total,
    Duration? cooldownLeft,
    bool isError = false,
    String? errorMessage,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Success/info: standard inverted card (white card in dark mode, black card in light mode).
    // Error/cooldown: card stays on the *theme* surface instead of inverting, with a red-accented
    // icon — so it reads as distinct from a routine usage confirmation, not just a recolored copy.
    final bg = isError
        ? (isDark ? const Color(0xFF1C1C1E) : Colors.white)
        : (isDark ? Colors.white : Colors.black);
    final fg = isError
        ? (isDark ? Colors.white : Colors.black)
        : (isDark ? Colors.black : Colors.white);
    final subFg = isError
        ? (isDark ? Colors.white60 : Colors.black54)
        : (isDark ? Colors.black54 : Colors.white60);
    final borderColor = isError
        ? (isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.06))
        : Colors.transparent;
    const errorAccent = Color(0xFFE5484D);

    final usedCount = (total - remaining).clamp(0, total);
    final progress = total > 0 ? usedCount / total : 0.0;

    String subtitle;
    if (isError && cooldownLeft != null && cooldownLeft > Duration.zero) {
      final m = cooldownLeft.inMinutes;
      final s = cooldownLeft.inSeconds % 60;
      final timeStr = m > 0 ? (s > 0 ? '${m}m ${s}s' : '${m}m') : '${s}s';
      subtitle = 'Try again in $timeStr';
    } else if (isError && errorMessage != null) {
      subtitle = errorMessage;
    } else {
      subtitle = '$remaining of $total $actionLabel left today';
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: isError ? 6 : 4),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          content: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14),
              border: borderColor != Colors.transparent
                  ? Border.all(color: borderColor)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.08 : 0.18),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isError
                        ? errorAccent.withValues(alpha: 0.12)
                        : fg.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isError
                        ? Icons.warning_rounded
                        : Icons.auto_awesome_rounded,
                    color: isError ? errorAccent : fg,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        featureName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: fg,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: subFg,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      // Real progress bar instead of unicode dots — only shown for
                      // the routine usage case, where "remaining of total" is the point.
                      if (!isError) ...[
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: SizedBox(
                            height: 3,
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: fg.withValues(alpha: 0.15),
                              valueColor: AlwaysStoppedAnimation<Color>(fg),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }
}
