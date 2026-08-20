import 'package:flutter_test/flutter_test.dart';

import 'package:quizz_mobile/models/DTOs/originalExamPaperDto.dart';
import 'package:quizz_mobile/widget/exam/question_navigator.dart';
import 'package:quizz_mobile/widget/exam/question_type_enum.dart';

/// Dựng nhanh một câu hỏi của đề (chỉ các trường mà việc đếm câu cần tới).
OriginalExamPaperDetailDto _question({
  required String id,
  int type = QuestionType.singleChoice,
  int order = 0,
  List<OriginalExamPaperDetailDto> children = const [],
}) {
  return OriginalExamPaperDetailDto(
    originalExamPaperDetailId: id,
    order: order,
    chapterId: 0,
    questionType: type,
    canShuffleQuestion: false,
    childQuestions: children,
  );
}

void main() {
  // Đề mẫu: 3 câu CẤP 1, trong đó 2 câu là câu cha có câu con.
  //   1. q1  - trắc nghiệm thường
  //   2. q2  - Matching, 3 câu con
  //   3. q3  - TFNG, 2 câu con
  final questions = <OriginalExamPaperDetailDto>[
    _question(id: 'q1', order: 1),
    _question(
      id: 'q2',
      order: 2,
      type: QuestionType.matching,
      children: [
        _question(id: 'q2c1', order: 1),
        _question(id: 'q2c2', order: 2),
        _question(id: 'q2c3', order: 3),
      ],
    ),
    _question(
      id: 'q3',
      order: 3,
      type: QuestionType.tfng,
      children: [
        _question(id: 'q3c1', order: 1),
        _question(id: 'q3c2', order: 2),
      ],
    ),
  ];

  group('ExamProgress đếm câu trên cùng một tập với tổng số câu', () {
    test('id câu con không làm số "đã trả lời" vượt tổng số câu', () {
      // Sinh viên đã nối xong cả 3 vế của câu Matching và trả lời 1 trong 2 ý
      // của câu TFNG -> bảng đáp án có 5 khoá trong khi đề chỉ có 3 câu.
      final answers = <String, String>{
        'q1': 'a1',
        'q2c1': 'x',
        'q2c2': 'y',
        'q2c3': 'z',
        'q3c1': 'TRUE',
      };

      final progress = ExamProgress.fromQuestions(
        questions: questions,
        answers: answers,
      );

      // Cách đếm cũ (selectedAnswers.length) cho 5/3 — đúng thứ đang gây lệch.
      expect(answers.length, greaterThan(questions.length));

      expect(progress.total, 3);
      expect(progress.answeredCount, 2); // q1 + q2
      expect(progress.answeredCount, lessThanOrEqualTo(progress.total));
      expect(
        progress.answeredCount +
            progress.partialCount +
            progress.unansweredCount,
        progress.total,
      );
    });

    test('câu cha Matching chỉ "đã làm" khi trả lời hết câu con', () {
      final progress = ExamProgress.fromQuestions(
        questions: questions,
        answers: const {'q2c1': 'x', 'q2c2': 'y', 'q2c3': 'z'},
      );

      expect(progress.stateAt(1), QuestionAnswerState.answered);
      expect(progress.answeredCount, 1);
    });

    test('câu cha TFNG trả lời dở dang là "làm dở", chưa tính là đã làm', () {
      final progress = ExamProgress.fromQuestions(
        questions: questions,
        answers: const {'q3c1': 'TRUE'},
      );

      expect(progress.stateAt(2), QuestionAnswerState.partial);
      expect(progress.answeredCount, 0);
      expect(progress.partialCount, 1);
      expect(progress.unansweredCount, 2);
    });

    test('trả lời hết câu con TFNG thì câu cha thành "đã làm"', () {
      final progress = ExamProgress.fromQuestions(
        questions: questions,
        answers: const {'q3c1': 'TRUE', 'q3c2': 'FALSE'},
      );

      expect(progress.stateAt(2), QuestionAnswerState.answered);
      expect(progress.answeredCount, 1);
    });

    test('không câu nào được trả lời thì mọi câu đều "chưa làm"', () {
      final progress = ExamProgress.fromQuestions(
        questions: questions,
        answers: const {},
      );

      expect(progress.answeredCount, 0);
      expect(progress.partialCount, 0);
      expect(progress.unansweredCount, 3);
      expect(progress.stateAt(0), QuestionAnswerState.unanswered);
      expect(progress.stateAt(1), QuestionAnswerState.unanswered);
      expect(progress.stateAt(2), QuestionAnswerState.unanswered);
    });

    test('ô trống "-" hay chuỗi rỗng không được tính là đã trả lời', () {
      final progress = ExamProgress.fromQuestions(
        questions: questions,
        answers: const {
          'q1': '-',
          'q2c1': '',
          'q2c2': '   ',
          'q2c3': 'z',
          'q3c1': '-',
          'q3c2': '-',
        },
      );

      expect(progress.stateAt(0), QuestionAnswerState.unanswered);
      expect(progress.stateAt(1), QuestionAnswerState.partial); // chỉ q2c3
      expect(progress.stateAt(2), QuestionAnswerState.unanswered);
      expect(progress.answeredCount, 0);
      expect(ExamProgress.isAnswerFilled('-'), isFalse);
      expect(ExamProgress.isAnswerFilled(null), isFalse);
      expect(ExamProgress.isAnswerFilled('A'), isTrue);
    });

    test('id câu con quy về đúng ô câu cha trong lưới điều hướng', () {
      final progress = ExamProgress.fromQuestions(
        questions: questions,
        answers: const {},
      );

      expect(progress.questionIndexOf('q1'), 0);
      expect(progress.questionIndexOf('q2c2'), 1);
      expect(progress.questionIdAt(progress.questionIndexOf('q2c2')!), 'q2');
      expect(progress.questionIndexOf('q3c2'), 2);
      expect(progress.questionIdAt(progress.questionIndexOf('q3c2')!), 'q3');
      expect(progress.questionIndexOf('khong-ton-tai'), isNull);
    });

    test('câu cha lưu đáp án gộp trên chính id của nó vẫn tính là đã làm', () {
      final progress = ExamProgress.fromQuestions(
        questions: questions,
        answers: const {'q2': 'a-1;b-2;c-3'},
      );

      expect(progress.stateAt(1), QuestionAnswerState.answered);
      expect(progress.answeredCount, 1);
    });

    test('đề rỗng không làm vỡ phép đếm', () {
      final progress = ExamProgress.fromQuestions(
        questions: const [],
        answers: const {'q1': 'a'},
      );

      expect(progress.total, 0);
      expect(progress.answeredCount, 0);
      expect(progress.stateAt(0), QuestionAnswerState.unanswered);
      expect(progress.questionIdAt(0), '');
    });
  });
}
