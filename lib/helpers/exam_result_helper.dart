import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';

/// Helper class chứa các hàm tiện ích cho ExamResult
class ExamResultHelper {
  /// Format thời gian từ giây sang MM:SS
  static String formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Bảng màu của trang kết quả, lấy đúng của web
  /// (`exam-results.css` + `ScoreDisplay.tsx`) để hai nền tảng nhìn ra là một
  /// sản phẩm.
  static const Color slate900 = Color(0xFF1E293B);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color sky500 = Color(0xFF0EA5E9);

  /// Màu vòng điểm, theo đúng ngưỡng dự phòng của web khi chưa cấu hình bảng
  /// quy đổi điểm chữ (`ScoreDisplay.tsx:218`): >= 8 xanh, >= 5 hổ phách, còn
  /// lại đỏ. App di động chưa đọc bảng quy đổi nên luôn đi nhánh này.
  static Color getScoreRingColor(double score) {
    if (score >= 8.0) return const Color(0xFF16A34A);
    if (score >= 5.0) return const Color(0xFFD97706);
    return const Color(0xFFDC2626);
  }

  /// Lấy nhận xét dựa theo điểm số
  static String getScoreComment(BuildContext context, double score) {
    final l10n = AppLocalizations.of(context);
    if (score >= 9.0) return l10n.examScoreCommentExcellent;
    if (score >= 8.0) return l10n.examScoreCommentGood;
    if (score >= 6.5) return l10n.examScoreCommentFair;
    if (score >= 5.0) return l10n.examScoreCommentAverage;
    return l10n.examScoreCommentNeedsImprovement;
  }

  /// Tính phần trăm hoàn thành
  static double getCompletionPercent(int answered, int total) {
    if (total == 0) return 0;
    return (answered / total) * 100;
  }

  /// Tính điểm số (số câu đúng / tổng số câu * 10)
  static double calculateScore(int correctAnswers, int totalQuestions) {
    if (totalQuestions == 0) return 0;
    return (correctAnswers / totalQuestions) * 10;
  }
}
