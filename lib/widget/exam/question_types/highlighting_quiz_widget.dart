import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../models/DTOs/originalExamPaperDto.dart';
import '../../common/app_buttons.dart';
import '../quiz_theme.dart';

/// Highlighting Quiz Widget (Type 10 - Bôi vùng).
///
/// Bản port của `frontend_manage/src/components/quiz/QuestionTypes/
/// HighlightingQuiz.tsx` (bản web đang chạy thật trong phòng thi).
///
/// ---------------------------------------------------------------------------
/// HỢP ĐỒNG CHẤM ĐIỂM (ScoreCalculator.cs, nhánh `[HL]`)
/// ---------------------------------------------------------------------------
/// Đáp án đúng trong DB:  `[HL]1:<answerId>|2:<answerId>|...`
/// Bài làm sinh viên:     `T_<idx>|T_<idx>|...|<answerId>|...|EXT:<text>`
///
/// Backend làm đúng 3 việc:
///   1. Bỏ mọi mảnh bắt đầu bằng `T_` và `EXT:` → phần còn lại là TẬP answerId.
///   2. `hasExtras` = có BẤT KỲ mảnh nào bắt đầu bằng `EXT:` → sai ngay lập tức.
///   3. `studentIds.SetEquals(correctIds)` (không phân biệt hoa thường, không
///      quan tâm thứ tự) → đúng/sai toàn phần, không có điểm thành phần.
///
/// Suy ra:
///   * `T_` chỉ để màn XEM LẠI tô đúng chỗ sinh viên đã bôi — không ảnh hưởng
///     điểm, nhưng vẫn phải gửi để web review vẽ lại được.
///   * Nội dung sau `EXT:` KHÔNG bao giờ được so sánh; chỉ cần nó tồn tại là
///     câu đó sai. Vì vậy widget này KHÔNG có ô nhập text tự do — thêm ô đó
///     là ép sinh viên trả lời sai 100%.
///   * Chuỗi rỗng bị backend chặn bằng 400 STUDENT_ANSWER_EMPTY → chưa bôi gì
///     phải gửi '-'.
///
/// ---------------------------------------------------------------------------
/// TÁCH VÙNG (giữ nguyên chỉ số token của web để 2 nền tảng đọc được của nhau)
/// ---------------------------------------------------------------------------
/// `questionContent` = `<lời dẫn> : <đoạn văn có thẻ [[Hn]]...[[/Hn]]>`
///   1. Giải mã HTML entity.
///   2. Cắt tại dấu ':' ĐẦU TIÊN: trước là lời dẫn, sau là đoạn văn (cả hai
///      đều `.trim()` — y hệt web).
///   3. Ghi lại vị trí từng vùng `[[Hn]]...[[/Hn]]` theo toạ độ của chuỗi ĐÃ
///      GỠ THẺ, rồi gỡ mọi thẻ `[[...]]`.
///   4. `T_<idx>` = chỉ số KÝ TỰ trong chuỗi đã gỡ thẻ (kể cả khoảng trắng).
/// Map `[[Hn]]` → answerId lấy từ `answerContent` của từng đáp án
/// (`answerContent` luôn có dạng `"[[Hn]] <nội dung vùng>"`).
class HighlightingQuizWidget extends StatefulWidget {
  final String questionId;
  final String questionContent;
  final List<AnswerDto> answers;
  final String? selectedAnswer;
  final bool submitted;
  final Function(String answerString) onOptionChange;
  final Widget Function(String text, double fontSize) renderMixedContent;

  const HighlightingQuizWidget({
    super.key,
    required this.questionId,
    required this.questionContent,
    required this.answers,
    this.selectedAnswer,
    required this.submitted,
    required this.onOptionChange,
    required this.renderMixedContent,
  });

  @override
  State<HighlightingQuizWidget> createState() => _HighlightingQuizWidgetState();
}

/// Một vùng đúng `[[Hn]]...[[/Hn]]`, toạ độ tính trên chuỗi ĐÃ GỠ THẺ.
class _HighlightZone {
  final int start; // bao gồm
  final int end; // KHÔNG bao gồm
  final String tag;
  final String answerId;

