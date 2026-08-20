import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quizz_mobile/l10n/generated/app_localizations.dart';
import 'package:quizz_mobile/models/DTOs/originalExamPaperDto.dart';
import 'package:quizz_mobile/widget/exam/flatten_questions.dart';
import 'package:quizz_mobile/widget/exam/question_content.dart';
import 'package:quizz_mobile/widget/exam/question_type_enum.dart';

AnswerDto _answer({
  required String id,
  required String content,
  required int order,
  required String questionId,
}) {
  return AnswerDto(
    answerId: id,
    order: order,
    answerContent: content,
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
  List<AnswerDto> answers = const [],
  List<OriginalExamPaperDetailDto> children = const [],
}) {
  return OriginalExamPaperDetailDto(
    originalExamPaperDetailId: id,
    order: order,
    questionContent: content,
    chapterId: 0,
    questionType: type,
    canShuffleQuestion: false,
    childQuestions: children,
    answers: answers,
  );
}

/// Câu cha Reading (questionType = 1) với 3 câu con thuộc 3 loại khác nhau.
/// Theo hợp đồng backend, câu cha có câu con thì `answers` LUÔN RỖNG.
OriginalExamPaperDetailDto _buildReadingParent() {
  final child1 = _question(
    id: 'child-1',
    type: QuestionType.singleChoice,
    order: 1,
    content: 'Nội dung câu con một',
    answers: [
      _answer(id: 'a1', content: 'Đáp án A1', order: 1, questionId: 'child-1'),
      _answer(id: 'a2', content: 'Đáp án A2', order: 2, questionId: 'child-1'),
    ],
  );

  final child2 = _question(
    id: 'child-2',
    type: QuestionType.multipleChoice,
    order: 2,
    content: 'Nội dung câu con hai',
    answers: [
      _answer(id: 'b1', content: 'Đáp án B1', order: 1, questionId: 'child-2'),
      _answer(id: 'b2', content: 'Đáp án B2', order: 2, questionId: 'child-2'),
    ],
  );

  final child3 = _question(
    id: 'child-3',
    type: QuestionType.ordering,
    order: 3,
    content: 'Nội dung câu con ba',
    answers: [
      _answer(
        id: 'o1',
        content: 'Vế thứ nhất',
        order: 1,
        questionId: 'child-3',
      ),
      _answer(id: 'o2', content: 'Vế thứ hai', order: 2, questionId: 'child-3'),
    ],
  );

  return _question(
    id: 'parent-reading',
    type: QuestionType.reading,
    order: 1,
    content: 'Đoạn văn đọc hiểu của câu cha',
    answers: const [], // câu cha KHÔNG có đáp án nào
    children: [child1, child2, child3],
  );
}

