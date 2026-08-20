import '../../models/DTOs/originalExamPaperDto.dart';
import 'question_type_enum.dart';

/// MỘT đơn vị hiển thị của màn thi: đúng một trang trong `PageView` và đúng
/// một ô trong lưới điều hướng.
///
/// Đây là bản Flutter của `FlattenedQuestionUnit` bên web
/// (`frontend_manage/src/utils/flattenQuestionStructures.ts`). Mọi phép đếm,
/// đánh số và điều hướng của màn thi phải chạy trên danh sách đơn vị này chứ
/// KHÔNG chạy trên `originalExamPaper.details` nữa: một câu cấp 1 có thể sinh
/// ra nhiều đơn vị (Reading) hoặc chiếm nhiều số thứ tự (Matching / TFNG).
class FlattenedQuestionUnit {
  /// Câu hỏi gốc đã được sắp xếp lại (câu con theo `order`, đáp án theo
  /// `order`). Giữ lại vì vài widget cần cả cây: `MatchingQuizWidget` nhận
  /// nguyên câu cha, `TFNGQuizWidget` nhận danh sách câu con.
  final OriginalExamPaperDetailDto source;

  /// Khoá lưu đáp án của đơn vị này.
  ///
  /// - Đơn vị thường / câu con Reading: id của CHÍNH câu lá đó.
  /// - Đơn vị gộp (Matching / TFNG): id câu cha — nhưng đơn vị gộp KHÔNG bao
  ///   giờ tự lưu đáp án, từng câu con của nó mới lưu (xem [answerableIds]).
  final String id;

  /// Nội dung/đề bài của chính đơn vị này.
  final String questionContent;

  /// Đáp án của chính đơn vị này, đã sắp theo `order`.
  final List<AnswerDto> answers;

  /// Đơn vị này được tách ra từ một câu cha (câu con Reading).
  final bool isChildQuestion;

  /// Id câu cha (chỉ có khi [isChildQuestion]).
  final String? parentDetailId;

  /// Nội dung câu cha — đoạn văn đọc hiểu — được LẶP LẠI trên từng câu con,
  /// đúng như web làm.
  final String? parentContent;

  final int questionType;

  /// Các câu con nằm CHUNG trong đơn vị này (chỉ Matching / TFNG). Rỗng với
  /// mọi loại đơn vị khác.
  final List<FlattenedQuestionUnit> subQuestions;

  /// Số thứ tự toàn cục đầu tiên mà đơn vị này chiếm (bắt đầu từ 1).
  final int displayIndex;

  /// Nhãn hiển thị: `"3"` với đơn vị một số, `"3-7"` với đơn vị gộp nhiều số.
  final String displayLabel;

  final bool isAudio;

  /// Số lượt nghe riêng của câu (null = kế thừa đề/ca; <= 0 = không giới hạn).
  final int? maxListenCount;

  /// Mức độ khó của CHÍNH đơn vị này (câu con giữ mức của câu con, không kế
  /// thừa của câu cha).
  final int? difficultyLevel;

  const FlattenedQuestionUnit({
    required this.source,
    required this.id,
    required this.questionContent,
    required this.answers,
    required this.isChildQuestion,
    required this.questionType,
    required this.subQuestions,
    required this.displayIndex,
    required this.displayLabel,
    this.parentDetailId,
    this.parentContent,
    this.isAudio = false,
    this.maxListenCount,
    this.difficultyLevel,
  });

  /// Đơn vị gộp nhiều câu con vào một trang (Matching / TFNG).
  bool get isGroup => subQuestions.isNotEmpty;

  /// Số ô số thứ tự mà đơn vị này chiếm (đơn vị gộp chiếm bằng số câu con).
  int get span => subQuestions.isEmpty ? 1 : subQuestions.length;

  /// Các id THỰC SỰ nhận đáp án của đơn vị này.
  ///
  /// RÀNG BUỘC SỐNG CÒN: backend chỉ chấm câu LÁ, nên danh sách này chỉ chứa
  /// id câu lá. Đơn vị thường trả về chính nó; đơn vị gộp trả về id các câu
  /// con lá của nó.
  List<String> get answerableIds {
    if (source.childQuestions.isNotEmpty) return _leafIds(source);
    return id.isEmpty ? const <String>[] : <String>[id];
  }
}

