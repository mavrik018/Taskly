import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../controllers/onboarding_provider.dart';

// ─── Data model for each slide ────────────────────────────────────────────────

class _SlideData {
  final String title;
  final String subtitle;
  final String description;
  final List<Color> gradient;
  final _IllustrationType illustration;

  const _SlideData({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.gradient,
    required this.illustration,
  });
}

enum _IllustrationType { name, premium }

// ─── Slide definitions ────────────────────────────────────────────────────────

const List<_SlideData> _slides = [
  _SlideData(
    title: 'Unlock AI',
    subtitle: 'Superpowers',
    description:
        'Smart task parsing, daily focus suggestions, and weekly reviews — all powered by AI.',
    gradient: [Color(0xFF2C2C2E), Color(0xFF1C1C1E), Color(0xFF000000)],
    illustration: _IllustrationType.premium,
  ),
];

// ─── Main screen ──────────────────────────────────────────────────────────────

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  late AnimationController _bgController;
  late AnimationController _floatController;
  int _currentPage = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
  }

  @override
  void dispose() {
    _pageController.dispose();
    _bgController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    _bgController.forward(from: 0);
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
  }

  void _nextPage() {
    HapticFeedback.lightImpact();
    if (_currentPage < _slides.length - 1) {
      _goToPage(_currentPage + 1);
    }
  }

  Future<void> _finishAsGuest() async {
    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);
    await ref.read(onboardingProvider.notifier).completeOnboarding('Champion');
    if (mounted) {
      setState(() => _isLoading = false);
      context.go('/');
    }
  }

  Future<void> _finishAsPremium() async {
    HapticFeedback.heavyImpact();
    setState(() => _isLoading = true);
    await ref.read(onboardingProvider.notifier).completeOnboarding('Champion');
    if (mounted) {
      setState(() => _isLoading = false);
      context.go('/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_currentPage];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // ── Animated gradient background ──────────────────────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: slide.gradient,
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),

            // ── Floating decorative blobs ──────────────────────────────────
            AnimatedBuilder(
              animation: _floatController,
              builder: (context, _) {
                final t = _floatController.value;
                return Stack(
                  children: [
                    Positioned(
                      top: -80 + (t * 30),
                      right: -60 + (t * 20),
                      child: _GlowBlob(
                        size: 300.r,
                        color: Colors.white.withOpacity(0.07),
                      ),
                    ),
                    Positioned(
                      bottom: 100 - (t * 20),
                      left: -80 + (t * 15),
                      child: _GlowBlob(
                        size: 240.r,
                        color: Colors.white.withOpacity(0.05),
                      ),
                    ),
                    Positioned(
                      top: 200 + (t * 40),
                      left: 50 - (t * 10),
                      child: _GlowBlob(
                        size: 120.r,
                        color: Colors.white.withOpacity(0.06),
                      ),
                    ),
                  ],
                );
              },
            ),

            // ── PageView ───────────────────────────────────────────────────
            PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemCount: _slides.length,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _PremiumChoicePage(
                    isLoading: _isLoading,
                    onGuest: _finishAsGuest,
                    onPremium: _finishAsPremium,
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Premium choice page (slide 0) ───────────────────────────────────────────

class _PremiumChoicePage extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onGuest;
  final VoidCallback onPremium;
  const _PremiumChoicePage({
    required this.isLoading,
    required this.onGuest,
    required this.onPremium,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 48.h),

            // Header
            Text(
              'Choose your',
              style: TextStyle(
                fontSize: 28.sp,
                fontWeight: FontWeight.w300,
                color: Colors.white.withOpacity(0.75),
              ),
            ).animate().fadeIn(delay: 50.ms, duration: 500.ms),
            Text(
              'Experience',
              style: TextStyle(
                fontSize: 46.sp,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -1.5,
                height: 1.0,
              ),
            ).animate().fadeIn(delay: 100.ms, duration: 500.ms),
            SizedBox(height: 8.h),
            Text(
              'Premium users unlock AI features, cloud sync, and unlimited projects.',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.white.withOpacity(0.6),
                height: 1.5,
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

            SizedBox(height: 32.h),

            // Premium card
            _FeatureCard(
              isPremium: true,
              isLoading: isLoading,
              onTap: onPremium,
            )
                .animate()
                .fadeIn(delay: 300.ms, duration: 500.ms)
                .slideY(begin: 0.15, end: 0),

            SizedBox(height: 16.h),

            // Guest card
            _FeatureCard(
              isPremium: false,
              isLoading: isLoading,
              onTap: onGuest,
            )
                .animate()
                .fadeIn(delay: 450.ms, duration: 500.ms)
                .slideY(begin: 0.15, end: 0),

            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final bool isPremium;
  final bool isLoading;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.isPremium,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final features = isPremium
        ? [
            '✦  AI Smart Task Parser',
            '✦  Daily Focus Suggestions',
            '✦  Weekly AI Review',
            '✦  Cloud Sync across devices',
            '✦  Unlimited projects',
          ]
        : [
            '✓  Up to 5 projects',
            '✓  Offline-first storage',
            '✓  Core task management',
            '✗  AI features locked',
            '✗  No cloud sync',
          ];

    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24.r),
          gradient: isPremium
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFFFFFF), Color(0xFFF0F0FF)],
                )
              : null,
          color: isPremium ? null : Colors.white.withOpacity(0.1),
          border: Border.all(
            color:
                isPremium ? Colors.transparent : Colors.white.withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: isPremium
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ]
              : null,
        ),
        child: Padding(
          padding: EdgeInsets.all(24.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.r),
                    decoration: BoxDecoration(
                      color: isPremium
                          ? const Color(0xFFF59E0B).withOpacity(0.15)
                          : Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      isPremium
                          ? Icons.bolt_rounded
                          : Icons.person_outline_rounded,
                      color: isPremium
                          ? const Color(0xFFF59E0B)
                          : Colors.white.withOpacity(0.8),
                      size: 22.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isPremium ? 'Go Premium' : 'Continue as Guest',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w800,
                            color: isPremium
                                ? const Color(0xFF1C1C2E)
                                : Colors.white,
                          ),
                        ),
                        Text(
                          isPremium
                              ? 'Sign up / Sign in'
                              : 'Free • Offline only',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: isPremium
                                ? const Color(0xFF6366F1)
                                : Colors.white.withOpacity(0.5),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isPremium)
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
                        ),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        'BEST',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 20.h),
              // Feature list
              ...features.map((f) {
                final isLocked = f.startsWith('✗');
                return Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: Text(
                    f,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: isPremium
                          ? (isLocked
                              ? const Color(0xFFBBBBCC)
                              : const Color(0xFF1C1C2E))
                          : (isLocked
                              ? Colors.white.withOpacity(0.3)
                              : Colors.white.withOpacity(0.8)),
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                );
              }),
              SizedBox(height: 8.h),
              // Action button
              SizedBox(
                width: double.infinity,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: isLoading
                      ? Center(
                          child: SizedBox(
                            width: 24.r,
                            height: 24.r,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: isPremium
                                  ? const Color(0xFF6366F1)
                                  : Colors.white,
                            ),
                          ),
                        )
                      : Container(
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          decoration: BoxDecoration(
                            gradient: isPremium
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFF6366F1),
                                      Color(0xFF8B5CF6)
                                    ],
                                  )
                                : null,
                            color: isPremium
                                ? null
                                : Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                isPremium ? 'Get Started ' : 'Continue Free ',
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Illustration widget ──────────────────────────────────────────────────────

