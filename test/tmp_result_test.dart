import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizz_mobile/l10n/generated/app_localizations.dart';
import 'package:quizz_mobile/screens/Exam/exam_result_screen.dart';
import 'package:quizz_mobile/widget/exam_result/circle_score_display.dart';

void main() {
  for (final scale in [1.0, 1.4]) {
    testWidgets('trang kết quả không tràn — 320x568 x$scale', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('vi'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: const ExamResultScreen(
            examTitle: 'Đề thi cuối kỳ Lập trình hướng đối tượng',
            totalQuestions: 56,
            answeredQuestions: 44,
            timeSpent: 1830,
            totalTime: 2700,
            score: 8.5,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CircleScoreDisplay), findsOneWidget);
      expect(find.text('8.5'), findsOneWidget);
      expect(find.text('Xuất sắc!'), findsNothing); // 8.5 -> "Giỏi!"
      expect(find.text('Giỏi!'), findsOneWidget);
      expect(find.text('30:30 / 45:00'), findsOneWidget);
      expect(find.text('12'), findsOneWidget); // chưa làm
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('ca không giới hạn chỉ hiện thời gian đã làm', (tester) async {
    tester.view.physicalSize = const Size(360, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('vi'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const ExamResultScreen(
          examTitle: 'Đề thi giữa kỳ',
          totalQuestions: 10,
          answeredQuestions: 10,
          timeSpent: 65,
          totalTime: 0,
          score: 4.0,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('01:05'), findsOneWidget);
    expect(find.textContaining('/'), findsOneWidget); // chỉ còn "/ 10" ở vòng điểm
    expect(tester.takeException(), isNull);
  });
}