  const _HighlightZone({
    required this.start,
    required this.end,
    required this.tag,
    required this.answerId,
  });

  bool contains(int index) => index >= start && index < end;
}

/// Một mảnh văn bản có thể chạm được (hoặc khoảng trắng nối giữa hai mảnh).
///
/// Web cho bôi từng KÝ TỰ vì có chuột kéo rê; trên điện thoại một ký tự chỉ
/// rộng vài pixel nên vùng chạm là "một từ". Ranh giới mảnh luôn cắt tại biên
/// vùng đúng, nhờ đó mọi vùng đúng đều biểu diễn được bằng các mảnh trọn vẹn.
class _HighlightChunk {
  final int start;
  final int end; // KHÔNG bao gồm
  final String text;
  final bool selectable; // false = mảnh toàn khoảng trắng

  const _HighlightChunk({
    required this.start,
    required this.end,
    required this.text,
    required this.selectable,
  });
}

class _ParsedHighlighting {
  final String instructions;
  final String cleanCode;
  final List<_HighlightZone> zones;
  final List<_HighlightChunk> chunks;

  const _ParsedHighlighting({
    required this.instructions,
    required this.cleanCode,
    required this.zones,
    required this.chunks,
  });
}

class _HighlightingQuizWidgetState extends State<HighlightingQuizWidget> {
  late _ParsedHighlighting _parsed;
  final List<TapGestureRecognizer> _recognizers = [];

  /// Chỉ số các MẢNH đang được bôi (không phải chỉ số ký tự).
  Set<int> _selectedChunks = <int>{};

  @override
  void initState() {
    super.initState();
    _parsed = _parseContent();
    _restoreFromAnswer();
  }

