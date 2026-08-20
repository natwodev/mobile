import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../models/DTOs/originalExamPaperDto.dart';
import '../quiz_theme.dart';

/// Matching Quiz Widget (Type 2 - Câu nối).
///
/// Bố cục HAI CỘT CẠNH NHAU kèm ĐƯỜNG NỐI, đúng như web
/// `frontend_manage/src/components/quiz/QuestionTypes/MatchingQuiz.tsx` +
/// `common/MatchingConnections.tsx`: Cột A (các vế câu hỏi) bên trái, Cột B
/// (danh sách đáp án gộp) bên phải, giữa hai cột là một hành lang trống để
/// đường nối đi qua.
///
/// TIỀN BỀ NGANG. Màn 360dp còn ~320dp cho nội dung; chia đôi thì mỗi cột chỉ
/// còn ~148dp. Toàn bộ file này là những lát cắt để chữ vẫn đọc được trong
/// chừng đó chỗ:
///   * Không dùng [QuizOptionTile] cho item trong cột — padding ngang 10 của
///     nó ăn 40px trên tổng 296px của hai cột. Item ở đây tự dựng, padding
///     ngang còn [QuizSpacing.sm], nhưng `minHeight` vẫn 40 nên vùng chạm
///     không nhỏ đi.
///   * Cỡ chữ dùng [QuizFont.option] cho CẢ HAI cột. [QuizFont.passage] được
///     đặt ra cho vế Cột A hồi bố cục còn xếp dọc và mỗi vế chiếm trọn bề
///     ngang màn hình; trong cột 148dp thì nửa px cũng là một lần vỡ dòng.
///   * Ô đánh dấu 18px thay vì 24px.
///
/// CẶP NỐI ĐƯỢC ĐỌC BẰNG BA KÊNH, theo đúng thứ tự quan trọng:
///   1. CON SỐ dùng chung (số thứ tự vế Cột A) in ở cả hai đầu — kênh chính,
///      người mù màu hay màn hình rẻ tiền vẫn dò được từng cặp.
///   2. ĐƯỜNG NỐI vẽ giữa mép phải item Cột A và mép trái item Cột B.
///   3. MÀU của cặp (bảng màu lấy nguyên của web) tô cho đường nối, ô số và
///      viền hai item — kênh phụ, chỉ để mắt bám nhanh khi có nhiều cặp.
///
/// Đường nối KHÔNG tính được bằng công thức: chiều cao mỗi item phụ thuộc nội
/// dung vỡ mấy dòng. Nên mỗi item đeo một [GlobalKey], sau mỗi frame ta đo
/// [RenderBox] của chúng quy về toạ độ của [Stack] bọc ngoài rồi mới vẽ. Chốt
/// chặn chống lặp vô hạn nằm ở [_measureLines]: chỉ `setState` khi danh sách
/// toạ độ mới KHÁC danh sách cũ.
///
/// Toàn bộ trạng thái nói bằng MÀU ĐẶC + VIỀN, không gradient — giống web
/// `frontend_manage/src/styles/quiz.css`.
///
/// DỮ LIỆU GỬI ĐI KHÔNG ĐỔI: mỗi cặp nối vẫn là một request riêng theo id CÂU
/// CON, `onOptionChange(subQuestionId, answerId)`, answerId rỗng quy về '-'.
class MatchingQuizWidget extends StatefulWidget {
  final OriginalExamPaperDetailDto currentQuestion;
  final Map<String, String> answersMap; // subQuestionId -> selectedAnswerId
  final bool submitted;
  final Function(String subQuestionId, String answerId) onOptionChange;
  final Widget Function(String text, double fontSize) renderMixedContent;

  const MatchingQuizWidget({
    super.key,
    required this.currentQuestion,
    required this.answersMap,
    required this.submitted,
    required this.onOptionChange,
    required this.renderMixedContent,
  });

  @override
  State<MatchingQuizWidget> createState() => _MatchingQuizWidgetState();
}

