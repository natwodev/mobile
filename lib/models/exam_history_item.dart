/// Lý do một bài KHÔNG mở xem lại được.
///
/// Bốn giá trị này là hợp đồng với backend (`ExamReviewService.OpenReviewAsync`
/// trả về đúng bốn chuỗi này), đồng thời khớp `ExamReviewBlockedReason` của web.
/// ĐỪNG đổi tên chuỗi trong [fromCode] — chỉ đổi được cách hiển thị.
enum ExamReviewBlockedReason {
  /// Ca thi không bật cho xem lại.
  notAllowed,

  /// Có bật nhưng chưa tới giờ mở.
  notOpenYet,

  /// Đã qua thời hạn xem lại.
  closed,

  /// Bài đang được mở lại để làm lại nên chưa chốt kết quả.
  notCompleted;

  static ExamReviewBlockedReason fromCode(String? code) {
    switch (code) {
      case 'NOT_OPEN_YET':
        return ExamReviewBlockedReason.notOpenYet;
      case 'CLOSED':
        return ExamReviewBlockedReason.closed;
      case 'NOT_COMPLETED':
        return ExamReviewBlockedReason.notCompleted;
      // Kể cả `NOT_ALLOWED` lẫn mã lạ đều về đây: mã lạ mà nói "không cho xem
      // lại" vẫn đúng bản chất, còn hơn để màn hình trống không giải thích gì.
      default:
        return ExamReviewBlockedReason.notAllowed;
    }
  }
}

/// Một dòng trong màn "Lịch sử làm bài" (`GET api/student/exam-history`).
///
/// Khớp `ExamHistoryItemDto` của backend
/// (`backend_manage.shared/DTOs/ExamReviewDtos.cs`) và bản web
/// (`frontend_manage/src/services/dto/examReview.ts`).
class ExamHistoryItem {
  final String studentExamSessionId;
  final String userCode;
  final String? subjectName;

  final DateTime? startTime;
  final DateTime? endTime;

  final double score;
  final int? correctAnswers;
  final int? totalQuestions;
  final bool isCompleted;

  /// Số lần vi phạm ghi nhận trong lúc thi.
  final int violationCount;

  /// Số phút giáo viên đã cộng thêm cho bài này.
  final int extraMinutes;

  /// Bấm "Xem lại" có mở được không.
  final bool canReview;

  /// Mở được thì có thấy đáp án đúng không.
  final bool showAnswerKey;

  /// Mở được thì có xem được nội dung từng câu không.
  /// `false` = chỉ thấy lưới đúng/sai.
  final bool showQuestionDetail;

  final ExamReviewBlockedReason? reviewBlockedReason;
  final DateTime? reviewOpensAt;
  final DateTime? reviewClosesAt;

  const ExamHistoryItem({
    required this.studentExamSessionId,
    required this.userCode,
    this.subjectName,
    this.startTime,
    this.endTime,
    this.score = 0,
    this.correctAnswers,
    this.totalQuestions,
    this.isCompleted = false,
    this.violationCount = 0,
    this.extraMinutes = 0,
    this.canReview = false,
    this.showAnswerKey = false,
    this.showQuestionDetail = false,
    this.reviewBlockedReason,
    this.reviewOpensAt,
    this.reviewClosesAt,
  });

  static DateTime? _date(dynamic raw) {
    if (raw == null) return null;
    final text = raw.toString();
    if (text.isEmpty) return null;
    return DateTime.tryParse(text);
  }

  static int? _int(dynamic raw) {
    if (raw == null) return null;
    if (raw is int) return raw;
    return int.tryParse(raw.toString());
  }

  factory ExamHistoryItem.fromJson(Map<String, dynamic> json) {
    return ExamHistoryItem(
      studentExamSessionId: json['studentExamSessionId']?.toString() ?? '',
      userCode: json['userCode']?.toString() ?? '',
      subjectName: json['subjectName']?.toString(),
      startTime: _date(json['startTime']),
      endTime: _date(json['endTime']),
      score: (json['score'] as num?)?.toDouble() ?? 0,
      correctAnswers: _int(json['correctAnswers']),
      totalQuestions: _int(json['totalQuestions']),
      isCompleted: json['isCompleted'] == true,
      violationCount: _int(json['violationCount']) ?? 0,
      extraMinutes: _int(json['extraMinutes']) ?? 0,
      canReview: json['canReview'] == true,
      showAnswerKey: json['showAnswerKey'] == true,
      showQuestionDetail: json['showQuestionDetail'] == true,
      // Chỉ dựng lý do khi backend thật sự gửi: `null` nghĩa là KHÔNG bị chặn,
      // khác hẳn với "bị chặn vì lý do không rõ".
      reviewBlockedReason: json['reviewBlockedReason'] == null
          ? null
          : ExamReviewBlockedReason.fromCode(
              json['reviewBlockedReason'].toString(),
            ),
      reviewOpensAt: _date(json['reviewOpensAt']),
      reviewClosesAt: _date(json['reviewClosesAt']),
    );
  }

  /// Mốc để xếp mới nhất lên đầu: ưu tiên giờ nộp, chưa có thì lấy giờ bắt đầu.
  ///
  /// Backend đã sắp giảm dần theo `endTime`, nhưng màn hình vẫn tự sắp lại để
  /// không phụ thuộc vào thứ tự đó (giống bản web).
  DateTime? get sortedAt => endTime ?? startTime;

  /// Số phút làm bài suy từ hai mốc thời gian.
  ///
  /// Trả `null` khi thiếu mốc hoặc dữ liệu vô lý (nộp trước cả lúc bắt đầu —
  /// vẫn xảy ra khi giờ máy chủ bị chỉnh). Màn hình hiển thị "-" cho `null`
  /// thay vì in ra một con số âm.
  int? get workedMinutes {
    final start = startTime;
    final end = endTime;
    if (start == null || end == null) return null;
    final diff = end.difference(start).inSeconds;
    if (diff <= 0) return null;
    return (diff / 60).round().clamp(1, 1 << 30);
  }
}
