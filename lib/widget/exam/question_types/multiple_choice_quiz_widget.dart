import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter/services.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../models/DTOs/originalExamPaperDto.dart';
import '../quiz_theme.dart';

/// MultipleChoice (Chọn nhiều đáp án).
///
/// Ô đánh dấu hình VUÔNG — khác hẳn hình tròn của câu chọn một, nên sinh viên
/// nhận ra "câu này được chọn nhiều đáp án" ngay từ cái liếc đầu tiên, trước cả
/// khi đọc dòng hướng dẫn. Hộp đáp án dùng chung [QuizOptionTile].
///
/// Ô vuông này ĐÃ đủ nói trạng thái chọn (nền đặc màu nhấn), nên không có dấu
/// tích ở đuôi hộp — xem lý do ở [StandardQuizWidget].
class MultipleChoiceQuizWidget extends StatelessWidget {
  final List<AnswerDto> answers;
  final String? selectedAnswerIds; // Comma or pipe separated: "id1|id2"
  final bool submitted;
  final Function(String newSelectedString) onOptionChange;
  final Widget Function(String text, double fontSize) renderMixedContent;

  const MultipleChoiceQuizWidget({
    super.key,
    required this.answers,
    this.selectedAnswerIds,
    required this.submitted,
    required this.onOptionChange,
    required this.renderMixedContent,
  });

  List<String> _getSelectedList() {
    if (selectedAnswerIds == null ||
        selectedAnswerIds!.isEmpty ||
        selectedAnswerIds == '-') {
      return [];
    }
    return selectedAnswerIds!
        .split('|')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty && s != '-')
        .toList();
  }

  void _toggleOption(String answerId) {
    if (submitted) return;
    HapticFeedback.lightImpact();
    final currentList = _getSelectedList();
    if (currentList.contains(answerId)) {
      currentList.remove(answerId);
    } else {
      currentList.add(answerId);
    }
    // Bỏ chọn hết -> danh sách rỗng. Backend trả 400 STUDENT_ANSWER_EMPTY nếu
    // `value` rỗng, nên trường hợp đó PHẢI gửi '-'. ĐỪNG "dọn dẹp" thành
    // currentList.join('|') trần.
    onOptionChange(currentList.isEmpty ? '-' : currentList.join('|'));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final selectedList = _getSelectedList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        QuizInstruction(
          text: l10n.questionMultipleChoiceInstruction,
          icon: HugeIcons.strokeRoundedCheckList,
        ),
        ...List.generate(answers.length, (index) {
          final ans = answers[index];
          final isSelected = selectedList.contains(ans.answerId);

          return QuizOptionTile(
            isSelected: isSelected,
            isDisabled: submitted,
            crossAxisAlignment: CrossAxisAlignment.start,
            onTap: () => _toggleOption(ans.answerId),
            leading: QuizMarker(
              label: quizOptionLabel(ans.order, index),
              isSelected: isSelected,
              isDisabled: submitted,
              shape: QuizMarkerShape.square,
            ),
            child: renderMixedContent(ans.answerContent, QuizFont.option),
          );
        }),
      ],
    );
  }
}
