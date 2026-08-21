import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'app_colors.dart';

/// Khung tấm trượt lên từ đáy màn, dùng chung cho các lựa chọn ngắn.
///
/// Song sinh với `AppModal`, khác ở chỗ ĐỨNG. Chọn cái nào là theo việc:
///
/// - `AppModal` (giữa màn) cho thứ CHẶN ĐƯỜNG — xác nhận đăng xuất, xác nhận
///   dọn sạch hộp thư. Nó cắt ngang, buộc trả lời trước khi đi tiếp.
/// - `AppSheet` (đáy màn) cho thứ chỉ MỞ RA XEM hoặc chọn nhanh rồi đóng —
///   thông tin thiết bị, chọn ngôn ngữ, chọn nguồn ảnh đại diện. Trượt xuống là
///   đóng, không cần tìm nút. Và nó nằm trong tầm ngón cái, khác hộp thoại giữa
///   màn phải với tay lên.
///
/// Vì sao dùng thay cho một trang riêng: mấy màn này chỉ có vài dòng nội dung.
/// Đẩy nguyên một trang chồng lên để hiện bốn dòng thông tin thì người dùng mất
/// hẳn ngữ cảnh đang đứng ở đâu, và phải bấm nút quay lại mới thoát được.
Future<T?> showAppSheet<T>({
  required BuildContext context,
  required String title,
  required List<Widget> children,
  List<List<dynamic>>? icon,
  Color accentColor = AppColors.accent,
  List<Widget> actions = const [],
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.white,
    // Nội dung dài (thông tin thiết bị) phải cuộn được và cao hơn nửa màn, mà
    // `showModalBottomSheet` mặc định chặn ở nửa màn và KHÔNG cuộn.
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => _AppSheetBody(
      title: title,
      icon: icon,
      accentColor: accentColor,
      actions: actions,
      children: children,
    ),
  );
}

class _AppSheetBody extends StatelessWidget {
  const _AppSheetBody({
    required this.title,
    required this.children,
    required this.icon,
    required this.accentColor,
    required this.actions,
  });

  final String title;
  final List<Widget> children;
  final List<List<dynamic>>? icon;
  final Color accentColor;
  final List<Widget> actions;

  /// Hàng nút cuối tấm.
  ///
  /// MỘT nút thì kéo dài hết bề ngang, giống nút "Sao chép thông tin" trong
  /// chính tấm Thông tin thiết bị. Nút đơn nép một góc đọc ra như hành động
  /// phụ, trong khi nó chính là việc người dùng mở tấm này ra để làm.
  ///
  /// NHIỀU nút thì chia đều, mỗi cái một phần bằng nhau. Không kéo dài từng
  /// cái vì hai nút full-width xếp chồng lên nhau chiếm gần nửa tấm sheet.
  Widget _buildActionBar() {
    if (actions.length == 1) {
      return SizedBox(width: double.infinity, child: actions.first);
    }

    return Row(
      children: [
        for (int i = 0; i < actions.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(child: actions[i]),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Trần 85% chiều cao màn: cao hơn thì tấm sheet che gần hết nền và đọc ra
    // như một trang mới, mất luôn cảm giác "đang mở tạm thứ gì đó bên trên".
    final double maxHeight = MediaQuery.sizeOf(context).height * 0.85;

    // Chỗ bàn phím đang chiếm. PHẢI tự đẩy lên: `showModalBottomSheet` không
    // tránh bàn phím, nên tấm sheet có ô nhập sẽ bị bàn phím che mất đúng cái ô
    // người dùng vừa chạm vào — gõ mà không thấy mình gõ gì.
    final double keyboard = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Thanh nắm: dấu hiệu duy nhất cho biết tấm này kéo xuống được.
              // Thiếu nó thì người dùng đi tìm nút đóng.
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 12, 10),
                child: Row(
                  children: [
                    if (icon != null) ...[
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: HugeIcon(
                            icon: icon!,
                            color: accentColor,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const HugeIcon(
                        icon: HugeIcons.strokeRoundedCancel01,
                        color: AppColors.inkMuted,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, color: AppColors.line),

              // `Flexible` chứ không phải `Expanded`: nội dung ngắn thì tấm sheet
              // phải co lại theo, `Expanded` sẽ kéo nó cao hết trần.
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: children,
                  ),
                ),
              ),

              if (actions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: _buildActionBar(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
