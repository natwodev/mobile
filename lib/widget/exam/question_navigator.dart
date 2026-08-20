import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/DTOs/originalExamPaperDto.dart';
import '../common/app_buttons.dart';
import 'flatten_questions.dart';
import 'quiz_theme.dart';

/// Trạng thái làm bài của MỘT đơn vị hiển thị (một ô trong lưới điều hướng).
enum QuestionAnswerState {
  /// Chưa trả lời câu con nào (hoặc chính câu đó chưa có đáp án).
  unanswered,

  /// Câu nhiều ý (Matching / TFNG) mới trả lời được một phần.
  partial,

  /// Đã trả lời đủ.
  answered,
}

/// Tiến độ làm bài tính trên ĐƠN VỊ HIỂN THỊ (xem [FlattenedQuestionUnit]).
///
/// Lý do lớp này tồn tại: `selectedAnswers` của màn thi chứa lẫn id câu cấp 1
/// và id CÂU CON (Matching / TFNG lưu đáp án theo từng câu con), trong khi lưới
/// điều hướng chỉ có một ô cho cả cụm. Đếm thẳng `selectedAnswers.length` khiến
/// số "đã trả lời" có thể VƯỢT tổng số câu và câu cha không bao giờ được tô
/// "đã làm". Ở đây hai vế luôn được tính trên cùng một tập: danh sách đơn vị
/// hiển thị — đúng tập mà `PageView` và lưới điều hướng đang dùng.
class ExamProgress {
  /// Id của từng đơn vị theo đúng thứ tự hiển thị.
  final List<String> questionIds;

  /// Nhãn số thứ tự của từng đơn vị (`"3"` hoặc `"3-7"`), song song với
  /// [questionIds].
  final List<String> displayLabels;

  /// Trạng thái từng đơn vị, song song với [questionIds].
  final List<QuestionAnswerState> states;

  /// Mọi id có thể nhận đáp án (id đơn vị và id câu con) -> chỉ số đơn vị chứa
  /// nó. Dùng để quy một đáp án lưu lỗi về đúng ô trong lưới.
  final Map<String, int> questionIndexByAnswerId;

  /// Tổng số Ô SỐ THỨ TỰ của đề (đơn vị gộp chiếm nhiều ô).
  ///
  /// Khác [total]: đây là con số đứng sau dấu `/` ở nhãn "Câu 3-7 / 40", giống
  /// hệt web. [total] mới là mẫu số của tiến độ "đã trả lời".
  final int numberedTotal;

  const ExamProgress._({
    required this.questionIds,
    required this.displayLabels,
    required this.states,
    required this.questionIndexByAnswerId,
    required this.numberedTotal,
  });

  static const ExamProgress empty = ExamProgress._(
    questionIds: <String>[],
    displayLabels: <String>[],
    states: <QuestionAnswerState>[],
    questionIndexByAnswerId: <String, int>{},
    numberedTotal: 0,
  );

  /// Tổng số đơn vị hiển thị (= số trang `PageView` = số ô trong lưới).
  int get total => questionIds.length;

  int get answeredCount => _count(QuestionAnswerState.answered);

  int get partialCount => _count(QuestionAnswerState.partial);

  int get unansweredCount => _count(QuestionAnswerState.unanswered);

  int _count(QuestionAnswerState state) =>
      states.where((item) => item == state).length;

  QuestionAnswerState stateAt(int index) {
    if (index < 0 || index >= states.length) {
      return QuestionAnswerState.unanswered;
    }
    return states[index];
  }

  String questionIdAt(int index) {
    if (index < 0 || index >= questionIds.length) return '';
    return questionIds[index];
  }

  /// Nhãn số thứ tự của ô thứ [index] (`"3"` hoặc `"3-7"`).
  String labelAt(int index) {
    if (index < 0 || index >= displayLabels.length) return '${index + 1}';
    return displayLabels[index];
  }

  /// Chỉ số đơn vị chứa [answerId] (bản thân nó hoặc câu cha của nó).
  int? questionIndexOf(String answerId) => questionIndexByAnswerId[answerId];

