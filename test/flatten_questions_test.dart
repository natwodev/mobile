import 'package:flutter_test/flutter_test.dart';

import 'package:quizz_mobile/models/DTOs/originalExamPaperDto.dart';
import 'package:quizz_mobile/widget/exam/flatten_questions.dart';
import 'package:quizz_mobile/widget/exam/question_type_enum.dart';

AnswerDto _answer({
  required String id,
  required int order,
  String content = '',
  String questionId = '',
}) {
  return AnswerDto(
    answerId: id,
    order: order,
    answerContent: content.isEmpty ? id : content,
    isCorrect: false,
    canShuffleAnswer: false,
    originalExamPaperDetailId: questionId,
  );
}

OriginalExamPaperDetailDto _question({
  required String id,
  int type = QuestionType.singleChoice,
  int order = 1,
  String? content,
  int? difficultyLevel,
  String? parentQuestionId,
  List<AnswerDto> answers = const [],
  List<OriginalExamPaperDetailDto> children = const [],
}) {
  return OriginalExamPaperDetailDto(
    originalExamPaperDetailId: id,
    order: order,
    questionContent: content,
    parentQuestionId: parentQuestionId,
    chapterId: 0,
    questionType: type,
    difficultyLevel: difficultyLevel,
    canShuffleQuestion: false,
    childQuestions: children,
    answers: answers,
  );
}

/// Đề mẫu của đầu bài:
///   1. một câu đơn
///   2. một câu Reading có 3 câu con
///   3. một câu Matching có 2 câu con
List<OriginalExamPaperDetailDto> _sampleExam() {
  return [
    _question(
      id: 'don',
      order: 1,
      content: 'Câu đơn lẻ',
      answers: [
        _answer(id: 'don-a', order: 1, questionId: 'don'),
        _answer(id: 'don-b', order: 2, questionId: 'don'),
      ],
    ),
    _question(
      id: 'doc-hieu',
      order: 2,
      type: QuestionType.reading,
      content: 'Đoạn văn đọc hiểu',
      difficultyLevel: 1,
      children: [
        _question(
          id: 'doc-1',
          order: 1,
          content: 'Câu con một',
          difficultyLevel: 3,
          parentQuestionId: 'doc-hieu',
          answers: [_answer(id: 'r1', order: 1, questionId: 'doc-1')],
        ),
        _question(
          id: 'doc-2',
          order: 2,
          content: 'Câu con hai',
          parentQuestionId: 'doc-hieu',
          answers: [_answer(id: 'r2', order: 1, questionId: 'doc-2')],
        ),
        _question(
          id: 'doc-3',
          order: 3,
          content: 'Câu con ba',
          parentQuestionId: 'doc-hieu',
          answers: [_answer(id: 'r3', order: 1, questionId: 'doc-3')],
        ),
      ],
    ),
    _question(
      id: 'noi',
      order: 3,
      type: QuestionType.matching,
      content: 'Nối cột A với cột B',
      children: [
        _question(
          id: 'noi-1',
          order: 1,
          content: 'Vế trái một',
          parentQuestionId: 'noi',
          answers: [_answer(id: 'm1', order: 1, questionId: 'noi-1')],
        ),
        _question(
          id: 'noi-2',
          order: 2,
          content: 'Vế trái hai',
          parentQuestionId: 'noi',
          answers: [_answer(id: 'm2', order: 1, questionId: 'noi-2')],
        ),
      ],
    ),
  ];
}

