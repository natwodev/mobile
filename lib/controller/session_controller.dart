import 'package:flutter/foundation.dart';

import '../services/auth/user_services.dart';

/// Giữ trạng thái "đã đăng nhập chưa" của cả app.
///
/// Cùng khuôn với [LocaleController]: một instance dùng chung, `main()` gọi
/// [load] một lần trước `runApp`.
///
/// Vì sao là singleton chứ không phải tham số của widget gốc: mỗi lần đổi chữ
/// ký hàm dựng widget gốc là một lần hot reload ném
/// `type 'Null' is not a subtype of type 'bool'` — instance đang chạy được tạo
/// bằng lớp cũ nên field mới thành null. Đọc qua singleton thì hình dạng
/// widget không đổi, hot reload không vỡ.
class SessionController extends ChangeNotifier {
  static final SessionController instance = SessionController._();

  SessionController._();

  bool _signedIn = false;

  /// Máy còn token còn hạn: vào thẳng trong app.
  bool get signedIn => _signedIn;

  /// Đọc lại phiên đã lưu. Gọi một lần trong `main()` trước khi dựng giao diện.
  Future<void> load() async {
    try {
      _signedIn = await UserService().isLoggedIn();
    } catch (e) {
      // Không đọc được thì coi như chưa đăng nhập; thà bắt đăng nhập lại còn
      // hơn chặn app không mở được.
      debugPrint('Không kiểm tra được phiên đăng nhập: $e');
      _signedIn = false;
    }
  }

  void markSignedIn() {
    if (_signedIn) return;
    _signedIn = true;
    notifyListeners();
  }

  void markSignedOut() {
    if (!_signedIn) return;
    _signedIn = false;
    notifyListeners();
  }
}
