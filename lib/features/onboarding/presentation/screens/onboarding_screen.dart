import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../controllers/onboarding_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _nextPage() {
    HapticFeedback.lightImpact();
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name to start!')),
      );
      return;
    }

    HapticFeedback.heavyImpact();
    await ref.read(onboardingProvider.notifier).completeOnboarding(name);
    if (mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          child: Column(
            children: [
              // Page View
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  children: [
                    _buildStep(
                      icon: Icons.check_circle_rounded,
                      color: AppColors.primary,
                      title: 'Welcome to TaskFlow',
                      description:
                          'A beautifully designed, premium space to organize your thoughts, clear your mind, and achieve your daily goals.',
                    ),
                    _buildStep(
                      icon: Icons.folder_shared_outlined,
                      color: Colors.indigoAccent,
                      title: 'Organize with Projects',
                      description:
                          'Group your tasks into dedicated projects. Free tier accounts can create up to 5 projects to keep lists focused.',
                    ),
                    _buildNameInputStep(theme),
                  ],
                ),
              ),

              // Bottom indicators & controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Indicators
                  Row(
                    children: List.generate(3, (index) {
                      final isSelected = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: isSelected ? 24.w : 8.w,
                        height: 8.h,
                        margin: EdgeInsets.only(right: AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : theme.dividerColor,
                          borderRadius: AppRadius.borderCircular,
                        ),
                      );
                    }),
                  ),

                  // Button
                  _currentPage == 2
                      ? FilledButton(
                          onPressed: _submit,
                          style: FilledButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                                vertical: AppSpacing.md),
                            shape: RoundedRectangleBorder(
                                borderRadius: AppRadius.borderMD),
                          ),
                          child: const Text('Get Started'),
                        )
                      : TextButton(
                          onPressed: _nextPage,
                          child: const Text('Next'),
                        ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 100.sp, color: color)
            .animate()
            .scale(duration: 500.ms, curve: Curves.elasticOut)
            .fadeIn(duration: 300.ms),
        SizedBox(height: AppSpacing.xl),
        Text(
          title,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w900,
          ),
          textAlign: TextAlign.center,
        ).animate().slideY(begin: 0.2, end: 0, duration: 300.ms).fadeIn(),
        SizedBox(height: AppSpacing.md),
        Text(
          description,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.textTheme.bodySmall?.color,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ).animate().slideY(begin: 0.3, end: 0, duration: 400.ms).fadeIn(),
      ],
    );
  }

  Widget _buildNameInputStep(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.face_outlined, size: 100.sp, color: AppColors.priorityMedium)
            .animate()
            .scale(duration: 500.ms, curve: Curves.elasticOut),
        SizedBox(height: AppSpacing.xl),
        Text(
          'Almost ready!',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: AppSpacing.sm),
        Text(
          'What should we call you?',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.disabledColor,
          ),
        ),
        SizedBox(height: AppSpacing.lg),
        TextField(
          controller: _nameController,
          autofocus: true,
          style: theme.textTheme.titleMedium,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: 'Your name',
            filled: true,
            fillColor: theme.cardColor,
            border: OutlineInputBorder(
              borderRadius: AppRadius.borderLG,
              borderSide: BorderSide.none,
            ),
            prefixIcon: const Icon(Icons.person_outline),
          ),
          onSubmitted: (_) => _submit(),
        ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.1, end: 0),
      ],
    );
  }
}
