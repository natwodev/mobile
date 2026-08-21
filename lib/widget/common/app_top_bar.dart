import 'package:animated_app_bar/animated_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'app_colors.dart';

/// Tab đang đứng, dùng để chọn icon rải làm nền thanh tiêu đề.
///
/// Icon lấy ĐÚNG icon của tab đó dưới thanh điều hướng
/// (`HomeNavigation.dart`). Rải một hình khác là người dùng phải học thêm một
/// biểu tượng nữa cho cùng một chỗ đứng.
///
/// Không có mục cho Trang chủ vì màn đó không dùng thanh tiêu đề.
enum AppTopBarTab {
  history(HugeIcons.strokeRoundedTaskDone01),
  schedule(HugeIcons.strokeRoundedCalendarCheckIn01),
  classroom(HugeIcons.strokeRoundedCourse),
  account(HugeIcons.strokeRoundedUserCircle);

  const AppTopBarTab(this.icon);

  /// Dữ liệu icon của HugeIcons — là JSON đường vẽ, không phải `IconData`.
  final List<List<dynamic>> icon;
}

/// Thanh tiêu đề dùng chung cho MỌI màn có thanh tiêu đề.
///
/// Chỉ là một lớp mỏng đặt sẵn cấu hình cho [AnimatedAppBar] — gói nằm cùng
/// workspace (`../animated_app_bar`). Phần dựng thanh, đổ màu chuyển sắc và
/// mấy cái bẫy của Flutter đã nằm hết trong gói.
///
/// Giữ lại lớp này thay vì gọi thẳng [AnimatedAppBar] ở từng màn: bảng màu và
/// cỡ chữ là chuyện riêng của app, còn cách dựng thanh là chuyện chung. Có lớp
/// này thì đổi màu app chỉ sửa MỘT chỗ, và các màn không phải biết tới gói.
///
/// Trước đây chỉ hai màn tab dùng lớp này, chín màn còn lại tự dựng `AppBar`
/// thô. Mỗi màn một kiểu: Quét mã không căn giữa tiêu đề lại để cỡ chữ mặc
/// định 22 in đậm, Kết quả bài thi dùng hẳn `Colors.blue` thay vì màu của app,
/// bảy màn kia nền phẳng cỡ 20. Giờ tất cả đi qua đây.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    this.title,
    this.titleWidget,
    this.tab,
    this.showBack = false,
    this.actions,
  }) : assert(
         title != null || titleWidget != null,
         'Phải có title hoặc titleWidget.',
       );

  /// Cạnh ô chứa mỗi icon nền. Tách hằng vì phải khớp với `size` của chính
  /// `HugeIcon` bên trong: lệch nhau thì icon bị cắt hoặc lọt thỏm trong ô.
  static const double _driftIconSize = 34;

  final String? title;

  /// Tiêu đề tự dựng, cho màn cần chữ chạy ngang khi tên đề quá dài.
  final Widget? titleWidget;

  /// Tab đang đứng. Bỏ trống thì thanh chỉ có dải màu, không rải icon.
  ///
  /// Chỉ màn TAB mới rải icon. Màn con là nơi người dùng vào làm đúng một việc
  /// — đổi mật khẩu, xem kết quả — nên nền động ở đó chỉ tổ tranh chỗ với nội
  /// dung, nhất là khi bên phải còn đồng hồ đếm ngược.
  final AppTopBarTab? tab;

  /// Hiện nút quay lại. Bật cho màn được đẩy chồng lên.
  ///
  /// Mặc định `false` vì màn tab là nơi lớp này ra đời: ở đó có nút quay lại
  /// thì bấm vào chẳng đi đâu được, không có gì trong ngăn xếp để quay về.
  final bool showBack;

  /// Nút phụ bên phải, ví dụ đồng hồ đếm ngược ở màn làm bài.
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final AppTopBarTab? currentTab = tab;

    return AnimatedAppBar.gradientColors(
      title: title,
      titleWidget: titleWidget,
      actions: actions,
      iconDrift: currentTab == null
          ? null
          : AppBarIconDrift(
              icon: HugeIcon(
                // Key theo tab: thiếu nó thì Flutter coi icon cũ và icon mới là
                // cùng một widget nên thay thẳng, đổi tab thấy icon nhảy cái
                // rụp thay vì mờ chồng.
                key: ValueKey(currentTab),
                icon: currentTab.icon,
                color: Colors.white,
                size: _driftIconSize,
              ),
              size: _driftIconSize,
              // Mờ 0.14 trên nền xanh đậm: đủ thấy là có hình chuyển động,
              // nhưng không tranh chấp với chữ tiêu đề màu trắng nằm đè lên.
              opacity: 0.14,
              // 26 giây một vòng. Người dùng đứng ở màn tab chừng vài chục
              // giây, nên chậm cỡ này thì mỗi lần nhìn lại icon đã ở một chỗ
              // khác, mà không lúc nào thấy nó "chạy".
              period: const Duration(seconds: 26),
              count: 6,
            ),
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
      automaticallyImplyLeading: showBack,
    );
  }
}
