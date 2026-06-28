import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../controllers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/error_mapper.dart';

/// Brand purple — the single AI/premium accent color used across TaskFlow.
/// Lives here as a const since AppColors didn't expose it; move it there
/// (e.g. AppColors.aiAccent) if/when you centralize accent colors.
const _kAccent = Color(0xFF7C6FF0);
const _kAccentLight = Color(0xFF8B7FF5);
const _kAccentDark = Color(0xFF6A5BD8);

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isSignUp = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    HapticFeedback.mediumImpact();

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      if (_isSignUp) {
        final name = _nameController.text.trim();
        await ref.read(authProvider.notifier).signUp(
              email,
              password,
              name: name.isEmpty ? 'Champion' : name,
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Registration successful! Please check your email for confirmation.',
              ),
            ),
          );
          setState(() => _isSignUp = false);
        }
      } else {
        await ref.read(authProvider.notifier).signIn(email, password);
        if (mounted) {
          context.go('/');
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = ErrorMapper.getAuthErrorMessage(e);
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _toggleMode() {
    HapticFeedback.lightImpact();
    setState(() {
      _isSignUp = !_isSignUp;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 8.h),

              // Back button — flat surface, matches Settings/card style
              _BackButton(onTap: () => context.go('/')),

              SizedBox(height: 28.h),

              // Logo mark — same checkmark-in-square as the splash screen
              Container(
                width: 64.r,
                height: 64.r,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18.r),
                  gradient: const LinearGradient(
                    begin: Alignment(-0.5, -1),
                    end: Alignment(0.5, 1),
                    colors: [Color(0xFFFFFFFF), Color(0xFFE9E9EF)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.08),
                      blurRadius: 30,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.check_rounded,
                    color: Colors.black,
                    size: 30.r,
                  ),
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(
                    begin: -0.15,
                    end: 0,
                    curve: Curves.easeOut,
                  ),

              SizedBox(height: 20.h),

              if (_isSignUp) ...[
                _ProPill(),
                SizedBox(height: 18.h),
              ],

              Text(
                _isSignUp ? 'Create your account' : 'Welcome back',
                style: GoogleFonts.inter(
                  fontSize: 25.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.4,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                _isSignUp
                    ? 'Unlock AI features and sync your tasks across every device.'
                    : 'Sign in to access your premium workspace.',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF8A8A8E),
                  height: 1.4,
                ),
              ),
              SizedBox(height: 28.h),

              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_errorMessage != null) ...[
                      _ErrorBanner(message: _errorMessage!),
                      SizedBox(height: 16.h),
                    ],
                    if (_isSignUp) ...[
                      _FieldLabel('FULL NAME'),
                      SizedBox(height: 7.h),
                      _AuthField(
                        controller: _nameController,
                        hint: 'Champion',
                        icon: Icons.person_outline_rounded,
                        textCapitalization: TextCapitalization.words,
                        validator: (v) => v != null && v.trim().isNotEmpty
                            ? null
                            : 'Please enter your name',
                      ),
                      SizedBox(height: 14.h),
                    ],
                    _FieldLabel('EMAIL ADDRESS'),
                    SizedBox(height: 7.h),
                    _AuthField(
                      controller: _emailController,
                      hint: 'you@example.com',
                      icon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => v != null && v.contains('@')
                          ? null
                          : 'Enter a valid email address',
                    ),
                    SizedBox(height: 14.h),
                    _FieldLabel('PASSWORD'),
                    SizedBox(height: 7.h),
                    _AuthField(
                      controller: _passwordController,
                      hint: 'At least 6 characters',
                      icon: Icons.lock_outline_rounded,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: const Color(0xFF5A5A5E),
                          size: 19.r,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                      validator: (v) => v != null && v.length >= 6
                          ? null
                          : 'Password must be at least 6 characters',
                    ),
                    if (!_isSignUp) ...[
                      SizedBox(height: 12.h),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            // TODO: wire up forgot-password flow
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Forgot password?',
                            style: GoogleFonts.inter(
                              fontSize: 12.5.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF9D97D6),
                            ),
                          ),
                        ),
                      ),
                    ],
                    SizedBox(height: _isSignUp ? 20.h : 22.h),
                    _SubmitButton(
                      isLoading: _isLoading,
                      label: _isSignUp ? 'Create Pro account' : 'Sign in',
                      showArrow: _isSignUp,
                      onPressed: _isLoading ? null : _submit,
                    ),
                    SizedBox(height: 18.h),
                    _Divider(),
                    SizedBox(height: 18.h),
                    Center(
                      child: GestureDetector(
                        onTap: _toggleMode,
                        child: RichText(
                          text: TextSpan(
                            style: GoogleFonts.inter(
                              fontSize: 13.5.sp,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF8A8A8E),
                            ),
                            children: [
                              TextSpan(
                                text: _isSignUp
                                    ? 'Already have an account? '
                                    : 'New to TaskFlow Pro? ',
                              ),
                              TextSpan(
                                text:
                                    _isSignUp ? 'Sign in' : 'Create an account',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (_isSignUp) ...[
                      SizedBox(height: 22.h),
                      Text(
                        "By continuing you agree to TaskFlow's Terms and Privacy Policy.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 11.5.sp,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF5A5A5E),
                          height: 1.6,
                        ),
                      ),
                    ],
                    SizedBox(height: 24.h),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(
                    begin: 0.04,
                    end: 0,
                    curve: Curves.easeOut,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Back button ─────────────────────────────────────────────────────────────

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38.r,
        height: 38.r,
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: const Color(0xFF222222)),
        ),
        child: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: const Color(0xFFCFCFD0),
          size: 15.r,
        ),
      ),
    );
  }
}

