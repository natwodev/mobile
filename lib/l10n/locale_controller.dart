import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Giữ ngôn ngữ đang chọn và lưu xuống máy để mở lại app vẫn nhớ.
///
/// App chỉ hỗ trợ 2 ngôn ngữ: Tiếng Việt (mặc định) và English.
class LocaleController extends ChangeNotifier {
  static const String _prefsKey = 'app_locale';

  static const Locale vietnamese = Locale('vi');
  static const Locale english = Locale('en');
  static const List<Locale> supportedLocales = [vietnamese, english];

  /// Dùng chung toàn app: main() khởi tạo, các màn hình đọc qua đây.
  static final LocaleController instance = LocaleController._();

  LocaleController._();

  Locale _locale = vietnamese;
  Locale get locale => _locale;

  bool get isVietnamese => _locale.languageCode == 'vi';

  /// Đọc ngôn ngữ đã lưu. Gọi một lần trong main() trước khi runApp.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_prefsKey);
      if (code != null && _isSupported(code)) {
        _locale = Locale(code);
        notifyListeners();
      }
    } catch (e) {
      // Không đọc được thì giữ mặc định tiếng Việt, không chặn khởi động app.
      debugPrint('Không đọc được ngôn ngữ đã lưu: $e');
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (!_isSupported(locale.languageCode) || locale == _locale) return;

    _locale = locale;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, locale.languageCode);
    } catch (e) {
      debugPrint('Không lưu được ngôn ngữ: $e');
    }
  }

  bool _isSupported(String languageCode) =>
      supportedLocales.any((l) => l.languageCode == languageCode);
}
