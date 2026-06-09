import 'package:flutter/material.dart';

class MinTouchTarget extends StatelessWidget {
  final Widget child;
  final double minWidth;
  final double minHeight;

  const MinTouchTarget({
    super.key,
    required this.child,
    this.minWidth = 48.0,
    this.minHeight = 48.0,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: minWidth,
        minHeight: minHeight,
      ),
      child: Center(
        widthFactor: 1.0,
        heightFactor: 1.0,
        child: child,
      ),
    );
  }
}