void main() {
  group('flattenQuestions: đề 1 câu đơn + Reading 3 con + Matching 2 con', () {
    final units = flattenQuestions(_sampleExam());

    test('sinh đúng 5 đơn vị hiển thị', () {
      // 1 (câu đơn) + 3 (mỗi câu con Reading một đơn vị) + 1 (Matching gộp).
      expect(units.length, 5);
      expect(units.map((u) => u.id).toList(), [
        'don',
        'doc-1',
        'doc-2',
        'doc-3',
        'noi',
      ]);
    });

    test('số thứ tự toàn cục chạy liên tục qua mọi đơn vị', () {
      expect(units.map((u) => u.displayIndex).toList(), [1, 2, 3, 4, 5]);
      expect(units.map((u) => u.displayLabel).toList(), [
        '1',
        '2',
        '3',
        '4',
        '5-6',
      ]);

      // Đơn vị Matching chiếm 2 ô số nên tổng số ô là 6 dù chỉ có 5 đơn vị.
      expect(units.fold<int>(0, (sum, u) => sum + u.span), 6);
    });

    test('đơn vị Matching gộp toàn bộ câu con và mang nhãn "đầu-cuối"', () {
      final matching = units.last;

      expect(matching.isGroup, isTrue);
      expect(matching.questionType, QuestionType.matching);
      expect(matching.displayLabel, '5-6');
      expect(matching.subQuestions.map((s) => s.id).toList(), [
        'noi-1',
        'noi-2',
      ]);
      // Mỗi câu con của cụm giữ số thứ tự riêng bên trong cụm.
      expect(matching.subQuestions.map((s) => s.displayIndex).toList(), [5, 6]);

      // RÀNG BUỘC SỐNG CÒN: khoá lưu đáp án là id CÂU LÁ, không phải id câu cha.
      expect(matching.answerableIds, ['noi-1', 'noi-2']);
    });

    test('mỗi câu con Reading là đơn vị riêng, mang đúng đoạn văn cha', () {
      final readingUnits = units.sublist(1, 4);

      for (final unit in readingUnits) {
        expect(unit.isChildQuestion, isTrue);
        expect(unit.parentContent, 'Đoạn văn đọc hiểu');
        expect(unit.parentDetailId, 'doc-hieu');
        expect(unit.isGroup, isFalse);
        // Câu con Reading tự lưu đáp án dưới id của chính nó.
        expect(unit.answerableIds, [unit.id]);
      }

      expect(readingUnits.map((u) => u.questionContent).toList(), [
        'Câu con một',
        'Câu con hai',
        'Câu con ba',
      ]);
    });

    test('câu đơn không có đoạn văn cha và tự lưu đáp án', () {
      final single = units.first;

      expect(single.isChildQuestion, isFalse);
      expect(single.parentContent, isNull);
      expect(single.parentDetailId, isNull);
      expect(single.answers.map((a) => a.answerId).toList(), [
        'don-a',
        'don-b',
      ]);
      expect(single.answerableIds, ['don']);
    });

    test('câu con giữ mức độ khó của CHÍNH NÓ, không kế thừa của cha', () {
      expect(units[1].difficultyLevel, 3); // doc-1 tự có mức 3
      expect(units[2].difficultyLevel, isNull); // doc-2 chưa phân mức
    });
  });

  group('Thứ tự và các trường hợp biên', () {
    test('đề rỗng cho danh sách rỗng', () {
      expect(flattenQuestions(const []), isEmpty);
    });

    test('câu cấp 1 và câu con được sắp theo `order`', () {
      final units = flattenQuestions([
        _question(id: 'sau', order: 9, content: 'Câu sau'),
        _question(
          id: 'truoc',
          order: 1,
          type: QuestionType.reading,
          content: 'Đoạn văn',
          children: [
            _question(id: 'c2', order: 2, content: 'Con hai'),
            _question(id: 'c1', order: 1, content: 'Con một'),
          ],
        ),
      ]);

      expect(units.map((u) => u.id).toList(), ['c1', 'c2', 'sau']);
      expect(units.map((u) => u.displayLabel).toList(), ['1', '2', '3']);
    });

    test('`order` bằng nhau thì GIỮ NGUYÊN thứ tự gốc (sắp xếp ổn định)', () {
      // Đề thiếu `order` (tất cả bằng 0) là chuyện có thật; sắp xếp không ổn
      // định sẽ xáo tung đề và làm "Câu 1" của mobile khác web.
      final units = flattenQuestions([
        for (final id in ['a', 'b', 'c', 'd', 'e', 'f'])
          _question(id: id, order: 0, content: id),
      ]);

      expect(units.map((u) => u.id).toList(), ['a', 'b', 'c', 'd', 'e', 'f']);
    });

    test('đáp án của mỗi đơn vị được sắp theo `order`', () {
      final units = flattenQuestions([
        _question(
          id: 'q',
          order: 1,
          answers: [
            _answer(id: 'a3', order: 3, questionId: 'q'),
            _answer(id: 'a1', order: 1, questionId: 'q'),
            _answer(id: 'a2', order: 2, questionId: 'q'),
          ],
        ),
      ]);

      expect(units.single.answers.map((a) => a.answerId).toList(), [
        'a1',
        'a2',
        'a3',
      ]);
    });

    test('TFNG cũng gộp một đơn vị như Matching', () {
      final units = flattenQuestions([
        _question(id: 'don', order: 1, content: 'Câu đơn'),
        _question(
          id: 'tfng',
          order: 2,
          type: QuestionType.tfng,
          content: 'Đúng / Sai / Không đề cập',
          children: [
            _question(id: 't1', order: 1, content: 'Mệnh đề một'),
            _question(id: 't2', order: 2, content: 'Mệnh đề hai'),
            _question(id: 't3', order: 3, content: 'Mệnh đề ba'),
          ],
        ),
      ]);

      expect(units.length, 2);
      expect(units.last.displayLabel, '2-4');
      expect(units.last.answerableIds, ['t1', 't2', 't3']);
      expect(isGroupedQuestionType(QuestionType.tfng), isTrue);
      expect(isGroupedQuestionType(QuestionType.reading), isFalse);
    });

    test('đơn vị gộp chỉ có 1 câu con mang nhãn một số, không phải dải', () {
      final units = flattenQuestions([
        _question(
          id: 'noi',
          order: 1,
          type: QuestionType.matching,
          content: 'Nối',
          children: [_question(id: 'noi-1', order: 1, content: 'Vế duy nhất')],
        ),
      ]);

      expect(units.single.displayLabel, '1');
      expect(units.single.displayIndex, 1);
      expect(units.single.span, 1);
    });

    test('câu cha Reading rỗng nội dung không che đoạn văn của ông', () {
      // Cây lồng 2 tầng: đoạn văn nằm ở nút ngoài cùng, nút giữa không có chữ.
      final units = flattenQuestions([
        _question(
          id: 'ngoai',
          order: 1,
          type: QuestionType.reading,
          content: 'Đoạn văn gốc',
          children: [
            _question(
              id: 'giua',
              order: 1,
              type: QuestionType.reading,
              children: [
                _question(id: 'la-1', order: 1, content: 'Câu lá một'),
                _question(id: 'la-2', order: 2, content: 'Câu lá hai'),
              ],
            ),
          ],
        ),
      ]);

      // Không câu nào bị nuốt mất: cả hai câu lá đều thành đơn vị riêng.
      expect(units.map((u) => u.id).toList(), ['la-1', 'la-2']);
      expect(units.map((u) => u.parentContent).toList(), [
        'Đoạn văn gốc',
        'Đoạn văn gốc',
      ]);
      expect(units.map((u) => u.answerableIds).toList(), [
        ['la-1'],
        ['la-2'],
      ]);
    });
  });
}
