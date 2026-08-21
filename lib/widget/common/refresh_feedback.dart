import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/notification_sound_service.dart';
import 'app_colors.dart';

/// Báo cho người dùng biết cú kéo-để-tải-lại đã xong.
///
/// Vòng xoay của `RefreshIndicator` chỉ nói "đang chạy" rồi biến mất, không nói
/// được kết quả. Kéo xong mà màn hình trông y như cũ (vì thật sự không có gì
/// mới) thì người dùng không phân biệt được là đã tải lại hay thao tác bị
/// trượt — nên phải có một câu xác nhận.
///
/// Dùng `SnackBar` chứ KHÔNG dùng [AppToast]: toast của app dành cho tin từ hệ
/// thống (giám thị nhắn, bị chặn khỏi ca thi) và luôn nằm góc trên phải. Đây là
/// phản hồi cho thao tác của chính người dùng, mắt họ đang ở đáy màn sau cú
/// vuốt xuống — trộn hai thứ vào một kiểu hiển thị là mất luôn khả năng nhìn
/// phát biết ngay tin đến từ đâu.
///
/// CHỈ gọi khi tải THÀNH CÔNG. Hỏng mạng mà vẫn báo "thành công" thì tệ hơn hẳn
/// việc im lặng.
void showRefreshDone(BuildContext context) {
  // Âm thanh phát độc lập, không chờ SnackBar: `SnackBar` tự nó không kêu.
  NotificationSoundService.play(NotificationSound.refresh).ignore();

  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);

  // Kéo liên tục mấy lần thì các thanh báo xếp hàng chờ nhau, cái cuối hiện lên
  // rất lâu sau khi người dùng đã bỏ đi. Dẹp cái đang hiện rồi mới đưa cái mới.
  messenger.hideCurrentSnackBar();

  messenger.showSnackBar(
    SnackBar(
      content: Row(
        children: [
          // Huy hiệu tròn xanh lá thay cho icon phẳng: trên nền trắng thì một
          // icon trơn chìm nghỉm, còn khối tròn đặc thì nhìn phát biết ngay là
          // báo thành công mà chưa cần đọc chữ.
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: Color(0xFF16A34A),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.commonReloadSuccess,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
          ),
        ],
      ),
      // Nền TRẮNG, không phải thanh tối mặc định của Material: thanh báo này
      // nổi ngay trên thanh tab xanh, nền tối đặt cạnh đó trông như một mảng
      // lạ dán đè lên giao diện.
      backgroundColor: Colors.white,
      elevation: 6,
      behavior: SnackBarBehavior.floating,
      // CHỈ 16, KHÔNG cộng thêm MediaQuery.paddingOf(context).bottom.
      //
      // HomeNavigation bơm chiều cao thanh tab vào MediaQuery, mà SnackBar dạng
      // floating đã tự trừ phần padding ấy rồi. Cộng tay lần nữa là đếm hai
      // lần: đo trên máy thật thì thanh báo bị đẩy lên tận giữa màn, che mất
      // mục "Cài đặt" — trông như lỗi bố cục chứ không ra lời xác nhận.
      margin: const EdgeInsets.all(16),
      // Viền mảnh: nền trắng trên nền trang cũng trắng thì không có viền là
      // thanh báo mất hẳn mép, trông như chữ tự nổi lên giữa màn.
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.line),
      ),
      // Ngắn hơn mặc định 4 giây: đây là lời xác nhận thoáng qua, không phải
      // tin cần đọc kỹ, mà nó lại nằm chắn ngay chỗ vừa vuốt.
      duration: const Duration(seconds: 2),
    ),
  );
}
