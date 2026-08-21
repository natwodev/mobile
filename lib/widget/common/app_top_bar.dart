import 'package:animated_app_bar/animated_app_bar.dart';
import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Thanh tiêu đề dùng chung cho các màn tab.
///
/// Chỉ còn là một lớp mỏng đặt sẵn cấu hình cho [AnimatedAppBar] — gói nằm
/// cùng workspace (`../animated_app_bar`). Phần dựng thanh, đổ màu chuyển sắc
/// và mấy cái bẫy của Flutter đã nằm hết trong gói.
///
/// Giữ lại lớp này thay vì gọi thẳng [AnimatedAppBar] ở từng màn: bảng màu và
/// cỡ chữ là chuyện riêng của app, còn cách dựng thanh là chuyện chung. Có lớp
/// này thì đổi màu app chỉ sửa MỘT chỗ, và các màn không phải biết tới gói.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({super.key, required this.title});

  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AnimatedAppBar.gradientColors(
      title: title,
      // Đúng cặp màu của thẻ thống kê ở màn Lịch sử
      // (`exam_history_screen.dart`), để hai mảng xanh lớn nhất của app nói
      // cùng một ngôn ngữ.
      //
      // THỨ TỰ ĐẢO so với thẻ thống kê: thẻ đó đi barBg -> accent, còn ở đây
      // accent phải nằm bên PHẢI vì hướng là rightToLeft và phần tử đầu nằm ở
      // đầu "begin". Lý do cần accent bên phải: tính ra `accent` (#2563EB) sáng
      // 96 còn `barBg` (#1E8BCF) sáng 121 — accent mới là màu ĐẬM. Chép nguyên
      // thứ tự của thẻ là thành nhạt phải đậm trái, ngược hẳn chiều mong muốn.
      colors: const [AppColors.accent, AppColors.barBg],
      direction: AppBarGradientDirection.rightToLeft,
      titleStyle: const TextStyle(
        // Cỡ 15 thay cho 22 như ban đầu: tiêu đề màn là nhãn chỉ chỗ đứng,
        // không phải nội dung để đọc. Cỡ 22 chiếm chỗ ngang với tiêu đề nội
        // dung bên dưới nên hai thứ tranh nhau sự chú ý.
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        letterSpacing: 0.2,
      ),
      // Đây là các màn TAB, không phải màn được đẩy chồng lên: có nút quay lại
      // thì bấm vào chẳng đi đâu được.
      automaticallyImplyLeading: false,
    );
  }
}
