import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quizz_mobile/l10n/locale_controller.dart';
import 'package:quizz_mobile/main.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    // Mỗi test bắt đầu từ tiếng Việt (mặc định của app).
    await LocaleController.instance.setLocale(LocaleController.vietnamese);
  });

  testWidgets('App mở ra màn đăng nhập bằng tiếng Việt', (tester) async {
    await tester.pumpWidget(HutechCampusApp());
    await tester.pumpAndSettle();

    expect(find.text('Đăng nhập'), findsWidgets);
    expect(find.text('Tiếng Việt'), findsOneWidget);
  });

  testWidgets('Đổi ngôn ngữ sang English thì giao diện đổi theo', (
    tester,
  ) async {
    await tester.pumpWidget(HutechCampusApp());
    await tester.pumpAndSettle();

    await LocaleController.instance.setLocale(LocaleController.english);
    await tester.pumpAndSettle();

    expect(find.text('Sign in'), findsWidgets);
    expect(find.text('Đăng nhập'), findsNothing);
  });
}
