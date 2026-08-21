import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../l10n/generated/app_localizations.dart';
import '../l10n/locale_controller.dart';
import 'common/app_buttons.dart';
import 'common/app_modal.dart';

/// Tên hiển thị của một ngôn ngữ, luôn viết bằng chính ngôn ngữ đó để người
/// dùng nhận ra kể cả khi đang mở app ở ngôn ngữ mình không đọc được.
String languageLabel(Locale locale) =>
    locale.languageCode == 'vi' ? 'Tiếng Việt' : 'English';

/// Hộp thoại chọn ngôn ngữ, dùng chung cho màn Đăng nhập và Tài khoản.
Future<void> showLanguagePicker(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final controller = LocaleController.instance;

  final selected = await showDialog<Locale>(
    context: context,
    builder: (dialogContext) => AppModal(
      title: l10n.settingsChooseLanguage,
      icon: HugeIcons.strokeRoundedLanguageCircle,
      onClose: () => Navigator.pop(dialogContext),
      children: LocaleController.supportedLocales.map((locale) {
        final isSelected =
            locale.languageCode == controller.locale.languageCode;

        return InkWell(
          onTap: () => Navigator.pop(dialogContext, locale),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    languageLabel(locale),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected ? AppColors.accent : Colors.black87,
                    ),
                  ),
                ),
                if (isSelected)
                  const HugeIcon(
                    icon: HugeIcons.strokeRoundedTick01,
                    color: AppColors.accent,
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    ),
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
      icon: HugeIcon(
        icon: HugeIcons.strokeRoundedGlobal,
        size: 20,
        color: color,
      ),
      // Không tự khai `TextStyle` cho nhãn nữa: cỡ chữ và độ đậm để
      // [AppButtons.quiet] lo (đã cắm sẵn qua `textButtonTheme`), còn màu thì
      // vẫn phải là [color] vì widget này nhận màu từ NGOÀI vào — nó nằm trên
      // nền ảnh của màn Đăng nhập chứ không phải trên nền trắng.
      label: Text(languageLabel(LocaleController.instance.locale)),
      style: TextButton.styleFrom(foregroundColor: color),
    );
  }
}
