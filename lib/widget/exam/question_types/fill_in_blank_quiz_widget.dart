import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter/services.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../models/DTOs/originalExamPaperDto.dart';
import '../quiz_theme.dart';

/// FillInBlank Quiz Widget (Type 5 - Điền vào chỗ trống)
///
/// Bố cục: ĐOẠN VĂN có ô trống ở trên, NGÂN HÀNG TỪ ở dưới.
///
/// Điểm dễ nhầm nhất của loại câu này là "từ nào đang nằm ở ô nào" — sinh viên
/// đặt xong 4 từ rồi không nhớ mình đã dùng từ nào ở đâu. Ở đây quan hệ đó
/// được nói ra bằng CON SỐ chứ không bắt người ta suy luận: ô trống mang số
/// thứ tự, và thẻ từ đã được đặt hiện đúng con số ấy ở mép phải. Cùng một con
/// số xuất hiện ở hai chỗ = cùng một cặp.
class FillInBlankQuizWidget extends StatefulWidget {
  final String questionContent;
  final List<AnswerDto> answers;
  final String? selectedAnswer; // Format: "1:answerId1|2:answerId2"
  final bool submitted;
  final Function(String answerString) onOptionChange;
  final Widget Function(String text, double fontSize) renderMixedContent;

  const FillInBlankQuizWidget({
    super.key,
    required this.questionContent,
    required this.answers,
    this.selectedAnswer,
    required this.submitted,
    required this.onOptionChange,
    required this.renderMixedContent,
  });

  @override
  State<FillInBlankQuizWidget> createState() => _FillInBlankQuizWidgetState();
}

class _FillInBlankQuizWidgetState extends State<FillInBlankQuizWidget> {
  /// Ô trống trong đề: `__(1)__`.
  ///
  /// KHÔNG tách đề bằng `String.split(_blankPattern)`. `split` của Dart VỨT BỎ
  /// phần phân tách kể cả khi mẫu có nhóm bắt — khác hẳn `String.prototype
  /// .split` của JavaScript (bản web port sang đây) vốn GIỮ LẠI nhóm bắt được.
  /// Dùng split thì `parts` không bao giờ chứa token ô trống, không ô nhập nào
  /// được vẽ, và sinh viên nhìn thấy một đề bài cụt không thể trả lời. Phải
  /// duyệt bằng `allMatches` rồi tự ghép xen kẽ chữ và ô trống.
  static final RegExp _blankPattern = RegExp(r'__\((\d+)\)__');

  // blankIndex -> answerId
  Map<int, String> filledBlanks = {};
  String? selectedWordId;

  /// Từ đang được KÉO trên tay. Khác [selectedWordId] ở chỗ nó chỉ sống trong
  /// lúc ngón tay còn chạm màn, dùng để làm sáng các ô trống còn nhận được.
  String? draggingWordId;

  @override
  void initState() {
    super.initState();
    _parseInitialAnswer();
  }

