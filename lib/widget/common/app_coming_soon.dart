import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'app_colors.dart';

/// Thân màn cho một tab ĐÃ DỰNG KHUNG NHƯNG CHƯA CÓ DỮ LIỆU.
///
/// Gom lại vì đã có hai màn như vậy (Lịch thi, Lớp học) và cả hai giống hệt
/// nhau: một vòng tròn nhạt bọc icon, một dòng tiêu đề, một đoạn giải thích.
/// Chép tay lần thứ hai là bắt đầu lệch — cỡ icon, độ đục nền, khoảng cách.
///
/// Vì sao dựng tab trước khi có API: chỗ đứng của một tab ảnh hưởng tới chỉ số
/// của mọi tab khác (thứ tự trong thanh, mảng màn, mảng bộ điều khiển cuộn).
/// Chốt sớm thì lúc dữ liệu về chỉ còn đúng một việc là thay phần thân này.
class ComingSoonView extends StatelessWidget {
  const ComingSoonView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.scrollController,
  });

  final List<List<dynamic>> icon;
  final String title;
  final String message;

  /// Do `HomeNavigation` giữ, để bấm nút tab là cuộn màn này về đầu.
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    // `ListView` chứ không phải `Center` trần, dù nội dung chỉ có mấy dòng:
    // `scrollController` phải bám được vào một vùng cuộn, không thì bấm nút tab
    // để cuộn về đầu chẳng có tác dụng gì. Và lúc có dữ liệu thật thì đây đã
    // sẵn là danh sách, không phải đổi kiểu widget.
    return ListView(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.14),
        Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: HugeIcon(icon: icon, color: AppColors.accent, size: 44),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: AppColors.inkMuted,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
