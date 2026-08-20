import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../l10n/generated/app_localizations.dart';
import 'flatten_questions.dart';
import 'question_type_enum.dart';
import 'quiz_theme.dart';
import 'question_types/standard_quiz_widget.dart';
import 'question_types/multiple_choice_quiz_widget.dart';
import 'question_types/tfng_quiz_widget.dart';
import 'question_types/true_false_quiz_widget.dart';
import 'question_types/matching_quiz_widget.dart';
import 'question_types/fill_in_blank_quiz_widget.dart';
import 'question_types/short_answer_quiz_widget.dart';
import 'question_types/dropdown_quiz_widget.dart';
import 'question_types/ordering_quiz_widget.dart';
import 'question_types/highlighting_quiz_widget.dart';

/// Vẽ MỘT đơn vị hiển thị (xem [FlattenedQuestionUnit]).
///
/// Widget này KHÔNG còn tự liệt kê câu con nữa. Việc tách câu cha thành từng
/// câu con đã nằm ở [flattenQuestions]: câu Reading vào đây đã là một câu con
/// độc lập kèm đoạn văn của cha, còn Matching/TFNG vào đây là cả cụm.
class QuestionContentWidget extends StatelessWidget {
  final FlattenedQuestionUnit unit;
  final Map<String, String> answersMap; // questionId -> answerString
  final bool submitted;
  final String? mediaBaseUrl;
  final Function(String questionId, String answerValue) onOptionChange;
  final Widget Function(String text, double fontSize) renderMixedContent;

  /// Câu này đang được ghim để xem lại.
  final bool isPinned;

  /// Bấm ghim / bỏ ghim. Null thì không vẽ nút — dùng cho các màn chỉ đọc.
  final VoidCallback? onTogglePin;

  const QuestionContentWidget({
    super.key,
    required this.unit,
    required this.answersMap,
    required this.submitted,
    this.mediaBaseUrl,
    required this.onOptionChange,
    required this.renderMixedContent,
    this.isPinned = false,
    this.onTogglePin,
  });