/// Chặn trên cho độ sâu cây câu hỏi.
///
/// Backend hiện chỉ sinh cây sâu 2 cấp (cha → con) và web cũng chỉ làm phẳng
/// đúng một cấp. Mobile đi sâu hơn vài cấp để dữ liệu lồng bất thường không
/// làm MẤT HẲN câu hỏi (sinh viên không thấy thì không làm được), nhưng vẫn
/// phải có ngưỡng dừng để không treo UI.
const int _maxFlattenDepth = 4;

/// Các loại câu GỘP toàn bộ câu con vào MỘT đơn vị hiển thị.
///
/// Lấy đúng theo web (`flattenQuestionStructures.ts:36-37`): chỉ Matching và
/// TFNG. Mọi loại câu cha khác (điển hình là Reading) bị tách thành mỗi câu
/// con một đơn vị.
bool isGroupedQuestionType(int questionType) =>
    questionType == QuestionType.matching || questionType == QuestionType.tfng;

/// Làm phẳng cây câu hỏi thành danh sách đơn vị hiển thị.
///
/// Thuật toán giữ nguyên ngữ nghĩa của
/// `frontend_manage/src/utils/flattenQuestionStructures.ts`:
///
/// 1. Câu cha có con và thuộc Matching/TFNG → MỘT đơn vị chứa toàn bộ câu con,
///    chiếm N số thứ tự, nhãn `"đầu-cuối"` khi N > 1.
/// 2. Câu cha có con và KHÔNG phải Matching/TFNG (Reading) → MỖI câu con một
///    đơn vị, mang theo đoạn văn của câu cha, mỗi đơn vị một số thứ tự.
/// 3. Câu không có con → một đơn vị bình thường.
List<FlattenedQuestionUnit> flattenQuestions(
  List<OriginalExamPaperDetailDto> questions,
) {
  if (questions.isEmpty) return const <FlattenedQuestionUnit>[];

  final result = <FlattenedQuestionUnit>[];
  var globalIndex = 0;

  void emit(
    OriginalExamPaperDetailDto node, {
    required int depth,
    String? parentDetailId,
    String? parentContent,
  }) {
    final children = node.childQuestions;
    final hasChildren = children.isNotEmpty;

    // ---- Trường hợp 1: đơn vị GỘP (Matching / TFNG) ----
    if (hasChildren && isGroupedQuestionType(node.questionType)) {
      final startingIndex = globalIndex + 1;
      final endingIndex = globalIndex + children.length;

      final subUnits = <FlattenedQuestionUnit>[];
      for (var i = 0; i < children.length; i++) {
        final child = children[i];
        subUnits.add(
          FlattenedQuestionUnit(
            source: child,
            id: child.originalExamPaperDetailId,
            questionContent: child.questionContent ?? '',
            answers: child.answers,
            isChildQuestion: true,
            parentDetailId: node.originalExamPaperDetailId,
            questionType: child.questionType,
            subQuestions: const <FlattenedQuestionUnit>[],
            displayIndex: startingIndex + i,
            displayLabel: '${startingIndex + i}',
            isAudio: child.isAudio,
            maxListenCount: child.maxListenCount,
            // Mức khó của chính câu con, KHÔNG kế thừa từ câu cha.
            difficultyLevel: child.difficultyLevel,
          ),
        );
      }

      result.add(
        FlattenedQuestionUnit(
          source: node,
          id: node.originalExamPaperDetailId,
          questionContent: node.questionContent ?? '',
          // Hợp đồng backend: câu cha có câu con thì `answers` luôn rỗng —
          // đáp án nằm ở từng câu con. Giữ nguyên danh sách của câu cha thay
          // vì ép rỗng để không che giấu dữ liệu bất thường.
          answers: node.answers,
          isChildQuestion: depth > 0,
          parentDetailId: parentDetailId,
          parentContent: parentContent,
          questionType: node.questionType,
          subQuestions: subUnits,
          displayIndex: startingIndex,
          displayLabel: children.length > 1
              ? '$startingIndex-$endingIndex'
              : '$startingIndex',
          isAudio: node.isAudio,
          maxListenCount: node.maxListenCount,
          difficultyLevel: node.difficultyLevel,
        ),
      );
      globalIndex = endingIndex;
      return;
    }

    // ---- Trường hợp 2: câu cha Reading → mỗi câu con một đơn vị ----
    if (hasChildren && depth < _maxFlattenDepth) {
      final ownContent = node.questionContent ?? '';
      // Đoạn văn hiển thị cho câu con: nội dung của câu cha gần nhất CÓ chữ.
      final passedContent = ownContent.isNotEmpty ? ownContent : parentContent;

      for (final child in children) {
        emit(
          child,
          depth: depth + 1,
          parentDetailId: node.originalExamPaperDetailId.trim().isNotEmpty
              ? node.originalExamPaperDetailId
              : child.parentQuestionId,
          parentContent: passedContent,
        );
      }
      return;
    }

    // ---- Trường hợp 3: câu lá (hoặc chạm ngưỡng độ sâu) ----
    globalIndex += 1;
    result.add(
      FlattenedQuestionUnit(
        source: node,
        id: node.originalExamPaperDetailId,
        questionContent: node.questionContent ?? '',
        answers: node.answers,
        isChildQuestion: depth > 0,
        parentDetailId: parentDetailId,
        parentContent: parentContent,
        questionType: node.questionType,
        subQuestions: const <FlattenedQuestionUnit>[],
        displayIndex: globalIndex,
        displayLabel: '$globalIndex',
        isAudio: node.isAudio,
        maxListenCount: node.maxListenCount,
        difficultyLevel: node.difficultyLevel,
      ),
    );
  }

  for (final question in _sortedByOrder(questions, (q) => q.order)) {
    emit(_normalized(question), depth: 0);
  }

  return result;
}