  /// Dựng tiến độ từ danh sách ĐƠN VỊ HIỂN THỊ và bảng đáp án đang giữ.
  ///
  /// QUY TẮC ĐÁNH DẤU ĐƠN VỊ GỘP (Matching / TFNG): chỉ được coi là "đã làm"
  /// khi TẤT CẢ câu con đã có đáp án; trả lời được một phần thì là
  /// [QuestionAnswerState.partial] và hiển thị bằng màu riêng. Tô xanh khi mới
  /// làm một ý sẽ khiến sinh viên tưởng đã xong và bỏ mất điểm các ý còn lại —
  /// đó là sai lầm nguy hiểm hơn hẳn việc để một câu làm dở trông chưa xong.
  ///
  /// Câu con Reading sau khi làm phẳng là đơn vị ĐỘC LẬP nên tự nó "đã làm"
  /// hay chưa, không còn phụ thuộc các câu con khác cùng đoạn văn.
  factory ExamProgress.fromUnits({
    required List<FlattenedQuestionUnit> units,
    required Map<String, String> answers,
  }) {
    final ids = <String>[];
    final labels = <String>[];
    final states = <QuestionAnswerState>[];
    final indexByAnswerId = <String, int>{};
    var numberedTotal = 0;

    for (var index = 0; index < units.length; index++) {
      final unit = units[index];
      ids.add(unit.id);
      labels.add(unit.displayLabel);
      numberedTotal += unit.span;

      if (unit.id.isNotEmpty) {
        indexByAnswerId.putIfAbsent(unit.id, () => index);
      }

      final answerableIds = unit.answerableIds;
      for (final answerableId in answerableIds) {
        indexByAnswerId.putIfAbsent(answerableId, () => index);
      }

      states.add(_stateOf(unit.id, answerableIds, answers));
    }

    return ExamProgress._(
      questionIds: ids,
      displayLabels: labels,
      states: states,
      questionIndexByAnswerId: indexByAnswerId,
      numberedTotal: numberedTotal,
    );
  }

  /// Dựng tiến độ thẳng từ cây câu hỏi của đề: làm phẳng trước rồi đếm.
  ///
  /// Luôn đi qua [flattenQuestions] để tổng số câu ở đây KHÔNG BAO GIỜ lệch
  /// với số trang `PageView` và số ô trong lưới điều hướng.
  factory ExamProgress.fromQuestions({
    required List<OriginalExamPaperDetailDto> questions,
    required Map<String, String> answers,
  }) {
    return ExamProgress.fromUnits(
      units: flattenQuestions(questions),
      answers: answers,
    );
  }

  static QuestionAnswerState _stateOf(
    String unitId,
    List<String> answerableIds,
    Map<String, String> answers,
  ) {
    // Một số loại câu có thể lưu đáp án gộp ngay trên id câu cha — nếu có thì
    // câu đó coi như đã làm, bất kể cấu trúc câu con.
    if (isAnswerFilled(answers[unitId])) {
      return QuestionAnswerState.answered;
    }

    if (answerableIds.isEmpty) return QuestionAnswerState.unanswered;

    final filled = answerableIds
        .where((id) => isAnswerFilled(answers[id]))
        .length;

    if (filled == 0) return QuestionAnswerState.unanswered;
    if (filled < answerableIds.length) return QuestionAnswerState.partial;
    return QuestionAnswerState.answered;
  }

  /// '-' là ký tự backend dùng cho ô chưa trả lời trong `studentAnswersString`,
  /// nên không được tính là đã làm.
  static bool isAnswerFilled(String? value) {
    if (value == null) return false;
    final trimmed = value.trim();
    return trimmed.isNotEmpty && trimmed != '-';
  }
}

class QuestionNavigator extends StatelessWidget {
  /// Tiến độ đã tính trên câu cấp 1 (xem [ExamProgress]).
  final ExamProgress progress;

  /// Id CÂU CẤP 1 có ít nhất một đáp án chưa lưu được lên máy chủ.

  /// Id câu đã được sinh viên GHIM để quay lại xem sau (chỉ lưu ở máy).
  final Set<String> pinnedQuestionIds;

  final int currentIndex;
  final Function(int index) onQuestionTap;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onSubmit;

  const QuestionNavigator({
    super.key,
    required this.progress,
    required this.currentIndex,
    required this.onQuestionTap,
    this.pinnedQuestionIds = const <String>{},
    this.onPrevious,
    this.onNext,
    this.onSubmit,
  });

  // Ba trạng thái, ba màu — lấy đúng tông của `.question-dot` trên web
  // (`frontend_manage/src/styles/quiz.css`). Ô "đang xem" KHÔNG nằm ở đây vì
  // nó dùng màu nhấn chung [QuizColors.accent] của cả bộ đề thi.
  static const Color _answeredColor = Color(0xFF059669); // emerald 600
  static const Color _answeredSurface = Color(0xFFECFDF5); // emerald 50
  static const Color _partialColor = Color(0xFFB45309); // amber 700
  static const Color _partialSurface = Color(0xFFFEF3C7); // amber 100
  // Tông hổ phách của nút ghim bên web (#f59e0b / #b45309).
  static const Color _pinnedColor = Color(0xFFF59E0B); // amber 500
  static const Color _pinnedSurface = Color(0xFFFFFBEB); // amber 50

