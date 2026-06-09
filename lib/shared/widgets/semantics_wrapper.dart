import 'package:flutter/material.dart';

class SemanticsWrapper extends StatelessWidget {
  final Widget child;
  final String? label;
  final String? hint;
  final String? value;
  final bool? checked;
  final bool? selected;
  final bool isButton;

  const SemanticsWrapper({
    super.key,
    required this.child,
    this.label,
    this.hint,
    this.value,
    this.checked,
    this.selected,
    this.isButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      hint: hint,
      value: value,
      checked: checked,
      selected: selected,
      button: isButton,
      container: true,
      child: child,
    );
  }
}
