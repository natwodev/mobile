import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hugeicons/hugeicons.dart';

import 'l10n/generated/app_localizations.dart';
import 'l10n/locale_controller.dart';
import 'widget/common/app_buttons.dart';
import 'component/HomeNavigation.dart';
import 'controller/session_controller.dart';
import 'services/pending_submit_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/account_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load file .env với xử lý lỗi encoding
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print("Không thể load file .env: $e");
    print("Sử dụng giá trị mặc định từ base_service");
  }

  // Đọc ngôn ngữ đã lưu trước khi dựng giao diện để tránh nháy đổi ngôn ngữ.
  await LocaleController.instance.load();

  // Khôi phục phiên đăng nhập TRƯỚC khi dựng giao diện.
  //
  // Trước đây app luôn mở thẳng màn đăng nhập dù token vẫn còn trong máy, nên
  // đóng app là phải đăng nhập lại. Kiểm ở đây thay vì dựng một màn splash
  // rồi điều hướng: không có nháy màn hình, và cũng không phải chờ thêm nhịp
  // nào vì chỉ là một lần đọc SharedPreferences.
  await SessionController.instance.load();

  // Còn lệnh nộp nào chưa gửi được từ lần chạy trước thì gửi tiếp NGAY tại đây.
  //
  // Đây là mắt xích giúp bài sống sót qua việc tắt app: sinh viên bấm "Nộp bài"
  // lúc mất mạng, app bị hệ điều hành thu hồi (hoặc bị tắt tay), mở lại là bài
  // tự bay lên máy chủ kèm ĐÚNG mốc giờ lúc bấm nộp.
  //
  // Chỉ chạy khi còn phiên đăng nhập: chưa có token thì mọi request đều 401,
  // mà 401 lại được xếp vào loại "thử lại sau" nên gọi bây giờ chỉ tổ quay
  // vòng vô ích.
  if (SessionController.instance.signedIn) {
    PendingSubmitService.instance.startAutoRetry();
  }

  runApp(HutechCampusApp());
}

/// Theme dùng chung của app.
///
/// Tách khỏi thân [HutechCampusApp] để bộ test dựng được ĐÚNG theme thật thay
/// vì một bản chép tay dễ lệch.
ThemeData buildAppTheme() {
  // appButtonThemes: cắm bộ nút dùng chung (xem `widget/common/app_buttons.dart`).
  //
  // Đây là chỗ sửa MỘT lần ăn cả app. Trước đây theme không khai
  // ElevatedButtonThemeData nào, nên nút không tự tô style rơi về mặc định
  // Material 3 — nền tím nhạt, chữ mờ, bo tròn hoàn toàn — còn nút có tô thì
  // mỗi chỗ tô một kiểu. Kết quả là 9 biến thể nút và 3 tông xanh khác nhau
  // cho cùng vai trò "hành động chính".
  return appButtonThemes(
    ThemeData(
      // colorScheme thay cho `primarySwatch: Colors.blue`: primarySwatch giữ
      // `colorScheme.primary` ở xanh Material #2196F3, nên mọi thứ ăn theo
      // primary mà KHÔNG phải nút — con trỏ ô nhập, vòng quay chờ, công tắc —
      // vẫn ra một tông xanh khác với nút. copyWith(primary:) để màu nhấn đúng
      // bằng #2563EB chứ không phải sắc độ mà fromSeed tự sinh ra.
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.accent,
      ).copyWith(primary: AppColors.accent),
      // Nút back của AppBar do Flutter TỰ CHÈN ([BackButton]) — không màn nào
      // trong app đặt `leading` bằng tay, nên muốn đổi icon thì phải đổi ở đây.
      // Sửa từng màn vừa sót vừa hỏng lại ngay khi thêm màn mới.
      actionIconTheme: ActionIconThemeData(
        backButtonIconBuilder: (context) {
          // HugeIcon vẽ bằng SVG nên KHÔNG ăn màu của [IconTheme] như [Icon]:
          // phải đọc màu đang hiệu lực ra rồi truyền thẳng vào `color`. Bỏ qua
          // bước này thì mũi tên đen trên AppBar xanh — coi như mất nút back.
          final iconTheme = IconTheme.of(context);
          return HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            color: iconTheme.color ?? Colors.white,
            size: iconTheme.size ?? 24,
          );
        },
      ),
    ),
  );
}

class HutechCampusApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final localeController = LocaleController.instance;

    // Nghe LocaleController để đổi ngôn ngữ là cả app dựng lại ngay.
    return AnimatedBuilder(
      animation: localeController,
      builder: (context, _) {
        return MaterialApp(
          title: 'HUTECH Campus Info',
          theme: buildAppTheme(),
          locale: localeController.locale,
          supportedLocales: LocaleController.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          // `home` thay cho `initialRoute`: điểm vào phụ thuộc phiên đăng
          // nhập, không phải một hằng số. Hai route dưới vẫn giữ tên vì luồng
          // đăng xuất điều hướng bằng tên (`pushNamedAndRemoveUntil('/login')`).
          home: SessionController.instance.signedIn
              ? const HomeNavigation()
              : LoginScreen(),
          routes: {
            '/login': (context) => LoginScreen(),
            '/account': (context) => AccountScreen(),
          },
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
