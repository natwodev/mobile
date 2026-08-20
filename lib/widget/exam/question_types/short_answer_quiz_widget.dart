import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter/services.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../quiz_theme.dart';

/// ShortAnswer Quiz Widget (Type 8 - Trả lời ngắn / Tự luận ngắn)
///
/// Ô nhập KHÔNG còn nằm chen giữa dòng chữ nữa: đề bài ở trên (ô trống hiện
/// ngay chữ đang gõ), các ô nhập xếp thành danh sách ở dưới. Hai lý do:
///  - Ô nhập rộng cố định 130px chen giữa mạch chữ là thứ đầu tiên vỡ trên máy
///    320dp, và đáp án dài hơn ô thì bị cuộn ngang trong một khe hẹp.
///  - Bàn phím bật lên đẩy màn hình: ô nhập nằm cuối danh sách thì trình soạn
///    thảo tự cuộn nó vào tầm nhìn, còn ô kẹt giữa đoạn văn thì hay bị che.
///
/// Quan hệ "ô trống số mấy ↔ đang gõ gì" giữ bằng con số: số trên ô trống
/// trong đề trùng với số trên ô nhập ở dưới, và chữ vừa gõ hiện lại ngay trong
/// đề bài.
class ShortAnswerQuizWidget extends StatefulWidget {
  final String questionContent;
  final String? selectedAnswer; // Format: "1:text1|2:text2"
  final bool submitted;
  final Function(String answerString) onOptionChange;
  final Widget Function(String text, double fontSize) renderMixedContent;

  const ShortAnswerQuizWidget({
    super.key,
    required this.questionContent,
    this.selectedAnswer,
    required this.submitted,
    required this.onOptionChange,
    required this.renderMixedContent,
  });

  @override
  State<ShortAnswerQuizWidget> createState() => _ShortAnswerQuizWidgetState();
}

class _ShortAnswerQuizWidgetState extends State<ShortAnswerQuizWidget> {
  /// Ô trống trong đề: `__(1)__`.
  ///
  /// KHÔNG tách đề bằng `String.split(_blankPattern)`. `split` của Dart VỨT BỎ
  /// phần phân tách kể cả khi mẫu có nhóm bắt — khác hẳn `String.prototype
  /// .split` của JavaScript (bản web port sang đây) vốn GIỮ LẠI nhóm bắt được.
  /// Dùng split thì `parts` không bao giờ chứa token ô trống, không ô nhập nào
  /// được vẽ, và sinh viên nhìn thấy một đề bài cụt không thể trả lời. Phải
  /// duyệt bằng `allMatches` rồi tự ghép xen kẽ chữ và ô trống.
  static final RegExp _blankPattern = RegExp(r'__\((\d+)\)__');