  @override
  void didUpdateWidget(covariant FillInBlankQuizWidget oldWidget) {
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
        filledBlanks = parsed;
      });
    } else {
      setState(() {
        filledBlanks = {};
      });
    }
  }

  void _notifyChange() {
    // Bỏ ô chưa có answerId thật, tránh sinh mảnh vô nghĩa dạng "1:".
    final String str = filledBlanks.entries
        .where((e) => e.value.isNotEmpty)
        .map((e) => '${e.key}:${e.value}')
        .join('|');
    // Chưa điền ô nào -> chuỗi rỗng, mà backend chặn `value` rỗng bằng 400
    // STUDENT_ANSWER_EMPTY nên PHẢI gửi '-'. ĐỪNG bỏ nhánh này.
    widget.onOptionChange(str.isEmpty ? '-' : str);
  }

  void _onWordTap(String wordId) {
    if (widget.submitted) return;
    HapticFeedback.lightImpact();
    setState(() {
      if (selectedWordId == wordId) {
        selectedWordId = null;
      } else {
        selectedWordId = wordId;
      }
    });
  }

  void _onBlankTap(int blankIndex) {
    if (widget.submitted) return;
    HapticFeedback.lightImpact();

    if (filledBlanks.containsKey(blankIndex)) {
      // Gỡ bỏ từ khỏi ô trống này
      setState(() {
        filledBlanks.remove(blankIndex);
        selectedWordId = null;
      });
      _notifyChange();
    } else if (selectedWordId != null) {
      _placeWord(blankIndex, selectedWordId!);
    }
  }

  /// Đặt một từ vào ô trống. Dùng chung cho cả hai lối: chạm-rồi-chạm và
  /// kéo-thả.
  void _placeWord(int blankIndex, String wordId) {
    if (widget.submitted) return;

    setState(() {
      // Gỡ từ này khỏi ô cũ nếu nó đang nằm đâu đó: một từ chỉ được ở một chỗ.
      filledBlanks.removeWhere((_, v) => v == wordId);
      filledBlanks[blankIndex] = wordId;
      selectedWordId = null;
    });
    _notifyChange();
  }

  String _cleanWordContent(String content) {
    return content.replaceAll(RegExp(r'\[\[B\d+\]\]\s*'), '').trim();
  }

  /// Các số ô trống có trong đề, không trùng. CHỈ dùng cho phần vẽ (chip đếm)
  /// — chuỗi gửi lên server vẫn do [_notifyChange] sinh ra từ [filledBlanks].
  Set<int> _blankNumbers() {
    return {
      for (final m in _blankPattern.allMatches(widget.questionContent))
        int.parse(m.group(1)!),
    };
  }

  /// Số thứ tự ô trống đang giữ từ này (null = từ còn trong ngân hàng).
  int? _blankHolding(String answerId) {
    for (final entry in filledBlanks.entries) {
      if (entry.value == answerId) return entry.key;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final usedAnswerIds = filledBlanks.values.toSet();
    final bool allWordsUsed =
        widget.answers.isNotEmpty &&
        usedAnswerIds.length == widget.answers.length;

    final int blankCount = _blankNumbers().length;
    final int filledCount = filledBlanks.values
        .where((v) => v.isNotEmpty)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        QuizInstruction(
          icon: allWordsUsed
              ? HugeIcons.strokeRoundedCheckmarkCircle02
              : HugeIcons.strokeRoundedTouch01,
          text: allWordsUsed
              ? l10n.questionFillBlankAllWordsUsed
              : l10n.questionFillBlankInstruction,
        ),
        _buildPassage(),
        // Chữ đã nhỏ đi một nấc nên khe giữa đề bài và ngân hàng từ lùi về
        // `sm`; tiêu đề cụm bên dưới đã tự có đệm đáy của nó.
        const SizedBox(height: QuizSpacing.sm),
        // Ngân hàng từ trước đây bắt đầu bằng một dãy thẻ không tên; tiêu đề
        // nói ra đây là gì, còn chip đếm nói còn bao nhiêu ô chưa điền.
        QuizSectionHeader(
          label: l10n.questionWordBankLabel,
          isActive: blankCount > 0 && filledCount < blankCount,
          trailing: blankCount == 0
              ? null
              : QuizCountChip(
                  label: l10n.questionBlankProgress(filledCount, blankCount),
                  icon: HugeIcons.strokeRoundedPencilEdit02,
                  isComplete: filledCount == blankCount,
                ),
        ),
        for (int i = 0; i < widget.answers.length; i++)
          _buildWordTile(widget.answers[i], i, usedAnswerIds),
      ],
    );
  }

  /// Khung đề bài: chữ chạy bình thường, ô trống chèn vào giữa dòng.
  Widget _buildPassage() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Ô trống không được rộng hơn lòng khung, nếu không đáp án dài sẽ đẩy
        // đoạn văn tràn ngang trên máy 320dp.
        final double slotMaxWidth = constraints.maxWidth - QuizSpacing.md * 2;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(QuizSpacing.md),
          decoration: BoxDecoration(
            // Nền ĐẶC + viền 1px, không gradient. Khung này chỉ cần tách đề
            // bài khỏi nền trắng của thẻ câu hỏi; tự làm mình nổi bật bằng dải
            // màu là cướp sự chú ý của thứ duy nhất cần được nhìn ở đây — ô
            // trống.
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
    final filledAnswerId = filledBlanks[blankNum];
    String? filledText;
    if (filledAnswerId != null) {
      final AnswerDto filledAnswer = widget.answers.firstWhere(
        (a) => a.answerId == filledAnswerId,
        orElse: () => AnswerDto(
          answerId: '',
          order: 0,
          answerContent: '',
          isCorrect: false,
          canShuffleAnswer: false,
          originalExamPaperDetailId: '',
        ),
      );
      if (filledAnswer.answerContent.isNotEmpty) {
        filledText = _cleanWordContent(filledAnswer.answerContent);
      }
    }

    final l10n = AppLocalizations.of(context);

    // Bọc ô trống thành CHỖ THẢ. `onWillAcceptWithDetails` từ chối khi đã nộp
    // bài, nhờ vậy ô không sáng lên mời gọi một thao tác không còn tác dụng.
    return DragTarget<String>(
      onWillAcceptWithDetails: (_) => !widget.submitted,
      onAcceptWithDetails: (details) {
        HapticFeedback.selectionClick();
        _placeWord(blankNum, details.data);
      },
      builder: (context, candidateData, rejectedData) {
        // Ngón tay đang lơ lửng ngay trên ô này: viền sáng đậm hơn mức "có từ
        // trên tay" bên dưới, để biết thả ra bây giờ là rơi vào ĐÚNG ô nào.
        final bool isHovered = candidateData.isNotEmpty;

        return _buildSlotBody(
          blankNum,
          slotMaxWidth,
          filledText,
          l10n,
          isHovered,
        );
      },
    );
  }

  Widget _buildSlotBody(
    int blankNum,
    double slotMaxWidth,
    String? filledText,
    AppLocalizations l10n,
    bool isHovered,
  ) {
    return QuizBlankSlot(
      number: blankNum,
      // Trước đây ô trống chỉ là một gạch chân câm: nhìn thì hiểu, nhưng trình
      // đọc màn hình không đọc được gì cả. Nay ô mang nhãn "Ô trống n".
      emptyHint: l10n.questionBlankLabel(blankNum),
      // Đã cầm sẵn một từ trên tay — chọn bằng cách chạm HOẶC đang kéo — thì
      // mọi ô còn trống sáng lên để chỉ chỗ thả. Ô đang bị ngón tay lơ lửng
      // ngay trên thì sáng bất kể đang trống hay đã có từ, vì thả vào ô đã có
      // từ là THAY từ cũ chứ không phải thao tác vô hiệu.
      isFocused:
          isHovered ||
          ((selectedWordId != null || draggingWordId != null) &&
              filledText == null &&
              !widget.submitted),
      isDisabled: widget.submitted,
      maxWidth: slotMaxWidth,
      onTap: () => _onBlankTap(blankNum),
      filled: filledText == null
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    filledText,
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
                  // Nút chỉ có icon -> phải có nhãn, nếu không sinh viên dùng
                  // trình đọc màn hình không biết chạm vào đây là GỠ từ ra.
                  Tooltip(
                    message: l10n.questionBlankClear,
                    child: const HugeIcon(
                      icon: HugeIcons.strokeRoundedCancel01,
                      size: 18,
                      color: QuizColors.inkMuted,
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildWordTile(AnswerDto ans, int position, Set<String> usedIds) {
    final Widget tile = _buildWordTileBody(ans, position, usedIds);

    // Từ đã đặt vào ô, hoặc bài đã nộp: không kéo được nữa. Cho kéo một từ đã
    // dùng thì phải xử lý chuyện nó rời ô cũ giữa chừng, mà gỡ từ ra đã có sẵn
    // dấu X trong ô rồi.
    if (usedIds.contains(ans.answerId) || widget.submitted) return tile;

    // LongPressDraggable chứ KHÔNG phải Draggable: thẻ từ nằm trong một cột
    // cuộn dọc, mà `Draggable` cướp cử chỉ kéo ngay từ pixel đầu — vuốt để cuộn
    // trang sẽ thành nhấc thẻ lên. Nhấn giữ tách hẳn hai cử chỉ ra.
    //
    // Rút thời gian giữ xuống 180ms thay vì 500ms mặc định: nửa giây là đủ lâu
    // để người dùng tưởng thẻ không kéo được rồi bỏ cuộc.
    return LongPressDraggable<String>(
      data: ans.answerId,
      delay: const Duration(milliseconds: 180),
      onDragStarted: () {
        HapticFeedback.selectionClick();
        setState(() => draggingWordId = ans.answerId);
      },
      onDragEnd: (_) => setState(() => draggingWordId = null),
      onDraggableCanceled: (_, _) => setState(() => draggingWordId = null),
      feedback: _buildDragFeedback(ans),
      // Thẻ gốc mờ đi chứ không biến mất: mất hẳn thì cả cột nhảy lên một nấc
      // ngay giữa lúc đang kéo, và chỗ định thả cũng trôi theo.
      childWhenDragging: Opacity(opacity: 0.3, child: tile),
      child: tile,
    );
  }

  /// Thẻ bay theo ngón tay trong lúc kéo.
  ///
  /// PHẢI bọc [Material]: widget này vẽ trên lớp overlay của Navigator, ngoài
  /// cây widget của màn — không có Material tổ tiên thì chữ hiện ra với gạch
  /// chân vàng của trạng thái "chưa có kiểu chữ".
  Widget _buildDragFeedback(AnswerDto ans) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: QuizSpacing.md,
          vertical: QuizSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(QuizRadius.card),
          border: Border.all(color: QuizColors.accent, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: QuizColors.accent.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          _cleanWordContent(ans.answerContent),
          style: const TextStyle(
            fontSize: QuizFont.option,
            fontWeight: FontWeight.w700,
            color: QuizColors.accent,
          ),
        ),
      ),
    );
  }

  Widget _buildWordTileBody(AnswerDto ans, int position, Set<String> usedIds) {
    final bool isUsed = usedIds.contains(ans.answerId);
    final bool isSelected = selectedWordId == ans.answerId;
    final bool isLocked = isUsed || widget.submitted;
    final int? placedAt = _blankHolding(ans.answerId);

    return QuizOptionTile(
      isSelected: isSelected,
      isDisabled: isLocked,
      crossAxisAlignment: CrossAxisAlignment.start,
      onTap: () => _onWordTap(ans.answerId),
      leading: QuizMarker(
        label: quizOptionLabel(0, position),
        isSelected: isSelected,
        isDisabled: isLocked,
        shape: QuizMarkerShape.ordinal,
      ),
      // Từ đã đặt: hiện SỐ Ô TRỐNG đang giữ nó, nền đặc, không bóng. Dấu tích
      // chỉ nói "đã dùng" rồi bắt sinh viên tự dò xem dùng ở đâu; con số nói
      // luôn cặp nào với cặp nào — cùng một số ở hai chỗ là cùng một cặp.
      trailing: placedAt == null
          ? null
          : QuizMarker(
              label: '$placedAt',
              isSelected: false,
              isFilled: true,
              isDisabled: widget.submitted,
              shape: QuizMarkerShape.ordinal,
              size: 20,
            ),
      // Chữ của thẻ từ để trần: lớp nền pha màu bọc quanh nó trước đây chỉ lặp
      // lại điều ô số bên phải đã nói, mà ăn thêm 8px chiều cao mỗi thẻ.
      child: Opacity(
        opacity: isUsed ? 0.85 : 1,
        child: widget.renderMixedContent(
          _cleanWordContent(ans.answerContent),
          QuizFont.option,
        ),
      ),
    );
  }
}
