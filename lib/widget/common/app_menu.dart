import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'app_colors.dart';
import 'app_surfaces.dart';

/// Menu tràn (ba chấm) dùng chung.
///
/// Mặc định của Material 3 lạc hẳn khỏi phần còn lại của app: bo góc và bóng
/// đổ theo hệ riêng của nó, và tệ nhất là `surfaceTintColor` — M3 tự pha một
/// lớp màu chủ đạo lên mọi mặt nổi, nên tấm menu lẽ ra trắng lại ngả tím nhạt.
/// Cùng lý do như bộ nút và bộ ô nhập: không khai theme thì mỗi thứ rơi về một
/// mặc định khác nhau.
class AppMenu {
  AppMenu._();

  /// Bo góc, bằng đúng bo góc thẻ.
  static const double radius = 12;

  /// Một mục trong menu: icon bên trái, chữ bên phải.
  ///
  /// Có icon vì menu tràn không cho xem trước hậu quả — chữ "Dọn tất cả" đọc
  /// lướt rất dễ nhầm với "Đọc tất cả", hai chữ chỉ khác một dấu. Thêm cái
  /// thùng rác đỏ vào là nhận ra ngay cả khi không đọc kỹ.
  ///
  /// [danger] tô đỏ cả icon lẫn chữ, dành cho thao tác không lùi lại được.
  static PopupMenuItem<T> item<T>({
    required T value,
    required List<List<dynamic>> icon,
    required String label,
    bool enabled = true,
    bool danger = false,
  }) {
    // Mục bị khoá phải NHẠT ĐI THẤY RÕ, không chỉ mất phản hồi khi chạm: khoá
    // mà trông y hệt mục dùng được thì người dùng bấm mãi rồi tưởng app treo.
    final Color tint = !enabled
        ? AppColors.disabledInk
        : danger
        ? AppColors.danger
        : AppColors.ink;

    return PopupMenuItem<T>(
      value: value,
      enabled: enabled,
      height: 46,
      child: Row(
        children: [
          HugeIcon(icon: icon, color: tint, size: 18),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: tint,
            ),
          ),
        ],
      ),
    );
  }
}

/// Cắm menu tràn vào `ThemeData`.
///
/// Đặt ở theme thay vì tô tại từng chỗ gọi, cùng lý do như `appButtonThemes`:
/// một `PopupMenuButton` không khai gì cũng đã đúng kiểu, và thêm menu mới ở
/// màn khác thì không có cơ hội quên.
ThemeData appMenuThemes(ThemeData base) {
  return base.copyWith(
    popupMenuTheme: PopupMenuThemeData(
      color: Colors.white,

      // PHẢI đặt trong suốt. Material 3 pha `surfaceTint` lên mặt nổi theo độ
      // cao, nên để mặc định là tấm menu trắng ngả tím — lệch hẳn với thẻ và
      // hộp thoại của app vốn trắng thật.
      surfaceTintColor: Colors.transparent,

      // Bóng lấy màu nhấn thay vì xám trung tính của Material, cho cùng họ với
      // quầng sáng của thẻ và nút (`AppSurfaces`).
      elevation: 3,
      shadowColor: AppColors.accent.withValues(alpha: AppSurfaces.shadowAlpha),

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppMenu.radius),
        // Cùng viền mảnh với mọi mặt nổi khác: menu nổi trên nền trắng của màn
        // thì bóng thôi chưa đủ tách, phải có đường bao.
        side: AppSurfaces.side(),
      ),

      menuPadding: const EdgeInsets.symmetric(vertical: 6),

      textStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.ink,
      ),
    ),
  );
}