/// Bảng màu phân biệt cặp nối — chép nguyên `getDistinctColor` của web để hai
/// nền tảng cùng tô một cặp bằng một màu.
const List<Color> _pairPalette = <Color>[
  Color(0xFF3B82F6),
  Color(0xFFF59E0B),
  Color(0xFF8B5CF6),
  Color(0xFFEC4899),
  Color(0xFF06B6D4),
  Color(0xFF6366F1),
  Color(0xFFF97316),
  Color(0xFF14B8A6),
  Color(0xFFA855F7),
];

/// Bề rộng hành lang giữa hai cột — chỗ duy nhất đường nối lộ ra (hai item đều
/// có nền đặc nên đè mất phần đường chạy bên dưới chúng). Hẹp hơn ~20px thì
/// đường cong bẹp thành gạch ngang, rộng hơn ~28px thì cột mất chữ.
const double _corridorWidth = 24;

/// Một đường nối đã đo xong, tính theo toạ độ của [Stack] bọc hai cột.
class _MatchLine {
  final Offset start;
  final Offset end;
  final Color color;

  const _MatchLine(this.start, this.end, this.color);

  // So sánh theo GIÁ TRỊ: đây là điều kiện dừng của vòng đo — dựng lại ->
  // đo lại -> danh sách bằng nhau -> không `setState` nữa.
  @override
  bool operator ==(Object other) =>
      other is _MatchLine &&
      other.start == start &&
      other.end == end &&
      other.color == color;

  @override
  int get hashCode => Object.hash(start, end, color);
}

class _MatchingQuizWidgetState extends State<MatchingQuizWidget> {
  String? selectedLeftSubQuestionId;

  /// Toạ độ đường nối của frame trước. Chỉ [_measureLines] được ghi.
  List<_MatchLine> _lines = const <_MatchLine>[];

  /// [Stack] bọc hai cột — gốc toạ độ của mọi phép đo và của [CustomPaint].
  final GlobalKey _boardKey = GlobalKey();

  /// subQuestionId / answerId -> key của item tương ứng. Giữ trong state để
  /// key sống qua các lần dựng lại, nếu không thì mỗi frame lại là một
  /// [GlobalKey] mới và Flutter phải gắn lại cả cây con.
  final Map<String, GlobalKey> _leftItemKeys = <String, GlobalKey>{};
  final Map<String, GlobalKey> _rightItemKeys = <String, GlobalKey>{};

  GlobalKey _leftItemKey(String subId) =>
      _leftItemKeys.putIfAbsent(subId, () => GlobalKey());

  GlobalKey _rightItemKey(String answerId) =>
      _rightItemKeys.putIfAbsent(answerId, () => GlobalKey());

  @override
  void didUpdateWidget(covariant MatchingQuizWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sang câu khác mà vẫn còn "đang cầm" một vế của câu cũ thì cú chạm tiếp
    // theo vào Cột B sẽ gửi đáp án cho một câu con KHÔNG còn trên màn hình.
    final oldId = oldWidget.currentQuestion.originalExamPaperDetailId;
    if (oldId != widget.currentQuestion.originalExamPaperDetailId) {
      selectedLeftSubQuestionId = null;
      _lines = const <_MatchLine>[];
    }
  }

  List<AnswerDto> _getRightOptions() {
    final subQuestions = widget.currentQuestion.childQuestions;
    if (subQuestions.isEmpty) return [];

    final Map<String, AnswerDto> uniqueAnswers = {};
    for (final sub in subQuestions) {
      for (final ans in sub.answers) {
        if (!uniqueAnswers.containsKey(ans.answerId)) {
          uniqueAnswers[ans.answerId] = ans;
        }
      }
    }

    final list = uniqueAnswers.values.toList();
    list.sort((a, b) => a.answerContent.compareTo(b.answerContent));
    return list;
  }