  // blankIndex -> text
  final Map<int, TextEditingController> _controllers = {};
  final Map<int, FocusNode> _focusNodes = {};
  int? _focusedIndex;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _parseAndSetupControllers();
  }

  @override
  void didUpdateWidget(covariant ShortAnswerQuizWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedAnswer != oldWidget.selectedAnswer) {
      _parseAndSetupControllers();
    }
  }

  void _parseAndSetupControllers() {
    final Map<int, String> parsed = {};
    if (widget.selectedAnswer != null &&
        widget.selectedAnswer!.isNotEmpty &&
        widget.selectedAnswer != '-') {
      final parts = widget.selectedAnswer!.split('|');
      for (final part in parts) {
        final colonIndex = part.indexOf(':');
        if (colonIndex != -1) {
          final idxStr = part.substring(0, colonIndex);
          final text = part.substring(colonIndex + 1);
          final idx = int.tryParse(idxStr);
          if (idx != null) {
            parsed[idx] = text;
          }
        }
      }
    }

    // Identify all blank numbers from questionContent
    final matches = _blankPattern.allMatches(widget.questionContent);
    final Set<int> blankIndices = {};
    for (final m in matches) {
      blankIndices.add(int.parse(m.group(1)!));
    }
    if (blankIndices.isEmpty) {
      blankIndices.add(1); // Default single blank if none specified
    }

    for (final idx in blankIndices) {
      final val = parsed[idx] ?? '';
      if (!_controllers.containsKey(idx)) {
        _controllers[idx] = TextEditingController(text: val);
      } else if (_controllers[idx]!.text != val) {
        _controllers[idx]!.text = val;
      }
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    for (final ctrl in _controllers.values) {
      ctrl.dispose();
    }
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  void _onTextChanged() {
    if (widget.submitted) return;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 800), () {
      final String str = _controllers.entries
          .where((e) => e.value.text.trim().isNotEmpty)
          .map((e) => '${e.key}:${e.value.text.trim()}')
          .join('|');
      // Xoá hết chữ trong mọi ô -> chuỗi rỗng, mà backend chặn `value` rỗng
      // bằng 400 STUDENT_ANSWER_EMPTY nên PHẢI gửi '-'. ĐỪNG bỏ nhánh này.
      widget.onOptionChange(str.isEmpty ? '-' : str);
    });
  }

  /// Lấy (hoặc tạo) FocusNode của một ô. Chỉ phục vụ phần VẼ: biết ô nào đang
  /// được gõ để tô sáng, và cho phép chạm vào ô trống trong đề để nhảy xuống
  /// đúng ô nhập tương ứng.
  FocusNode _focusNodeFor(int index) {
    return _focusNodes.putIfAbsent(index, () {
      final node = FocusNode();
      node.addListener(() {
        if (!mounted) return;
        final bool hasFocus = node.hasFocus;
        if (hasFocus && _focusedIndex == index) return;
        if (!hasFocus && _focusedIndex != index) return;
        if (hasFocus && !widget.submitted) {
          HapticFeedback.lightImpact();
        }
        setState(() {
          _focusedIndex = hasFocus ? index : null;
        });
      });
      return node;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final matches = _blankPattern.allMatches(widget.questionContent);

    if (matches.isEmpty) {
      // Cả câu hỏi chỉ có một ô trả lời tự do.
      final ctrl = _controllers[1] ?? TextEditingController();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          widget.renderMixedContent(widget.questionContent, QuizFont.stem),
          const SizedBox(height: QuizSpacing.md),
          _buildAnswerField(
            index: 1,
            controller: ctrl,
            hint: l10n.questionShortAnswerHint,
            maxLines: 3,
            showMarker: false,
          ),
        ],
      );
    }

    final List<int> blankNumbers = [];
    for (final m in matches) {
      final n = int.parse(m.group(1)!);
      if (!blankNumbers.contains(n)) blankNumbers.add(n);
    }
    blankNumbers.sort();

    final int filledCount = blankNumbers
        .where((n) => (_controllers[n]?.text ?? '').trim().isNotEmpty)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPassage(),
        // Chữ đã nhỏ đi một nấc nên khe giữa đề bài và danh sách ô nhập lùi về
        // `sm`; tiêu đề cụm bên dưới đã tự có đệm đáy của nó.
        const SizedBox(height: QuizSpacing.sm),
        // Danh sách ô nhập trước đây bắt đầu bằng một dãy ô không tên; tiêu đề
        // nói ra phải làm gì, chip đếm nói còn thiếu bao nhiêu ô.
        QuizSectionHeader(
          label: l10n.questionShortAnswerInstruction,
          isActive: filledCount < blankNumbers.length,
          trailing: QuizCountChip(
            label: l10n.questionBlankProgress(filledCount, blankNumbers.length),
            icon: HugeIcons.strokeRoundedPencilEdit02,
            isComplete: filledCount == blankNumbers.length,
          ),
        ),
        for (final n in blankNumbers)
          _buildAnswerField(
            index: n,
            controller: _controllers[n] ?? TextEditingController(),
            hint: l10n.questionShortAnswerHint,
            maxLines: 1,
            showMarker: true,
          ),
      ],
    );
  }

  /// Đề bài với ô trống hiện lại chữ vừa gõ.
  Widget _buildPassage() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double slotMaxWidth = constraints.maxWidth - QuizSpacing.md * 2;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(QuizSpacing.md),
          decoration: BoxDecoration(
            // Nền ĐẶC + viền 1px, không gradient. Khung này chỉ cần tách đề
            // bài khỏi nền trắng của thẻ câu hỏi; dải màu ở đây chỉ tranh chỗ
            // với thứ duy nhất cần được nhìn — ô trống và chữ vừa gõ trong đó.
            color: QuizColors.surfaceRest,
            borderRadius: BorderRadius.circular(QuizRadius.card),
            border: Border.all(color: QuizColors.line),
          ),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: QuizSpacing.xs,
            runSpacing: QuizSpacing.sm,
            children: _buildPassageChildren(slotMaxWidth),
          ),
        );
      },
    );
  }

  /// Ghép xen kẽ: chữ, ô trống, chữ, ô trống... theo đúng thứ tự trong đề.
  List<Widget> _buildPassageChildren(double slotMaxWidth) {
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
      children.add(_buildBlankSlot(int.parse(m.group(1)!), slotMaxWidth));
      last = m.end;
    }
    if (last < content.length) {
      children.add(
        widget.renderMixedContent(content.substring(last), QuizFont.stem),
      );
    }
    return children;
  }

  Widget _buildBlankSlot(int blankNum, double slotMaxWidth) {
    final l10n = AppLocalizations.of(context);
    final String text = (_controllers[blankNum]?.text ?? '').trim();

    return QuizBlankSlot(
      number: blankNum,
      // Trước đây ô trống chỉ là một gạch chân câm: nhìn thì hiểu, nhưng trình
      // đọc màn hình không đọc được gì cả. Nay ô mang nhãn "Ô trống n".
      emptyHint: l10n.questionBlankLabel(blankNum),
      isFocused: _focusedIndex == blankNum,
      isDisabled: widget.submitted,
      maxWidth: slotMaxWidth,
      onTap: () => _focusNodeFor(blankNum).requestFocus(),
      filled: text.isEmpty
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: QuizFont.option,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                      color: widget.submitted
                          ? QuizColors.disabled
                          : QuizColors.ink,
                    ),
                  ),
                ),
                if (!widget.submitted) ...[
                  const SizedBox(width: QuizSpacing.xs),
                  // Icon trần không nói được gì với trình đọc màn hình; nhãn
                  // cho biết chạm vào đây là quay lại SỬA ô trống này.
                  Tooltip(
                    message: l10n.questionBlankLabel(blankNum),
                    child: const HugeIcon(
                      icon: HugeIcons.strokeRoundedPencilEdit01,
                      size: 18,
                      color: QuizColors.inkMuted,
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  /// Một ô nhập trong danh sách dưới đề bài.
  ///
  /// Khung tự dựng chứ không mượn [QuizOptionTile]: hộp đáp án luôn kèm một
  /// lớp bóng nhẹ và được thiết kế cho thứ CHẠM ĐỂ CHỌN, còn đây là chỗ GÕ CHỮ
  /// — nó chỉ nên nói bằng viền và nền đặc. Không gradient, không bóng.
  Widget _buildAnswerField({
    required int index,
    required TextEditingController controller,
    required String hint,
    required int maxLines,
    required bool showMarker,
  }) {
    final bool hasText = controller.text.trim().isNotEmpty;
    final bool isFocused = _focusedIndex == index;

    // "Đang gõ" và "đã trả lời" là HAI trạng thái, nói bằng hai kênh khác nhau:
    // VIỀN accent = con trỏ đang ở đây (ô có thể còn trống), NỀN accentSoft =
    // ô đã có chữ (vẫn giữ khi con trỏ đi chỗ khác). Gộp vào một cờ là mất một
    // trong hai.
    final Color background = widget.submitted
        ? QuizColors.disabledSurface
        : (hasText || isFocused ? QuizColors.accentSoft : Colors.white);
    final Color borderColor = widget.submitted
        ? QuizColors.line
        : (isFocused
              ? QuizColors.accent
              : (hasText ? QuizColors.accentBorder : QuizColors.lineStrong));

    return Padding(
      padding: const EdgeInsets.only(bottom: QuizSpacing.betweenOptions),
      child: GestureDetector(
        // Chạm vào phần lề quanh ô chữ cũng phải nhảy được con trỏ vào đây;
        // riêng vùng chữ thì TextField tự nhận trước.
        behavior: HitTestBehavior.opaque,
        onTap: () => _focusNodeFor(index).requestFocus(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          // 40px là ngưỡng vùng chạm tối thiểu, đừng hạ thêm. Chữ trong ô nay
          // là QuizFont.option nên đệm dọc lùi về `sm` — ô một dòng vẫn cao
          // đúng 40px nhờ ràng buộc trên, chỉ ô nhiều dòng là bớt thừa.
          constraints: const BoxConstraints(minHeight: 40),
          padding: const EdgeInsets.symmetric(
            horizontal: QuizSpacing.lg,
            vertical: QuizSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(QuizRadius.option),
            border: Border.all(color: borderColor, width: isFocused ? 1.5 : 1),
          ),
          child: Row(
            crossAxisAlignment: maxLines == 1
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              if (showMarker) ...[
                QuizMarker(
                  label: '$index',
                  // Ô đã có chữ: ô số tô đặc — phân biệt được với ô còn trống
                  // dù đang không đứng ở đó, và sau khi nộp bài vẫn tô xám đặc.
                  isSelected: hasText,
                  isDisabled: widget.submitted,
                  shape: QuizMarkerShape.ordinal,
                  size: 20,
                ),
                const SizedBox(width: QuizSpacing.md),
              ],
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: _focusNodeFor(index),
                  enabled: !widget.submitted,
                  onChanged: (_) {
                    // Debounce 800ms nằm trong _onTextChanged — GIỮ NGUYÊN,
                    // đừng gửi mỗi ký tự. setState ở đây chỉ vẽ lại xem trước
                    // trong đề bài, không đụng tới việc gửi.
                    _onTextChanged();
                    setState(() {});
                  },
                  maxLines: maxLines,
                  minLines: 1,
                  textInputAction: maxLines == 1
                      ? TextInputAction.done
                      : TextInputAction.newline,
                  cursorColor: QuizColors.accent,
                  style: TextStyle(
                    fontSize: QuizFont.option,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                    color: widget.submitted
                        ? QuizColors.disabled
                        : QuizColors.ink,
                  ),
                  // Viền do khung ngoài lo hết, ô chữ bên trong để trần: chồng
                  // thêm viền của InputDecoration là hai đường kẻ lồng nhau.
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    hintText: hint,
                    hintStyle: const TextStyle(
                      fontSize: QuizFont.caption,
                      fontWeight: FontWeight.w400,
                      height: 1.35,
                      color: QuizColors.inkMuted,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: QuizSpacing.sm),
              QuizSelectionMark(
                isSelected: hasText,
                isDisabled: widget.submitted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
