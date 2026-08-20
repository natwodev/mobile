import 'package:flutter/material.dart';

import '../exam/quiz_theme.dart';

/// Lớp phủ "đang xử lý, đừng thoát" dùng chung.
///
/// Cố ý KHÔNG dùng `showDialog`: hộp thoại chờ phải đóng bằng `Navigator.pop`
/// sau một chuỗi `await`, rất dễ pop nhầm route khác khi có điều hướng chen
/// vào. Lớp phủ nằm ngay trong cây widget nên tự biến mất theo trạng thái.
///
/// Tách khỏi màn làm bài để màn vào thi dùng đúng một hình hài — hai lúc chờ
/// lâu nhất của sinh viên (vào phòng thi và nộp bài) mà hiện hai kiểu khác
/// nhau thì trông như hai ứng dụng.
class AppBusyOverlay extends StatelessWidget {
  const AppBusyOverlay({super.key, required this.title, this.hint});

  final String title;

  /// Dòng dặn thêm, ví dụ "đừng thoát ứng dụng". Nhỏ hơn tiêu đề một nấc: gộp
  /// cả hai thành một dòng đậm thì đọc ra như đang có sự cố, trong khi việc
  /// đang diễn ra hoàn toàn bình thường.
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      child: ColoredBox(
        color: const Color(0xFF0F172A).withValues(alpha: 0.55),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 300),
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 34,
                    height: 34,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        QuizColors.accent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: QuizColors.ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (hint != null && hint!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      hint!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: QuizColors.inkMuted,
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
