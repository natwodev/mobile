/// Các sự kiện SignalR mà MÀN LÀM BÀI quan tâm.
///
/// Tên field bám đúng payload backend gửi xuống nhóm `student_{studentId}_{ca thi}`
/// (xem backend_manage.core/Services/AuthService/NotificationService.cs và
/// Messages/RabbitMQ/MessageProcessingService.cs).
sealed class ExamRealtimeEvent {
  const ExamRealtimeEvent();
}

/// `ReceiveExtraTime` — giám thị cộng/trừ thời gian.
class ExtraTimeEvent extends ExamRealtimeEvent {
  const ExtraTimeEvent({
    required this.minutes,
    required this.reason,
    this.newEndTime,
    this.timestamp,
  });

  /// Số phút cộng thêm; ÂM nghĩa là bị trừ giờ.
  final int minutes;

  /// Mốc kết thúc mới do máy chủ tính. Có thể null (một nhánh gửi thiếu field).
  final DateTime? newEndTime;

  final String reason;

  /// Mốc thời gian máy chủ gắn vào sự kiện.
  ///
  /// Dùng để KHỬ TRÙNG: backend có hai đường xử lý song song (RabbitMQ consumer
  /// và bản đồng bộ dự phòng), một hành động cộng giờ có thể dội về hai lần —
  /// cộng hai lần là sinh viên được gấp đôi thời gian.
  final String? timestamp;

  bool get isAdded => minutes >= 0;
}

/// `ExamSubmittedByTeacher` — bài ĐÃ được đóng ở máy chủ.
///
/// [forced] = true khi hệ thống tự nộp do vi phạm quá ngưỡng, false khi giám
/// thị bấm nộp hộ. App TUYỆT ĐỐI không gọi submit thêm lần nữa.
class TeacherSubmittedEvent extends ExamRealtimeEvent {
  const TeacherSubmittedEvent({
    required this.forced,
    required this.reason,
    this.submittedTime,
  });

  final bool forced;
  final String reason;
  final DateTime? submittedTime;
}

/// `ReceiveViolationWarning` — chạm ngưỡng vi phạm. Mỗi phiên chỉ gửi một lần.
class ViolationWarningEvent extends ExamRealtimeEvent {
  const ViolationWarningEvent({
    required this.violationCount,
    required this.threshold,
  });

  final int violationCount;
  final int threshold;
}

/// `StudentBlocked` — giám thị chặn thí sinh. Máy chủ đã nộp bài hộ trước đó.
class StudentBlockedEvent extends ExamRealtimeEvent {
  const StudentBlockedEvent({required this.examSessionSubjectId});

  final String examSessionSubjectId;
}

/// `ReceiveNotification` — tin nhắn của giám thị.
///
/// [title] có thể null: nhánh gửi cho một sinh viên không kèm tiêu đề.
class TeacherMessageEvent extends ExamRealtimeEvent {
  const TeacherMessageEvent({
    required this.message,
    this.title,
    this.durationMs,
    this.style,
    this.position,
    this.color,
  });

  final String message;
  final String? title;

  /// `toastDuration` (mili-giây). Web mặc định 3000 khi máy chủ không gửi.
  final int? durationMs;

  /// `toastStyle`: error | success | promise | multiline | warning | dark |
  /// themed | (khác) → success. Giữ nguyên chuỗi của máy chủ để bản mobile ánh
  /// xạ đúng như web (`frontend_manage/src/hooks/useQuiz.ts:580-639`).
  final String? style;

  /// `toastPosition`: top-right | top-center | top-left | bottom-* .
  final String? position;

  /// `toastColor`: màu NỀN giám thị tự chọn trong bảng cấu hình thông báo, dạng
  /// hex `#RRGGBB` (ví dụ `#0EA5E9`).
  ///
  /// null (máy chủ không gửi, hoặc gửi chuỗi rỗng) = dùng nguyên màu mặc định
  /// của [style]. Chuỗi sai định dạng cũng rơi về mặc định, việc kiểm tra nằm ở
  /// `AppToast.parseHexColor` để chỗ nào hiện toast cũng chịu chung một luật.
  ///
  /// Máy chủ KHÔNG gửi màu chữ: app tự tính theo độ sáng của nền.
  final String? color;
}

/// `ReceiveExamScore` — máy chủ chấm xong.
class ExamScoreEvent extends ExamRealtimeEvent {
  const ExamScoreEvent({required this.score, required this.resultToken});

  final double score;
  final String resultToken;
}

/// `ViolationWarningConfigChanged` — giám thị đổi cấu hình cảnh báo giữa ca thi.
class ViolationConfigChangedEvent extends ExamRealtimeEvent {
  const ViolationConfigChangedEvent({
    required this.examSessionSubjectId,
    required this.enableWarnings,
    required this.showWarningModal,
  });

  final String examSessionSubjectId;
  final bool enableWarnings;
  final bool showWarningModal;
}
