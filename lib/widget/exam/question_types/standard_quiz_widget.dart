import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter/services.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../models/DTOs/originalExamPaperDto.dart';
import '../quiz_theme.dart';

/// SingleChoice (Trắc nghiệm 1 đáp án).
///
/// Ô đánh dấu hình TRÒN — hình dạng mã hoá luật trả lời "chỉ được chọn MỘT".
/// Dòng hướng dẫn phía trên nói lại luật đó BẰNG CHỮ: hình dạng ô đánh dấu chỉ
/// đọc được bằng mắt, còn trình đọc màn hình thì không thấy gì cả.
///
/// Hộp đáp án là [QuizOptionTile] và nhãn A/B/C do [quizOptionLabel] sinh —
/// cả hai dùng chung với các loại câu còn lại; đừng thay bằng bản riêng, đó là
/// thứ giữ cho cả bài thi trông như một hệ thống.
///
/// KHÔNG còn dấu tích ở đuôi hộp. Ô đánh dấu đầu dòng khi được chọn đã tô nền
/// đặc màu nhấn, dấu tích chỉ nói lại đúng điều đó lần thứ hai mà ăn 24px bề
/// ngang của MỌI dòng — trên máy 360dp là 7% chiều rộng, đủ để một đáp án dài
/// vỡ thêm một dòng. Web (`StandardQuiz.tsx`) cũng không có dấu này.
class StandardQuizWidget extends StatelessWidget {
  final List<AnswerDto> answers;
  final String? selectedAnswerId;
  final bool submitted;
  final Function(String answerId) onOptionChange;
  final Widget Function(String text, double fontSize) renderMixedContent;

  const StandardQuizWidget({
    super.key,
    required this.answers,
    this.selectedAnswerId,
    required this.submitted,
    required this.onOptionChange,
    required this.renderMixedContent,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      // stretch: mọi hộp đáp án rộng bằng nhau nên mép trái/phải thẳng hàng,
      // mắt chỉ phải quét theo một trục dọc duy nhất.
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        QuizInstruction(
          text: l10n.questionSingleChoiceInstruction,
          icon: HugeIcons.strokeRoundedRadioButton,
        ),
        ...List.generate(answers.length, (index) {
          final ans = answers[index];
          final isSelected = selectedAnswerId == ans.answerId;

          return QuizOptionTile(
            isSelected: isSelected,
            isDisabled: submitted,
            crossAxisAlignment: CrossAxisAlignment.start,
            // answerId có thể là '' khi backend thiếu trường (DTO fallback ''),
            // mà `value` rỗng bị backend chặn bằng 400 STUDENT_ANSWER_EMPTY nên
            // phải quy về '-'. ĐỪNG bỏ nhánh này.
            onTap: submitted
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    onOptionChange(ans.answerId.isEmpty ? '-' : ans.answerId);
                  },
            leading: QuizMarker(
              label: quizOptionLabel(ans.order, index),
              isSelected: isSelected,
              isDisabled: submitted,
              shape: QuizMarkerShape.circle,
            ),
            child: renderMixedContent(ans.answerContent, QuizFont.option),
          );
        }),
      ],
    );
  }
}
