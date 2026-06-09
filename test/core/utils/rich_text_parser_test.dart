import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/core/utils/rich_text_parser.dart';

void main() {
  const baseStyle = TextStyle(fontSize: 16);

  group('RichTextParser.parse', () {
    test('should return empty list for empty string', () {
      final spans = RichTextParser.parse('', baseStyle);
      expect(spans, isEmpty);
    });

    test('should parse normal text with no formatting', () {
      final spans = RichTextParser.parse('Hello World', baseStyle);
      expect(spans.length, equals(1));
      expect(spans.first, isA<TextSpan>());
      expect((spans.first as TextSpan).text, equals('Hello World'));
      expect((spans.first as TextSpan).style, equals(baseStyle));
    });

    test('should parse bold formatting', () {
      final spans = RichTextParser.parse('Hello **bold** world', baseStyle);
      expect(spans.length, equals(3));
      expect((spans[0] as TextSpan).text, equals('Hello '));
      expect((spans[1] as TextSpan).text, equals('bold'));
      expect((spans[1] as TextSpan).style?.fontWeight, equals(FontWeight.bold));
      expect((spans[2] as TextSpan).text, equals(' world'));
    });

    test('should parse italic formatting', () {
      final spans = RichTextParser.parse('Hello *italic* world', baseStyle);
      expect(spans.length, equals(3));
      expect((spans[1] as TextSpan).text, equals('italic'));
      expect((spans[1] as TextSpan).style?.fontStyle, equals(FontStyle.italic));
    });

    test('should parse underline formatting', () {
      final spans = RichTextParser.parse('Hello _underlined_ world', baseStyle);
      expect(spans.length, equals(3));
      expect((spans[1] as TextSpan).text, equals('underlined'));
      expect((spans[1] as TextSpan).style?.decoration, equals(TextDecoration.underline));
    });

    test('should parse strikethrough formatting', () {
      final spans = RichTextParser.parse('Hello ~strikethrough~ world', baseStyle);
      expect(spans.length, equals(3));
      expect((spans[1] as TextSpan).text, equals('strikethrough'));
      expect((spans[1] as TextSpan).style?.decoration, equals(TextDecoration.lineThrough));
    });
  });
}
