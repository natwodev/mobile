import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quizz_mobile/l10n/generated/app_localizations.dart';
import 'package:quizz_mobile/models/DTOs/originalExamPaperDto.dart';
import 'package:quizz_mobile/widget/exam/quiz_theme.dart';
import 'package:quizz_mobile/widget/exam/question_types/true_false_quiz_widget.dart';
import 'package:quizz_mobile/widget/exam/question_types/tfng_quiz_widget.dart';

/// Lỗi im lặng đã lên tới máy thật: câu Đúng/Sai được chuyển sang [QuizChoiceChip]
/// xếp ngang, nhưng trên màn hình hai chip vẫn nằm CHỒNG DỌC và kéo dài hết bề
/// ngang — đúng thứ mà chip sinh ra để thay thế.
///
/// Nguyên nhân là `Container.alignment`: nó bọc con trong một [Align] KHÔNG có
/// `widthFactor`, mà Align không factor thì nở hết ràng buộc lỏng. Trong [Wrap],
/// ràng buộc lỏng rộng bằng cả hàng, nên mỗi chip chiếm trọn một dòng.
///
/// `flutter analyze` không thấy được lỗi này (code hợp lệ) và test cũ cũng
/// không, vì không có test nào nhìn tới TOẠ ĐỘ của chip. Bộ test này canh đúng
/// chỗ đó: chip phải nằm CÙNG MỘT HÀNG và phải HẸP HƠN bề ngang màn hình.
AnswerDto _answer({required String id, required String content, int order = 1}) {
  return AnswerDto(
    answerId: id,
    order: order,
    answerContent: content,
    isCorrect: false,
    canShuffleAnswer: false,
    originalExamPaperDetailId: 'q1',
  );
}

/// Bề ngang thật của khung màn hình test, sau khi đã trừ padding của [_pump].
const double _screenWidth = 320;

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(_screenWidth, 568);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('vi'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
  await tester.pumpAndSettle();
}

Widget _plainContent(String text, double fontSize) =>
    Text(text, style: TextStyle(fontSize: fontSize));

/// Hình chữ nhật của chip mang đúng nhãn [label].
///
/// Tìm theo [QuizChoiceChip] chứ không theo [Text]: [Text] nằm lọt bên trong
/// chip nên bề ngang của nó luôn nhỏ, đo nó thì lỗi phình chip lọt lưới.
Rect _chipRect(WidgetTester tester, String label) {
  final finder = find.ancestor(
    of: find.text(label),
    matching: find.byType(QuizChoiceChip),
  );
  expect(finder, findsOneWidget, reason: 'không thấy chip "$label"');
  return tester.getRect(finder);
}

void main() {
  testWidgets('Đúng/Sai: hai chip nằm cùng một hàng, không chiếm hết bề ngang', (
    tester,
  ) async {
    await _pump(
      tester,
      TrueFalseQuizWidget(
        answers: [
          _answer(id: 'a1', content: 'Đúng', order: 1),
          _answer(id: 'a2', content: 'Sai', order: 2),
        ],
        submitted: false,
        onOptionChange: (_) {},
      ),
    );

    final dung = _chipRect(tester, 'Đúng');
    final sai = _chipRect(tester, 'Sai');

    // Cùng một hàng: mép trên trùng nhau.
    expect(dung.top, sai.top, reason: 'hai chip phải nằm cùng một hàng');
    // Nằm cạnh nhau chứ không đè lên nhau.
    expect(dung.right, lessThanOrEqualTo(sai.left));
    // Không chip nào được nở hết bề ngang — đây là chính lỗi cũ.
    for (final rect in [dung, sai]) {
      expect(
        rect.width,
        lessThan(_screenWidth / 2),
        reason: 'chip đang nở hết bề ngang như hộp đáp án cũ',
      );
    }
    // Vùng chạm vẫn đủ cao.
    expect(dung.height, greaterThanOrEqualTo(40));
  });

  testWidgets('TFNG: ba chip của một mệnh đề nằm cùng một hàng', (tester) async {
    final sub = OriginalExamPaperDetailDto(
      originalExamPaperDetailId: 'sub-1',
      order: 1,
      questionContent: 'Mệnh đề thứ nhất của bài đọc.',
      chapterId: 1,
      questionType: 6,
      canShuffleQuestion: false,
      childQuestions: const [],
      answers: [
        _answer(id: 'a1', content: 'True', order: 1),
        _answer(id: 'a2', content: 'False', order: 2),
        _answer(id: 'a3', content: 'Not Given', order: 3),
      ],
    );

    await _pump(
      tester,
      TFNGQuizWidget(
        subQuestions: [sub],
        answersMap: const {},
        submitted: false,
        onOptionChange: (_, _) {},
        renderMixedContent: _plainContent,
      ),
    );

    final t = _chipRect(tester, 'True');
    final f = _chipRect(tester, 'False');
    final ng = _chipRect(tester, 'Not Given');

    expect(t.top, f.top);
    expect(f.top, ng.top);
    expect(t.right, lessThanOrEqualTo(f.left));
    expect(f.right, lessThanOrEqualTo(ng.left));
    // Ba chip cộng lại vẫn phải lọt trong một hàng của màn 320dp.
    expect(ng.right, lessThanOrEqualTo(_screenWidth));
  });
}
