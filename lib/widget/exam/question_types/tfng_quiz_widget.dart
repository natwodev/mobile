import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter/services.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../models/DTOs/originalExamPaperDto.dart';
import '../quiz_theme.dart';

/// True / False / Not Given (Type 4 & 6).
///
/// Một trang chứa NHIỀU mệnh đề, mỗi mệnh đề là một câu hỏi độc lập có bộ đáp
/// án riêng. Rủi ro lớn nhất của loại này là sinh viên bấm nhầm đáp án của mệnh
/// đề bên cạnh, nên bố cục phải trả lời được câu "ô này thuộc mệnh đề nào" chỉ
/// bằng cái nhìn.
///
/// BỐ CỤC MỚI, dựng theo `frontend_manage/src/components/quiz/QuestionTypes/
/// TFNGQuiz.tsx`:
///   * Đáp án là CHIP NGẮN xếp ngang, tự xuống dòng ([QuizChoiceChip]). Đáp án
///     của loại câu này luôn là hai đến ba từ ("Đúng", "Sai", "Không đề cập"):
///     xếp dọc mỗi đáp án một hộp full-width như bản cũ tốn ba dòng cho thứ vừa
///     gọn trong một, và đó là nguồn chiều cao lớn nhất của cả trang.
///   * Ranh giới giữa hai mệnh đề là một ĐƯỜNG KẺ MẢNH, không phải một thẻ có
///     viền. Thẻ ăn thêm 22px bề ngang (viền + padding hai bên) trên mọi mệnh
///     đề, trong khi đường kẻ nói cùng một điều với 0px.
///
/// Số thứ tự mệnh đề nằm trong ô đánh dấu đầu dòng thay vì một dòng tiêu đề
/// riêng — tiết kiệm nguyên một dòng cho mỗi mệnh đề. Số đó vẫn đọc lên được
/// nhờ [Semantics] mang đúng câu "Mệnh đề n" như trước.
///
/// Ô số cũng là ĐỒNG HỒ TIẾN ĐỘ: tô đặc khi mệnh đề đã có đáp án, để trống khi
/// chưa — cuộn nhanh qua trang là thấy ngay còn thiếu chỗ nào.
class TFNGQuizWidget extends StatelessWidget {
  final List<OriginalExamPaperDetailDto> subQuestions;
  final Map<String, String> answersMap; // subQuestionId -> selectedAnswerId
  final bool submitted;
  final Function(String subQuestionId, String answerId) onOptionChange;
  final Widget Function(String text, double fontSize) renderMixedContent;

  const TFNGQuizWidget({
    super.key,
    required this.subQuestions,
    required this.answersMap,
    required this.submitted,
    required this.onOptionChange,
    required this.renderMixedContent,
  });

  @override
  Widget build(BuildContext context) {
    if (subQuestions.isEmpty) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        QuizInstruction(
          text: l10n.questionTfngInstruction,
          icon: HugeIcons.strokeRoundedCheckmarkSquare02,
        ),
        ...List.generate(subQuestions.length, (subIndex) {
          final sub = subQuestions[subIndex];
          final currentAnswerId = answersMap[sub.originalExamPaperDetailId];
          final bool hasAnswer =
              currentAnswerId != null &&
              currentAnswerId.isNotEmpty &&
              currentAnswerId != '-';
          final hasContent =
              sub.questionContent != null && sub.questionContent!.isNotEmpty;
          final bool isLast = subIndex == subQuestions.length - 1;

          return Container(
            // Mệnh đề nay là QuizFont.option nên đệm dọc lùi về `sm`: ranh giới
            // hai mệnh đề đã do đường kẻ nói, đệm dày chỉ kéo dài trang.
            padding: const EdgeInsets.symmetric(vertical: QuizSpacing.sm),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isLast ? Colors.transparent : QuizColors.line,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      label: l10n.questionStatementNumber(subIndex + 1),
                      child: QuizMarker(
                        label: '${subIndex + 1}',
                        isSelected: false,
                        isFilled: hasAnswer,
                        isDisabled: submitted,
                        shape: QuizMarkerShape.ordinal,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: QuizSpacing.md),
                    Expanded(
                      child: hasContent
                          ? renderMixedContent(
                              sub.questionContent!,
                              QuizFont.option,
                            )
                          : Text(
                              l10n.questionStatementNumber(subIndex + 1),
                              style: const TextStyle(
                                fontSize: QuizFont.option,
                                color: QuizColors.inkMuted,
                              ),
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: QuizSpacing.sm),
                // Thụt vào bằng đúng bề ngang ô số + khoảng cách của nó, để
                // hàng chip nằm thẳng cột với chữ mệnh đề phía trên.
                Padding(
                  padding: const EdgeInsets.only(left: 20 + QuizSpacing.md),
                  child: Wrap(
                    spacing: QuizSpacing.sm,
                    runSpacing: QuizSpacing.sm,
                    children: List.generate(sub.answers.length, (index) {
                      final ans = sub.answers[index];
                      final isSelected = currentAnswerId == ans.answerId;

                      return QuizChoiceChip(
                        label: ans.answerContent,
                        isSelected: isSelected,
                        isDisabled: submitted,
                        // key là id CÂU CON (mỗi mệnh đề là một request riêng),
                        // không phải id câu cha. answerId rỗng phải gửi '-' vì
                        // backend chặn `value` rỗng bằng 400
                        // STUDENT_ANSWER_EMPTY.
                        onTap: submitted
                            ? null
                            : () {
                                HapticFeedback.lightImpact();
                                onOptionChange(
                                  sub.originalExamPaperDetailId,
                                  ans.answerId.isEmpty ? '-' : ans.answerId,
                                );
                              },
                      );
                    }),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
