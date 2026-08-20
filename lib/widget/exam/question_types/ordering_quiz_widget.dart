import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../models/DTOs/originalExamPaperDto.dart';
import '../quiz_theme.dart';

/// Ordering Quiz Widget (Type 7 - Sắp xếp thứ tự)
class OrderingQuizWidget extends StatefulWidget {
  final String questionId;
  final List<AnswerDto> answers;
  final String? selectedAnswer; // Pipe separated ordered IDs: "id1|id2|id3"
  final bool submitted;
  final Function(String orderedIdsString) onOptionChange;
  final Widget Function(String text, double fontSize) renderMixedContent;

  const OrderingQuizWidget({
    super.key,
    required this.questionId,
    required this.answers,
    this.selectedAnswer,
    required this.submitted,
    required this.onOptionChange,
    required this.renderMixedContent,
  });

  @override
  State<OrderingQuizWidget> createState() => _OrderingQuizWidgetState();
}

class _OrderingQuizWidgetState extends State<OrderingQuizWidget> {
  late List<AnswerDto> items;

  /// Đã gửi thứ tự mặc định cho câu hiện tại hay chưa (chỉ gửi 1 lần / câu).
  bool _defaultOrderSaved = false;

  @override
  void initState() {
    super.initState();
    _initOrder();
    _scheduleDefaultOrderSave();
  }

