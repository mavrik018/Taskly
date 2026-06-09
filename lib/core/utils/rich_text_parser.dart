import 'package:flutter/material.dart';

/// A simple utility to parse inline markdown tags:
/// - **bold**
/// - *italic*
/// - _underline_
/// - ~strikethrough~
class RichTextParser {
  RichTextParser._();

  /// Parses markdown text and returns a list of InlineSpans with styles applied.
  static List<InlineSpan> parse(String text, TextStyle baseStyle) {
    if (text.isEmpty) return [];

    final List<InlineSpan> spans = [];
    final RegExp regExp = RegExp(
      r'(\*\*(.*?)\*\*)|(\*(.*?)\*)|(_(.*?)_)|(~(.*?)~)',
      dotAll: true,
    );

    int lastMatchEnd = 0;

    for (final Match match in regExp.allMatches(text)) {
      // Add plain text before match
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
          style: baseStyle,
        ));
      }

      if (match.group(1) != null) {
        // Bold
        final content = match.group(2) ?? '';
        spans.add(TextSpan(
          text: content,
          style: baseStyle.copyWith(fontWeight: FontWeight.bold),
        ));
      } else if (match.group(3) != null) {
        // Italic
        final content = match.group(4) ?? '';
        spans.add(TextSpan(
          text: content,
          style: baseStyle.copyWith(fontStyle: FontStyle.italic),
        ));
      } else if (match.group(5) != null) {
        // Underline
        final content = match.group(6) ?? '';
        spans.add(TextSpan(
          text: content,
          style: baseStyle.copyWith(decoration: TextDecoration.underline),
        ));
      } else if (match.group(7) != null) {
        // Strikethrough
        final content = match.group(8) ?? '';
        spans.add(TextSpan(
          text: content,
          style: baseStyle.copyWith(decoration: TextDecoration.lineThrough),
        ));
      }

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd),
        style: baseStyle,
      ));
    }

    return spans;
  }
}

/// A custom TextEditingController that highlights markdown formatting inline in real time.
class RichTextEditingController extends TextEditingController {
  final TextStyle baseStyle;

  RichTextEditingController({super.text, required this.baseStyle});

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final textStyle = style ?? baseStyle;
    if (text.isEmpty) return TextSpan(style: textStyle);

    final List<InlineSpan> spans = [];
    final RegExp regExp = RegExp(
      r'(\*\*(.*?)\*\*)|(\*(.*?)\*)|(_(.*?)_)|(~(.*?)~)',
      dotAll: true,
    );

    int lastMatchEnd = 0;
    // Dim styling for the formatting symbols themselves
    final tagStyle = textStyle.copyWith(
      color: textStyle.color?.withOpacity(0.35),
      fontWeight: FontWeight.normal,
      fontStyle: FontStyle.normal,
      decoration: TextDecoration.none,
    );

    for (final Match match in regExp.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
        ));
      }

      if (match.group(1) != null) {
        // **bold**
        spans.add(TextSpan(text: '**', style: tagStyle));
        spans.add(TextSpan(
          text: match.group(2) ?? '',
          style: textStyle.copyWith(fontWeight: FontWeight.bold),
        ));
        spans.add(TextSpan(text: '**', style: tagStyle));
      } else if (match.group(3) != null) {
        // *italic*
        spans.add(TextSpan(text: '*', style: tagStyle));
        spans.add(TextSpan(
          text: match.group(4) ?? '',
          style: textStyle.copyWith(fontStyle: FontStyle.italic),
        ));
        spans.add(TextSpan(text: '*', style: tagStyle));
      } else if (match.group(5) != null) {
        // _underline_
        spans.add(TextSpan(text: '_', style: tagStyle));
        spans.add(TextSpan(
          text: match.group(6) ?? '',
          style: textStyle.copyWith(decoration: TextDecoration.underline),
        ));
        spans.add(TextSpan(text: '_', style: tagStyle));
      } else if (match.group(7) != null) {
        // ~strikethrough~
        spans.add(TextSpan(text: '~', style: tagStyle));
        spans.add(TextSpan(
          text: match.group(8) ?? '',
          style: textStyle.copyWith(decoration: TextDecoration.lineThrough),
        ));
        spans.add(TextSpan(text: '~', style: tagStyle));
      }

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd),
      ));
    }

    return TextSpan(children: spans, style: textStyle);
  }
}
