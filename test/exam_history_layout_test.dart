import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quizz_mobile/l10n/generated/app_localizations.dart';
import 'package:quizz_mobile/l10n/locale_controller.dart';
import 'package:quizz_mobile/models/DTOs/ExamSubmissionDto.dart';
import 'package:quizz_mobile/models/api_result.dart';
import 'package:quizz_mobile/models/exam_history_item.dart';
import 'package:quizz_mobile/screens/Exam/exam_history_screen.dart';
import 'package:quizz_mobile/services/auth/user_services.dart';

/// UserService giả: màn hình gọi mạng ngay trong initState nên không cắm bản
/// giả thì test treo chờ một request thật.
class _FakeUserService extends UserService {
  _FakeUserService(this.items);

  final List<ExamHistoryItem> items;

  @override
  Future<ExamHistoryResult> getExamHistory() async =>
      ExamHistoryResult(success: true, items: items);

  @override
  Future<ExamReviewOpenResult> openExamReview(String id) async =>
      const ExamReviewOpenResult(success: true);

  @override
  Future<ExamSubmissionDto?> getSubmissionResult(String id) async =>
      ExamSubmissionDto(
        userCode: 'SV001',
        score: 8.75,
        correctAnswers: 35,
        totalQuestions: 40,
        startTime: DateTime(2025, 5, 20, 8, 0),
        endTime: DateTime(2025, 5, 20, 9, 15),
      );
}

final _items = <ExamHistoryItem>[
  // Bài xem lại được, dữ liệu đủ.
  ExamHistoryItem(
    studentExamSessionId: 'a',
    userCode: 'SV001',
    subjectName: 'Lập trình hướng đối tượng nâng cao',
    startTime: DateTime(2025, 5, 20, 8, 0),
    endTime: DateTime(2025, 5, 20, 9, 15),
    score: 8.75,
    correctAnswers: 35,
    totalQuestions: 40,
    isCompleted: true,
    canReview: true,
    showAnswerKey: true,
    showQuestionDetail: true,
  ),
  // Bài bị chặn, có giờ mở.
  ExamHistoryItem(
    studentExamSessionId: 'b',
    userCode: 'SV001',
    subjectName: 'Toán rời rạc',
    startTime: DateTime(2025, 5, 18, 13, 0),
    endTime: DateTime(2025, 5, 18, 14, 0),
    score: 6.5,
    correctAnswers: 26,
    totalQuestions: 40,
    isCompleted: true,
    reviewBlockedReason: ExamReviewBlockedReason.notOpenYet,
    reviewOpensAt: DateTime(2025, 6, 1, 7, 30),
  ),
  // Bài có vi phạm + cộng giờ.
  ExamHistoryItem(
    studentExamSessionId: 'c',
    userCode: 'SV001',
    subjectName: 'Cơ sở dữ liệu',
    startTime: DateTime(2025, 5, 10, 7, 0),
    endTime: DateTime(2025, 5, 10, 8, 30),
    score: 10,
    correctAnswers: 40,
    totalQuestions: 40,
    isCompleted: true,
    violationCount: 3,
    extraMinutes: 15,
    canReview: true,
    showQuestionDetail: false,
  ),
  // Bài thiếu endTime, thiếu số câu, không nói lý do bị chặn.
  ExamHistoryItem(
    studentExamSessionId: 'd',
    userCode: 'SV001',
    startTime: DateTime(2025, 5, 1, 9, 0),
    score: 0,
  ),
];

Widget _wrap(Widget child, {double textScale = 1.0}) {
  return MaterialApp(
    locale: LocaleController.instance.locale,
    supportedLocales: LocaleController.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: child,
    ),
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocaleController.instance.setLocale(LocaleController.vietnamese);
  });

  const sizes = <Size>[Size(320, 568), Size(360, 640), Size(412, 915)];

  for (final locale in LocaleController.supportedLocales) {
    for (final size in sizes) {
      for (final scale in <double>[1.0, 1.3]) {
        testWidgets('Lịch sử làm bài không tràn pixel — ${locale.languageCode} '
            '${size.width.toInt()}x${size.height.toInt()} cỡ chữ x$scale', (
          tester,
        ) async {
          await LocaleController.instance.setLocale(locale);
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            _wrap(
              ExamHistoryScreen(userService: _FakeUserService(_items)),
              textScale: scale,
            ),
          );
          await tester.pump();
          await tester.pump();

          expect(tester.takeException(), isNull);
          // Danh sách đã hiện (không còn kẹt ở vòng quay).
          expect(find.byType(ListView), findsOneWidget);

          // ListView chỉ dựng phần đang thấy, nên phải cuộn hết danh sách
          // thì mọi thẻ mới thật sự được đo — kể cả thẻ có nhãn vi phạm và
          // thẻ thiếu giờ nộp nằm cuối.
          for (var i = 0; i < 6; i++) {
            await tester.drag(find.byType(ListView), const Offset(0, -260));
            await tester.pump();
            expect(tester.takeException(), isNull);
          }
        });
      }
    }
  }

  testWidgets('Màn rỗng không tràn pixel ở 320x568', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _wrap(ExamHistoryScreen(userService: _FakeUserService(const []))),
    );
    await tester.pump();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Chưa có bài thi nào'), findsOneWidget);
  });

  testWidgets('Bảng chi tiết không tràn pixel ở 320x568', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _wrap(ExamHistoryScreen(userService: _FakeUserService(_items))),
    );
    await tester.pump();
    await tester.pump();

    // Nút của thẻ đầu nằm dưới mép màn ở 320x568 (hàng thẻ tổng hợp chiếm
    // phần trên), phải cuộn tới rồi mới bấm được.
    await tester.ensureVisible(find.text('Xem lại').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Xem lại').first);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Kết quả bài thi'), findsOneWidget);
    // Ưu tiên số liệu của getSubmissionResult (8.75) chứ không lấy điểm trong
    // danh sách.
    expect(find.text('8.75'), findsWidgets);
  });

  testWidgets('Bài bị chặn: nút tắt và hiện chữ lý do', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _wrap(ExamHistoryScreen(userService: _FakeUserService(_items))),
    );
    await tester.pump();
    await tester.pump();

    // Bài bị chặn nằm dưới màn hình ở 320x568 nên phải cuộn tới.
    await tester.scrollUntilVisible(
      find.text('Mở xem lại từ 01/06/2025 07:30'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Mở xem lại từ 01/06/2025 07:30'), findsOneWidget);

    // Vùng bấm của CHÍNH thẻ đó phải tắt (tìm theo thẻ chứa câu lý do, không
    // lấy bừa nút đầu tiên trên màn). `Column` gần nhất bọc câu lý do chính là
    // thân thẻ, trong đó có đúng một `InkWell` — dải "Xem lại" ở cuối thẻ.
    final blockedCard = find
        .ancestor(
          of: find.text('Mở xem lại từ 01/06/2025 07:30'),
          matching: find.byType(Column),
        )
        .first;
    final blockedTap = tester.widget<InkWell>(
      find.descendant(of: blockedCard, matching: find.byType(InkWell)),
    );
    expect(blockedTap.onTap, isNull);

    // Bài không nói lý do vẫn phải có câu giải thích chung.
    await tester.scrollUntilVisible(
      find.text('Ca thi không cho xem lại bài'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Ca thi không cho xem lại bài'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });
}
