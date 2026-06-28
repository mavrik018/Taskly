import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

// ── shared alpha constants ──────────────────────────────────────────────────────
class _SplashAlpha {
  static const ambientGlowInner = 0.05;
  static const ambientGlowOuter = 0.04;
  static const radialHighlight = 0.025;
  static const markGlow = 0.18;
  static const ringBorder = 0.08;
  static const cardShadowLight = 0.10;
  static const cardShadowDark = 0.5;
  static const cardShadowRim = 0.06;
  static const underlineMid = 0.35;
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── ambient breathe ──────────────────────────────────────────────────────────
  late final AnimationController _breatheCtrl;
  late final Animation<double> _breatheScale;
  late final Animation<double> _breatheOpacity;

  // ── mark pop-in ──────────────────────────────────────────────────────────────
  late final AnimationController _markCtrl;
  late final Animation<double> _markScale;
  late final Animation<double> _markOpacity;

  // ── glow pulse ───────────────────────────────────────────────────────────────
  late final AnimationController _glowCtrl;
  late final Animation<double> _glowOpacity;
  late final Animation<double> _glowScale;

  // ── check draw ───────────────────────────────────────────────────────────────
  late final AnimationController _checkCtrl;
  late final Animation<double> _checkProgress;

  // ── wordmark + tagline ───────────────────────────────────────────────────────
  late final AnimationController _wordCtrl;
  late final Animation<double> _wordOpacity;
  late final Animation<Offset> _wordSlide;

  late final AnimationController _tagCtrl;
  late final Animation<double> _tagOpacity;
  late final Animation<Offset> _tagSlide;

  // ── flow underline ───────────────────────────────────────────────────────────
  late final AnimationController _underlineCtrl;
  late final Animation<double> _underlineScale;
  late final Animation<double> _underlineOpacity;

  // ── loader ───────────────────────────────────────────────────────────────────
  late final AnimationController _loaderCtrl;
  late final Animation<double> _loaderOpacity;

