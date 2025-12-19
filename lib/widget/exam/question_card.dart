import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import '../../models/DTOs/originalExamPaperDto.dart';
import '../../services/auth/user_services.dart';

class QuestionCard extends StatelessWidget {
  final OriginalExamPaperDetailDto question;
  final int questionNumber;
  final int? selectedAnswerId;
  final Function(int answerId)? onAnswerSelected;
  final int studentExamSessionId;
  final UserService userService;

  const QuestionCard({
    super.key,
    required this.question,
    required this.questionNumber,
    this.selectedAnswerId,
    this.onAnswerSelected,
    required this.studentExamSessionId,
    required this.userService,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            _buildQuestionContent(),
            const SizedBox(height: 16),
            ...question.answers.map(_buildAnswerOption),
          ],
        ),
      ),
    );
  }

  // ================= HEADER =================
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Câu $questionNumber',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ================= QUESTION CONTENT =================
  Widget _buildQuestionContent() {
    final content = question.questionContent;
    if (content == null || content.isEmpty) {
      return const SizedBox.shrink();
    }

    // Parse và render text với LaTeX inline
    return _buildMixedContent(content, 16);
  }

  /// Render text có chứa LaTeX inline (dạng $...$, $$...$$, \(...\), \[...\])
  Widget _buildMixedContent(String text, double fontSize) {
    // Regex để tìm $$...$$, $...$, \[...\], \(...\)
    // Thứ tự quan trọng: $$...$$ trước $...$, \[...\] trước \(...\)
    final regex = RegExp(
      r'\$\$([^$]+)\$\$|\$([^$]+)\$|\\\[(.*?)\\\]|\\\((.*?)\\\)',
    );
    final matches = regex.allMatches(text).toList();

    if (matches.isEmpty) {
      // Không có LaTeX, render text thường
      return Text(text, style: TextStyle(fontSize: fontSize, height: 1.5));
    }

    // Có LaTeX, chia thành các phần
    List<InlineSpan> spans = [];
    int lastEnd = 0;

    for (final match in matches) {
      // Text trước LaTeX
      if (match.start > lastEnd) {
        spans.add(
          TextSpan(
            text: text.substring(lastEnd, match.start),
            style: TextStyle(fontSize: fontSize, height: 1.5),
          ),
        );
      }

      // LaTeX content - kiểm tra group nào match
      // group(1): $$...$$ | group(2): $...$ | group(3): \[...\] | group(4): \(...\)
      final latex =
          match.group(1) ??
          match.group(2) ??
          match.group(3) ??
          match.group(4) ??
          '';
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Math.tex(
            latex,
            mathStyle: MathStyle.display, // Dùng display để công thức to hơn
            textStyle: TextStyle(fontSize: fontSize * 1.4), // Tăng thêm 40%
            onErrorFallback: (err) => Text(
              '\$${latex}\$',
              style: TextStyle(fontSize: fontSize, color: Colors.red),
            ),
          ),
        ),
      );

      lastEnd = match.end;
    }

    // Text còn lại sau LaTeX cuối
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

  // ================= ANSWER OPTION =================
  Widget _buildAnswerOption(AnswerDto answer) {
    final isSelected = selectedAnswerId == answer.answerId;

    return GestureDetector(
      onTap: onAnswerSelected != null
          ? () async {
              // Gọi callback để cập nhật UI
              onAnswerSelected!(answer.answerId);

              // Gọi API saveAnswer
              await _saveAnswerToServer(answer.answerId);
            }
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.white,
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            _buildRadio(isSelected),
            const SizedBox(width: 12),
            Expanded(child: _buildAnswerContent(answer.answerContent)),
          ],
        ),
      ),
    );
  }

  // ================= SAVE ANSWER TO SERVER =================
  Future<void> _saveAnswerToServer(int answerId) async {
    try {
      final response = await userService.saveAnswer(
        studentExamSessionId: studentExamSessionId,
        key: question.originalExamPaperDetailId,
        value: answerId,
      );

      if (response != null && response.success) {
        // Lưu thành công
        debugPrint(
          '✅ Đã lưu câu trả lời: Question ${question.originalExamPaperDetailId} -> Answer $answerId',
        );
      } else {
        // Lưu thất bại
        debugPrint(
          '❌ Lỗi lưu câu trả lời: ${response?.message ?? "Unknown error"}',
        );
      }
    } catch (e) {
      debugPrint('❌ Exception khi lưu câu trả lời: $e');
    }
  }

  Widget _buildAnswerContent(String text) {
    return _buildMixedContent(text, 15);
  }

  Widget _buildRadio(bool isSelected) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? Colors.blue : Colors.grey,
          width: 2,
        ),
        color: isSelected ? Colors.blue : Colors.transparent,
      ),
      child: isSelected
          ? const Icon(Icons.check, size: 16, color: Colors.white)
          : null,
    );
  }
}
