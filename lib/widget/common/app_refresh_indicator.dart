import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Kéo-để-tải-lại dùng chung cho mọi màn.
///
/// Vì sao phải gói lại thay vì mỗi màn tự gọi `RefreshIndicator`: trước file
/// này app có BỐN chỗ kéo-để-tải-lại, và chỉ hai chỗ đặt `color` — hai chỗ còn
/// lại (màn Tài khoản, màn Lịch sử lúc rỗng) rơi về màu mặc định của Material.
/// Cùng một thao tác mà vòng xoay đổi màu tuỳ màn, người dùng nhìn ra ngay là
/// lệch dù không gọi tên được vấn đề.
///
/// Đây cũng là hạt giống của lần trôi dạt tiếp theo: thêm màn mới, quên một
/// tham số, lại lệch. Gói vào một chỗ thì không quên được nữa.
class AppRefreshIndicator extends StatelessWidget {
  const AppRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
    this.edgeOffset = 0,
  });

  final Future<void> Function() onRefresh;
  final Widget child;

  /// Khoảng đẩy vòng xoay xuống khỏi mép trên vùng cuộn.
  ///
  /// Màn có `AppBar` thì vùng cuộn đã bắt đầu dưới thanh tiêu đề nên để 0.
  /// Trang chủ KHÔNG có `AppBar` — băng ảnh chạy lên tận mép trên, luồn cả
  /// dưới thanh trạng thái — nên phải đẩy xuống đúng chiều cao thanh trạng
  /// thái, không thì vòng xoay nằm đè lên đồng hồ và cột sóng.
  final double edgeOffset;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.accent,
      backgroundColor: Colors.white,
      edgeOffset: edgeOffset,
      child: child,
    );
  }
}
