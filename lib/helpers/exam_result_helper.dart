import 'package:flutter/material.dart';

/// Helper class chứa các hàm tiện ích cho ExamResult
class ExamResultHelper {
  /// Format thời gian từ giây sang MM:SS
  static String formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Lấy màu gradient dựa theo điểm số
  static List<Color> getScoreColors(double score) {
    if (score >= 8.0) return [Colors.green, Colors.green[700]!];
    if (score >= 6.5) return [Colors.blue, Colors.blue[700]!];
    if (score >= 5.0) return [Colors.orange, Colors.orange[700]!];
    return [Colors.red, Colors.red[700]!];
  }

  /// Lấy nhận xét dựa theo điểm số
  static String getScoreComment(double score) {
    if (score >= 9.0) return 'Xuất sắc!';
    if (score >= 8.0) return 'Giỏi!';
    if (score >= 6.5) return 'Khá!';
    if (score >= 5.0) return 'Trung bình!';
    return 'Cần cố gắng thêm!';
  }

  /// Lấy màu chính dựa theo điểm số
  static Color getScoreMainColor(double score) {
    if (score >= 8.0) return Colors.green;
    if (score >= 6.5) return Colors.blue;
    if (score >= 5.0) return Colors.orange;
    return Colors.red;
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
