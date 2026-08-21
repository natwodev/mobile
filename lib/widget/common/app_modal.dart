import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'package:hugeicons/hugeicons.dart';

/// Khung hộp thoại dùng chung cho các modal của app (chọn ngôn ngữ, xác nhận
/// vào thi, ...).
///
/// Dựng trên [Dialog] thay vì [AlertDialog] để kiểm soát được ba thứ mà
/// AlertDialog không cho chỉnh gọn:
/// - dải tiêu đề có nền nhạt + ô icon bo góc, tách phần đầu khỏi nội dung mà
///   không cần đường kẻ đậm;
/// - trần chiều cao 80% màn hình, phần giữa tự cuộn — `AlertDialog.content`
///   KHÔNG tự cuộn nên nội dung dài (danh sách ngôn ngữ, thông tin ca thi kèm
///   cảnh báo định vị) sẽ tràn dọc trên máy nhỏ hoặc khi bật cỡ chữ lớn;
/// - trần bề rộng 420 để hộp thoại không kéo dài lê thê trên máy tablet.
class AppModal extends StatelessWidget {
  const AppModal({
    super.key,
    required this.title,
    required this.children,
    this.icon,
    this.accentColor = AppColors.accent,
    this.onClose,
    this.actions = const [],
  });

  /// Tiêu đề hộp thoại.
  final String title;

  /// Nội dung, xếp dọc trong vùng tự cuộn.
  final List<Widget> children;

  /// Icon Hugeicons (`HugeIcons.strokeRounded*`) đặt trong ô vuông bo góc cạnh
  /// tiêu đề. Bỏ trống thì tiêu đề chiếm trọn hàng.
  final List<List<dynamic>>? icon;

  /// Màu nhấn của dải tiêu đề và ô icon.
  final Color accentColor;

  /// Việc cần làm khi bấm dấu X ở góc phải tiêu đề. Bỏ trống thì không hiện
  /// dấu X — dùng cho modal bắt buộc phải chọn một phương án ở thanh nút.
  final VoidCallback? onClose;

  /// Hàng nút cuối hộp thoại. Bỏ trống khi modal tự đóng bằng thao tác chọn
  /// (ví dụ chọn ngôn ngữ).
  final List<Widget> actions;

  static const double _radius = 20;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.8;

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 12,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_radius),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 420, maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            // Flexible chứ không Expanded: hộp thoại co theo nội dung khi ngắn,
            // chỉ cuộn khi chạm trần chiều cao.
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  actions.isEmpty ? 20 : 8,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: children,
                ),
              ),
            ),
            if (actions.isNotEmpty) _buildActionBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      // Đệm phải nhỏ hơn khi có dấu X: IconButton đã tự mang vùng chạm 40x40
      // quanh icon, cộng thêm 20 nữa thì dấu X trông lệch hẳn vào trong.
      padding: EdgeInsets.fromLTRB(20, 18, onClose == null ? 20 : 8, 16),
      // Nền MỘT MÀU + một đường kẻ dưới, không gradient. Dải chuyển màu chéo
      // của bản cũ nhạt dần về góc phải nên ranh giới giữa phần đầu và phần
      // nội dung mờ hẳn ở đúng phía có dấu X; đường kẻ nói cùng một điều mà
      // đều nét trên cả bề ngang.
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        border: Border(
          bottom: BorderSide(color: accentColor.withValues(alpha: 0.18)),
        ),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(_radius),
        ),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(10),
              ),
              child: HugeIcon(icon: icon!, color: accentColor, size: 22),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          if (onClose != null) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: onClose,
              // Màu đặt thẳng trên HugeIcon: icon là SVG nên IconButton.color
              // không với tới được.
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedCancel01,
                color: Colors.grey.shade600,
                size: 20,
              ),
              visualDensity: VisualDensity.compact,
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      // MỘT nút thì kéo dài hết bề ngang. Nút đơn nép một góc đọc ra như hành
      // động phụ, trong khi nó chính là việc người dùng mở hộp thoại ra để làm
      // — bấm Đăng xuất rồi vẫn phải đi tìm nút Đăng xuất thứ hai ở góc.
      //
      // NHIỀU nút thì vẫn dùng OverflowBar (thứ AlertDialog vẫn dùng): nó tự
      // xếp dọc khi hàng ngang không đủ chỗ, nên nhãn dài hoặc cỡ chữ lớn không
      // làm tràn ngang. Kéo dài từng nút thì mất đúng khả năng đó.
      child: actions.length == 1
          ? SizedBox(width: double.infinity, child: actions.first)
          : OverflowBar(
              alignment: MainAxisAlignment.center,
              overflowAlignment: OverflowBarAlignment.center,
              spacing: 8,
              overflowSpacing: 4,
              children: actions,
            ),
    );
  }
}
