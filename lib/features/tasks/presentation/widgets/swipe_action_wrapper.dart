import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';

class SwipeActionWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback onComplete;
  final VoidCallback onDelete;
  final bool isCompleted;

  const SwipeActionWrapper({
    super.key,
    required this.child,
    required this.onComplete,
    required this.onDelete,
    required this.isCompleted,
  });

  @override
  State<SwipeActionWrapper> createState() => _SwipeActionWrapperState();
}

class _SwipeActionWrapperState extends State<SwipeActionWrapper>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _shrinkController;
  double _dragOffset = 0.0;
  bool _hapticTriggered = false;
  bool _isDeleting = false;

  // Constants
  static const double _deleteRevealWidth = 80.0;
  static const double _completeRevealWidth = 80.0;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _shrinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _slideController.dispose();
    _shrinkController.dispose();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (_isDeleting) return;

    setState(() {
      _dragOffset += details.primaryDelta ?? 0.0;

      // Restrict drag bounds
      if (_dragOffset > 0) {
        // Dragging right (Complete reveal)
        // Add resistance past complete width
        if (_dragOffset > _completeRevealWidth) {
          _dragOffset = _completeRevealWidth + (_dragOffset - _completeRevealWidth) * 0.3;
        }

        // Haptic feedback trigger on crossing threshold
        if (_dragOffset >= _completeRevealWidth / 2 && !_hapticTriggered) {
          HapticFeedback.lightImpact();
          _hapticTriggered = true;
        } else if (_dragOffset < _completeRevealWidth / 2 && _hapticTriggered) {
          _hapticTriggered = false;
        }
      } else {
        // Dragging left (Delete reveal)
        // Add resistance past delete width
        if (_dragOffset < -_deleteRevealWidth) {
          _dragOffset = -_deleteRevealWidth + (_dragOffset + _deleteRevealWidth) * 0.3;
        }

        // Haptic feedback trigger on crossing threshold
        if (_dragOffset.abs() >= _deleteRevealWidth / 2 && !_hapticTriggered) {
          HapticFeedback.lightImpact();
          _hapticTriggered = true;
        } else if (_dragOffset.abs() < _deleteRevealWidth / 2 && _hapticTriggered) {
          _hapticTriggered = false;
        }
      }
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_isDeleting) return;

    if (_dragOffset > 0) {
      // Swipe Right: check if revealed
      if (_dragOffset >= _completeRevealWidth / 2) {
        _snapTo(_completeRevealWidth);
        HapticFeedback.lightImpact();
      } else {
        _snapTo(0.0);
      }
    } else {
      // Swipe Left: check if revealed
      if (_dragOffset.abs() >= _deleteRevealWidth / 2) {
        _snapTo(-_deleteRevealWidth);
        HapticFeedback.lightImpact();
      } else {
        _snapTo(0.0);
      }
    }
    _hapticTriggered = false;
  }

  void _snapTo(double target) {
    final start = _dragOffset;
    final animation = Tween<double>(begin: start, end: target).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _slideController.reset();
    animation.addListener(() {
      setState(() {
        _dragOffset = animation.value;
      });
    });
    _slideController.forward();
  }

  Future<void> _triggerDelete() async {
    setState(() {
      _isDeleting = true;
    });
    HapticFeedback.heavyImpact();
    // Start shrinking card height instantly
    await _shrinkController.forward();
    widget.onDelete();
  }

  void _triggerComplete() {
    HapticFeedback.mediumImpact();
    widget.onComplete();
    _snapTo(0.0);
  }

  @override
  Widget build(BuildContext context) {
    if (_isDeleting) {
      return SizeTransition(
        sizeFactor: Tween<double>(begin: 1.0, end: 0.0).animate(
          CurvedAnimation(parent: _shrinkController, curve: Curves.easeInOut),
        ),
        child: FadeTransition(
          opacity: Tween<double>(begin: 1.0, end: 0.0).animate(
            CurvedAnimation(parent: _shrinkController, curve: Curves.easeInOut),
          ),
          child: widget.child,
        ),
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Background Actions Layer
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return ClipRRect(
                borderRadius: AppRadius.borderLG,
                child: Stack(
                  children: [
                    // Right swipe action (Complete Button sits physically underneath)
                    if (_dragOffset > 0)
                      Positioned(
                        left: 0,
                        top: AppSpacing.xs,
                        bottom: AppSpacing.xs,
                        width: _completeRevealWidth.w,
                        child: GestureDetector(
                          onTap: _triggerComplete,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.priorityLow,
                              borderRadius: BorderRadius.horizontal(
                                left: Radius.circular(16.r),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              widget.isCompleted ? Icons.radio_button_unchecked : Icons.check_circle,
                              color: Colors.white,
                              size: 24.sp,
                            ),
                          ),
                        ),
                      ),

                    // Left swipe action (Delete Button sits physically underneath)
                    if (_dragOffset < 0)
                      Positioned(
                        right: 0,
                        top: AppSpacing.xs,
                        bottom: AppSpacing.xs,
                        width: _deleteRevealWidth.w,
                        child: GestureDetector(
                          onTap: _triggerDelete,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.priorityHigh,
                              borderRadius: BorderRadius.horizontal(
                                right: Radius.circular(16.r),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.delete_outline,
                              color: Colors.white,
                              size: 24.sp,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),

        // Foreground Card Layer
        GestureDetector(
          onHorizontalDragUpdate: _onHorizontalDragUpdate,
          onHorizontalDragEnd: _onHorizontalDragEnd,
          child: Transform.translate(
            offset: Offset(_dragOffset, 0.0),
            child: widget.child,
          ),
        ),
      ],
    );
  }
}
