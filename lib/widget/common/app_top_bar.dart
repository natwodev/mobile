import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Thanh tiêu đề dùng chung cho các màn tab.
///
/// Gói lại vì hai màn Tài khoản và Lịch sử đang khai `AppBar` y hệt nhau, chép
/// tay từng dòng — thêm màn thứ ba là lệch. Cùng khuôn với [AppRefreshIndicator]
/// và [AppToast].
///
/// Chữ IN HOA cỡ nhỏ thay cho chữ thường cỡ 22 như trước: tiêu đề màn là nhãn
/// chỉ chỗ đứng, không phải nội dung để đọc. Cỡ 22 chiếm chỗ ngang với tiêu đề
/// nội dung bên dưới nên hai thứ tranh nhau sự chú ý. Chữ in hoa nhỏ đọc ra
/// ngay là "tên màn" mà không cần to.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({super.key, required this.title});

  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          // Chữ in hoa dính nhau hơn chữ thường vì không có phần thò lên thụt
          // xuống để mắt bám vào; nới chữ ra một chút cho dễ đọc.
          letterSpacing: 1.1,
        ),
      ),
      backgroundColor: AppColors.barBg,
      centerTitle: true,
      // Đây là các màn TAB, không phải màn được đẩy chồng lên: có nút quay lại
      // thì bấm vào chẳng đi đâu được.
      automaticallyImplyLeading: false,
    );
  }
}