class _Illustration extends StatelessWidget {
  final _IllustrationType type;
  const _Illustration({required this.type});

  @override
  Widget build(BuildContext context) {
    return switch (type) {
      _IllustrationType.name => _NameIllustration(),
      _IllustrationType.premium => _PremiumIllustration(),
    };
  }
}

// Name illustration
class _NameIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220.w,
      height: 200.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 160.r,
            height: 160.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.08),
              border:
                  Border.all(color: Colors.white.withOpacity(0.2), width: 2),
            ),
          ),
          Container(
            width: 100.r,
            height: 100.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.12),
            ),
            child: Icon(Icons.waving_hand_rounded,
                size: 48.sp, color: Colors.white),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).rotate(
                begin: -0.05,
                end: 0.05,
                duration: 800.ms,
                curve: Curves.easeInOut,
              ),
          // Stars
          for (final pos in [
            [0.0, -90.0],
            [80.0, -50.0],
            [-80.0, -40.0],
            [60.0, 60.0],
            [-70.0, 55.0],
          ])
            Positioned(
              left: 80.w + pos[0].w,
              top: 80.h + pos[1].h,
              child: Icon(Icons.star_rounded,
                      size: 16.sp, color: Colors.white.withOpacity(0.5))
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .fadeIn(duration: 600.ms)
                  .scaleXY(
                      begin: 0.8,
                      end: 1.2,
                      duration: 1200.ms,
                      curve: Curves.easeInOut),
            ),
        ],
      ),
    );
  }
}

// Premium / AI illustration
class _PremiumIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280.w,
      height: 200.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ring
          Container(
            width: 180.r,
            height: 180.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border:
                  Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
            ),
          ),
          // Bolt icon
          Container(
            width: 90.r,
            height: 90.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.15),
              border:
                  Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
            ),
            child:
                const Icon(Icons.bolt_rounded, size: 52, color: Colors.white),
          ),
          // Feature chips orbiting
          for (final item in _orbitItems)
            Positioned(
              left: 80.w + item.$1,
              top: 60.h + item.$2,
              child: _MiniChip(
                label: item.$3,
                icon: item.$4,
                delay: item.$5.ms,
              ),
            ),
        ],
      ),
    );
  }

  static const _orbitItems = [
    (-110.0, -50.0, 'AI Parse', Icons.auto_awesome_rounded, 0),
    (60.0, -60.0, 'Sync', Icons.cloud_sync_rounded, 150),
    (-120.0, 75.0, 'Review', Icons.rate_review_rounded, 300),
  ];
}

class _MiniChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Duration delay;
  const _MiniChip(
      {required this.label, required this.icon, required this.delay});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13.sp, color: Colors.white.withOpacity(0.9)),
          SizedBox(width: 5.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: delay, duration: 400.ms).slideY(
        begin: 0.2,
        end: 0,
        delay: delay,
        duration: 400.ms,
        curve: Curves.easeOut);
  }
}

// ─── Glass button ─────────────────────────────────────────────────────────────

class _GlassButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;

  const _GlassButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          color: isPrimary ? Colors.white : Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(18.r),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: isPrimary ? const Color(0xFF10B981) : Colors.white,
              ),
            ),
            SizedBox(width: 8.w),
            Icon(icon,
                size: 18.sp,
                color: isPrimary ? const Color(0xFF10B981) : Colors.white),
          ],
        ),
      ),
    );
  }
}

// ─── Glow blob ────────────────────────────────────────────────────────────────

class _GlowBlob extends StatelessWidget {
  final double size;
  final Color color;
  const _GlowBlob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}
