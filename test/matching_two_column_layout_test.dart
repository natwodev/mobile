import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quizz_mobile/l10n/generated/app_localizations.dart';
import 'package:quizz_mobile/models/DTOs/originalExamPaperDto.dart';
import 'package:quizz_mobile/widget/exam/question_types/matching_quiz_widget.dart';

/// Test TẠM (không commit): bố cục hai cột của câu nối trên máy 320x568.
/// RenderFlex tràn -> Flutter ném FlutterError -> `tester.takeException()`
/// khác null -> test fail.

AnswerDto _answer(String id, String content) => AnswerDto(
  answerId: id,
  order: 1,
  answerContent: content,
  isCorrect: false,
  canShuffleAnswer: false,
  originalExamPaperDetailId: 'sub-x',
);

OriginalExamPaperDetailDto _sub(String id, String content, List<AnswerDto> a) =>
    OriginalExamPaperDetailDto(
      originalExamPaperDetailId: id,
      order: 1,
      questionContent: content,
      chapterId: 0,
      questionType: 2,
      canShuffleQuestion: false,
      answers: a,
    );

OriginalExamPaperDetailDto _matchingQuestion() {
  final answers = [
    _answer('ans-1', 'Đáp án số một rất dài để ép chữ vỡ nhiều dòng trong cột hẹp'),
    _answer('ans-2', 'Đáp án số hai cũng dài không kém gì đáp án số một ở trên'),
    _answer('ans-3', 'Nucleotide adenine guanine cytosine thymine'),
    _answer('ans-4', 'Đáp án bốn'),
  ];
  return OriginalExamPaperDetailDto(
    originalExamPaperDetailId: 'parent-1',
    order: 1,
    questionContent: 'Nối các vế ở cột A với đáp án tương ứng ở cột B',
    chapterId: 0,
    questionType: 2,
    canShuffleQuestion: false,
    childQuestions: [
      _sub('sub-1', 'Vế câu hỏi thứ nhất dài lê thê để kiểm tra việc vỡ dòng trong cột hẹp 148dp', answers),
      _sub('sub-2', 'Vế câu hỏi thứ hai cũng dài tương đương và có cả một từ siêu dài Pneumonoultramicroscopicsilicovolcanoconiosis', answers),
      _sub('sub-3', 'Vế câu hỏi thứ ba với công thức a2 + b2 = c2 và vài chữ nữa cho đủ dài', answers),
      _sub('sub-4', 'Vế câu hỏi thứ tư dài không kém ba vế phía trên để ép layout tới hạn', answers),
    ],
    answers: const [],
  );
}

Widget _plain(String text, double fontSize) =>
    Text(text, style: TextStyle(fontSize: fontSize));

Future<void> _pump(
  WidgetTester tester, {
  required Map<String, String> answers,
  required bool submitted,
  required double horizontalPadding,
  double textScale = 1.0,
  void Function(String subId, String answerId)? onChange,
}) async {
  tester.view.physicalSize = const Size(320, 568);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('vi'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: Scaffold(
          body: RepaintBoundary(
            key: _boundaryKey,
            child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: MatchingQuizWidget(
                currentQuestion: _matchingQuestion(),
                answersMap: answers,
                submitted: submitted,
                onOptionChange: (subId, answerId) =>
                    onChange?.call(subId, answerId),
                renderMixedContent: _plain,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

final GlobalKey _boundaryKey = GlobalKey();

/// Đếm điểm ảnh mang màu cặp nối #3b82f6 trong DẢI HÀNH LANG giữa hai cột.
/// Không widget nào khác vẽ vào dải này, nên đếm > 0 nghĩa là đường nối đã
/// được đo và vẽ thật.
Future<int> _corridorPixels(WidgetTester tester) async {
  var hits = 0;
  await tester.runAsync(() async {
    final boundary =
        _boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final bytes = data!.buffer.asUint8List();
    // padding 12 + cột (320-24-24)/2 = 136 -> hành lang là x thuộc [150, 170).
    for (var y = 0; y < image.height; y++) {
      for (var x = 150; x < 170; x++) {
        final i = (y * image.width + x) * 4;
        final dr = (bytes[i] - 0x3b).abs();
        final dg = (bytes[i + 1] - 0x82).abs();
        final db = (bytes[i + 2] - 0xf6).abs();
        if (dr < 40 && dg < 40 && db < 40) hits++;
      }
    }
    image.dispose();
  });
  return hits;
}

void main() {
  for (final padding in <double>[0, 12, 20]) {
    testWidgets('320x568 padding $padding — chưa nối gì, không tràn pixel', (
      tester,
    ) async {
      await _pump(
        tester,
        answers: const {},
        submitted: false,
        horizontalPadding: padding,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('320x568 padding $padding — đã nối hết, không tràn pixel', (
      tester,
    ) async {
      await _pump(
        tester,
        answers: const {
          'sub-1': 'ans-1',
          'sub-2': 'ans-2',
          'sub-3': 'ans-3',
          'sub-4': 'ans-4',
        },
        submitted: false,
        horizontalPadding: padding,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('320x568 — hai vế cùng trỏ một đáp án, không tràn pixel', (
    tester,
  ) async {
    await _pump(
      tester,
      answers: const {'sub-1': 'ans-1', 'sub-2': 'ans-1', 'sub-3': 'ans-1'},
      submitted: false,
      horizontalPadding: 12,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('320x568 — đã nộp bài, không tràn pixel', (tester) async {
    await _pump(
      tester,
      answers: const {'sub-1': 'ans-1', 'sub-2': 'ans-2'},
      submitted: true,
      horizontalPadding: 12,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('320x568 cỡ chữ x1.3 — không tràn pixel', (tester) async {
    await _pump(
      tester,
      answers: const {'sub-1': 'ans-1'},
      submitted: false,
      horizontalPadding: 12,
      textScale: 1.3,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Chạm Cột A rồi Cột B gửi đúng id câu con + đường nối được vẽ', (
    tester,
  ) async {
    final calls = <String>[];
    await _pump(
      tester,
      answers: const {},
      submitted: false,
      horizontalPadding: 12,
      onChange: (subId, answerId) => calls.add('$subId=$answerId'),
    );

    // Bấm Cột B trước khi cầm vế nào -> không gửi gì.
    await tester.tap(find.textContaining('Đáp án bốn'));
    await tester.pumpAndSettle();
    expect(calls, isEmpty);

    await tester.tap(find.textContaining('Vế câu hỏi thứ nhất'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Đáp án bốn'));
    await tester.pumpAndSettle();
    expect(calls, ['sub-1=ans-4']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Hành lang giữa hai cột: có cặp nối thì có nét vẽ, không thì trống', (
    tester,
  ) async {
    await _pump(
      tester,
      answers: const {},
      submitted: false,
      horizontalPadding: 12,
    );
    expect(await _corridorPixels(tester), 0);

    await _pump(
      tester,
      answers: const {'sub-1': 'ans-1'},
      submitted: false,
      horizontalPadding: 12,
    );
    expect(await _corridorPixels(tester), greaterThan(10));
    expect(tester.takeException(), isNull);
  });
}
