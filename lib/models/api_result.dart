import 'exam_history_item.dart';

/// Kết quả của các API chỉ cần biết thành công hay không kèm thông báo lỗi.
class ProfileUpdateResult {
  final bool success;
  final String? error;

  ProfileUpdateResult({required this.success, this.error});
}

/// Kết quả tải lịch sử làm bài.
class ExamHistoryResult {
  final bool success;
  final List<ExamHistoryItem> items;

  /// Câu lỗi đã dịch, chỉ có khi [success] là `false`.
  final String? error;

  const ExamHistoryResult({
    required this.success,
    this.items = const [],
    this.error,
  });
}

/// Kết quả xin phiếu xem lại một bài.
class ExamReviewOpenResult {
  final bool success;

  /// Lý do bị chặn do máy chủ trả về (403). `null` khi thất bại vì lý do khác
  /// (mất mạng, lỗi máy chủ) — khi đó dùng [error].
  final ExamReviewBlockedReason? blockedReason;

  final String? error;

  const ExamReviewOpenResult({
    required this.success,
    this.blockedReason,
    this.error,
  });
}