/// Bản sao của [node] với câu con và đáp án đã sắp theo `order`.
///
/// Web sắp bằng `Array.prototype.sort` — vốn ỔN ĐỊNH theo chuẩn — nên đề mà
/// backend không điền `order` (tất cả bằng 0) vẫn giữ nguyên thứ tự gốc.
/// `List.sort` của Dart KHÔNG ổn định, vì vậy [_sortedByOrder] phải tự chèn
/// chỉ số gốc làm khoá phụ; thiếu bước này thì "Câu 1/2/3" của mobile và của
/// web trỏ vào hai câu khác nhau.
OriginalExamPaperDetailDto _normalized(
  OriginalExamPaperDetailDto node, {
  int depth = 0,
}) {
  final children = depth >= _maxFlattenDepth
      ? node.childQuestions
      : _sortedByOrder(
          node.childQuestions,
          (c) => c.order,
        ).map((child) => _normalized(child, depth: depth + 1)).toList();

  return OriginalExamPaperDetailDto(
    originalExamPaperDetailId: node.originalExamPaperDetailId,
    order: node.order,
    questionContent: node.questionContent,
    correctAnswerIndex: node.correctAnswerIndex,
    parentQuestionId: node.parentQuestionId,
    chapterId: node.chapterId,
    questionType: node.questionType,
    difficultyLevel: node.difficultyLevel,
    isAudio: node.isAudio,
    maxListenCount: node.maxListenCount,
    canShuffleQuestion: node.canShuffleQuestion,
    answerShuffleInfo: node.answerShuffleInfo,
    parentQuestion: node.parentQuestion,
    childQuestions: children,
    answers: _sortedByOrder(node.answers, (a) => a.order),
  );
}

/// Sắp xếp ỔN ĐỊNH theo `order` (xem lý do ở [_normalized]).
List<T> _sortedByOrder<T>(List<T> items, int Function(T item) orderOf) {
  final indexed = <MapEntry<int, T>>[
    for (var i = 0; i < items.length; i++) MapEntry(i, items[i]),
  ];
  indexed.sort((a, b) {
    final byOrder = orderOf(a.value).compareTo(orderOf(b.value));
    if (byOrder != 0) return byOrder;
    return a.key.compareTo(b.key);
  });
  return indexed.map((entry) => entry.value).toList();
}

/// Id của mọi câu LÁ trong cây [node] — chính là các khoá lưu đáp án hợp lệ.
List<String> _leafIds(OriginalExamPaperDetailDto node) {
  final ids = <String>[];

  void visit(OriginalExamPaperDetailDto current, int depth) {
    if (current.childQuestions.isEmpty || depth >= _maxFlattenDepth) {
      if (current.originalExamPaperDetailId.isNotEmpty) {
        ids.add(current.originalExamPaperDetailId);
      }
      return;
    }
    for (final child in current.childQuestions) {
      visit(child, depth + 1);
    }
  }

  visit(node, 0);
  return ids;
}
