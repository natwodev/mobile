import 'package:flutter/material.dart';

import 'app_colors.dart';

// Xuất lại [AppColors] để chỗ nào dùng nút thì có luôn bảng màu, khỏi phải nhớ
// hai đường import cho một việc.
export 'app_colors.dart';

/// BỘ NÚT DÙNG CHUNG cho toàn app.
///
/// Trước file này, mỗi nút tự khai kiểu dáng tại chỗ và không chỗ nào giống
/// chỗ nào: bốn bo góc khác nhau cho cùng cấp "nút chính" (5, 6, 8, 12 và cả
/// bo tròn hoàn toàn của Material 3), bốn chiều cao (40, 44, 48), bốn cỡ chữ
/// (13/w600, 14/w500, 14/w700, 16/bold) và HAI tông xanh đứng cạnh nhau trong
/// cùng một hành trình vào thi (#2196F3 ở luồng nhập mã / QR, #2563EB ở luồng
/// làm bài).
///
/// Chỗ lộ rõ nhất: cùng một hành động "Nộp bài" mà nút trong hộp thoại và nút
/// dưới thanh điều hướng là hai nút khác nhau về bo góc, bóng, cỡ chữ và
/// chiều cao.
///
/// Cách dùng:
///   * Không đặt style gì cả → nút đã đúng chuẩn, vì [appButtonThemes] đã cắm
///     bộ này vào `ThemeData`. Đây là cách MẶC ĐỊNH nên dùng.
///   * Cần một biến thể (nguy hiểm / phụ / nhạt) thì lấy từ [AppButtons].
///
/// ĐỪNG khai `backgroundColor`, `shape`, `padding`, `textStyle` ngay tại chỗ
/// gọi nữa — đó chính là thứ đã làm rối lên.
/// Kích thước dùng chung của mọi nút.
class AppButtonMetrics {
  AppButtonMetrics._();

  /// Bo góc. Không dùng bo tròn hoàn toàn (mặc định Material 3): nút bo tròn
  /// nằm cạnh ô nhập bo 8 và thẻ bo 12 thì đọc ra như một con chip trạng thái
  /// chứ không phải nút bấm.
  static const double radius = 8;

  /// Chiều cao tối thiểu. 48 là ngưỡng vùng chạm của Material, cũng đúng bằng
  /// chiều cao mà 5 nút chính sẵn có trong app đang ghim bằng `SizedBox`.
  static const double minHeight = 48;

  static const EdgeInsets padding = EdgeInsets.symmetric(horizontal: 18);

  /// Cỡ chữ: chọn 15 chứ không phải 16 của các nút cũ, vì thanh điều hướng khi
  /// làm bài phải xếp hai nút có icon cạnh nhau trên màn 320dp.
  static const TextStyle textStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
  );

  static RoundedRectangleBorder get shape =>
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));
}

/// Các biến thể nút. Dùng khi vai trò của nút KHÔNG phải "hành động chính".
class AppButtons {
  AppButtons._();

  /// Hành động chính: nền đặc màu nhấn, chữ trắng.
  ///
  /// Không cần gọi tường minh — đây đã là mặc định của mọi [ElevatedButton].
  static ButtonStyle get primary => ElevatedButton.styleFrom(
    backgroundColor: AppColors.accent,
    foregroundColor: Colors.white,
    disabledBackgroundColor: AppColors.line,
    disabledForegroundColor: AppColors.disabledInk,
    elevation: 0,
    minimumSize: const Size(64, AppButtonMetrics.minHeight),
    padding: AppButtonMetrics.padding,
    shape: AppButtonMetrics.shape,
    textStyle: AppButtonMetrics.textStyle,
  );