/// Vẽ MỘT đơn vị đã làm phẳng và trả về danh sách lời gọi `onOptionChange`.
Future<List<(String, String)>> _pumpUnit(
  WidgetTester tester,
  FlattenedQuestionUnit unit, {
  Map<String, String> answersMap = const {},
}) async {
  final calls = <(String, String)>[];

  tester.view.physicalSize = const Size(1400, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('vi'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: QuestionContentWidget(
            unit: unit,
            answersMap: Map<String, String>.from(answersMap),
            submitted: false,
            onOptionChange: (questionId, value) =>
                calls.add((questionId, value)),
            renderMixedContent: (text, fontSize) =>
                Text(text, style: TextStyle(fontSize: fontSize)),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return calls;
}

/// Vẽ đơn vị thứ [index] của đề [questions] sau khi làm phẳng.
Future<List<(String, String)>> _pumpFlattened(
  WidgetTester tester,
  List<OriginalExamPaperDetailDto> questions,
  int index, {
  Map<String, String> answersMap = const {},
}) {
  final units = flattenQuestions(questions);
  return _pumpUnit(tester, units[index], answersMap: answersMap);
}

void main() {
  group('Câu cha Reading: MỖI câu con là MỘT trang riêng', () {
    testWidgets('trang câu con hiện đoạn văn cha + ĐÚNG MỘT câu con', (
      tester,
    ) async {
      // Đơn vị số 0 = câu con thứ nhất của câu cha Reading.
      await _pumpFlattened(tester, [_buildReadingParent()], 0);

      // Đoạn văn của câu cha được LẶP LẠI trên trang của câu con.
      expect(find.text('Đoạn văn đọc hiểu của câu cha'), findsOneWidget);

      // Chỉ câu con đang mở được vẽ — đây chính là lỗi cũ: cả 3 câu con bị
      // liệt kê chung một trang.
      expect(find.text('Nội dung câu con một'), findsOneWidget);
      expect(find.text('Nội dung câu con hai'), findsNothing);
      expect(find.text('Nội dung câu con ba'), findsNothing);

      expect(find.text('Đáp án A1'), findsOneWidget);
      expect(find.text('Đáp án A2'), findsOneWidget);
      expect(find.text('Đáp án B1'), findsNothing);
      expect(find.text('Vế thứ nhất'), findsNothing);
      expect(find.byType(ReorderableListView), findsNothing);
    });

    testWidgets('onOptionChange nhận id CÂU CON, không phải id câu cha', (
      tester,
    ) async {
      final calls = await _pumpFlattened(tester, [_buildReadingParent()], 0);

      await tester.tap(find.text('Đáp án A2'));
      await tester.pumpAndSettle();

      expect(calls, [('child-1', 'a2')]);

      // Backend chỉ chấm câu LÁ -> tuyệt đối không được gửi id câu cha.
      expect(
        calls.where((c) => c.$1 == 'parent-reading'),
        isEmpty,
        reason: 'Không được lưu đáp án dưới id câu cha',
      );
    });

    testWidgets('mỗi câu con dùng đúng widget theo loại CỦA CHÍNH NÓ', (
      tester,
    ) async {
      // Câu con thứ 2 (chọn nhiều đáp án).
      final multiCalls = await _pumpFlattened(tester, [
        _buildReadingParent(),
      ], 1);
      expect(find.text('Đoạn văn đọc hiểu của câu cha'), findsOneWidget);
      expect(find.text('Nội dung câu con hai'), findsOneWidget);
      await tester.tap(find.text('Đáp án B1'));
      await tester.pumpAndSettle();
      expect(multiCalls, [('child-2', 'b1')]);

      // Câu con thứ 3 (sắp xếp) — lưu thứ tự mặc định ngay khi dựng, cũng
      // bằng id câu con.
      final orderCalls = await _pumpFlattened(tester, [
        _buildReadingParent(),
      ], 2);
      expect(find.byType(ReorderableListView), findsOneWidget);
      expect(find.text('Vế thứ nhất'), findsOneWidget);
      expect(orderCalls, [('child-3', 'o1|o2')]);
    });

    testWidgets('câu con lồng thêm một cấp nữa vẫn được vẽ', (tester) async {
      final grandChild = _question(
        id: 'grand-1',
        type: QuestionType.singleChoice,
        content: 'Nội dung câu cháu',
        answers: [
          _answer(
            id: 'g1',
            content: 'Đáp án G1',
            order: 1,
            questionId: 'grand-1',
          ),
        ],
      );
      final parent = _question(
        id: 'parent-2-cap',
        type: QuestionType.reading,
        content: 'Đoạn văn nhiều cấp',
        children: [
          _question(
            id: 'child-long',
            type: QuestionType.reading,
            content: 'Nội dung câu con lồng',
            children: [grandChild],
          ),
        ],
      );

      final units = flattenQuestions([parent]);
      expect(units.map((u) => u.id).toList(), ['grand-1']);

      final calls = await _pumpUnit(tester, units.single);

      expect(find.text('Nội dung câu cháu'), findsOneWidget);
      // Đoạn văn hiển thị là của câu cha gần nhất CÓ chữ.
      expect(find.text('Nội dung câu con lồng'), findsOneWidget);

      await tester.tap(find.text('Đáp án G1'));
      await tester.pumpAndSettle();

      expect(calls, [('grand-1', 'g1')]);
    });
  });

  group('Câu KHÔNG có câu con giữ nguyên hành vi cũ', () {
    testWidgets('câu trắc nghiệm thường vẽ đáp án và lưu bằng id của nó', (
      tester,
    ) async {
      final normal = _question(
        id: 'q-thuong',
        type: QuestionType.singleChoice,
        content: 'Thủ đô của Việt Nam là gì?',
        answers: [
          _answer(
            id: 'ans-1',
            content: 'Hà Nội',
            order: 1,
            questionId: 'q-thuong',
          ),
          _answer(
            id: 'ans-2',
            content: 'Huế',
            order: 2,
            questionId: 'q-thuong',
          ),
        ],
      );

      final calls = await _pumpFlattened(tester, [normal], 0);

      expect(find.text('Thủ đô của Việt Nam là gì?'), findsOneWidget);
      expect(find.text('Hà Nội'), findsOneWidget);
      // Không phải câu con -> không vẽ khung đoạn văn cha.
      expect(find.text('Bài đọc / Ngữ cảnh:'), findsNothing);

      await tester.tap(find.text('Hà Nội'));
      await tester.pumpAndSettle();

      expect(calls, [('q-thuong', 'ans-1')]);
    });

    testWidgets('câu TFNG vẫn gộp một trang và tự vẽ toàn bộ câu con', (
      tester,
    ) async {
      final tfng = _question(
        id: 'q-tfng',
        type: QuestionType.tfng,
        content: 'Đọc và chọn True / False / Not Given',
        children: [
          _question(
            id: 'tfng-1',
            order: 1,
            content: 'Mệnh đề số một',
            answers: [
              _answer(
                id: 't1',
                content: 'TRUE',
                order: 1,
                questionId: 'tfng-1',
              ),
              _answer(
                id: 'f1',
                content: 'FALSE',
                order: 2,
                questionId: 'tfng-1',
              ),
            ],
          ),
          _question(
            id: 'tfng-2',
            order: 2,
            content: 'Mệnh đề số hai',
            answers: [
              _answer(
                id: 't2',
                content: 'TRUE',
                order: 1,
                questionId: 'tfng-2',
              ),
            ],
          ),
        ],
      );

      final units = flattenQuestions([tfng]);
      // Matching/TFNG KHÔNG bị tách: vẫn đúng một đơn vị, chiếm 2 số thứ tự.
      expect(units.length, 1);
      expect(units.single.displayLabel, '1-2');

      final calls = await _pumpUnit(tester, units.single);

      // Cả hai mệnh đề nằm chung một trang.
      expect(find.text('Mệnh đề số một'), findsOneWidget);
      expect(find.text('Mệnh đề số hai'), findsOneWidget);

      await tester.tap(find.text('FALSE'));
      await tester.pumpAndSettle();

      expect(calls, [('tfng-1', 'f1')]);
    });
  });
}