  @override
  void didUpdateWidget(covariant HighlightingQuizWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final contentChanged =
        widget.questionContent != oldWidget.questionContent ||
        widget.answers != oldWidget.answers ||
        widget.questionId != oldWidget.questionId;
    if (contentChanged) {
      _parsed = _parseContent();
    }
    if (contentChanged || widget.selectedAnswer != oldWidget.selectedAnswer) {
      _restoreFromAnswer();
    }
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  // =========================== PHÂN TÍCH NỘI DUNG ===========================

  /// Giải mã HTML entity, 2 lượt như `unescapeHTML` của web (chuỗi bị mã hoá
  /// 2 lần kiểu `&amp;lt;` vẫn ra đúng).
  static String _unescapeHtml(String input) {
    String decodeOnce(String s) {
      return s.replaceAllMapped(
        RegExp(r'&(#x?[0-9a-fA-F]+|[a-zA-Z][a-zA-Z0-9]*);'),
        (match) {
          final entity = match.group(1)!;
          if (entity.startsWith('#')) {
            final isHex =
                entity.length > 1 && (entity[1] == 'x' || entity[1] == 'X');
            final code = isHex
                ? int.tryParse(entity.substring(2), radix: 16)
                : int.tryParse(entity.substring(1));
            if (code == null || code < 0 || code > 0x10FFFF)
              return match.group(0)!;
            return String.fromCharCode(code);
          }
          switch (entity.toLowerCase()) {
            case 'amp':
              return '&';
            case 'lt':
              return '<';
            case 'gt':
              return '>';
            case 'quot':
              return '"';
            case 'apos':
              return "'";
            case 'nbsp':
              return ' ';
            default:
              return match.group(0)!;
          }
        },
      );
    }

    final first = decodeOnce(input);
    return first.contains('&') ? decodeOnce(first) : first;
  }

  static bool _isWhitespace(String char) => char.trim().isEmpty;

  _ParsedHighlighting _parseContent() {
    _disposeRecognizers();

    // [[Hn]] -> answerId. answerContent luôn có dạng "[[Hn]] <nội dung>".
    final answerMap = <String, String>{};
    final tagInAnswer = RegExp(r'\[\[H(\d+)\]\]');
    for (final ans in widget.answers) {
      final match = tagInAnswer.firstMatch(ans.answerContent);
      if (match != null && ans.answerId.isNotEmpty) {
        answerMap['H${match.group(1)}'] = ans.answerId;
      }
    }

    final fullContent = _unescapeHtml(widget.questionContent);
    final splitIndex = fullContent.indexOf(':');
    var instructions = '';
    var codePart = fullContent;
    if (splitIndex != -1) {
      instructions = fullContent.substring(0, splitIndex + 1).trim();
      codePart = fullContent.substring(splitIndex + 1).trim();
    }

    // Vị trí các vùng đúng, quy về toạ độ chuỗi đã gỡ thẻ (biến `diff` cộng
    // dồn độ dài thẻ đã bỏ — giống hệt web).
    final zones = <_HighlightZone>[];
    final zonePattern = RegExp(r'\[\[(H\d+)\]\](.*?)\[\[\/\1\]\]');
    var diff = 0;
    for (final match in zonePattern.allMatches(codePart)) {
      final tag = match.group(1)!;
      final inside = match.group(2)!;
      final start = match.start - diff;
      final answerId = answerMap[tag];
      if (answerId != null) {
        zones.add(
          _HighlightZone(
            start: start,
            end: start + inside.length,
            tag: tag,
            answerId: answerId,
          ),
        );
      }
      diff += match.group(0)!.length - inside.length;
    }

    final cleanCode = codePart.replaceAll(RegExp(r'\[\[\/?[^\]]+\]\]'), '');

    // Cắt thành mảnh: đổi giữa "khoảng trắng" và "không khoảng trắng", và
    // luôn cắt tại biên vùng đúng để mỗi vùng phủ trọn các mảnh.
    final boundaries = <int>{0, cleanCode.length};
    for (final zone in zones) {
      boundaries.add(zone.start.clamp(0, cleanCode.length));
      boundaries.add(zone.end.clamp(0, cleanCode.length));
    }

    final chunks = <_HighlightChunk>[];
    var chunkStart = 0;
    for (var i = 1; i <= cleanCode.length; i++) {
      final atEnd = i == cleanCode.length;
      final typeChanged =
          !atEnd &&
          _isWhitespace(cleanCode[i]) != _isWhitespace(cleanCode[i - 1]);
      if (atEnd || typeChanged || boundaries.contains(i)) {
        final text = cleanCode.substring(chunkStart, i);
        if (text.isNotEmpty) {
          chunks.add(
            _HighlightChunk(
              start: chunkStart,
              end: i,
              text: text,
              selectable: text.trim().isNotEmpty,
            ),
          );
        }
        chunkStart = i;
      }
    }

    return _ParsedHighlighting(
      instructions: instructions,
      cleanCode: cleanCode,
      zones: zones,
      chunks: chunks,
    );
  }

  // ======================= ĐỌC / DỰNG CHUỖI ĐÁP ÁN =======================

  /// Khôi phục lựa chọn từ chuỗi đã lưu: chỉ đọc các mảnh `T_<idx>` (đúng như
  /// web làm khi resume).
  void _restoreFromAnswer() {
    final raw = widget.selectedAnswer;
    if (raw == null || raw.trim().isEmpty || raw.trim() == '-') {
      _selectedChunks = <int>{};
      return;
    }

    final indices = <int>{};
    for (final part in raw.split('|')) {
      final trimmed = part.trim();
      if (!trimmed.startsWith('T_')) continue;
      final value = int.tryParse(trimmed.substring(2));
      if (value != null) indices.add(value);
    }

    final restored = <int>{};
    for (var i = 0; i < _parsed.chunks.length; i++) {
      final chunk = _parsed.chunks[i];
      if (!chunk.selectable) continue;
      var covered = true;
      for (var idx = chunk.start; idx < chunk.end; idx++) {
        if (!indices.contains(idx)) {
          covered = false;
          break;
        }
      }
      if (covered) restored.add(i);
    }
    _selectedChunks = restored;
  }

  /// Chỉ số KÝ TỰ đang được bôi.
  ///
  /// Ngoài ký tự của các mảnh được chọn, còn nối thêm khoảng trắng nằm GIỮA
  /// hai mảnh được chọn liền kề. Không có bước nối này thì "the quick fox"
  /// (một vùng đúng có khoảng trắng bên trong) sẽ vỡ thành 3 khối rời và
  /// không khớp được vùng nào.
  Set<int> _selectedCharIndices() {
    final indices = <int>{};
    int? previousSelected;
    for (var i = 0; i < _parsed.chunks.length; i++) {
      final chunk = _parsed.chunks[i];
      if (!_selectedChunks.contains(i)) continue;

      if (previousSelected != null) {
        var onlyWhitespaceBetween = true;
        for (var j = previousSelected + 1; j < i; j++) {
          if (_parsed.chunks[j].selectable) {
            onlyWhitespaceBetween = false;
            break;
          }
        }
        if (onlyWhitespaceBetween) {
          for (var j = previousSelected + 1; j < i; j++) {
            for (
              var k = _parsed.chunks[j].start;
              k < _parsed.chunks[j].end;
              k++
            ) {
              indices.add(k);
            }
          }
        }
      }

      for (var k = chunk.start; k < chunk.end; k++) {
        indices.add(k);
      }
      previousSelected = i;
    }
    return indices;
  }

  /// Dựng chuỗi `T_<idx>|...|<answerId>|EXT:<text>` gửi lên server.
  String _buildAnswerString() {
    final selected = _selectedCharIndices();
    if (selected.isEmpty) return '-';

    // Gom thành các khối ký tự liên tiếp (web cũng gom khối như vậy).
    final sorted = selected.toList()..sort();
    final blocks = <List<int>>[];
    var current = <int>[sorted.first];
    for (var i = 1; i < sorted.length; i++) {
      if (sorted[i] == sorted[i - 1] + 1) {
        current.add(sorted[i]);
      } else {
        blocks.add(current);
        current = <int>[sorted[i]];
      }
    }
    blocks.add(current);

    final tokenIndices = <int>{...selected};
    final idParts = <String>[];

    for (final block in blocks) {
      final blockStart = block.first;
      final blockEnd = block.last + 1; // KHÔNG bao gồm

      final inside = _parsed.zones
          .where((z) => z.start >= blockStart && z.end <= blockEnd)
          .toList();

      final covered = <int>{};
      for (final zone in inside) {
        for (var i = zone.start; i < zone.end; i++) {
          covered.add(i);
        }
      }

      // Phần dư ngoài các vùng đúng: chỉ chấp nhận khoảng trắng. Dư ra một
      // chữ nào đó nghĩa là bôi thừa → phải khai báo EXT: (và câu sẽ sai,
      // đúng như backend quy định).
      var extraIsWhitespaceOnly = true;
      for (final index in block) {
        if (covered.contains(index)) continue;
        if (index < _parsed.cleanCode.length &&
            !_isWhitespace(_parsed.cleanCode[index])) {
          extraIsWhitespaceOnly = false;
          break;
        }
      }

      if (inside.isNotEmpty && extraIsWhitespaceOnly) {
        for (final zone in inside) {
          idParts.add(zone.answerId);
          // Gửi T_ phủ trọn vùng để màn xem lại tô đúng nguyên vùng.
          for (var i = zone.start; i < zone.end; i++) {
            tokenIndices.add(i);
          }
        }
        continue;
      }

      if (extraIsWhitespaceOnly && inside.isEmpty) {
        // Khối toàn khoảng trắng: web bỏ qua (`if (blockText.trim())`).
        continue;
      }

      final buffer = StringBuffer();
      for (final index in block) {
        if (index < _parsed.cleanCode.length) {
          buffer.write(_parsed.cleanCode[index]);
        }
      }
      final text = buffer.toString().trim();
      if (text.isNotEmpty) idParts.add('EXT:$text');
    }

    final ordered = tokenIndices.toList()..sort();
    final parts = <String>[for (final index in ordered) 'T_$index', ...idParts];
    final unique = <String>{...parts};
    // Backend chặn `value` rỗng bằng 400 STUDENT_ANSWER_EMPTY → phải là '-'.
    return unique.isEmpty ? '-' : unique.join('|');
  }

  void _toggleChunk(int chunkIndex) {
    if (widget.submitted) return;
    setState(() {
      if (_selectedChunks.contains(chunkIndex)) {
        _selectedChunks.remove(chunkIndex);
      } else {
        _selectedChunks.add(chunkIndex);
      }
    });
    widget.onOptionChange(_buildAnswerString());
  }

  void _clearSelection() {
    if (widget.submitted || _selectedChunks.isEmpty) return;
    setState(() => _selectedChunks = <int>{});
    widget.onOptionChange('-');
  }

  // ================================ GIAO DIỆN ================================
  //
  // Dưới đây chỉ là phần VẼ. Cách tách mảnh, cách dựng chuỗi `T_/EXT:` và quy
  // tắc gửi '-' nằm ở trên và không được đụng tới.
  //
  // Nguyên tắc: PHẲNG. Không gradient, không bóng — trạng thái một mảnh chữ nói
  // bằng đúng ba thứ: màu nền, màu chữ, gạch chân.

  /// Khoảng trắng NỐI giữa hai mảnh đang bôi.
  ///
  /// Chỉ để nhìn: tô luôn khoảng trắng ở giữa cho vệt bôi liền một mạch, đúng
  /// như `_selectedCharIndices()` đã nối chúng khi dựng chuỗi gửi đi. Không có
  /// nó thì "the quick fox" hiện ra thành ba vệt rời.
  bool _isBridgeWhitespace(int index) {
    final chunk = _parsed.chunks[index];
    if (chunk.selectable) return false;
    if (index == 0 || index + 1 >= _parsed.chunks.length) return false;
    return _selectedChunks.contains(index - 1) &&
        _selectedChunks.contains(index + 1);
  }

  /// Kiểu chữ của một mảnh trong đoạn văn.
  ///
  /// Trước đây mảnh đang bôi là một `WidgetSpan` bọc `Container` có gradient +
  /// padding riêng: mỗi hộp đội chiều cao dòng lên và làm dòng chữ nhấp nhô.
  /// Nay MỌI mảnh đều là `TextSpan`, nền/gạch chân vẽ thẳng trên mạch chữ nên
  /// cả đoạn văn giữ đúng một nhịp dòng.
  TextStyle _chunkStyle({required bool isSelected, required bool tappable}) {
    // Chưa nộp mà chưa bôi: gạch chân chấm mảnh để biết chỗ nào bấm được.
    final bool hintTappable = tappable && !isSelected;

    return TextStyle(
      fontFamily: 'monospace',
      fontSize: QuizFont.stem,
      // Chữ hạ một nấc nên hệ số dòng lên 2.0 để vùng chạm của MỘT TỪ vẫn là
      // ~28px — đây là mức thấp nhất còn bấm trúng, siết nữa là chạm nhầm từ
      // bên cạnh.
      height: 2.0,
      letterSpacing: 0.2,
      color: isSelected
          ? QuizColors.accentDeep
          : (widget.submitted ? QuizColors.disabled : QuizColors.ink),
      fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
      backgroundColor: isSelected
          ? QuizColors.accentSoft
          : (hintTappable ? Colors.white : null),
      decoration: (isSelected || hintTappable)
          ? TextDecoration.underline
          : null,
      decorationColor: isSelected ? QuizColors.accent : QuizColors.lineStrong,
      decorationThickness: isSelected ? 1.5 : 1,
      decorationStyle: isSelected
          ? TextDecorationStyle.solid
          : TextDecorationStyle.dotted,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    _disposeRecognizers();

    final spans = <InlineSpan>[];
    for (var i = 0; i < _parsed.chunks.length; i++) {
      final chunk = _parsed.chunks[i];
      final bool tappable = chunk.selectable && !widget.submitted;
      final bool isSelected =
          _selectedChunks.contains(i) || _isBridgeWhitespace(i);

      TapGestureRecognizer? recognizer;
      if (tappable) {
        // Mảnh đang bôi vẫn nhận chạm để bỏ bôi.
        recognizer = TapGestureRecognizer()..onTap = () => _toggleChunk(i);
        _recognizers.add(recognizer);
      }

      spans.add(
        TextSpan(
          text: chunk.text,
          recognizer: recognizer,
          style: _chunkStyle(isSelected: isSelected, tappable: tappable),
        ),
      );
    }

    final hasSelection = _selectedChunks.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Lời dẫn (phần trước dấu ':' của `questionContent`) để CHỮ TRẦN.
        // Cái hộp gradient bo 14 + viền cũ tốn ~24px chiều cao chỉ để nhắc lại
        // một câu, lại còn trông nặng hơn chính đoạn văn phải bôi bên dưới.
        if (_parsed.instructions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: QuizSpacing.sm),
            child: widget.renderMixedContent(
              _parsed.instructions,
              QuizFont.stem,
            ),
          ),
        QuizInstruction(
          icon: HugeIcons.strokeRoundedPencilEdit02,
          text: l10n.questionHighlightInstruction,
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: QuizSpacing.sm),
          // Wrap chứ không phải Row: chip đếm nay mang chữ ("Đã chọn 3 phần")
          // nên đứng cạnh nút "Bỏ chọn hết" là tràn ngang ở 320dp. Wrap cho nút
          // rơi xuống dòng dưới thay vì cắt cụt.
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: QuizSpacing.sm,
            runSpacing: QuizSpacing.xs,
            children: [
              // Bộ đếm có CHỮ chứ không còn là con số trần cạnh một cây cọ:
              // đây là thứ duy nhất cho biết "mình đã bôi tới đâu" khi đoạn văn
              // dài hơn một màn hình, nên nó phải đọc lên được.
              QuizCountChip(
                label: l10n.questionHighlightSelectedCount(
                  _selectedChunks.length,
                ),
                icon: HugeIcons.strokeRoundedPencilEdit02,
                isComplete: hasSelection,
              ),
              if (!widget.submitted)
                // Nền ĐẶC, không gradient, không bóng: bật thì xanh chủ đạo chữ
                // trắng, tắt thì nền xám chữ mờ.
                //
                // CỐ Ý NHỎ HƠN CHUẨN NÚT CHUNG (cao 40 + chữ caption thay vì
                // 48 + chữ 15): đây là điều khiển nằm TRONG câu hỏi, đứng cạnh
                // chip đếm, chứ không phải nút hành động cấp màn hình như
                // "Tiếp theo" / "Nộp bài". Ép nó lên 48/15 là ăn thêm chiều
                // cao của trang thi — đúng thứ vừa được dọn đi. Cao 40 giữ
                // được nhờ `shrinkWrap` + `minimumSize` (mặc định của
                // TextButton là 48).
                //
                // Cái PHẢI theo chuẩn chung là NGÔN NGỮ HÌNH DẠNG: bo 8 như
                // mọi nút khác thay cho bo pill, và cùng một tông xanh
                // [AppColors.accent].
                TextButton.icon(
                  onPressed: hasSelection ? _clearSelection : null,
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedEraser,
                    size: 15.0,
                    color: AppColors.accent,
                  ),
                  label: Text(
                    l10n.questionHighlightClear,
                    style: const TextStyle(
                      fontSize: QuizFont.caption,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: AppColors.accent,
                    disabledForegroundColor: QuizColors.disabled,
                    disabledBackgroundColor: QuizColors.disabledSurface,
                    padding: const EdgeInsets.symmetric(
                      horizontal: QuizSpacing.lg,
                    ),
                    minimumSize: const Size(0, 40),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppButtonMetrics.radius,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Hộp bọc đoạn văn: nền phẳng + viền 1px, padding còn `md x sm`.
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: QuizSpacing.md,
            vertical: QuizSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: widget.submitted
                ? QuizColors.disabledSurface
                : QuizColors.surfaceRest,
            borderRadius: BorderRadius.circular(QuizRadius.card),
            border: Border.all(color: QuizColors.line),
          ),
          child: _parsed.cleanCode.isEmpty
              ? const SizedBox.shrink()
              : Text.rich(TextSpan(children: spans)),
        ),
      ],
    );
  }
}