// ── "TASKFLOW PRO" pill ─────────────────────────────────────────────────────

class _ProPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: _kAccent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: _kAccent.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome_rounded,
              color: const Color(0xFFB3A9FF), size: 12.r),
          SizedBox(width: 6.w),
          Text(
            'TASKFLOW PRO',
            style: GoogleFonts.inter(
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFB3A9FF),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Field label ──────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 12.5.sp,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF8A8A8E),
      ),
    );
  }
}

// ── Auth text field — flat dark surface, no glass blur ──────────────────────

class _AuthField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const _AuthField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.suffixIcon,
    this.validator,
  });

  @override
  State<_AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<_AuthField> {
  final _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _focused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: _focused ? const Color(0xFF181818) : const Color(0xFF141414),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: _focused ? const Color(0xFF3A3A3A) : const Color(0xFF222222),
        ),
      ),
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        obscureText: widget.obscureText,
        keyboardType: widget.keyboardType,
        textCapitalization: widget.textCapitalization,
        validator: widget.validator,
        style: GoogleFonts.inter(
          fontSize: 15.sp,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        cursorColor: _kAccentLight,
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: GoogleFonts.inter(
            fontSize: 15.sp,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF5A5A5E),
          ),
          prefixIcon: Padding(
            padding: EdgeInsets.only(left: 14.w, right: 10.w),
            child:
                Icon(widget.icon, color: const Color(0xFF5A5A5E), size: 18.r),
          ),
          prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
          suffixIcon: widget.suffixIcon,
          filled: false,
          contentPadding: EdgeInsets.symmetric(vertical: 15.h, horizontal: 0),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          errorStyle: GoogleFonts.inter(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.priorityHigh,
          ),
        ),
      ),
    );
  }
}

// ── Error banner ─────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.priorityHigh.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12.r),
        border:
            Border.all(color: AppColors.priorityHigh.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded,
              color: const Color(0xFFFF8B8B), size: 16.r),
          SizedBox(width: 9.w),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFFF8B8B),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Submit button — the one purple/AI accent moment on this screen ─────────

class _SubmitButton extends StatelessWidget {
  final bool isLoading;
  final String label;
  final bool showArrow;
  final VoidCallback? onPressed;

  const _SubmitButton({
    required this.isLoading,
    required this.label,
    required this.showArrow,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56.h,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kAccentLight, _kAccentDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: onPressed,
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 22.r,
                    height: 22.r,
                    child: const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.2,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.inter(
                          fontSize: 15.5.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      if (showArrow) ...[
                        SizedBox(width: 8.w),
                        Icon(Icons.arrow_forward_rounded,
                            color: Colors.white, size: 17.r),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ── "OR" divider ─────────────────────────────────────────────────────────────

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: const Color(0xFF1C1C1C))),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: Text(
            'OR',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF5A5A5E),
            ),
          ),
        ),
        Expanded(child: Container(height: 1, color: const Color(0xFF1C1C1C))),
      ],
    );
  }
}