  /// Hành động phụ đứng cạnh một nút chính (ví dụ "Trước" cạnh "Tiếp theo").
  ///
  /// Nền xám đặc chứ không phải viền: hai nút cùng hàng thì nút có nền và nút
  /// chỉ có viền cân nhau về khối lượng, mắt không phân được cái nào là chính.
  static ButtonStyle get secondary => ElevatedButton.styleFrom(
    backgroundColor: AppColors.surfaceMuted,
    foregroundColor: AppColors.ink,
    disabledBackgroundColor: AppColors.surfaceMuted,
    disabledForegroundColor: AppColors.disabledInk,
    elevation: 0,
    minimumSize: const Size(64, AppButtonMetrics.minHeight),
    padding: AppButtonMetrics.padding,
    shape: AppButtonMetrics.shape,
    textStyle: AppButtonMetrics.textStyle,
  );

  /// Hành động không thể hoàn tác và gây mất mát (đăng xuất, xoá).
  ///
  /// KHÔNG dùng cho "Nộp bài": nộp bài là việc sinh viên đến đây để làm, tô đỏ
  /// nó là dạy người dùng rằng đỏ không thực sự có nghĩa gì.
  static ButtonStyle get danger => ElevatedButton.styleFrom(
    backgroundColor: AppColors.danger,
    foregroundColor: Colors.white,
    disabledBackgroundColor: AppColors.line,
    disabledForegroundColor: AppColors.disabledInk,
    elevation: 0,
    minimumSize: const Size(64, AppButtonMetrics.minHeight),
    padding: AppButtonMetrics.padding,
    shape: AppButtonMetrics.shape,
    textStyle: AppButtonMetrics.textStyle,
  );

  /// Nút viền — hành động phụ đứng MỘT MÌNH (không cạnh nút chính nào).
  static ButtonStyle get outlined => OutlinedButton.styleFrom(
    foregroundColor: AppColors.accent,
    disabledForegroundColor: AppColors.disabledInk,
    side: const BorderSide(color: AppColors.accent),
    minimumSize: const Size(64, AppButtonMetrics.minHeight),
    padding: AppButtonMetrics.padding,
    shape: AppButtonMetrics.shape,
    textStyle: AppButtonMetrics.textStyle,
  );

  /// Nút chữ trần — lối thoát nhẹ ("Đóng", "Để sau").
  static ButtonStyle get quiet => TextButton.styleFrom(
    foregroundColor: AppColors.inkMuted,
    disabledForegroundColor: AppColors.disabledInk,
    minimumSize: const Size(64, AppButtonMetrics.minHeight),
    padding: AppButtonMetrics.padding,
    shape: AppButtonMetrics.shape,
    textStyle: AppButtonMetrics.textStyle,
  );

  /// Nút chữ mang nghĩa nguy hiểm ("Đăng xuất" trong hộp thoại xác nhận).
  static ButtonStyle get quietDanger => TextButton.styleFrom(
    foregroundColor: AppColors.danger,
    disabledForegroundColor: AppColors.disabledInk,
    minimumSize: const Size(64, AppButtonMetrics.minHeight),
    padding: AppButtonMetrics.padding,
    shape: AppButtonMetrics.shape,
    textStyle: AppButtonMetrics.textStyle,
  );
}

/// Cắm bộ nút trên vào `ThemeData`.
///
/// Đây mới là phần quan trọng: nhờ nó, một [ElevatedButton] KHÔNG khai style
/// nào cũng đã đúng chuẩn. Trước đây nút không khai style rơi về mặc định
/// Material 3 — nền tím nhạt, chữ mờ, bo tròn hoàn toàn — trông y như nút đang
/// bị khoá, và đó chính là hình dạng của nút "Nộp bài" trong hộp thoại.
ThemeData appButtonThemes(ThemeData base) {
  return base.copyWith(
    elevatedButtonTheme: ElevatedButtonThemeData(style: AppButtons.primary),
    outlinedButtonTheme: OutlinedButtonThemeData(style: AppButtons.outlined),
    textButtonTheme: TextButtonThemeData(style: AppButtons.quiet),
  );
}
