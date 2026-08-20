import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter/services.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../models/DTOs/originalExamPaperDto.dart';
import '../quiz_theme.dart';

/// Câu Đúng/Sai PHẲNG — loại 4 & 6 nhưng KHÔNG có câu con.
///
/// Trước đây loại này rơi xuống [StandardQuizWidget], tức mỗi đáp án một hộp
/// full-width xếp dọc. Đáp án ở đây luôn là một hai từ ("Đúng", "Sai", "Không
/// đề cập"): xếp dọc nghĩa là ba hộp cao 40px + khoảng cách, chiếm gần 150px
/// chiều cao cho thứ vừa gọn trong MỘT dòng, và mỗi hộp lại kéo dài hết bề
/// ngang màn hình để chứa đúng hai chữ cái.
///
/// Nay dùng [QuizChoiceChip] xếp NGANG, tự xuống dòng khi đáp án dài — cùng
/// một ngôn ngữ hình ảnh với cụm mệnh đề trong [TFNGQuizWidget], và bám theo
/// `frontend_manage/src/components/quiz/QuestionTypes/TFNGQuiz.tsx` của web.
///
/// [Wrap] chứ không phải [Row]: đề Không-đề-cập của một số môn viết đáp án dài
/// ("Không có thông tin trong bài đọc"), gặp [Row] là tràn ngang ở 320dp.
class TrueFalseQuizWidget extends StatelessWidget {
  final List<AnswerDto> answers;
  final String? selectedAnswerId;
  final bool submitted;
  final Function(String answerId) onOptionChange;

  const TrueFalseQuizWidget({
    super.key,
    required this.answers,
    this.selectedAnswerId,
    required this.submitted,
    required this.onOptionChange,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        QuizInstruction(
          text: l10n.questionSingleChoiceInstruction,
          icon: HugeIcons.strokeRoundedCheckmarkSquare02,
        ),
        Wrap(
          spacing: QuizSpacing.sm,
          runSpacing: QuizSpacing.sm,
          children: List.generate(answers.length, (index) {
            final ans = answers[index];
            final isSelected = selectedAnswerId == ans.answerId;

            return QuizChoiceChip(
              label: ans.answerContent,
              isSelected: isSelected,
              isDisabled: submitted,
              // answerId có thể là '' khi backend thiếu trường (DTO fallback
              // ''), mà `value` rỗng bị backend chặn bằng 400
              // STUDENT_ANSWER_EMPTY nên phải quy về '-'. ĐỪNG bỏ nhánh này.
              onTap: submitted
                  ? null
                  : () {
                      HapticFeedback.lightImpact();
                      onOptionChange(ans.answerId.isEmpty ? '-' : ans.answerId);
                    },
            );
          }),
        ),
      ],
    );
  }
}