  bool _isLinked(String? answerId) => answerId != null && answerId != '-';

  /// Màu của cặp nối thứ [subIndex]. Sau khi nộp bài mọi cặp về một màu xám:
  /// lúc đó không còn thao tác nào để phân biệt, giữ 9 màu chỉ làm bài đã khoá
  /// trông như vẫn đang sửa được.
  Color _pairColor(int subIndex) => widget.submitted
      ? QuizColors.disabled
      : _pairPalette[subIndex % _pairPalette.length];

  // ================================= ĐO ĐẠC =================================

  /// Đo lại vị trí hai đầu của từng đường nối.
  ///
  /// Gọi trong `addPostFrameCallback` vì trước khi frame vẽ xong thì item chưa
  /// có kích thước. Ba lớp chốt chặn, thiếu lớp nào cũng ra treo hoặc crash:
  ///   * `mounted` — widget có thể đã bị gỡ trong lúc chờ frame.
  ///   * `hasSize` — item vừa được thêm vào cây có [RenderBox] nhưng chưa
  ///     layout; đọc `size` lúc đó là ném assert.
  ///   * so sánh danh sách cũ/mới — `setState` vô điều kiện ở đây là một vòng
  ///     lặp vô hạn (setState -> build -> post frame -> setState).
  void _measureLines() {
    if (!mounted) return;

    final boardBox = _boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (boardBox == null || !boardBox.hasSize) return;

    final subQuestions = widget.currentQuestion.childQuestions;
    final next = <_MatchLine>[];

    for (var i = 0; i < subQuestions.length; i++) {
      final subId = subQuestions[i].originalExamPaperDetailId;
      final answerId = widget.answersMap[subId];
      if (!_isLinked(answerId)) continue;

      final leftBox =
          _leftItemKeys[subId]?.currentContext?.findRenderObject()
              as RenderBox?;
      final rightBox =
          _rightItemKeys[answerId]?.currentContext?.findRenderObject()
              as RenderBox?;
      if (leftBox == null || !leftBox.hasSize) continue;
      if (rightBox == null || !rightBox.hasSize) continue;

      final leftTopLeft = leftBox.localToGlobal(
        Offset.zero,
        ancestor: boardBox,
      );
      final rightTopLeft = rightBox.localToGlobal(
        Offset.zero,
        ancestor: boardBox,
      );

      next.add(
        _MatchLine(
          // Mép PHẢI của item Cột A -> mép TRÁI của item Cột B, cả hai lấy
          // giữa chiều cao item (item cao thấp khác nhau tuỳ nội dung).
          Offset(
            leftTopLeft.dx + leftBox.size.width,
            leftTopLeft.dy + leftBox.size.height / 2,
          ),
          Offset(rightTopLeft.dx, rightTopLeft.dy + rightBox.size.height / 2),
          _pairColor(i),
        ),
      );
    }

    if (listEquals(next, _lines)) return;
    setState(() {
      _lines = next;
    });
  }

  // ================================ GIAO DIỆN ================================