  /// Nội dung câu hỏi có được vẽ TÁCH RIÊNG phía trên phần đáp án hay không.
  ///
  /// FillInBlank / ShortAnswer / Dropdown / Highlighting nhúng thẳng ô nhập
  /// (hoặc vùng bôi) vào giữa nội dung nên widget của chúng tự vẽ phần chữ;
  /// vẽ thêm ở ngoài là lặp nội dung.
  ///
  /// Danh sách này lấy đúng theo web:
  /// `frontend_manage/src/components/quiz/QuestionContent.tsx:268-283`.
  static bool _rendersOwnContent(int type) =>
      type == QuestionType.fillInBlank ||
      type == QuestionType.shortAnswer ||
      type == QuestionType.dropdown ||
      type == QuestionType.highlighting;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = unit.questionType;
    final parentContent = unit.parentContent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hàng nhãn: hai chip PHẲNG, cao 20px. Bản cũ là chip gradient tím
        // cao 30px — to bằng một dòng chữ đề bài mà chỉ nói loại câu, thứ sinh
        // viên đọc đúng một lần rồi thôi. Cỡ chữ 10 (dưới thang [QuizFont])
        // vì đây là NHÃN, không phải thứ để đọc thành câu.
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: QuizSpacing.md,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: QuizColors.accentSoft,
                  borderRadius: BorderRadius.circular(QuizRadius.marker),
                  border: Border.all(color: QuizColors.accentBorder),
                ),
                child: Text(
                  QuestionType.getLabel(context, type),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: QuizColors.accent,
                  ),
                ),
              ),
            ),
            if (unit.difficultyLevel != null) ...[
              const SizedBox(width: QuizSpacing.sm),
              _buildDifficultyBadge(l10n, unit.difficultyLevel!),
            ],
            // Nút ghim nằm CUỐI hàng nhãn, đúng chỗ của web
            // (`QuestionContent.tsx:216-250`). Bài đã nộp thì ẩn: ghim để quay
            // lại làm tiếp, nộp rồi thì không còn gì để quay lại.
            if (onTogglePin != null && !submitted) ...[
              const SizedBox(width: QuizSpacing.sm),
              _buildPinButton(l10n),
            ],
          ],
        ),

        const SizedBox(height: QuizSpacing.md),

        if (unit.isChildQuestion &&
            parentContent != null &&
            parentContent.isNotEmpty)
          // Đoạn văn của câu cha — dựng theo `.parent-context` của web: nền
          // xanh nhạt ĐẶC, viền một màu, nhãn in hoa nhỏ. Không gradient, không
          // ShaderMask: nền pha hai màu làm chữ đoạn văn (thứ phải đọc kỹ
          // nhất cả trang) mất tương phản đều.
          Container(
            margin: const EdgeInsets.only(bottom: QuizSpacing.lg),
            padding: const EdgeInsets.all(QuizSpacing.lg),
            decoration: BoxDecoration(
              color: QuizColors.passageSurface,
              borderRadius: BorderRadius.circular(QuizRadius.card),
              border: Border.all(color: QuizColors.passageBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const HugeIcon(
                      icon: HugeIcons.strokeRoundedBookOpen01,
                      // HugeIcon vẽ SVG với nét mặc định 1.5/24, ở cỡ 12 chỉ
                      // còn 0.75px nên gần như tàng hình cạnh chữ w700. Ép nét
                      // 2.2 đúng như web ép `strokeWidth` cho icon nhỏ.
                      size: 12.0,
                      strokeWidth: 2.2,
                      color: QuizColors.passageLabel,
                    ),
                    const SizedBox(width: QuizSpacing.xs),
                    Flexible(
                      child: Text(
                        l10n.questionReadingPassageLabel.toUpperCase(),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: QuizColors.passageLabel,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: QuizSpacing.sm),
                renderMixedContent(parentContent, QuizFont.passage),
              ],
            ),
          ),

        // ĐỀ BÀI CỦA CHÍNH ĐƠN VỊ ĐANG HIỂN THỊ
        if (unit.questionContent.isNotEmpty && !_rendersOwnContent(type))
          Padding(
            padding: const EdgeInsets.only(bottom: QuizSpacing.lg),
            child: renderMixedContent(unit.questionContent, QuizFont.stem),
          ),

        _renderAnswersInterface(context),
      ],
    );
  }

  String _getDifficultyText(AppLocalizations l10n, int level) {
    switch (level) {
      case 1:
        return l10n.questionDifficultyEasy;
      case 2:
        return l10n.questionDifficultyMedium;
      case 3:
        return l10n.questionDifficultyHard;
      case 4:
        return l10n.questionDifficultyVeryHard;
      default:
        return l10n.questionDifficultyLevel(level);
    }
  }

  /// Nút Ghim / Bỏ ghim của câu đang xem.
  ///
  /// Tông hổ phách lấy từ web: chưa ghim thì nền kem chữ nâu, ghim rồi thì nền
  /// cam chữ trắng. Cỡ bằng hai chip bên trái để hàng nhãn không bị cao lên.
  Widget _buildPinButton(AppLocalizations l10n) {
    const Color amber = Color(0xFFF59E0B);
    const Color amberInk = Color(0xFFB45309);
    const Color amberSurface = Color(0xFFFFFBEB);
    const Color amberBorder = Color(0xFFFDE68A);

    return InkWell(
      onTap: onTogglePin,
      borderRadius: BorderRadius.circular(QuizRadius.marker),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: QuizSpacing.md,
          vertical: 3,
        ),
        decoration: BoxDecoration(
          color: isPinned ? amber : amberSurface,
          borderRadius: BorderRadius.circular(QuizRadius.marker),
          border: Border.all(color: isPinned ? amber : amberBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(
              // Đúng cặp icon của web: đang ghim thì nút mang nghĩa "bỏ ghim"
              // nên vẽ PinOff (`QuestionContent.tsx:248`).
              icon: isPinned
                  ? HugeIcons.strokeRoundedPinOff
                  : HugeIcons.strokeRoundedPin,
              size: 12.0,
              strokeWidth: 2.2,
              color: isPinned ? Colors.white : amberInk,
            ),
            const SizedBox(width: 4),
            Text(
              isPinned ? l10n.examUnpinQuestion : l10n.examPinQuestion,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: isPinned ? Colors.white : amberInk,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyBadge(AppLocalizations l10n, int level) {
    final Color textColor;
    final Color bgColor;

    switch (level) {
      case 1:
        textColor = const Color(0xFF10B981);
        bgColor = const Color(0xFFD1FAE5);
        break;
      case 2:
        textColor = const Color(0xFFF59E0B);
        bgColor = const Color(0xFFFEF3C7);
        break;
      case 3:
        textColor = const Color(0xFFDC2626);
        bgColor = const Color(0xFFFEF2F2);
        break;
      case 4:
        textColor = const Color(0xFF9F1239);
        bgColor = const Color(0xFFFFE4E6);
        break;
      default:
        textColor = QuizColors.inkMuted;
        bgColor = QuizColors.surfaceRest;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: QuizSpacing.md,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(QuizRadius.marker),
        border: Border.all(color: textColor.withValues(alpha: 0.25)),
      ),
      child: Text(
        _getDifficultyText(l10n, level),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: textColor,
        ),
      ),
    );
  }

  /// Vẽ phần trả lời của đơn vị.
  ///
  /// RÀNG BUỘC SỐNG CÒN: mọi lời gọi [onOptionChange] phải mang id của CÂU LÁ.
  /// - Đơn vị thường / câu con Reading: `unit.id` chính là câu lá.
  /// - Đơn vị gộp Matching / TFNG: widget con tự gọi lại với id từng câu con.
  Widget _renderAnswersInterface(BuildContext context) {
    final type = unit.questionType;
    final currentQuestionId = unit.id;

    switch (type) {
      case QuestionType.multipleChoice:
        return MultipleChoiceQuizWidget(
          answers: unit.answers,
          selectedAnswerIds: answersMap[currentQuestionId],
          submitted: submitted,
          onOptionChange: (newVal) => onOptionChange(currentQuestionId, newVal),
          renderMixedContent: renderMixedContent,
        );

      case QuestionType.tfng:
      case QuestionType.trueFalse:
        // Web chỉ vẽ TFNGQuiz khi câu đó CÓ câu con
        // (`isTFNG && currentQuestion.subQuestions`); không có con thì rơi
        // xuống nhánh `default` = StandardQuiz. Câu Đúng/Sai phẳng (type 4,
        // đáp án nằm ngay trên nó) vì thế không bị vẽ ra một khoảng trống.
        if (!unit.isGroup) {
          // Câu Đúng/Sai phẳng: đáp án là một hai từ nên xếp NGANG bằng
          // [TrueFalseQuizWidget], không dùng [StandardQuizWidget] (mỗi đáp án
          // một hộp full-width xếp dọc) — xem lý do trong doc của widget đó.
          return TrueFalseQuizWidget(
            answers: unit.answers,
            selectedAnswerId: answersMap[currentQuestionId],
            submitted: submitted,
            onOptionChange: (newVal) =>
                onOptionChange(currentQuestionId, newVal),
          );
        }
        return TFNGQuizWidget(
          subQuestions: unit.source.childQuestions,
          answersMap: answersMap,
          submitted: submitted,
          onOptionChange: onOptionChange,
          renderMixedContent: renderMixedContent,
        );

      case QuestionType.matching:
        return MatchingQuizWidget(
          currentQuestion: unit.source,
          answersMap: answersMap,
          submitted: submitted,
          onOptionChange: onOptionChange,
          renderMixedContent: renderMixedContent,
        );

      case QuestionType.fillInBlank:
        return FillInBlankQuizWidget(
          questionContent: unit.questionContent,
          answers: unit.answers,
          selectedAnswer: answersMap[currentQuestionId],
          submitted: submitted,
          onOptionChange: (newVal) => onOptionChange(currentQuestionId, newVal),
          renderMixedContent: renderMixedContent,
        );

      case QuestionType.shortAnswer:
        return ShortAnswerQuizWidget(
          questionContent: unit.questionContent,
          selectedAnswer: answersMap[currentQuestionId],
          submitted: submitted,
          onOptionChange: (newVal) => onOptionChange(currentQuestionId, newVal),
          renderMixedContent: renderMixedContent,
        );

      case QuestionType.dropdown:
        return DropdownQuizWidget(
          questionContent: unit.questionContent,
          answers: unit.answers,
          selectedAnswer: answersMap[currentQuestionId],
          submitted: submitted,
          onOptionChange: (newVal) => onOptionChange(currentQuestionId, newVal),
          renderMixedContent: renderMixedContent,
        );

      case QuestionType.ordering:
        return OrderingQuizWidget(
          questionId: currentQuestionId,
          answers: unit.answers,
          selectedAnswer: answersMap[currentQuestionId],
          submitted: submitted,
          onOptionChange: (newVal) => onOptionChange(currentQuestionId, newVal),
          renderMixedContent: renderMixedContent,
        );

      case QuestionType.highlighting:
        return HighlightingQuizWidget(
          questionId: currentQuestionId,
          questionContent: unit.questionContent,
          answers: unit.answers,
          selectedAnswer: answersMap[currentQuestionId],
          submitted: submitted,
          onOptionChange: (newVal) => onOptionChange(currentQuestionId, newVal),
          renderMixedContent: renderMixedContent,
        );

      case QuestionType.singleChoice:
      default:
        return StandardQuizWidget(
          answers: unit.answers,
          selectedAnswerId: answersMap[currentQuestionId],
          submitted: submitted,
          onOptionChange: (newVal) => onOptionChange(currentQuestionId, newVal),
          renderMixedContent: renderMixedContent,
        );
    }
  }
}
