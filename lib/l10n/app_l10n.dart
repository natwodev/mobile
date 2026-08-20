import 'generated/app_localizations.dart';
import 'locale_controller.dart';

/// Cầu nối để tầng KHÔNG có BuildContext (service, controller, model) vẫn lấy
/// được chuỗi đã dịch.
///
/// Widget thì luôn dùng `AppLocalizations.of(context)` — chuẩn Flutter và tự
/// rebuild khi đổi ngôn ngữ. Chỉ nơi nào không có context mới dùng lớp này.
class AppL10n {
  AppL10n._();

  /// Bộ chuỗi theo ngôn ngữ đang chọn.
  static AppLocalizations get current =>
      lookupAppLocalizations(LocaleController.instance.locale);
}