  /// Ô số của một cặp đã nối — nền tô đúng màu đường nối của cặp đó.
  ///
  /// Không dùng được [QuizMarker] ở đây vì nó chỉ có một màu accent duy nhất,
  /// mà cả điểm của bảng màu là mỗi cặp một màu. Hình vuông bo góc giữ nguyên
  /// quy ước "số thứ tự" của [QuizMarkerShape.ordinal].
  Widget _pairBadge(int subIndex) {
    return Container(
      width: 18,
      height: 18,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _pairColor(subIndex),
        borderRadius: BorderRadius.circular(QuizRadius.marker),
        border: Border.all(color: _pairColor(subIndex), width: 1.5),
      ),
      child: Text(
        '${subIndex + 1}',
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          height: 1,
        ),
      ),
    );
  }

  /// Khung một item trong cột.
  ///
  /// [itemKey] gắn thẳng lên [Container] có viền — đó chính là hình chữ nhật
  /// mà đường nối phải chạm vào, nên phải đo đúng nó chứ không phải phần
  /// [Padding] bao ngoài.
  Widget _columnItem({
    required GlobalKey itemKey,
    required VoidCallback? onTap,
    required Color background,
    required Color borderColor,
    required double borderWidth,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: QuizSpacing.betweenOptions),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(QuizRadius.option),
          splashColor: QuizColors.accent.withValues(alpha: 0.06),
          highlightColor: QuizColors.accent.withValues(alpha: 0.03),
          child: Container(
            key: itemKey,
            // Vùng chạm vẫn ≥40px dù padding ngang đã siết còn 6.
            constraints: const BoxConstraints(minHeight: 40),
            padding: const EdgeInsets.symmetric(
              horizontal: QuizSpacing.sm,
              vertical: QuizSpacing.md,
            ),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(QuizRadius.option),
              border: Border.all(color: borderColor, width: borderWidth),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  /// Một vế Cột A.
  Widget _leftItem({
    required int index,
    required OriginalExamPaperDetailDto sub,
    required bool isArmed,
    required bool isLinked,
    required String emptySlotLabel,
  }) {
    final subId = sub.originalExamPaperDetailId;
    final bool locked = widget.submitted;

    final Color background;
    final Color borderColor;
    final double borderWidth;
    if (locked) {
      background = QuizColors.disabledSurface;
      borderColor = QuizColors.line;
      borderWidth = 1;
    } else if (isArmed) {
      // "Đang cầm vế này trên tay": viền accent dày, không phải màu của cặp —
      // đây là trạng thái THAO TÁC, không phải danh tính của cặp nối.
      background = QuizColors.accentSoft;
      borderColor = QuizColors.accent;
      borderWidth = 1.5;
    } else if (isLinked) {
      background = _pairColor(index).withValues(alpha: 0.06);
      borderColor = _pairColor(index);
      borderWidth = 1;
    } else {
      background = Colors.white;
      borderColor = QuizColors.line;
      borderWidth = 1;
    }

    final Widget marker = isLinked
        ? _pairBadge(index)
        : QuizMarker(
            label: '${index + 1}',
            isSelected: isArmed,
            isDisabled: locked,
            shape: QuizMarkerShape.ordinal,
            size: 18,
          );

    return _columnItem(
      itemKey: _leftItemKey(subId),
      onTap: locked
          ? null
          : () {
              setState(() {
                selectedLeftSubQuestionId = isArmed ? null : subId;
              });
            },
      background: background,
      borderColor: borderColor,
      borderWidth: borderWidth,
      child: Row(
        // Nội dung vỡ nhiều dòng trong cột hẹp nên ô số neo theo ĐỈNH, ngang
        // với dòng đầu, thay vì trôi ra giữa khối.
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bố cục mới không còn ô "Chưa nối" nào để in chữ ra — đường nối và
          // con số đã nói thay. Nhãn vẫn phải còn cho trình đọc màn hình, nếu
          // không thì vế chưa nối và vế đã nối nghe y hệt nhau.
          isLinked ? marker : Semantics(label: emptySlotLabel, child: marker),
          const SizedBox(width: QuizSpacing.sm),
          Expanded(
            child: widget.renderMixedContent(
              sub.questionContent ?? '',
              QuizFont.option,
            ),
          ),
        ],
      ),
    );
  }

  /// Một đáp án Cột B.
  ///
  /// [subIndexes] là các vế Cột A đang trỏ vào đáp án này — HAI vế khác nhau
  /// vẫn được phép chọn cùng một đáp án, khi đó item mang hai con số xếp dọc
  /// (xếp ngang thì trong cột 148dp là tràn).
  Widget _rightItem({
    required int index,
    required AnswerDto ans,
    required List<int> subIndexes,
    required bool isArmed,
  }) {
    final bool locked = widget.submitted;
    final bool isConnected = subIndexes.isNotEmpty;
    // Đang cầm một vế trên tay: mọi đáp án còn trống là đích đến hợp lệ, tô
    // nhạt để ngón tay biết chỗ mà hạ xuống.
    final bool isTarget = isArmed && !isConnected && !locked;

    final Color background;
    final Color borderColor;
    final double borderWidth;
    if (locked) {
      background = QuizColors.disabledSurface;
      borderColor = QuizColors.line;
      borderWidth = 1;
    } else if (isConnected) {
      background = _pairColor(subIndexes.first).withValues(alpha: 0.06);
      borderColor = _pairColor(subIndexes.first);
      borderWidth = 1;
    } else if (isTarget) {
      background = QuizColors.accentSoft;
      borderColor = QuizColors.accent;
      borderWidth = 1.5;
    } else {
      background = Colors.white;
      borderColor = QuizColors.line;
      borderWidth = 1;
    }

    return _columnItem(
      itemKey: _rightItemKey(ans.answerId),
      onTap: locked
          ? null
          : () {
              if (selectedLeftSubQuestionId == null) return;
              // key là id CÂU CON (mỗi cặp nối là một request riêng).
              // answerId rỗng phải gửi '-' vì backend chặn `value` rỗng bằng
              // 400 STUDENT_ANSWER_EMPTY.
              widget.onOptionChange(
                selectedLeftSubQuestionId!,
                ans.answerId.isEmpty ? '-' : ans.answerId,
              );
              setState(() {
                selectedLeftSubQuestionId = null;
              });
            },
      background: background,
      borderColor: borderColor,
      borderWidth: borderWidth,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ô đánh dấu nằm ở MÉP TRÁI, đúng chỗ đường nối chạm vào: đã nối thì
          // là con số của cặp, chưa nối thì là nhãn chữ cái của đáp án. Cùng
          // 18px nên nội dung không nhảy ngang lúc vừa nối xong.
          SizedBox(
            width: 18,
            child: isConnected
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final subIndex in subIndexes) ...[
                        if (subIndex != subIndexes.first)
                          const SizedBox(height: 2),
                        _pairBadge(subIndex),
                      ],
                    ],
                  )
                : QuizMarker(
                    label: quizOptionLabel(0, index),
                    isSelected: false,
                    isDisabled: locked,
                    size: 18,
                  ),
          ),
          const SizedBox(width: QuizSpacing.sm),
          Expanded(
            child: widget.renderMixedContent(
              ans.answerContent,
              QuizFont.option,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final subQuestions = widget.currentQuestion.childQuestions;
    final rightOptions = _getRightOptions();

    if (subQuestions.isEmpty) {
      return const SizedBox.shrink();
    }

    // answerId -> các vế Cột A đang trỏ tới nó.
    final linkedSubIndexes = <String, List<int>>{};
    var linkedCount = 0;
    for (var i = 0; i < subQuestions.length; i++) {
      final answerId =
          widget.answersMap[subQuestions[i].originalExamPaperDetailId];
      if (!_isLinked(answerId)) continue;
      linkedCount++;
      linkedSubIndexes.putIfAbsent(answerId!, () => <int>[]).add(i);
    }

    final bool isArmed = selectedLeftSubQuestionId != null && !widget.submitted;

    // Chiều cao item chỉ biết được sau khi frame vẽ xong, nên phép đo luôn
    // chậm một frame so với lần dựng này. [_measureLines] tự cắt vòng lặp khi
    // toạ độ không đổi.
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureLines());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        QuizInstruction(
          icon: HugeIcons.strokeRoundedLink01,
          text: l10n.questionMatchingInstruction,
        ),

        // Chip đếm + bước tiếp theo nằm TRÊN hai cột chứ không nhét vào tiêu
        // đề cột: cột chỉ rộng ~148dp, thêm chip vào đó là tiêu đề bị cắt cụt.
        Row(
          children: [
            QuizCountChip(
              label: l10n.questionMatchingLinkedCount(
                linkedCount,
                subQuestions.length,
              ),
              icon: HugeIcons.strokeRoundedLink01,
              isComplete: linkedCount == subQuestions.length,
            ),
            const SizedBox(width: QuizSpacing.sm),
            // Chưa cầm vế nào thì nói thẳng bước tiếp theo bằng CHỮ, thay vì
            // để sinh viên bấm vào Cột B rồi không thấy gì xảy ra. Dòng này
            // GIỮ CHỖ kể cả khi ẩn để hai cột không nhảy lên đúng lúc ngón tay
            // sắp chạm xuống.
            Expanded(
              child: Visibility(
                visible: !isArmed && !widget.submitted,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: Text(
                  l10n.questionMatchingPickColumnAFirst,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: QuizFont.caption,
                    fontWeight: FontWeight.w600,
                    color: QuizColors.inkMuted,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: QuizSpacing.md),

        // ----------------------------- HAI CỘT -----------------------------
        // [CustomPaint] nằm DƯỚI hai cột trong [Stack]: item nào cũng có nền
        // đặc nên đường nối chỉ lộ ra ở hành lang giữa hai cột, đúng như web
        // (ở web các item có `z-index` cao hơn lớp SVG).
        Stack(
          key: _boardKey,
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _MatchingLinePainter(_lines)),
              ),
            ),
            Row(
              // Hai cột dài ngắn khác nhau; neo theo đỉnh để dòng đầu của hai
              // cột thẳng hàng.
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      QuizSectionHeader(label: l10n.questionMatchingColumnA),
                      ...List.generate(subQuestions.length, (idx) {
                        final sub = subQuestions[idx];
                        final subId = sub.originalExamPaperDetailId;
                        return _leftItem(
                          index: idx,
                          sub: sub,
                          isArmed: selectedLeftSubQuestionId == subId,
                          isLinked: _isLinked(widget.answersMap[subId]),
                          emptySlotLabel: l10n.questionMatchingEmptySlot,
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(width: _corridorWidth),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      QuizSectionHeader(
                        label: l10n.questionMatchingColumnB,
                        isActive: isArmed,
                      ),
                      ...List.generate(rightOptions.length, (idx) {
                        final ans = rightOptions[idx];
                        return _rightItem(
                          index: idx,
                          ans: ans,
                          subIndexes:
                              linkedSubIndexes[ans.answerId] ?? const <int>[],
                          isArmed: isArmed,
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

/// Vẽ đường nối giữa hai cột.
///
/// Đường cong Bezier với điểm điều khiển lệch ngang `deltaX * 0.4` — cùng công
/// thức với `MatchingConnections.tsx` — nên đường rời item Cột A theo phương
/// ngang, đủ để hai cặp có tung độ gần nhau không chồng lên nhau. Hai đầu chấm
/// tròn đặc, đúng `marker` hai đầu của bản web.
class _MatchingLinePainter extends CustomPainter {
  final List<_MatchLine> lines;

  const _MatchingLinePainter(this.lines);

  @override
  void paint(Canvas canvas, Size size) {
    for (final line in lines) {
      final stroke = Paint()
        ..color = line.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true;

      final controlOffset = (line.end.dx - line.start.dx) * 0.4;
      final path = Path()
        ..moveTo(line.start.dx, line.start.dy)
        ..cubicTo(
          line.start.dx + controlOffset,
          line.start.dy,
          line.end.dx - controlOffset,
          line.end.dy,
          line.end.dx,
          line.end.dy,
        );
      canvas.drawPath(path, stroke);

      final dot = Paint()
        ..color = line.color
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;
      canvas.drawCircle(line.start, 3, dot);
      canvas.drawCircle(line.end, 3, dot);
    }
  }

  @override
  bool shouldRepaint(_MatchingLinePainter oldDelegate) =>
      !listEquals(oldDelegate.lines, lines);
}
