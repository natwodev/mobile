import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quizz_mobile/l10n/generated/app_localizations.dart';
import 'package:quizz_mobile/models/DTOs/originalExamPaperDto.dart';
import 'package:quizz_mobile/widget/exam/question_types/dropdown_quiz_widget.dart';
import 'package:quizz_mobile/widget/exam/question_types/fill_in_blank_quiz_widget.dart';
import 'package:quizz_mobile/widget/exam/question_types/short_answer_quiz_widget.dart';

/// Lỗi im lặng đã xảy ra trên máy thật: đề bài hiện ra nhưng KHÔNG có ô nhập
/// nào, vì code được port từ web dùng `String.split(RegExp(...))` với ngữ nghĩa
/// của JavaScript. `split` của Dart VỨT BỎ phần phân tách (kể cả nhóm bắt),
/// nên danh sách `parts` không bao giờ chứa token `__(1)__` / `(1)` và vòng
/// lặp vẽ ô nhập phía sau không khớp gì cả. Bộ test này canh đúng chỗ đó.

AnswerDto _answer({
  required String id,
  required String content,
  int order = 1,
}) {
  return AnswerDto(
    answerId: id,
    order: order,
    answerContent: content,
    isCorrect: false,
    canShuffleAnswer: false,
    originalExamPaperDetailId: 'q1',
  );
}

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(1400, 4000);
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

/// Đếm mũi tên của ô dropdown.
///
/// Không dùng `find.byIcon` được nữa: mũi tên đã chuyển sang [HugeIcon] cho
/// đồng bộ bộ icon với web, mà [HugeIcon] không phải [Icon] nên finder theo
/// IconData trượt hết.
Finder findDropdownArrows() =>
    findHugeIcon(HugeIcons.strokeRoundedArrowDown01, 'mũi tên dropdown');

/// Tìm một [HugeIcon] theo đúng bộ dữ liệu icon của nó.
///
/// `find.byIcon` chỉ nhận [IconData] nên trượt hết với [HugeIcon]; dùng chung
/// hàm này cho mọi icon thay vì viết lại vị từ ở từng chỗ.
Finder findHugeIcon(List<List<dynamic>> icon, String description) =>
    find.byWidgetPredicate(
      (widget) => widget is HugeIcon && identical(widget.icon, icon),
      description: description,
    );

