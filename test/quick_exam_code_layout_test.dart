import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quizz_mobile/l10n/generated/app_localizations.dart';
import 'package:quizz_mobile/l10n/locale_controller.dart';
import 'package:quizz_mobile/screens/Exam/quick_exam_code_screen.dart';

/// Test tràn pixel: khi một RenderFlex tràn, Flutter ném FlutterError và
/// widget test tự động fail. Nên chỉ cần dựng màn hình ở các kích thước/cỡ chữ
/// khắc nghiệt là đủ bắt lỗi.
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
  // BẮT BUỘC: `LocaleController.setLocale` ghi ngôn ngữ xuống SharedPreferences.
  // Không cắm bản giả thì `SharedPreferences.getInstance()` chờ một phản hồi
  // kênh nền tảng KHÔNG BAO GIỜ tới trong vùng thời gian giả của `testWidgets`
  // → `await setLocale(...)` treo vĩnh viễn. Các test `vi` không lộ ra lỗi này
  // vì `setLocale` thoát sớm khi ngôn ngữ không đổi (mặc định đã là `vi`);
  // test `en` đầu tiên mới là chỗ treo.
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocaleController.instance.setLocale(LocaleController.vietnamese);
  });

  // Máy hẹp phổ biến (360dp) và máy rất hẹp (320dp, ví dụ iPhone SE đời đầu).
  const sizes = <Size>[Size(320, 568), Size(360, 640), Size(412, 915)];

  for (final locale in LocaleController.supportedLocales) {
    for (final size in sizes) {
      for (final scale in <double>[1.0, 1.3]) {
        testWidgets('Màn nhập mã không tràn pixel — ${locale.languageCode} '
            '${size.width.toInt()}x${size.height.toInt()} cỡ chữ x$scale', (
          tester,
        ) async {
          await LocaleController.instance.setLocale(locale);
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            _wrap(const QuickExamCodeScreen(), textScale: scale),
          );
          await tester.pump();

          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