  /// Padding NGANG riêng cho hàng nút điều hướng.
  ///
  /// Chuẩn chung là 18 mỗi bên, nhưng ở đây một hàng phải chứa "Trước" + nút
  /// lưới 48 + "Tiếp theo"/"Nộp bài", cả hai nút đều có icon và chữ đã lên 15.
  /// Ở màn 320dp mỗi nút chỉ được ~120px nên 18 làm chữ bị bóp xuống dòng.
  /// Bớt padding là cách duy nhất được phép: cỡ chữ 15 và chiều cao 48 phải
  /// giữ nguyên để nút này không lệch chuẩn so với nút trong hộp thoại.
  static const EdgeInsets _navButtonPadding = EdgeInsets.symmetric(
    horizontal: 6,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isLastQuestion = currentIndex >= progress.total - 1;
    // HugeIcon vẽ bằng SVG nên KHÔNG nhận màu từ `foregroundColor` /
    // `disabledForegroundColor` của nút như [Icon] — phải tự tính và truyền
    // thẳng vào `color`, nếu không icon vẫn đen sì khi nút đã tắt.
    final bool canGoBack = currentIndex > 0 && onPrevious != null;
    final bool canGoForward = isLastQuestion
        ? onSubmit != null
        : onNext != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            // Nút Trước
            Expanded(
              child: ElevatedButton.icon(
                onPressed: currentIndex > 0 ? onPrevious : null,
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowLeft01,
                  size: 18,
                  color: canGoBack ? QuizColors.ink : QuizColors.disabled,
                ),
                label: Text(l10n.questionPrevious),
                // Nút phụ đứng cạnh nút chính: lấy nguyên [AppButtons.secondary]
                // thay cho bản tự chế cũ (bo 8, chữ 13/w600, cao 40) — chính
                // chỗ này làm nút "Nộp bài" ở thanh điều hướng khác nút "Nộp
                // bài" trong hộp thoại.
                style: AppButtons.secondary.copyWith(
                  // Chỉ bớt padding NGANG: ba nút phải nằm trọn một hàng ở màn
                  // 320dp mà chữ đã lên 15. Cỡ chữ và chiều cao 48 giữ nguyên.
                  padding: WidgetStatePropertyAll(_navButtonPadding),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Nút xem danh sách câu hỏi.
            //
            // Vuông 48x48 để cao BẰNG hai nút hai bên (trước đây 44x40 nên nó
            // thấp hơn, hàng nút trông như bị khuyết một miếng ở giữa) và bo
            // theo [AppButtonMetrics.radius] chứ không phải bo 6 của ô đánh dấu
            // trong lưới — đây là nút bấm, không phải một ô trạng thái.
            Container(
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(AppButtonMetrics.radius),
              ),
              child: IconButton(
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedGridView,
                  color: Colors.white,
                  size: 20,
                ),
                // Ghim `standard`: `compact` bớt 8px mỗi chiều nên ô vuông 48
                // co lại còn 40 và nút lại thấp hơn hai nút bên cạnh đúng như
                // trước khi sửa.
                visualDensity: VisualDensity.standard,
                constraints: const BoxConstraints(
                  minWidth: AppButtonMetrics.minHeight,
                  minHeight: AppButtonMetrics.minHeight,
                ),
                padding: EdgeInsets.zero,
                onPressed: () {
                  _showQuestionGrid(context);
                },
                tooltip: l10n.questionViewList,
              ),
            ),
            const SizedBox(width: 8),

            // Nút Tiếp/Nộp bài
            Expanded(
              child: ElevatedButton.icon(
                onPressed: isLastQuestion ? onSubmit : onNext,
                icon: HugeIcon(
                  icon: isLastQuestion
                      ? HugeIcons.strokeRoundedCheckmarkCircle02
                      : HugeIcons.strokeRoundedArrowRight01,
                  size: 18,
                  color: canGoForward ? Colors.white : QuizColors.disabled,
                ),
                label: Text(
                  isLastQuestion ? l10n.questionSubmit : l10n.questionNext,
                ),
                // KHÔNG khai màu / bo góc / cỡ chữ ở đây nữa: nút này ăn thẳng
                // `elevatedButtonTheme` nên "Nộp bài" ở thanh điều hướng và
                // "Nộp bài" trong hộp thoại xác nhận giờ là MỘT nút.
                style: ButtonStyle(
                  // Ngoại lệ duy nhất, và chỉ theo chiều ngang (xem
                  // [_navButtonPadding]).
                  padding: WidgetStatePropertyAll(_navButtonPadding),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Modal DANH SÁCH CÂU HỎI.
  ///
  /// Dựng lại theo lưới `.question-dot` của web (`quiz.css`): ô 32px, bo 6,
  /// viền mảnh, chữ 12 — thay cho lưới 5 cột ô ~60px trước đây. Trên máy 320dp
  /// một hàng giờ chứa 6-7 ô thay vì 5, nên đề 40 câu nhìn hết trong một màn
  /// mà không phải cuộn.
  ///
  /// Ba khối phía trên cũng đã gộp lại: khối thống kê chữ 24px + hàng chú
  /// thích rời trước đây ăn gần 170px chiều cao TRƯỚC KHI thấy ô đầu tiên —
  /// tức nửa modal dùng để nói về lưới thay vì hiện lưới. Nay còn một thanh
  /// tiến độ mảnh kèm hàng chip: chip vừa là số đếm, vừa là chú thích màu.
  void _showQuestionGrid(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        final hasPartial = progress.partialCount > 0;
        final double done = progress.total == 0
            ? 0
            : progress.answeredCount / progress.total;

        return SafeArea(
          top: false,
          child: ConstrainedBox(
            // Trần chứ không phải chiều cao CỐ ĐỊNH: đề 10 câu trước đây vẫn
            // chiếm 70% màn hình với một mảng trắng phía dưới.
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.72,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Thanh kéo: dấu hiệu duy nhất nói "vuốt xuống để đóng".
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(top: QuizSpacing.lg),
                    decoration: BoxDecoration(
                      color: QuizColors.lineStrong,
                      borderRadius: BorderRadius.circular(QuizRadius.pill),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    QuizSpacing.xl,
                    QuizSpacing.md,
                    QuizSpacing.md,
                    0,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.questionListTitle,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: QuizColors.ink,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const HugeIcon(
                          icon: HugeIcons.strokeRoundedCancel01,
                          size: 18,
                          color: QuizColors.inkMuted,
                        ),
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                        padding: EdgeInsets.zero,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                // Tiến độ: một thanh mảnh + tỉ lệ, đọc được trong một cái liếc.
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    QuizSpacing.xl,
                    QuizSpacing.sm,
                    QuizSpacing.xl,
                    0,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(QuizRadius.pill),
                          child: LinearProgressIndicator(
                            value: done,
                            minHeight: 5,
                            backgroundColor: QuizColors.line,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              _answeredColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: QuizSpacing.md),
                      // "12/40" đọc bằng mắt thì rõ, nhưng trình đọc màn hình
                      // chỉ phát ra "mười hai trên bốn mươi" — không biết đó
                      // là số gì. Nhãn ngữ nghĩa nói đủ cả hai vế.
                      Semantics(
                        label:
                            '${l10n.questionStatAnswered} '
                            '${progress.answeredCount} / '
                            '${l10n.questionStatTotal} ${progress.total}',
                        child: ExcludeSemantics(
                          child: Text(
                            '${progress.answeredCount}/${progress.total}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: QuizColors.ink,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Chip vừa đếm vừa chú thích màu — gộp hai khối cũ làm một.
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    QuizSpacing.xl,
                    QuizSpacing.lg,
                    QuizSpacing.xl,
                    QuizSpacing.lg,
                  ),
                  child: Wrap(
                    spacing: QuizSpacing.sm,
                    runSpacing: QuizSpacing.sm,
                    children: [
                      _buildLegendChip(
                        color: _answeredColor,
                        surface: _answeredSurface,
                        label: l10n.questionLegendAnswered,
                        count: progress.answeredCount,
                      ),
                      if (hasPartial)
                        _buildLegendChip(
                          color: _partialColor,
                          surface: _partialSurface,
                          label: l10n.examPartialLabel,
                          count: progress.partialCount,
                        ),
                      _buildLegendChip(
                        color: QuizColors.inkMuted,
                        surface: QuizColors.surfaceRest,
                        label: l10n.questionStatUnanswered,
                        count: progress.unansweredCount,
                      ),
                      if (pinnedQuestionIds.isNotEmpty)
                        _buildLegendChip(
                          color: _pinnedColor,
                          surface: _pinnedSurface,
                          label: l10n.examPinnedLabel,
                          count: pinnedQuestionIds.length,
                        ),
                      _buildLegendChip(
                        color: QuizColors.accent,
                        surface: QuizColors.accentSoft,
                        label: l10n.questionLegendCurrent,
                      ),
                    ],
                  ),
                ),

                Flexible(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      QuizSpacing.xl,
                      0,
                      QuizSpacing.xl,
                      QuizSpacing.xl,
                    ),
                    shrinkWrap: true,
                    // maxCrossAxisExtent thay cho crossAxisCount cố định: máy
                    // rộng tự thêm cột, máy 320dp vẫn giữ ô ≥ 40px (ngưỡng
                    // chạm) thay vì bóp nhỏ lại.
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 52,
                          crossAxisSpacing: QuizSpacing.sm,
                          mainAxisSpacing: QuizSpacing.sm,
                          childAspectRatio: 1,
                        ),
                    itemCount: progress.total,
                    itemBuilder: (context, index) {
                      return _buildGridCell(context, l10n, index);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Ô trong lưới điều hướng.
  ///
  /// Trạng thái nói bằng CẶP nền-nhạt + viền-đậm cùng tông (như `.question-dot`
  /// của web), trừ ô "đang xem" tô đặc màu nhấn. Bản cũ tô ĐẶC cả ba trạng
  /// thái nên lưới 40 câu là 40 khối màu bão hoà cạnh nhau — ô đang xem chìm
  /// nghỉm giữa đám đó, mà đấy lại là ô duy nhất cần tìm thấy ngay.
  Widget _buildGridCell(
    BuildContext context,
    AppLocalizations l10n,
    int index,
  ) {
    final state = progress.stateAt(index);
    final isCurrent = index == currentIndex;
    final isPinned = pinnedQuestionIds.contains(progress.questionIdAt(index));

    final Color background;
    final Color borderColor;
    final Color foreground;

    if (isCurrent) {
      background = QuizColors.accent;
      borderColor = QuizColors.accent;
      foreground = Colors.white;
    } else {
      switch (state) {
        case QuestionAnswerState.answered:
          background = _answeredSurface;
          borderColor = _answeredColor;
          foreground = _answeredColor;
          break;
        case QuestionAnswerState.partial:
          background = _partialSurface;
          borderColor = _partialColor;
          foreground = _partialColor;
          break;
        case QuestionAnswerState.unanswered:
          background = Colors.white;
          borderColor = QuizColors.line;
          foreground = QuizColors.inkMuted;
          break;
      }
    }

    final cell = Container(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(QuizRadius.marker),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: QuizColors.accent.withValues(alpha: 0.2),
                  blurRadius: 0,
                  spreadRadius: 2,
                ),
              ]
            : const [],
      ),
      child: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              // Nhãn "10-15" dài hơn hẳn "10"; thu nhỏ chữ cho vừa ô thay vì
              // để tràn.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  // Ô của đơn vị gộp mang nhãn dạng "3-7" (đúng như web) để
                  // sinh viên biết ô này chứa nhiều số thứ tự, không phải một
                  // câu duy nhất.
                  progress.labelAt(index),
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: foreground,
                  ),
                ),
              ),
            ),
          ),
          // Ghim nằm ở góc TRÁI trên để không tranh chỗ với dấu "chưa lưu".
          if (isPinned)
            Positioned(
              top: 1,
              left: 1,
              child: Container(
                padding: const EdgeInsets.all(1),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const HugeIcon(
                  icon: HugeIcons.strokeRoundedPin,
                  // 12 chứ không phải 10 của bản Material: HugeIcon là SVG nét
                  // 1.5/24, ở cỡ 10 nét chỉ dày 0.6px nên chấm ghim mờ hẳn đi
                  // trong ô 52px. Ép thêm strokeWidth 2.8 đúng như web làm cho
                  // chính dấu ghim này (`QuestionGrid.tsx:166`).
                  size: 12.0,
                  strokeWidth: 2.8,
                  color: _pinnedColor,
                ),
              ),
            ),
        ],
      ),
    );

    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onQuestionTap(index);
      },
      child: cell,
    );
  }

  /// Chip GỘP số đếm và chú thích màu.
  ///
  /// Trước đây hai thứ này là hai khối tách rời nói cùng một chuyện: khối
  /// thống kê cho con số, hàng chú thích cho ý nghĩa màu — sinh viên phải tự
  /// ghép "24" ở trên với ô xanh ở dưới. Gộp lại thì mẫu màu, con số và tên
  /// trạng thái nằm cạnh nhau, không phải ghép gì cả.
  ///
  /// [count] bỏ trống cho trạng thái không đếm được (ô "đang xem" luôn là một).
  Widget _buildLegendChip({
    required Color color,
    required Color surface,
    required String label,
    int? count,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: QuizSpacing.md,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(QuizRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: QuizSpacing.sm),
          Text(
            count == null ? label : '$label $count',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
