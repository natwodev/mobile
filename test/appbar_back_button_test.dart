import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:quizz_mobile/main.dart';

/// Nút back của AppBar KHÔNG do màn hình nào tự đặt: Flutter tự chèn
/// [BackButton] khi có route để lùi về. Vì vậy nó chỉ đổi được ở một chỗ duy
/// nhất — `ActionIconThemeData.backButtonIconBuilder` trong [buildAppTheme].
///
/// Hai thứ bộ test này canh:
///   1. Icon phải là [HugeIcon], không phải `Icons.arrow_back` của Material.
///   2. Icon phải NHẬN ĐÚNG MÀU của AppBar. [HugeIcon] vẽ bằng SVG nên không
///      ăn màu từ [IconTheme] như [Icon] — quên truyền `color` là được một mũi
///      tên đen trên nền AppBar xanh, tức mất nút back mà không có lỗi nào báo.
final GlobalKey<NavigatorState> _nav = GlobalKey<NavigatorState>();

Future<void> _pushPageWithAppBar(
  WidgetTester tester, {
  required AppBar appBar,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(),
      navigatorKey: _nav,
      home: const Scaffold(body: SizedBox.shrink()),
    ),
  );

  _nav.currentState!.push(
    MaterialPageRoute<void>(
      builder: (_) => Scaffold(appBar: appBar, body: const SizedBox.shrink()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('AppBar xanh chữ trắng: nút back là HugeIcon màu trắng', (
    tester,
  ) async {
    // Đúng cấu hình AppBar mà các màn trong app đang dùng
    // (xem `screens/Auth/edit_profile_screen.dart`).
    await _pushPageWithAppBar(
      tester,
      appBar: AppBar(
        title: const Text('Sửa thông tin cá nhân'),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
    );

    expect(
      find.byIcon(Icons.arrow_back),
      findsNothing,
      reason: 'vẫn còn nút back mặc định của Material',
    );

    final hugeIcon = find.descendant(
      of: find.byType(AppBar),
      matching: find.byType(HugeIcon),
    );
    expect(hugeIcon, findsOneWidget);
    expect(
      tester.widget<HugeIcon>(hugeIcon).color,
      Colors.white,
      reason: 'mũi tên không lấy màu của AppBar — sẽ chìm vào nền',
    );
  });

  testWidgets('AppBar không tự đặt iconTheme: nút back vẫn có màu nhìn thấy', (
    tester,
  ) async {
    await _pushPageWithAppBar(tester, appBar: AppBar(title: const Text('X')));

    final hugeIcon = find.descendant(
      of: find.byType(AppBar),
      matching: find.byType(HugeIcon),
    );
    expect(hugeIcon, findsOneWidget);

    final color = tester.widget<HugeIcon>(hugeIcon).color;
    expect(color, isNotNull);
    expect(color!.a, greaterThan(0), reason: 'icon trong suốt = mất nút back');
  });

  testWidgets('Route gốc không có nút back thì cũng không vẽ HugeIcon', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          appBar: AppBar(title: const Text('Trang đầu')),
          body: const SizedBox.shrink(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byType(HugeIcon),
      ),
      findsNothing,
    );
  });
}
