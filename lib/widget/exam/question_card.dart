import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../services/base_service.dart';
import '../../services/auth/user_services.dart';
import 'flatten_questions.dart';
import 'code_content.dart';
import 'question_content.dart';

class QuestionCard extends StatelessWidget {
  /// Đơn vị hiển thị của trang này (xem [FlattenedQuestionUnit]).
  final FlattenedQuestionUnit unit;

  /// Tổng số Ô SỐ THỨ TỰ của đề — mẫu số của nhãn "Câu 3-7 / 40", giống web.
  final Map<String, String> answersMap; // questionId -> answerString
  final Function(String questionId, String value)? onAnswerChanged;
  final String? mediaBaseUrl;
  final String studentExamSessionId;
  final UserService userService;
  final bool submitted;

  /// Câu này đang được ghim.
  final bool isPinned;

  /// Bấm ghim / bỏ ghim.
  final VoidCallback? onTogglePin;

  const QuestionCard({
    super.key,
    required this.unit,
    required this.answersMap,
    this.onAnswerChanged,
    this.mediaBaseUrl,
    required this.studentExamSessionId,
    required this.userService,
    this.submitted = false,
    this.isPinned = false,
    this.onTogglePin,
  });

  @override
  Widget build(BuildContext context) {
    // KHÔNG có lề ngang: `exam_screen` đã chừa 8px mỗi bên ở mép màn hình.
    // Bản cũ cộng dồn 10 (màn) + 8 (lề thẻ) + 16 (padding thẻ) = 34px mỗi bên,
    // tức 19% bề ngang máy 360dp bị ăn trước khi chữ đầu tiên được vẽ. Giờ còn
    // 8 + 12 = 20px, đủ để một dòng công thức dài không phải vỡ thêm.
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withAlpha(8),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            QuestionContentWidget(
              unit: unit,
              answersMap: answersMap,
              submitted: submitted,
              mediaBaseUrl: mediaBaseUrl,
              isPinned: isPinned,
              onTogglePin: onTogglePin,
              onOptionChange: (questionId, value) async {
                if (onAnswerChanged != null) {
                  onAnswerChanged!(questionId, value);
                }
                await _saveAnswerToServer(questionId, value);
              },
              renderMixedContent: (text, fontSize) =>
                  _buildMixedContentWithImages(context, text, fontSize),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveAnswerToServer(String questionId, String value) async {
    try {
      final response = await userService.saveAnswer(
        studentExamSessionId: studentExamSessionId,
        key: questionId,
        value: value,
      );

      if (response != null && response.success) {
        debugPrint(
          '✅ Đã lưu câu trả lời: Question $questionId -> Value $value',
        );
      } else if (response == null) {
        // null KHÔNG phải "lỗi không rõ": saveAnswer đã cất câu này vào hàng đợi
        // và sẽ tự gửi lại khi có mạng. Ghi đúng như vậy để đọc log không hoảng.
        debugPrint('⏳ Chưa gửi được, đã đưa vào hàng đợi: Question $questionId');
      } else {
        debugPrint('❌ Máy chủ từ chối lưu đáp án: ${response.message}');
      }
    } catch (e) {
      debugPrint('❌ Exception khi lưu câu trả lời: $e');
    }
  }

  // ================= LATEX & IMAGE RENDERING =================
  /// Vẽ nội dung câu hỏi: tách CODE ra trước, phần còn lại đi tiếp đường cũ
  /// (ảnh + LaTeX + chữ).
  ///
  /// Phải tách code TRƯỚC LaTeX: đoạn code có ký tự `$` (chuỗi PHP, template
  /// JS) sẽ bị bộ tách công thức nuốt mất một khúc nếu để sau.
  Widget _buildMixedContentWithImages(
    BuildContext context,
    String text,
    double fontSize,
  ) {
    if (!CodeContent.hasCode(text)) {
      return _buildContentWithImages(context, text, fontSize);
    }

    final List<Widget> parts = <Widget>[];
    for (final ContentSegment segment in CodeContent.split(text)) {
      if (segment.isCode) {
        parts.add(
          segment.isBlock
              ? CodeContent.buildBlock(
                  segment.value, segment.language, fontSize)
              : Align(
                  alignment: Alignment.centerLeft,
                  child: CodeContent.buildInline(
                      segment.value, segment.language, fontSize),
                ),
        );
        continue;
      }
      if (segment.value.trim().isEmpty) continue;
      parts.add(_buildContentWithImages(context, segment.value, fontSize));
    }

    if (parts.isEmpty) return _buildContentWithImages(context, text, fontSize);
    if (parts.length == 1) return parts.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: parts,
    );
  }

  Widget _buildContentWithImages(
    BuildContext context,
    String text,
    double fontSize,
  ) {
    final imgRegex = RegExp(
      '<img\\s+src=(["\'])([^"\']+)\\1(?:\\s+alt=(["\'])([^"\']*)\\3)?(?:\\s+style=(["\'])([^"\']*)\\5)?\\s*/?>',
      caseSensitive: false,
    );
    final imgMatches = imgRegex.allMatches(text).toList();

    if (imgMatches.isEmpty) {
      return _buildMixedContent(text, fontSize);
    }

    List<Widget> widgets = [];
    int lastEnd = 0;

    for (final imgMatch in imgMatches) {
      if (imgMatch.start > lastEnd) {
        final textBefore = text.substring(lastEnd, imgMatch.start);
        if (textBefore.trim().isNotEmpty) {
          widgets.add(_buildMixedContent(textBefore, fontSize));
          widgets.add(const SizedBox(height: 8));
        }
      }

      final src = imgMatch.group(2) ?? '';
      final alt = imgMatch.group(4) ?? '';
      if (src.isNotEmpty) {
        widgets.add(_buildImageWidget(context, src, alt));
        widgets.add(const SizedBox(height: 8));
      }

      lastEnd = imgMatch.end;
    }

    if (lastEnd < text.length) {
      final textAfter = text.substring(lastEnd);
      if (textAfter.trim().isNotEmpty) {
        widgets.add(_buildMixedContent(textAfter, fontSize));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildImageWidget(BuildContext context, String src, String alt) {
    final isFullUrl = src.startsWith('http://') || src.startsWith('https://');

    List<String> candidates = [];
    if (isFullUrl) {
      candidates.add(src);
    } else {
      try {
        final baseUrl = mediaBaseUrl ?? BaseService.baseUrl;
        final cleanBaseUrl = baseUrl.endsWith('/')
            ? baseUrl.substring(0, baseUrl.length - 1)
            : baseUrl;
        final cleanSrc = src.startsWith('/') ? src.substring(1) : src;

        if (mediaBaseUrl != null && cleanSrc.startsWith('Images/')) {
          candidates.add('$cleanBaseUrl/$cleanSrc');
        } else {
          candidates.add('$cleanBaseUrl/$cleanSrc');
        }

        if (cleanSrc.toLowerCase().endsWith('.jpg')) {
          final pngSrc = cleanSrc.substring(0, cleanSrc.length - 4) + '.png';
          candidates.add('$cleanBaseUrl/$pngSrc');
        }
      } catch (e) {
        candidates.add(src);
      }
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: double.infinity),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _buildNetworkImageWithFallback(context, candidates, alt),
      ),
    );
  }

  Widget _buildNetworkImageWithFallback(
    BuildContext context,
    List<String> urls,
    String alt,
  ) {
    final l10n = AppLocalizations.of(context);
    if (urls.isEmpty) {
      return _imageErrorPlaceholder(l10n.questionImageNoUrl, '');
    }

    final currentUrl = urls.first;
    final remaining = urls.skip(1).toList();

    return Image.network(
      currentUrl,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        if (remaining.isNotEmpty) {
          return _buildNetworkImageWithFallback(context, remaining, alt);
        }
        return _imageErrorPlaceholder(
          alt.isNotEmpty ? alt : l10n.questionImageLoadFailed,
          currentUrl,
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
    );
  }

  Widget _imageErrorPlaceholder(String message, String url) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          HugeIcon(icon: HugeIcons.strokeRoundedImageNotFound01, color: Colors.grey[600], size: 48),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMixedContent(String text, double fontSize) {
    final regex = RegExp(
      r'\$\$([^$]+)\$\$|\$([^$]+)\$|\\\[(.+?)\\\]|\\\((.+?)\\\)|\[latex\](.+?)\[/latex\]',
      dotAll: true,
    );
    final matches = regex.allMatches(text).toList();

    if (matches.isEmpty) {
      return Text(text, style: TextStyle(fontSize: fontSize, height: 1.5));
    }

    List<InlineSpan> spans = [];
    int lastEnd = 0;

    for (final match in matches) {
      if (match.start > lastEnd) {
        spans.add(
          TextSpan(
            text: text.substring(lastEnd, match.start),
            style: TextStyle(fontSize: fontSize, height: 1.5),
          ),
        );
      }

      final latex =
          match.group(1) ??
          match.group(2) ??
          match.group(3) ??
          match.group(4) ??
          match.group(5) ??
          '';

      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Math.tex(
            latex,
            mathStyle: MathStyle.display,
            textStyle: TextStyle(fontSize: fontSize * 1.3),
            onErrorFallback: (err) => Text(
              '\$$latex\$',
              style: TextStyle(fontSize: fontSize, color: Colors.red),
            ),
          ),
        ),
      );

      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(lastEnd),
          style: TextStyle(fontSize: fontSize, height: 1.5),
        ),
      );
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(fontSize: fontSize, color: Colors.black, height: 1.5),
        children: spans,
      ),
    );
  }
}
