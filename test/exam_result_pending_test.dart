import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizz_mobile/l10n/generated/app_localizations.dart';
import 'package:quizz_mobile/screens/Exam/exam_result_screen.dart';
import 'package:quizz_mobile/services/pending_submit_service.dart';
import 'package:quizz_mobile/widget/exam_result/circle_score_display.dart';

/// Màn kết quả của một bài nộp lúc MẤT MẠNG.
///
/// Cố tình dùng khung hình rộng rãi: chuyện tràn bố cục ở màn hình bé đã có bộ
/// test riêng lo, ở đây chỉ kiểm ĐÚNG một điều — chỗ vòng điểm hiện gì trong ba
/// giai đoạn: đang chờ mạng, gửi xong, và bị máy chủ từ chối.
Widget _app(Widget home) {
  return MaterialApp(
    locale: const Locale('vi'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  );
}

void main() {
  testWidgets('đang chờ gửi: chỗ điểm quay vòng chờ, gửi xong thì điền điểm vào', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(420, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final completer = Completer<PendingSubmitOutcome>();

    await tester.pumpWidget(
      _app(
        ExamResultScreen(
          examTitle: 'Đề thi cuối kỳ',
          totalQuestions: 40,
          answeredQuestions: 38,
          timeSpent: 1200,
          totalTime: 2700,
          pendingOutcome: completer.future,
          pendingSubmittedAt: DateTime.utc(2026, 8, 20, 10),
        ),
      ),
    );
    await tester.pump();

    // Chưa có điểm thì KHÔNG được vẽ vòng điểm 0.0 — sinh viên sẽ tưởng mình
    // bị 0 điểm thật.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(CircleScoreDisplay), findsNothing);
    expect(find.text('Đang chờ mạng để gửi bài'), findsOneWidget);

    completer.complete(const PendingSubmitOutcome.accepted(score: 8.5));
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(CircleScoreDisplay), findsOneWidget);
    expect(find.text('8.5'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('máy chủ từ chối: nói thẳng lý do, vòng xoay dừng lại', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(420, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _app(
        ExamResultScreen(
          examTitle: 'Đề thi cuối kỳ',
          totalQuestions: 40,
          answeredQuestions: 38,
          timeSpent: 1200,
          totalTime: 2700,
          pendingOutcome: Future<PendingSubmitOutcome>.value(
            const PendingSubmitOutcome.rejected('Bài thi này đã được nộp.'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(CircleScoreDisplay), findsNothing);
    expect(find.text('Máy chủ không nhận bài'), findsOneWidget);
    expect(find.text('Bài thi này đã được nộp.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('không có lệnh nộp chờ thì màn kết quả giữ nguyên như cũ', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(420, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _app(
        const ExamResultScreen(
          examTitle: 'Đề thi cuối kỳ',
          totalQuestions: 40,
          answeredQuestions: 38,
          timeSpent: 1200,
          totalTime: 2700,
          score: 8.5,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CircleScoreDisplay), findsOneWidget);
    expect(find.text('8.5'), findsOneWidget);
    expect(find.text('Giỏi!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