void main() {
  group('Tách ô trống khỏi đề bài', () {
    test('split() của Dart vứt token đi — allMatches mới giữ được', () {
      const content = 'Trước __(1)__ giữa __(2)__ sau';

      // Ngữ nghĩa JavaScript (String.prototype.split giữ nhóm bắt) KHÔNG đúng
      // với Dart: không mảnh nào còn là token ô trống.
      final bySplit = content.split(RegExp(r'(__\(\d+\)__)'));
      expect(
        bySplit.where((p) => RegExp(r'__\((\d+)\)__').hasMatch(p)),
        isEmpty,
        reason: 'split() không giữ token -> không ô nhập nào được vẽ',
      );

      // Cách đúng: duyệt bằng allMatches, đọc được cả chỉ số lẫn vị trí.
      final matches = RegExp(r'__\((\d+)\)__').allMatches(content).toList();
      expect(matches.map((m) => m.group(1)).toList(), ['1', '2']);
      expect(content.substring(0, matches[0].start), 'Trước ');
      expect(content.substring(matches[0].end, matches[1].start), ' giữa ');
      expect(content.substring(matches[1].end), ' sau');
    });

    testWidgets('FillInBlank: 2 ô trống -> 3 mẩu chữ + 2 ô thả từ', (
      tester,
    ) async {
      final calls = <String>[];
      await _pump(
        tester,
        FillInBlankQuizWidget(
          questionContent: 'Thủ đô Việt Nam là __(1)__ còn của Lào là __(2)__.',
          answers: [
            _answer(id: 'w1', content: 'Hà Nội', order: 1),
            _answer(id: 'w2', content: 'Viêng Chăn', order: 2),
          ],
          submitted: false,
          onOptionChange: calls.add,
          renderMixedContent: _plainContent,
        ),
      );

      // Chữ giữa các ô trống vẫn còn nguyên, đúng thứ tự.
      expect(find.text('Thủ đô Việt Nam là '), findsOneWidget);
      expect(find.text(' còn của Lào là '), findsOneWidget);
      expect(find.text('.'), findsOneWidget);

      // Và có ĐÚNG hai ô trống, đánh số 1 và 2 (đây là thứ trước kia mất sạch).
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);

      // ĐIỀN MỘT PHẦN: chuỗi đúng định dạng "chỉ_số:giá_trị".
      await tester.tap(find.text('Hà Nội'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('1'));
      await tester.pumpAndSettle();
      expect(calls, ['1:w1']);

      // ĐIỀN ĐỦ: hai ô nối bằng '|', theo thứ tự chỉ số.
      await tester.tap(find.text('Viêng Chăn'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2'));
      await tester.pumpAndSettle();
      expect(calls.last, '1:w1|2:w2');

      // Gỡ ô 1 ra: chỉ còn mảnh của ô 2, KHÔNG sinh mảnh rỗng "1:".
      await tester.tap(findHugeIcon(HugeIcons.strokeRoundedCancel01, 'nút gỡ từ').first);
      await tester.pumpAndSettle();
      expect(calls.last, '2:w2');

      // ĐỂ TRỐNG hết -> phải gửi '-' chứ không phải chuỗi rỗng.
      await tester.tap(findHugeIcon(HugeIcons.strokeRoundedCancel01, 'nút gỡ từ').first);
      await tester.pumpAndSettle();
      expect(calls.last, '-');
    });

    testWidgets('ShortAnswer: 2 ô trống -> 2 ô nhập, chỉ số 1 và 2', (
      tester,
    ) async {
      final calls = <String>[];
      await _pump(
        tester,
        ShortAnswerQuizWidget(
          questionContent: 'Điền __(1)__ rồi điền __(2)__ nhé.',
          submitted: false,
          onOptionChange: calls.add,
          renderMixedContent: _plainContent,
        ),
      );

      expect(find.text('Điền '), findsOneWidget);
      expect(find.text(' rồi điền '), findsOneWidget);
      expect(find.text(' nhé.'), findsOneWidget);

      final fields = find.byType(TextField);
      expect(fields, findsNWidgets(2));

      await tester.enterText(fields.at(0), 'Alpha');
      // Debounce 800ms: chưa tới hạn thì chưa được gửi gì cả.
      await tester.pump(const Duration(milliseconds: 300));
      expect(calls, isEmpty);
      await tester.pump(const Duration(milliseconds: 600));
      expect(calls.last, '1:Alpha');

      await tester.enterText(fields.at(1), 'Beta');
      await tester.pump(const Duration(milliseconds: 900));
      expect(calls.last, '1:Alpha|2:Beta');

      // Xoá sạch -> '-' (backend chặn value rỗng bằng STUDENT_ANSWER_EMPTY).
      await tester.enterText(fields.at(0), '');
      await tester.pump(const Duration(milliseconds: 900));
      await tester.enterText(fields.at(1), '');
      await tester.pump(const Duration(milliseconds: 900));
      expect(calls.last, '-');
      await tester.pumpAndSettle();
    });

    testWidgets('Dropdown: 2 ô trống -> 2 ô chọn, mỗi ô đúng nhóm đáp án', (
      tester,
    ) async {
      final calls = <String>[];
      await _pump(
        tester,
        DropdownQuizWidget(
          questionContent:
              'Lớp A và lớp B là quan hệ (1). Lớp C và lớp D là quan hệ (2).',
          answers: [
            _answer(id: 'd1', content: '[[B1]] kế thừa', order: 1),
            _answer(id: 'd2', content: '[[B1]] kết hợp', order: 2),
            _answer(id: 'd3', content: '[[B2]] phụ thuộc', order: 3),
          ],
          submitted: false,
          onOptionChange: calls.add,
          renderMixedContent: _plainContent,
        ),
      );

      // Đề bài không còn bị cắt vụn: cả hai mẩu chữ và hai ô chọn đều có mặt.
      expect(find.text('Lớp A và lớp B là quan hệ '), findsOneWidget);
      expect(find.text('. Lớp C và lớp D là quan hệ '), findsOneWidget);
      expect(find.text('.'), findsOneWidget);
      expect(findDropdownArrows(), findsNWidgets(2));
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);

      // Mở ô số 1: chỉ thấy đáp án của [[B1]].
      await tester.tap(find.text('1'));
      await tester.pumpAndSettle();
      expect(find.text('kế thừa'), findsOneWidget);
      expect(find.text('kết hợp'), findsOneWidget);
      expect(find.text('phụ thuộc'), findsNothing);

      await tester.tap(find.text('kết hợp'));
      await tester.pumpAndSettle();
      expect(calls, ['1:d2']);

      // Ô số 2 dùng nhóm đáp án riêng và nối vào chuỗi bằng '|'.
      await tester.tap(find.text('2'));
      await tester.pumpAndSettle();
      expect(find.text('phụ thuộc'), findsOneWidget);
      await tester.tap(find.text('phụ thuộc'));
      await tester.pumpAndSettle();
      expect(calls.last, '1:d2|2:d3');

      // Bỏ chọn ô 1: chỉ còn mảnh của ô 2, không có mảnh rỗng "1:".
      await tester.tap(find.text('1'));
      await tester.pumpAndSettle();
      await tester.tap(findHugeIcon(HugeIcons.strokeRoundedMinusSignCircle, 'hàng bỏ chọn'));
      await tester.pumpAndSettle();
      expect(calls.last, '2:d3');

      // Bỏ chọn nốt ô 2 -> ĐỂ TRỐNG -> '-'.
      await tester.tap(find.text('2'));
      await tester.pumpAndSettle();
      await tester.tap(findHugeIcon(HugeIcons.strokeRoundedMinusSignCircle, 'hàng bỏ chọn'));
      await tester.pumpAndSettle();
      expect(calls.last, '-');
    });

    testWidgets('Dropdown: nhận cả dạng _(1)_ và ___(1)___', (tester) async {
      await _pump(
        tester,
        DropdownQuizWidget(
          questionContent: 'Một _(1)_ hai ___(2)___ ba (3) hết.',
          answers: [
            _answer(id: 'x1', content: '[[B1]] một'),
            _answer(id: 'x2', content: '[[B2]] hai'),
            _answer(id: 'x3', content: '[[B3]] ba'),
          ],
          submitted: false,
          onOptionChange: (_) {},
          renderMixedContent: _plainContent,
        ),
      );

      expect(findDropdownArrows(), findsNWidgets(3));
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('không tràn ngang ở 320dp dù đáp án dài', (tester) async {
      tester.view.physicalSize = const Size(320, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const longWord =
          'quan hệ kết hợp hai chiều có ràng buộc toàn vẹn tham chiếu';

      Future<void> check(Widget child) async {
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('vi'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: SingleChildScrollView(child: child)),
          ),
        );
        await tester.pumpAndSettle();
        // Tràn ngang được Flutter ném ra dưới dạng exception khi vẽ.
        expect(tester.takeException(), isNull);
      }

      await check(
        FillInBlankQuizWidget(
          questionContent: 'Đây là __(1)__ và kia là __(2)__ nhé.',
          answers: [
            _answer(id: 'w1', content: longWord),
            _answer(id: 'w2', content: longWord),
          ],
          selectedAnswer: '1:w1|2:w2',
          submitted: false,
          onOptionChange: (_) {},
          renderMixedContent: _plainContent,
        ),
      );

      await check(
        ShortAnswerQuizWidget(
          questionContent: 'Đây là __(1)__ và kia là __(2)__ nhé.',
          selectedAnswer: '1:$longWord|2:$longWord',
          submitted: false,
          onOptionChange: (_) {},
          renderMixedContent: _plainContent,
        ),
      );

      await check(
        DropdownQuizWidget(
          questionContent: 'Đây là (1) và kia là (2) nhé.',
          answers: [
            _answer(id: 'd1', content: '[[B1]] $longWord'),
            _answer(id: 'd2', content: '[[B2]] $longWord'),
          ],
          selectedAnswer: '1:d1|2:d2',
          submitted: false,
          onOptionChange: (_) {},
          renderMixedContent: _plainContent,
        ),
      );
    });

    testWidgets('submitted = true thì khoá mọi thao tác', (tester) async {
      final calls = <String>[];
      await _pump(
        tester,
        DropdownQuizWidget(
          questionContent: 'Đáp án là (1).',
          answers: [_answer(id: 'd1', content: '[[B1]] kế thừa')],
          submitted: true,
          onOptionChange: calls.add,
          renderMixedContent: _plainContent,
        ),
      );

      await tester.tap(find.text('1'));
      await tester.pumpAndSettle();
      expect(find.text('kế thừa'), findsNothing);
      expect(calls, isEmpty);

      final fibCalls = <String>[];
      await _pump(
        tester,
        FillInBlankQuizWidget(
          questionContent: 'Đáp án là __(1)__.',
          answers: [_answer(id: 'w1', content: 'Hà Nội')],
          submitted: true,
          onOptionChange: fibCalls.add,
          renderMixedContent: _plainContent,
        ),
      );

      await tester.tap(find.text('Hà Nội'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('1'));
      await tester.pumpAndSettle();
      expect(fibCalls, isEmpty);
    });
  });
}
