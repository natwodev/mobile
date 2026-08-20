import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../models/DTOs/originalExamPaperDto.dart';
import '../quiz_theme.dart';

/// Dropdown Quiz Widget (Type 9 - Chọn từ Menu thả xuống trong đoạn văn)
///
/// Menu xổ xuống của Material vẽ danh sách ngay tại chỗ, nên một đáp án dài
/// chen giữa dòng chữ là hỏng bố cục trên máy nhỏ. Ở đây ô trống trong đề chỉ
/// còn là một cái nút mang số thứ tự + đáp án đang chọn; bấm vào thì danh sách
/// mở ra ở tấm trượt dưới màn hình, nơi mỗi lựa chọn được vẽ bằng
/// [QuizOptionTile] với ô đánh dấu TRÒN — đúng luật "mỗi ô trống chọn một".
///
/// Toàn bộ file PHẲNG: không gradient, không bóng khi chọn. Trạng thái chỉ nói
/// bằng nền + viền, đúng bảng màu của [QuizColors] (bám theo web `quiz.css`).
class DropdownQuizWidget extends StatefulWidget {
  final String questionContent;
  final List<AnswerDto> answers;
  final String? selectedAnswer; // Format: "1:answerId1|2:answerId2"
  final bool submitted;
  final Function(String answerString) onOptionChange;
  final Widget Function(String text, double fontSize) renderMixedContent;

  const DropdownQuizWidget({
    super.key,
    required this.questionContent,
    required this.answers,
    this.selectedAnswer,
    required this.submitted,
    required this.onOptionChange,
    required this.renderMixedContent,
  });

  @override
  State<DropdownQuizWidget> createState() => _DropdownQuizWidgetState();
}

class _DropdownQuizWidgetState extends State<DropdownQuizWidget> {
  /// Ô trống trong đề: `(1)`, `_(1)_` hoặc `___(1)___`.
  ///
  /// KHÔNG tách đề bằng `String.split(_blankPattern)`. `split` của Dart VỨT BỎ
  /// phần phân tách kể cả khi mẫu có nhóm bắt — khác hẳn `String.prototype
  /// .split` của JavaScript (bản web port sang đây) vốn GIỮ LẠI nhóm bắt được.
  /// Vì thế bản cũ vẽ ra đề bài KHÔNG CÓ Ô CHỌN NÀO: `parts` chỉ còn các mẩu
  /// chữ, `firstMatch(part)` không khớp gì, câu hỏi thành không thể trả lời.
  /// Phải duyệt bằng `allMatches` rồi tự ghép xen kẽ chữ và ô trống.
  static final RegExp _blankPattern = RegExp(
    r'(?:_{1,3})?\((\d+)\)(?:_{1,3})?',
  );

  // blankIndex -> answerId
  Map<int, String> selectedBlanks = {};

  /// Ô trống đang mở danh sách (chỉ để tô sáng).
  int? _openBlank;

  @override
  void initState() {
    super.initState();
    _parseInitialAnswer();
  }