  @override
  void didUpdateWidget(covariant OrderingQuizWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedAnswer != oldWidget.selectedAnswer ||
        widget.answers != oldWidget.answers) {
      _initOrder();
    }
    // PageView có thể tái dùng State này cho một câu sắp xếp KHÁC (chỉ đổi
    // props, không gọi lại initState) → thứ tự mặc định của câu mới cũng phải
    // được lưu.
    if (widget.questionId != oldWidget.questionId) {
      _defaultOrderSaved = false;
      _scheduleDefaultOrderSave();
    }
  }

  /// Câu này đã có đáp án lưu từ trước (sinh viên đã kéo thả / đang resume).
  bool get _hasSavedAnswer {
    final saved = widget.selectedAnswer?.trim();
    return saved != null && saved.isNotEmpty && saved != '-';
  }

  /// Gửi thứ tự ĐANG HIỂN THỊ ngay lần dựng đầu tiên khi câu chưa có đáp án.
  ///
  /// Trước đây `onOptionChange` chỉ chạy lúc kéo thả: sinh viên thấy thứ tự
  /// mặc định đã đúng ý rồi chuyển câu thì KHÔNG có gì được lưu và câu bị
  /// chấm là chưa trả lời.
  ///
  /// Hai ràng buộc bắt buộc:
  ///  - KHÔNG ghi đè đáp án sinh viên đã chọn trước đó (`_hasSavedAnswer`).
  ///  - KHÔNG gọi setState / gửi request trong `build` → hoãn tới sau khung
  ///    hình đầu bằng addPostFrameCallback.
  void _scheduleDefaultOrderSave() {
    if (_defaultOrderSaved) return;
    if (widget.submitted) return;
    if (_hasSavedAnswer) return;
    if (widget.answers.isEmpty) return;

    _defaultOrderSaved = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.submitted) return;
      // Trong lúc chờ khung hình, sinh viên có thể đã kéo thả hoặc đáp án cũ
      // vừa về từ server → lúc đó không được ghi đè nữa.
      if (_hasSavedAnswer) return;
      _notifyOrderChanged();
    });
  }

  void _initOrder() {
    if (widget.selectedAnswer != null &&
        widget.selectedAnswer!.isNotEmpty &&
        widget.selectedAnswer != '-') {
      final savedIds = widget.selectedAnswer!
          .split('|')
          .map((s) => s.trim())
          .toList();
      if (savedIds.length == widget.answers.length) {
        final List<AnswerDto> reordered = [];
        for (final id in savedIds) {
          final match = widget.answers.firstWhere(
            (a) => a.answerId == id,
            orElse: () => AnswerDto(
              answerId: id,
              order: 0,
              answerContent: '',
              isCorrect: false,
              canShuffleAnswer: false,
              originalExamPaperDetailId: '',
            ),
          );
          if (match.answerContent.isNotEmpty) {
            reordered.add(match);
          }
        }
        if (reordered.length == widget.answers.length) {
          items = reordered;
          return;
        }
      }
    }

    // Chưa có đáp án lưu -> dựng thứ tự khởi tạo giống web.
    items = _buildInitialOrder();
  }

  /// Thứ tự hiển thị lần đầu — port từ web
  /// (`frontend_manage/src/components/quiz/QuestionTypes/OrderingQuiz.tsx:104-144`).
  ///
  /// Backend KHÔNG hoán vị đáp án của câu sắp xếp khi sinh đề (giữ nguyên thứ
  /// tự gốc = thứ tự ĐÚNG), việc xáo do client làm. Trước đây mobile chỉ
  /// `sort(order)` nên hiển thị thẳng đáp án đúng; cộng với việc tự lưu thứ tự
  /// mặc định (xem `_scheduleDefaultOrderSave`) thì sinh viên được cho không
  /// điểm câu này. Vì vậy phải xáo y như web.
  ///
  /// Chỉ xáo các đáp án có `canShuffleAnswer = true`; đáp án bị ghim
  /// (`false`) giữ nguyên vị trí theo `order`.
  List<AnswerDto> _buildInitialOrder() {
    final sortedByOrder = List<AnswerDto>.from(widget.answers)
      ..sort((a, b) => a.order.compareTo(b.order));

    final shufflable = widget.answers.where((a) => a.canShuffleAnswer).toList();
    if (shufflable.length < 2) return sortedByOrder;

    final shuffled = _shuffleWithSeed(shufflable, widget.questionId);
    final result = <AnswerDto>[];
    var shuffledIndex = 0;
    for (final ans in sortedByOrder) {
      if (!ans.canShuffleAnswer) {
        result.add(ans);
      } else if (shuffledIndex < shuffled.length) {
        result.add(shuffled[shuffledIndex]);
        shuffledIndex++;
      }
    }
    return result;
  }

  /// Fisher-Yates với seed từ questionId — chép đúng thuật toán của web để
  /// một sinh viên luôn thấy cùng một thứ tự dù đổi thiết bị / tải lại trang.
  ///
  /// `toSigned(32)` mô phỏng phép `hash & hash` (ToInt32) của JavaScript;
  /// bỏ nó đi là ra dãy khác hẳn web.
  static List<T> _shuffleWithSeed<T>(List<T> array, String seed) {
    final result = List<T>.from(array);

    var hashInt = 0;
    for (var i = 0; i < seed.length; i++) {
      final shifted = (hashInt << 5).toSigned(32);
      hashInt = (shifted - hashInt + seed.codeUnitAt(i)).toSigned(32);
    }

    var hash = hashInt.toDouble();
    double seededRandom() {
      hash = math.sin(hash) * 10000;
      return hash - hash.floorToDouble();
    }

    for (var i = result.length - 1; i > 0; i--) {
      final j = (seededRandom() * (i + 1)).floor();
      final tmp = result[i];
      result[i] = result[j];
      result[j] = tmp;
    }
    return result;
  }

  void _notifyOrderChanged() {
    final String orderedString = items
        .map((i) => i.answerId)
        .where((id) => id.isNotEmpty)
        .join('|');
    // Backend (StudentController.SaveAnswer) trả 400 STUDENT_ANSWER_EMPTY khi
    // `value` rỗng/toàn khoảng trắng, và ScoreCalculator coi '-' là "chưa trả
    // lời". Vì vậy danh sách rỗng PHẢI gửi '-' chứ không phải ''.
    // ĐỪNG rút gọn thành onOptionChange(orderedString).
    widget.onOptionChange(orderedString.isEmpty ? '-' : orderedString);
  }

  // ================================ GIAO DIỆN ================================
  //
  // Chỉ phần VẼ nằm dưới đây. Mọi thứ liên quan tới chuỗi gửi lên server
  // (_buildInitialOrder / _shuffleWithSeed / _notifyOrderChanged) nằm ở trên và
  // không được đụng tới.
  //
  // Diện mạo lấy theo web `frontend_manage/src/styles/components.css` mục
  // ORDERING QUIZ STYLES: dòng nền trắng viền `#E2E8F0`, đang kéo thì viền
  // `#2563EB` + nền `#EFF6FF`, ô số thứ tự nền đặc `#2563EB` chữ trắng bo 6px.
  // KHÔNG gradient, KHÔNG bóng dày ở bất kỳ đâu.

  /// Tay cầm kéo thả: chỉ một icon, đặt trong vùng chạm 36x40.
  ///
  /// Bản cũ là ô 44x44 tô gradient tím + đổ bóng — to và đậm hơn cả ô số thứ
  /// tự, trong khi con số mới là thứ sinh viên phải đọc. Nay tay cầm lùi về
  /// đúng vai trò gợi ý thao tác: màu [QuizColors.lineStrong] lúc nghỉ, đổi
  /// sang [QuizColors.accent] khi dòng đang được nhấc lên. Vùng chạm vẫn giữ
  /// 40px chiều cao — ngưỡng tối thiểu để ngón cái bấm trúng ngay lần đầu.
  ///
  /// Chỉ có icon nên phải kèm [Semantics] — không có nhãn thì trình đọc màn
  /// hình chỉ thấy một ô trống không biết để làm gì. (Chưa có khoá dịch riêng
  /// cho tay cầm kéo thả nên tạm mượn dòng hướng dẫn của cả câu.)
  Widget _dragHandle(String label, {required bool isDragging}) {
    return Semantics(
      label: label,
      button: true,
      child: SizedBox(
        width: 36,
        height: 40,
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedDragDropVertical,
          size: 20.0,
          color: isDragging ? QuizColors.accent : QuizColors.lineStrong,
        ),
      ),
    );
  }

  /// Một dòng đáp án. `isDragging` chỉ đổi diện mạo, không đổi dữ liệu.
  Widget _buildRow(
    int index, {
    required bool isDragging,
    required String dragHandleLabel,
  }) {
    final item = items[index];
    final locked = widget.submitted;

    return QuizOptionTile(
      key: ValueKey(item.answerId),
      // Ô đánh dấu hình SỐ (QuizMarkerShape.ordinal): với câu sắp xếp thì thứ
      // tự chính là đáp án, nên con số phải là thứ nổi bật nhất trên dòng.
      // Cỡ theo web `.ordering-index` (ô 20px, chữ 12) thay cho ô 32px cũ.
      //
      // isFilled chứ không phải isSelected: con số là ĐỊNH DANH vị trí, dòng
      // nào cũng có, không dòng nào đang "được chọn".
      leading: QuizMarker(
        label: '${index + 1}',
        isSelected: false,
        isFilled: true,
        isDisabled: locked,
        shape: QuizMarkerShape.ordinal,
        size: 20,
      ),
      // isSelected ở đây = "đang bị nhấc lên": [QuizOptionTile] đổi sang nền
      // accentSoft + viền accent, đúng `.ordering-item.dragging` của web.
      isSelected: isDragging,
      isDisabled: locked,
      crossAxisAlignment: CrossAxisAlignment.start,
      trailing: locked
          ? null
          : ReorderableDragStartListener(
              index: index,
              child: _dragHandle(dragHandleLabel, isDragging: isDragging),
            ),
      child: widget.renderMixedContent(item.answerContent, QuizFont.option),
    );
  }

  /// Diện mạo của dòng đang được nhấc lên.
  ///
  /// Nền + viền đã do [QuizOptionTile] lo (xem `isSelected` trong [_buildRow]),
  /// ở đây chỉ thêm hai tín hiệu "đang bay": phóng 1% như web
  /// (`transform: scale(1.01)`) và một quầng sáng MỎNG màu nhấn. Quầng này
  /// thay cho bóng đen blur 24 / dịch xuống 10px của bản cũ — bóng dày làm
  /// dòng đang kéo trông nặng gấp đôi các dòng còn lại và ăn thêm khoảng trống
  /// dọc.
  ///
  /// Quầng vẽ bằng một lớp nền riêng đặt lùi lên đúng phần thân dòng —
  /// [QuizOptionTile] tự chừa `QuizSpacing.betweenOptions` ở đáy làm khoảng
  /// cách giữa hai dòng, nếu vẽ theo cả ô thì sẽ thừa ra một vệt lơ lửng.
  Widget _dragProxy(
    Widget child,
    int index,
    Animation<double> animation,
    String dragHandleLabel,
  ) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final double t = Curves.easeInOut.transform(animation.value);
        return Transform.scale(
          scale: 1 + 0.01 * t,
          child: Stack(
            children: [
              Positioned.fill(
                bottom: QuizSpacing.betweenOptions,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(QuizRadius.option),
                    boxShadow: [
                      BoxShadow(
                        color: QuizColors.accent.withValues(alpha: 0.18 * t),
                        blurRadius: 10 * t,
                        offset: Offset(0, 3 * t),
                      ),
                    ],
                  ),
                ),
              ),
              _buildRow(
                index,
                isDragging: true,
                dragHandleLabel: dragHandleLabel,
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dragHandleLabel = l10n.questionOrderingInstruction;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        QuizInstruction(
          icon: HugeIcons.strokeRoundedSorting05,
          text: l10n.questionOrderingInstruction,
        ),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          // Không đặt buildDefaultDragHandles: false — trên điện thoại nó cho
          // phép nhấn giữ BẤT KỲ đâu trên dòng để kéo, tay cầm bên phải chỉ là
          // đường tắt kéo được ngay.
          proxyDecorator: (child, index, animation) =>
              _dragProxy(child, index, animation, dragHandleLabel),
          itemCount: items.length,
          onReorder: (oldIndex, newIndex) {
            if (widget.submitted) return;
            setState(() {
              if (newIndex > oldIndex) {
                newIndex -= 1;
              }
              final item = items.removeAt(oldIndex);
              items.insert(newIndex, item);
            });
            _notifyOrderChanged();
          },
          itemBuilder: (context, index) => _buildRow(
            index,
            isDragging: false,
            dragHandleLabel: dragHandleLabel,
          ),
        ),
      ],
    );
  }
}
