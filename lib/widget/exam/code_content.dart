import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';

/// Một mẩu nội dung câu hỏi sau khi tách phần code ra khỏi phần chữ.
class ContentSegment {
  const ContentSegment.text(this.value)
      : isCode = false,
        isBlock = false,
        language = '';

  const ContentSegment.code(
    this.value, {
    required this.language,
    required this.isBlock,
  }) : isCode = true;

  final String value;
  final bool isCode;

  /// Code khối (xuống dòng riêng, có nền) hay code lọt giữa câu chữ.
  final bool isBlock;

  final String language;
}

/// Tách và tô màu code trong nội dung câu hỏi.
///
/// Bám theo bản web (`frontend_manage/src/components/common/ProcessedHTML.tsx`
/// và `QuestionTypes/HighlightingQuiz.tsx`): dùng highlight.js với chủ đề
/// `github`, nên màu chữ trên mobile trùng với màu sinh viên thấy trên web.
class CodeContent {
  const CodeContent._();

  /// Khối ```lang ... ``` kiểu Markdown.
  static final RegExp _fenced = RegExp(
    r'```([a-zA-Z0-9+#-]*)\r?\n([\s\S]*?)```',
    multiLine: true,
  );

  /// <pre>...</pre>, kèm cả <code> lồng bên trong nếu có.
  static final RegExp _preBlock = RegExp(
    r'<pre[^>]*>([\s\S]*?)</pre>',
    caseSensitive: false,
  );

  /// <code>...</code> nằm giữa dòng chữ.
  static final RegExp _inlineCode = RegExp(
    r'<code[^>]*>([\s\S]*?)</code>',
    caseSensitive: false,
  );

  /// Thẻ HTML bị escape trong đề: `&lt;div&gt;`.
  ///
  /// Đây chính là dạng web coi là code (ProcessedHTML.tsx:27) — đề dạy HTML
  /// hay hỏi "đoạn thẻ sau in ra gì" đều rơi vào đây.
  static final RegExp _escapedTag = RegExp(
    r'&lt;\/?[a-zA-Z][^&]*?&gt;',
  );

  /// Nội dung có code hay không — dùng để bỏ qua toàn bộ nhánh xử lý cho
  /// những câu chữ thuần, vốn là đa số.
  static bool hasCode(String input) =>
      _fenced.hasMatch(input) ||
      _preBlock.hasMatch(input) ||
      _inlineCode.hasMatch(input) ||
      _escapedTag.hasMatch(input);

  /// Cắt [input] thành các mẩu chữ / code theo đúng thứ tự xuất hiện.
  static List<ContentSegment> split(String input) {
    if (input.isEmpty) return const <ContentSegment>[];

    // Xét theo thứ tự: khối trước, rồi mới tới code giữa dòng.
    final List<_Match> matches = <_Match>[];

    void collect(RegExp regex, {required bool block, String? forcedLanguage}) {
      for (final RegExpMatch m in regex.allMatches(input)) {
        // Bỏ qua nếu nằm lọt trong một mẩu đã nhận trước đó.
        final bool overlaps = matches.any(
          (e) => m.start < e.end && m.end > e.start,
        );
        if (overlaps) continue;

        final String raw = regex == _escapedTag
            ? (m.group(0) ?? '')
            : (m.groupCount >= 2 ? (m.group(2) ?? '') : (m.group(1) ?? ''));
        final String declared =
            regex == _fenced ? (m.group(1) ?? '').trim() : '';

        matches.add(_Match(
          start: m.start,
          end: m.end,
          code: unescape(_stripTags(raw)).trim(),
          block: block,
          language: forcedLanguage ??
              (declared.isNotEmpty ? declared : detectLanguage(raw)),
        ));
      }
    }

    collect(_fenced, block: true);
    collect(_preBlock, block: true);
    collect(_inlineCode, block: false);
    collect(_escapedTag, block: false, forcedLanguage: 'xml');

    if (matches.isEmpty) return <ContentSegment>[ContentSegment.text(input)];

    matches.sort((a, b) => a.start.compareTo(b.start));

    final List<ContentSegment> segments = <ContentSegment>[];
    int cursor = 0;

    for (final _Match m in matches) {
      if (m.start > cursor) {
        segments.add(ContentSegment.text(input.substring(cursor, m.start)));
      }
      if (m.code.isNotEmpty) {
        segments.add(ContentSegment.code(
          m.code,
          language: m.language,
          isBlock: m.block,
        ));
      }
      cursor = m.end;
    }

    if (cursor < input.length) {
      segments.add(ContentSegment.text(input.substring(cursor)));
    }

    return segments;
  }

  /// Đoán ngôn ngữ theo đúng thứ tự luật của web
  /// (`HighlightingQuiz.tsx:260-270`).
  static String detectLanguage(String code) {
    final String text = code.toLowerCase();

    if (text.contains('css') ||
        text.contains('display: flex') ||
        text.contains('justify-content')) {
      return 'css';
    }
    if (text.contains('html') || RegExp(r'<\/?[a-z][\s\S]*>').hasMatch(text)) {
      return 'xml';
    }
    if (text.contains('python') ||
        text.contains('def ') ||
        text.contains('print(')) {
      return 'python';
    }
    if (text.contains('java') ||
        text.contains('system.out') ||
        text.contains('public static void')) {
      return 'java';
    }
    if (text.contains('javascript') ||
        text.contains('function ') ||
        text.contains('const ')) {
      return 'javascript';
    }
    return 'plaintext';
  }

  static String unescape(String input) => input
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&nbsp;', ' ')
      // &amp; phải thay CUỐI CÙNG, không thì "&amp;lt;" ra nhầm thành "<".
      .replaceAll('&amp;', '&');

  static String _stripTags(String input) =>
      input.replaceAll(RegExp(r'<\/?code[^>]*>', caseSensitive: false), '');

  /// Code khối: có nền, viền, và cuộn ngang khi dòng dài.
  static Widget buildBlock(String code, String language, double fontSize) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: SingleChildScrollView(
        // Code KHÔNG được tự xuống dòng: thụt đầu dòng là một phần ngữ nghĩa
        // của Python, bẻ dòng là đề sai. Cho cuộn ngang thay vì bẻ.
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: HighlightView(
          code,
          language: language,
          theme: githubTheme,
          padding: EdgeInsets.zero,
          textStyle: TextStyle(
            fontFamily: 'monospace',
            fontSize: fontSize - 1,
            height: 1.45,
          ),
        ),
      ),
    );
  }

  /// Code giữa dòng chữ: bám sát chữ xung quanh, không nền to.
  static Widget buildInline(String code, String language, double fontSize) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(4),
      ),
      child: HighlightView(
        code,
        language: language,
        theme: githubTheme,
        padding: EdgeInsets.zero,
        textStyle: TextStyle(
          fontFamily: 'monospace',
          fontSize: fontSize - 1,
          height: 1.3,
        ),
      ),
    );
  }
}

class _Match {
  const _Match({
    required this.start,
    required this.end,
    required this.code,
    required this.block,
    required this.language,
  });

  final int start;
  final int end;
  final String code;
  final bool block;
  final String language;
}
