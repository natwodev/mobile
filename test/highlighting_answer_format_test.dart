import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quizz_mobile/l10n/generated/app_localizations.dart';
import 'package:quizz_mobile/models/DTOs/originalExamPaperDto.dart';
import 'package:quizz_mobile/widget/exam/question_types/highlighting_quiz_widget.dart';

/// Đề mẫu: "The [quick brown] fox [jumps] now" với 2 vùng đúng.
///
/// Chuỗi đã gỡ thẻ: `The quick brown fox jumps now`
///   - vùng H1 = "quick brown" -> ký tự 4..14
///   - vùng H2 = "jumps"       -> ký tự 20..24
const _content =
    'Chọn các từ đúng: '
    'The [[H1]]quick brown[[/H1]] fox [[H2]]jumps[[/H2]] now';

AnswerDto _zoneAnswer(String id, String content) => AnswerDto(
  answerId: id,
  order: 1,
  answerContent: content,
  isCorrect: false,
  canShuffleAnswer: false,
  originalExamPaperDetailId: 'q-hl',
);

Future<List<String>> _pump(
  WidgetTester tester, {
  String? selectedAnswer,
}) async {
  final sent = <String>[];

  tester.view.physicalSize = const Size(1400, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('vi'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: HighlightingQuizWidget(
            questionId: 'q-hl',
            questionContent: _content,
            answers: [
              _zoneAnswer('id-h1', '[[H1]] quick brown'),
              _zoneAnswer('id-h2', '[[H2]] jumps'),
            ],
            selectedAnswer: selectedAnswer,
            submitted: false,
            onOptionChange: sent.add,
            renderMixedContent: (text, fontSize) => Text(text),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return sent;
}

void main() {
  group('Highlighting dựng chuỗi đúng hợp đồng [HL] của backend', () {
    testWidgets('thẻ [[Hn]] bị gỡ khỏi phần hiển thị', (tester) async {
      await _pump(tester);

      expect(
        find.textContaining('The quick brown fox jumps now'),
        findsOneWidget,
      );
      expect(find.textContaining('[[H1]]'), findsNothing);
      // Lời dẫn (phần trước dấu ':' đầu tiên) vẫn hiển thị.
      expect(find.text('Chọn các từ đúng:'), findsOneWidget);
    });

    testWidgets('bôi trọn một vùng đúng thì gửi kèm answerId, không có EXT:', (
      tester,
    ) async {
      final sent = await _pump(tester);

      await tester.tapOnText(find.textRange.ofSubstring('quick'));
      await tester.pumpAndSettle();
      await tester.tapOnText(find.textRange.ofSubstring('brown'));
      await tester.pumpAndSettle();

      final last = sent.last;
      final parts = last.split('|');

      // Đúng 1 answerId, không có mảnh EXT: nào (EXT: = sai ngay lập tức).
      expect(parts.where((p) => !p.startsWith('T_')), ['id-h1']);
      expect(parts.any((p) => p.startsWith('EXT:')), isFalse);

      // T_ phủ trọn vùng 4..14, kể cả khoảng trắng nối giữa 2 từ.
      final tIndices = parts
          .where((p) => p.startsWith('T_'))
          .map((p) => int.parse(p.substring(2)))
          .toSet();
      expect(tIndices, {for (var i = 4; i <= 14; i++) i});
    });

    testWidgets('bôi cả 2 vùng thì gửi cả 2 answerId', (tester) async {
      final sent = await _pump(tester);

      await tester.tapOnText(find.textRange.ofSubstring('quick'));
      await tester.pumpAndSettle();
      await tester.tapOnText(find.textRange.ofSubstring('brown'));
      await tester.pumpAndSettle();
      await tester.tapOnText(find.textRange.ofSubstring('jumps'));
      await tester.pumpAndSettle();

      final ids = sent.last.split('|').where((p) => !p.startsWith('T_'));
      expect(ids.toSet(), {'id-h1', 'id-h2'});
    });

    testWidgets('bôi thừa chữ ngoài vùng đúng thì phải khai báo EXT:', (
      tester,
    ) async {
      final sent = await _pump(tester);

      await tester.tapOnText(find.textRange.ofSubstring('fox'));
      await tester.pumpAndSettle();

      final parts = sent.last.split('|');
      expect(parts.where((p) => !p.startsWith('T_')), ['EXT:fox']);
    });

    testWidgets('bôi nửa vùng cũng là bôi sai -> EXT:', (tester) async {
      final sent = await _pump(tester);

      await tester.tapOnText(find.textRange.ofSubstring('quick'));
      await tester.pumpAndSettle();

      final parts = sent.last.split('|');
      expect(parts.where((p) => !p.startsWith('T_')), ['EXT:quick']);
    });

    testWidgets('bỏ chọn hết thì gửi "-" chứ không phải chuỗi rỗng', (
      tester,
    ) async {
      final sent = await _pump(tester);

      await tester.tapOnText(find.textRange.ofSubstring('fox'));
      await tester.pumpAndSettle();
      // Chạm lần nữa để bỏ chọn.
      await tester.tapOnText(find.textRange.ofSubstring('fox'));
      await tester.pumpAndSettle();

      expect(sent.last, '-');
    });

    testWidgets('resume: đọc lại các mảnh T_ đã lưu và bôi lại đúng chỗ', (
      tester,
    ) async {
      final saved = [for (var i = 20; i <= 24; i++) 'T_$i', 'id-h2'].join('|');

      final sent = await _pump(tester, selectedAnswer: saved);
      expect(sent, isEmpty, reason: 'Resume không được tự gửi lại đáp án');

      // Bôi thêm vùng H1 -> chuỗi mới phải giữ nguyên vùng cũ.
      await tester.tapOnText(find.textRange.ofSubstring('quick'));
      await tester.pumpAndSettle();
      await tester.tapOnText(find.textRange.ofSubstring('brown'));
      await tester.pumpAndSettle();

      final ids = sent.last.split('|').where((p) => !p.startsWith('T_'));
      expect(ids.toSet(), {'id-h1', 'id-h2'});
    });
  });
}
