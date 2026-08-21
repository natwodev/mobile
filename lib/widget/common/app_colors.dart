import 'package:flutter/material.dart';

/// BẢNG MÀU DÙNG CHUNG — nguồn DUY NHẤT cho mọi màu lặp lại của app.
///
/// Trước file này, cùng một giá trị màu được khai ở hai nơi dưới hai cái tên
/// (`QuizColors.accent` cho luồng làm bài, một hằng số riêng cho phần còn lại)
/// — và bên cạnh đó còn ba tông "xanh" khác nhau cho cùng vai trò nút chính:
/// `#2196F3`, `#2563EB`, `#0EA5E9`. Hai tên cho một màu chính là hạt giống của
/// lần trôi dạt tiếp theo: sửa một bên, bên kia ở lại.
///
/// Giá trị lấy theo web (`csharp_manage/frontend_manage/src/styles/variables.css`)
/// để app di động và web nói cùng một ngôn ngữ màu.
class AppColors {
  AppColors._();

  /// Xanh chủ đạo DUY NHẤT (`--color-primary-dark`).
  static const Color accent = Color(0xFF2563EB);
  static const Color accentPressed = Color(0xFF1D4ED8);

  /// Nền xanh nhạt cho ô/nút phụ trên nền trắng (`--color-primary-bg`).
  static const Color accentBg = Color(0xFFEFF6FF);

  /// Nền các thanh khung app — thanh tiêu đề (`AppBar`) và thanh tab dưới cùng
  /// dùng chung một tông xanh trời; đổi ở đây là đổi cả hai, không còn cảnh
  /// header một màu thanh tab một màu.
  static const Color barBg = Color(0xFF1E8BCF);

  static const Color danger = Color(0xFFDC2626);

  /// Vàng cảnh báo.
  ///
  /// Bằng đúng màu thanh báo kiểu warning trong `app_banner.dart` — cùng một ý
  /// nghĩa thì phải cùng một màu, và đặt tên ở đây để lần sau khỏi ai chép lại
  /// mã hex lần thứ ba.
  static const Color warning = Color(0xFFF59E0B);

  static const Color ink = Color(0xFF1E293B);
  static const Color inkMuted = Color(0xFF64748B);

  static const Color line = Color(0xFFE2E8F0);
  static const Color surfaceMuted = Color(0xFFF1F5F9);
  static const Color disabledInk = Color(0xFF94A3B8);
}
