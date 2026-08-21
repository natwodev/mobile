import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../l10n/generated/app_localizations.dart';
import '../l10n/locale_controller.dart';
import 'common/app_buttons.dart';
import 'common/app_sheet.dart';
import 'common/app_surfaces.dart';

/// Tên hiển thị của một ngôn ngữ, luôn viết bằng chính ngôn ngữ đó để người
/// dùng nhận ra kể cả khi đang mở app ở ngôn ngữ mình không đọc được.
String languageLabel(Locale locale) =>
    locale.languageCode == 'vi' ? 'Tiếng Việt' : 'English';

/// Icon đại diện cho ngôn ngữ, dùng chung mọi chỗ.
///
/// Đặt hằng chứ không gõ tay ở ba nơi (hàng Cài đặt, tấm chọn, nút ở màn Đăng
/// nhập): trước đây hai chỗ dùng `LanguageCircle` còn nút màn Đăng nhập dùng
/// `Global` — cùng một việc mà hai hình.
const List<List<dynamic>> languageIcon = HugeIcons.strokeRoundedTranslate;

/// Tấm chọn ngôn ngữ, dùng chung cho màn Đăng nhập và Tài khoản.
///
/// Trượt lên từ đáy chứ không phải hộp thoại giữa màn: đây là chọn nhanh rồi
/// đóng, không phải câu hỏi chặn đường — xem ghi chú ở `AppSheet`.
Future<void> showLanguagePicker(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final controller = LocaleController.instance;

  final selected = await showAppSheet<Locale>(
    context: context,
    title: l10n.settingsChooseLanguage,
    icon: languageIcon,
    children: LocaleController.supportedLocales.map((locale) {
      final isSelected = locale.languageCode == controller.locale.languageCode;

      return InkWell(
        onTap: () => Navigator.pop(context, locale),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          // Ngôn ngữ đang dùng có nền và viền riêng, không chỉ mỗi dấu tích:
          // trên tấm sheet chỉ có hai dòng thì một dấu tích nhỏ ở mép phải rất
          // dễ lướt qua.
          decoration: isSelected
              ? AppSurfaces.card(color: AppColors.accentBg, soft: true)
              : AppSurfaces.card(tint: AppColors.disabledInk, shadow: false),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  languageLabel(locale),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? AppColors.accent : AppColors.ink,
                  ),
                ),
              ),
              if (isSelected)
                const HugeIcon(
                  icon: HugeIcons.strokeRoundedTick01,
                  color: AppColors.accent,
                  size: 20,
                ),
            ],
          ),
        ),
      );
    }).toList(),
  );

  if (selected != null) {
    await controller.setLocale(selected);
  }
}

/// Nút đổi ngôn ngữ gọn cho màn Đăng nhập (chưa có thanh tab).
class LanguageToggleButton extends StatelessWidget {
  final Color color;

  const LanguageToggleButton({super.key, this.color = AppColors.accent});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => showLanguagePicker(context),
      icon: HugeIcon(icon: languageIcon, size: 20, color: color),
      // Không tự khai `TextStyle` cho nhãn nữa: cỡ chữ và độ đậm để
      // [AppButtons.quiet] lo (đã cắm sẵn qua `textButtonTheme`), còn màu thì
      // vẫn phải là [color] vì widget này nhận màu từ NGOÀI vào — nó nằm trên
      // nền ảnh của màn Đăng nhập chứ không phải trên nền trắng.
      label: Text(languageLabel(LocaleController.instance.locale)),
      style: TextButton.styleFrom(foregroundColor: color),
    );
  }
}