  @override
  void didUpdateWidget(covariant DropdownQuizWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedAnswer != oldWidget.selectedAnswer) {
      _parseInitialAnswer();
    }
  }

  void _parseInitialAnswer() {
    if (widget.selectedAnswer != null &&
        widget.selectedAnswer!.isNotEmpty &&
        widget.selectedAnswer != '-') {
      final Map<int, String> parsed = {};
      final parts = widget.selectedAnswer!.split('|');
      for (final part in parts) {
        final colonIndex = part.indexOf(':');
        if (colonIndex != -1) {
          final idxStr = part.substring(0, colonIndex);
          final ansId = part.substring(colonIndex + 1);
          final idx = int.tryParse(idxStr);
          if (idx != null && ansId.isNotEmpty) {
            parsed[idx] = ansId;
          }
        }
      }
      setState(() {
        selectedBlanks = parsed;
      });
    } else {
      setState(() {
        selectedBlanks = {};
      });
    }
  }

  Map<int, List<AnswerDto>> _getBlankToAnswersMap() {
    final Map<int, List<AnswerDto>> map = {};
    for (final ans in widget.answers) {
      final match = RegExp(r'\[\[B(\d+)\]\]').firstMatch(ans.answerContent);
      final blankIndex = match != null ? int.parse(match.group(1)!) : 1;
      if (!map.containsKey(blankIndex)) {
        map[blankIndex] = [];
      }
      map[blankIndex]!.add(ans);
    }
    return map;
  }

  String _cleanOptionText(String content) {
    return content.replaceAll(RegExp(r'\[\[B\d+\]\]\s*'), '').trim();
  }

  void _onDropdownChanged(int blankIndex, String? newAnswerId) {
    if (widget.submitted) return;
    setState(() {
      if (newAnswerId == null || newAnswerId.isEmpty) {
        selectedBlanks.remove(blankIndex);
      } else {
        selectedBlanks[blankIndex] = newAnswerId;
      }
    });

    // Bỏ ô chưa chọn answerId thật, tránh sinh mảnh vô nghĩa dạng "1:".
    final String str = selectedBlanks.entries
        .where((e) => e.value.isNotEmpty)
        .map((e) => '${e.key}:${e.value}')
        .join('|');
    // Bỏ chọn hết -> chuỗi rỗng, mà backend chặn `value` rỗng bằng 400
    // STUDENT_ANSWER_EMPTY nên PHẢI gửi '-'. ĐỪNG bỏ nhánh này.
    widget.onOptionChange(str.isEmpty ? '-' : str);
  }

  /// Mở danh sách lựa chọn của một ô trống.
  ///
  /// Kết quả trả về: null = đóng mà không chọn gì (giữ nguyên đáp án cũ),
  /// chuỗi rỗng = bỏ chọn, còn lại = answerId. Cả hai trường hợp sau đều đi
  /// qua [_onDropdownChanged] nên chuỗi gửi lên vẫn do đúng một chỗ sinh ra.
  Future<void> _openOptions(
    BuildContext context,
    int blankIndex,
    List<AnswerDto> options,
  ) async {
    if (widget.submitted) return;

    final l10n = AppLocalizations.of(context);
    final String? current = selectedBlanks[blankIndex];

    setState(() => _openBlank = blankIndex);

    final String? picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetContext).size.height * 0.7,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thanh kéo: một vạch xám đặc, không tô chuyển màu.
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.symmetric(
                      vertical: QuizSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: QuizColors.lineStrong,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Đầu tấm trượt: cho biết đang chọn cho ô trống số mấy.
                // Nền xanh nhạt đặc + viền, cùng tông với hộp đáp án đang chọn.
                Container(
                  margin: const EdgeInsets.fromLTRB(
                    QuizSpacing.md,
                    0,
                    QuizSpacing.md,
                    QuizSpacing.md,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: QuizSpacing.md,
                    vertical: QuizSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: QuizColors.accentSoft,
                    borderRadius: BorderRadius.circular(QuizRadius.option),
                    border: Border.all(color: QuizColors.accentBorder),
                  ),
                  child: Row(
                    children: [
                      // isFilled: con số chỉ là ĐỊNH DANH ô trống đang mở,
                      // không phải một lựa chọn của sinh viên.
                      QuizMarker(
                        label: '$blankIndex',
                        isSelected: false,
                        isFilled: true,
                        shape: QuizMarkerShape.ordinal,
                        size: 22,
                      ),
                      const SizedBox(width: QuizSpacing.sm),
                      Expanded(
                        child: Text(
                          l10n.questionDropdownHint(blankIndex),
                          style: const TextStyle(
                            fontSize: QuizFont.caption,
                            fontWeight: FontWeight.w700,
                            color: QuizColors.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(
                      QuizSpacing.md,
                      0,
                      QuizSpacing.md,
                      QuizSpacing.md,
                    ),
                    children: [
                      for (int i = 0; i < options.length; i++)
                        QuizOptionTile(
                          isSelected: options[i].answerId == current,
                          onTap: () => Navigator.of(
                            sheetContext,
                          ).pop(options[i].answerId),
                          leading: QuizMarker(
                            label: quizOptionLabel(0, i),
                            isSelected: options[i].answerId == current,
                          ),
                          child: widget.renderMixedContent(
                            _cleanOptionText(options[i].answerContent),
                            QuizFont.option,
                          ),
                        ),
                      // Hàng bỏ chọn: chuỗi rỗng -> _onDropdownChanged gỡ ô
                      // này khỏi đáp án.
                      QuizOptionTile(
                        isSelected: current == null,
                        onTap: () => Navigator.of(sheetContext).pop(''),
                        leading: const SizedBox(
                          width: 22,
                          height: 22,
                          child: HugeIcon(
                            icon: HugeIcons.strokeRoundedMinusSignCircle,
                            size: 18,
                            color: QuizColors.inkMuted,
                          ),
                        ),
                        child: Text(
                          l10n.questionDropdownPlaceholder,
                          style: const TextStyle(
                            fontSize: QuizFont.caption,
                            color: QuizColors.inkMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted) return;
    setState(() => _openBlank = null);
    if (picked == null) return; // đóng tấm trượt, không đổi gì
    _onDropdownChanged(blankIndex, picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final blankToAnswers = _getBlankToAnswersMap();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ô trống nằm lọt trong mạch chữ nên rất dễ bị đọc lướt qua; dòng này
        // nói thẳng rằng chúng bấm được.
        QuizInstruction(
          icon: HugeIcons.strokeRoundedCircleArrowDown01,
          text: l10n.questionDropdownInstruction,
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            // Nút chọn không được rộng hơn lòng khung, nếu không đáp án dài sẽ
            // đẩy đoạn văn tràn ngang trên máy 320dp. Trừ đúng padding đang
            // đặt cho khung dưới đây (QuizSpacing.md mỗi bên).
            final double slotMaxWidth =
                constraints.maxWidth - QuizSpacing.md * 2;
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(QuizSpacing.md),
              // Nền xám rất nhạt + viền 1px: đủ tách đoạn văn khỏi phần còn
              // lại mà không cạnh tranh màu với ô trống đang chọn.
              decoration: BoxDecoration(
                color: QuizColors.surfaceRest,
                borderRadius: BorderRadius.circular(QuizRadius.card),
                border: Border.all(color: QuizColors.line),
              ),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: QuizSpacing.xs,
                runSpacing: QuizSpacing.xs,
                children: _buildPassageChildren(blankToAnswers, slotMaxWidth),
              ),
            );
          },
        ),
      ],
    );
  }

  /// Ghép xen kẽ: chữ, ô chọn, chữ, ô chọn... theo đúng thứ tự trong đề.
  List<Widget> _buildPassageChildren(
    Map<int, List<AnswerDto>> blankToAnswers,
    double slotMaxWidth,
  ) {
    final String content = widget.questionContent;
    final List<Widget> children = [];
    int last = 0;
    for (final m in _blankPattern.allMatches(content)) {
      if (m.start > last) {
        children.add(
          widget.renderMixedContent(
            content.substring(last, m.start),
            QuizFont.stem,
          ),
        );
      }
      children.add(
        _buildBlankSlot(int.parse(m.group(1)!), blankToAnswers, slotMaxWidth),
      );
      last = m.end;
    }
    if (last < content.length) {
      children.add(
        widget.renderMixedContent(content.substring(last), QuizFont.stem),
      );
    }
    return children;
  }

  Widget _buildBlankSlot(
    int blankNum,
    Map<int, List<AnswerDto>> blankToAnswers,
    double slotMaxWidth,
  ) {
    final options = blankToAnswers[blankNum] ?? [];
    final currentValue = selectedBlanks[blankNum];

    // Đáp án đã lưu có thể không còn trong danh sách (đề đổi) -> coi như trống,
    // đúng như nhánh `options.any(...) ? currentValue : null` trước đây.
    String? currentText;
    for (final opt in options) {
      if (opt.answerId == currentValue) {
        currentText = _cleanOptionText(opt.answerContent);
        break;
      }
    }

    final l10n = AppLocalizations.of(context);

    return _DropdownSlot(
      index: blankNum,
      filledText: currentText,
      // Ô chưa chọn trước đây chỉ là một gạch chân câm; nay nó tự nói ra rằng
      // đây là chỗ phải chọn đáp án.
      emptyHint: l10n.questionDropdownPlaceholder,
      menuLabel: l10n.questionDropdownHint(blankNum),
      isFocused: _openBlank == blankNum,
      isDisabled: widget.submitted,
      maxWidth: slotMaxWidth,
      onTap: () => _openOptions(context, blankNum, options),
    );
  }
}

/// Nút chọn nằm giữa dòng chữ của đề bài.
///
/// Vì sao KHÔNG dùng [QuizBlankSlot] dùng chung như hai widget nhập liệu kia:
/// ô này phải mang mũi tên xổ xuống NGAY CẢ KHI CHƯA CHỌN GÌ — đó là thứ duy
/// nhất cho biết chạm vào sẽ mở ra một danh sách chứ không phải bật bàn phím.
/// [QuizBlankSlot] chưa có chỗ đặt widget ở đuôi, mà nhét mũi tên vào tham số
/// `filled` thì mọi ô CÒN TRỐNG sẽ hiện ra y như ô đã chọn xong (viền và ô số
/// đều tô màu nhấn) — đúng thứ sinh viên cần phân biệt nhất. Màu, bo góc,
/// khoảng cách và ô số vẫn lấy nguyên từ quiz_theme, và cũng phẳng như ở đó:
/// đã chọn = nền [QuizColors.accentSoft] + viền [QuizColors.accent], KHÔNG bóng.
class _DropdownSlot extends StatelessWidget {
  final int index;

  /// null = chưa chọn.
  final String? filledText;

  /// Chữ hiện khi chưa chọn gì.
  final String emptyHint;

  /// Nhãn cho trình đọc màn hình của mũi tên xổ xuống.
  final String menuLabel;

  /// Đang mở danh sách lựa chọn.
  final bool isFocused;
  final bool isDisabled;
  final double maxWidth;
  final VoidCallback? onTap;

  const _DropdownSlot({
    required this.index,
    required this.filledText,
    required this.emptyHint,
    required this.menuLabel,
    required this.isFocused,
    required this.isDisabled,
    required this.maxWidth,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isFilled = filledText != null && filledText!.isNotEmpty;
    final bool highlighted = (isFilled || isFocused) && !isDisabled;
    // Đang chọn thì viền đã đủ tách ô khỏi nền; thêm bóng chỉ làm dòng chữ
    // quanh nó phải giãn ra để chừa chỗ cho vệt bóng.
    final bool flat = isDisabled || highlighted;

    final Color background = isDisabled
        ? QuizColors.disabledSurface
        : (highlighted ? QuizColors.accentSoft : Colors.white);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        borderRadius: BorderRadius.circular(QuizRadius.marker),
        splashColor: QuizColors.accent.withValues(alpha: 0.06),
        highlightColor: QuizColors.accent.withValues(alpha: 0.03),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          constraints: BoxConstraints(
            // 40 là ngưỡng vùng chạm tối thiểu, bằng đúng `minHeight` của
            // [QuizOptionTile]; KHÔNG hạ thấp hơn.
            minHeight: 40,
            minWidth: 80,
            maxWidth: maxWidth > 80 ? maxWidth : 80,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: QuizSpacing.sm,
            vertical: QuizSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(QuizRadius.marker),
            border: Border.all(
              color: highlighted ? QuizColors.accent : QuizColors.lineStrong,
              width: highlighted ? 1.5 : 1,
            ),
            boxShadow: flat ? const [] : QuizShadow.soft,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              QuizMarker(
                label: '$index',
                isSelected: false,
                isFilled: isFilled && !isDisabled,
                isDisabled: isDisabled,
                shape: QuizMarkerShape.ordinal,
                size: 20,
              ),
              const SizedBox(width: QuizSpacing.sm),
              Flexible(
                child: Text(
                  isFilled ? filledText! : emptyHint,
                  style: TextStyle(
                    // Đã chọn = một đáp án (option); chưa chọn = chữ gợi ý
                    // (caption).
                    fontSize: isFilled ? QuizFont.option : QuizFont.caption,
                    fontWeight: isFilled ? FontWeight.w600 : FontWeight.w400,
                    fontStyle: isFilled ? FontStyle.normal : FontStyle.italic,
                    height: 1.3,
                    color: isDisabled
                        ? QuizColors.disabled
                        : (isFilled ? QuizColors.ink : QuizColors.inkMuted),
                  ),
                ),
              ),
              const SizedBox(width: QuizSpacing.xs),
              // Mũi tên: nền xanh đặc khi đã chọn, còn lại là ô xám viền mảnh.
              Semantics(
                label: menuLabel,
                button: true,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: isFilled && !isDisabled
                        ? QuizColors.accent
                        : QuizColors.surfaceRest,
                    borderRadius: BorderRadius.circular(QuizRadius.marker),
                    border: isFilled && !isDisabled
                        ? null
                        : Border.all(color: QuizColors.line),
                  ),
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedArrowDown01,
                    size: 15.0,
                    color: isFilled && !isDisabled
                        ? Colors.white
                        : (isDisabled
                              ? QuizColors.disabled
                              : QuizColors.inkMuted),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