  // ── dot pulses (always exactly 3 — built once in initState) ────────────────
  final List<AnimationController> _dotCtrl = [];
  final List<Animation<double>> _dotOpacity = [];
  final List<Animation<double>> _dotScale = [];

  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    // ── ambient breathe ────────────────────────────────────────────────────────
    _breatheCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    )..repeat(reverse: true);

    _breatheScale = Tween(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _breatheCtrl, curve: Curves.easeInOut),
    );
    _breatheOpacity = Tween(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _breatheCtrl, curve: Curves.easeInOut),
    );

    // ── mark pop-in at delay 150ms, duration 900ms ────────────────────────────
    _markCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    // Scale: 0.6 → 1.06 → 1.0
    _markScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.6, end: 1.06)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.06, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 40,
      ),
    ]).animate(_markCtrl);
    _markOpacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.0),
        weight: 40,
      ),
    ]).animate(_markCtrl);

    // ── glow pulse at delay 1000ms, repeating ─────────────────────────────────
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    _glowOpacity = Tween(begin: 0.25, end: 0.55).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );
    _glowScale = Tween(begin: 0.95, end: 1.08).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );

    // ── check draw at delay 750ms, duration 500ms ─────────────────────────────
    _checkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _checkProgress = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _checkCtrl, curve: Curves.easeInOut),
    );

    // ── wordmark at delay 550ms, duration 700ms ───────────────────────────────
    _wordCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _wordOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _wordCtrl, curve: Curves.easeOut),
    );
    _wordSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _wordCtrl, curve: Curves.easeOut));

    // ── tagline at delay 950ms, duration 700ms ────────────────────────────────
    _tagCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _tagOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _tagCtrl, curve: Curves.easeOut),
    );
    _tagSlide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _tagCtrl, curve: Curves.easeOut));

    // ── flow underline at delay 1300ms, duration 1100ms ───────────────────────
    _underlineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _underlineScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.0),
        weight: 60,
      ),
    ]).animate(_underlineCtrl);
    _underlineOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 60),
    ]).animate(_underlineCtrl);

    // ── loader fade-in at delay 1500ms ────────────────────────────────────────
    _loaderCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _loaderOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _loaderCtrl, curve: Curves.easeOut),
    );

    // ── 3 dot pulse controllers ───────────────────────────────────────────────
    for (int i = 0; i < 3; i++) {
      final ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1200),
      );
      final op = TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 0.2, end: 1.0), weight: 40),
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.2), weight: 40),
        TweenSequenceItem(tween: Tween(begin: 0.2, end: 0.2), weight: 20),
      ]).animate(CurvedAnimation(parent: ctrl, curve: Curves.easeInOut));
      final sc = TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 0.8, end: 1.15), weight: 40),
        TweenSequenceItem(tween: Tween(begin: 1.15, end: 0.8), weight: 40),
        TweenSequenceItem(tween: Tween(begin: 0.8, end: 0.8), weight: 20),
      ]).animate(CurvedAnimation(parent: ctrl, curve: Curves.easeInOut));
      _dotCtrl.add(ctrl);
      _dotOpacity.add(op);
      _dotScale.add(sc);
    }

    _runSequence();
  }

  Future<void> _runSequence() async {
    // 150ms — mark pop-in
    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    _markCtrl.forward();

    // 550ms — wordmark
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    _wordCtrl.forward();

    // 750ms — check draw
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    _checkCtrl.forward();

    // 950ms — tagline
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    _tagCtrl.forward();

    // 1000ms — glow pulse
    await Future.delayed(const Duration(milliseconds: 50));
    if (!mounted) return;
    _glowCtrl.repeat(reverse: true);
    // Trigger a rebuild now that the glow controller is animating, so the
    // AnimatedBuilder below picks up isAnimating=true on the very next frame
    // instead of waiting for the controller's first tick (avoids a 1-frame
    // flash of the glow's begin-value opacity/scale).
    setState(() {});

    // 1300ms — flow underline (one-shot)
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    _underlineCtrl.forward();

    // 1500ms — loader fade-in then dots
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    _loaderCtrl.forward();

    // Stagger dot animations
    for (int i = 0; i < 3; i++) {
      await Future.delayed(const Duration(milliseconds: 150));
      if (!mounted) return;
      _dotCtrl[i].repeat();
    }

    // Navigate after ~2.8s total
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted || _navigated) return;
    _navigated = true;
    if (mounted) context.go('/');
  }

  @override
  void dispose() {
    _breatheCtrl.dispose();
    _markCtrl.dispose();
    _glowCtrl.dispose();
    _checkCtrl.dispose();
    _wordCtrl.dispose();
    _tagCtrl.dispose();
    _underlineCtrl.dispose();
    _loaderCtrl.dispose();
    for (final c in _dotCtrl) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── ambient breathing glow ─────────────────────────────────────────
          Center(
            child: AnimatedBuilder(
              animation: _breatheCtrl,
              builder: (_, __) => Opacity(
                opacity: _breatheOpacity.value,
                child: Transform.scale(
                  scale: _breatheScale.value,
                  child: Container(
                    width: 560.r,
                    height: 560.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white
                              .withValues(alpha: _SplashAlpha.ambientGlowInner),
                          Colors.white
                              .withValues(alpha: _SplashAlpha.ambientGlowOuter),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.38, 0.70],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── grain / radial highlights ──────────────────────────────────────
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.6, -0.5),
                  radius: 0.9,
                  colors: [
                    Colors.white
                        .withValues(alpha: _SplashAlpha.radialHighlight),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── main content ───────────────────────────────────────────────────
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo mark
              AnimatedBuilder(
                animation: _markCtrl,
                builder: (_, __) => Opacity(
                  opacity: _markOpacity.value,
                  child: Transform.scale(
                    scale: _markScale.value,
                    child: SizedBox(
                      width: 108.r,
                      height: 108.r,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Glow behind mark
                          AnimatedBuilder(
                            animation: _glowCtrl,
                            builder: (_, __) {
                              final active = _glowCtrl.isAnimating;
                              return Opacity(
                                opacity: active ? _glowOpacity.value : 0,
                                child: Transform.scale(
                                  scale: active ? _glowScale.value : 1,
                                  child: Container(
                                    width: 168.r,
                                    height: 168.r,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          Colors.white.withValues(
                                              alpha: _SplashAlpha.markGlow),
                                          Colors.transparent,
                                        ],
                                        stops: const [0, 0.65],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          // Border ring
                          Container(
                            width: 108.r,
                            height: 108.r,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(32.r),
                              border: Border.all(
                                color: Colors.white
                                    .withValues(alpha: _SplashAlpha.ringBorder),
                                width: 1.5,
                              ),
                            ),
                          ),
                          // White rounded square
                          Container(
                            width: 108.r,
                            height: 108.r,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30.r),
                              gradient: const LinearGradient(
                                begin: Alignment(-0.5, -1),
                                end: Alignment(0.5, 1),
                                colors: [
                                  Color(0xFFFFFFFF),
                                  Color(0xFFE9E9EF),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withValues(
                                      alpha: _SplashAlpha.cardShadowLight),
                                  blurRadius: 45,
                                  offset: const Offset(0, 20),
                                ),
                                BoxShadow(
                                  color: Colors.black.withValues(
                                      alpha: _SplashAlpha.cardShadowDark),
                                  blurRadius: 18,
                                  offset: const Offset(0, 4),
                                ),
                                BoxShadow(
                                  color: Colors.white.withValues(
                                      alpha: _SplashAlpha.cardShadowRim),
                                  blurRadius: 0,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Center(
                              child: AnimatedBuilder(
                                animation: _checkProgress,
                                builder: (_, __) => CustomPaint(
                                  size: Size(52.r, 52.r),
                                  painter: _CheckPainter(
                                    progress: _checkProgress.value,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 34.h),

              // Wordmark: "Task" + "Flow" with underline shimmer
              AnimatedBuilder(
                animation: _wordCtrl,
                builder: (_, __) => FadeTransition(
                  opacity: _wordOpacity,
                  child: SlideTransition(
                    position: _wordSlide,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          'Task',
                          style: GoogleFonts.inter(
                            fontSize: 32.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        // "Flow" with animated underline
                        _FlowText(
                          underlineScale: _underlineScale,
                          underlineOpacity: _underlineOpacity,
                          fontSize: 32.sp,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: 10.h),

              // Tagline
              FadeTransition(
                opacity: _tagOpacity,
                child: SlideTransition(
                  position: _tagSlide,
                  child: Text(
                    'Clarity, every day.',
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6A6A6E),
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ── loader dots at bottom ──────────────────────────────────────────
          Positioned(
            bottom: 90.h,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _loaderOpacity,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  return AnimatedBuilder(
                    animation: _dotCtrl[i],
                    builder: (_, __) => Padding(
                      padding: EdgeInsets.symmetric(horizontal: 3.5.w),
                      child: Opacity(
                        opacity: _dotOpacity[i].value,
                        child: Transform.scale(
                          scale: _dotScale[i].value,
                          child: Container(
                            width: 6.r,
                            height: 6.r,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Custom painter for the animated check-mark ─────────────────────────────────

class _CheckPainter extends CustomPainter {
  final double progress;
  const _CheckPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) return;

    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // Checkmark path: "M4 13L9 18L20 6" in a 24×24 viewBox
    // Scale to the given size (52×52 logical pixels from the SVG)
    final scaleX = size.width / 24;
    final scaleY = size.height / 24;

    // Two segments: 4,13 → 9,18 and 9,18 → 20,6
    final p1 = Offset(4 * scaleX, 13 * scaleY);
    final p2 = Offset(9 * scaleX, 18 * scaleY);
    final p3 = Offset(20 * scaleX, 6 * scaleY);

    // Total path length approximation for proportional drawing
    final seg1Len = (p2 - p1).distance; // ~7.07
    final seg2Len = (p3 - p2).distance; // ~13.45
    final totalLen = seg1Len + seg2Len;

    final drawn = progress * totalLen;

    final path = Path();
    path.moveTo(p1.dx, p1.dy);

    if (drawn <= seg1Len) {
      final t = drawn / seg1Len;
      path.lineTo(
        p1.dx + (p2.dx - p1.dx) * t,
        p1.dy + (p2.dy - p1.dy) * t,
      );
    } else {
      path.lineTo(p2.dx, p2.dy);
      final t = (drawn - seg1Len) / seg2Len;
      path.lineTo(
        p2.dx + (p3.dx - p2.dx) * t,
        p2.dy + (p3.dy - p2.dy) * t,
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.progress != progress;
}

// ── "Flow" text with one-time underline shimmer ────────────────────────────────

class _FlowText extends StatelessWidget {
  final Animation<double> underlineScale;
  final Animation<double> underlineOpacity;
  final double fontSize;

  const _FlowText({
    required this.underlineScale,
    required this.underlineOpacity,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: underlineScale,
      builder: (_, __) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Text(
              'Flow',
              style: GoogleFonts.inter(
                fontSize: fontSize,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            // White underline shimmer (behind text, like z-index:-1 in HTML)
            Positioned(
              left: 0,
              right: 0,
              bottom: 3,
              child: Opacity(
                opacity: underlineOpacity.value,
                child: Transform.scale(
                  scaleX: underlineScale.value,
                  child: Container(
                    height: 9,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.0),
                          Colors.white
                              .withValues(alpha: _SplashAlpha.underlineMid),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
