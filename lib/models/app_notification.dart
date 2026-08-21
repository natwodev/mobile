/// Một thư trong hộp thư của sinh viên.
///
/// Bản THẬT nằm ở máy chủ (`GET /api/notification`). Push của FCM chỉ là tiếng
/// gõ cửa, không mang nội dung để app tự dựng danh sách — xem
/// `HOP-THU-man-chuong-ban-giao.md`.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.severity,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.examSessionSubjectId,
    this.studentExamSessionId,
  });

  final String id;

  /// Loại thư, quyết định biểu tượng.
  ///
  /// Hiện có `TeacherMessage`, `Violation`, `VpnDetected`. Giữ nguyên dạng chuỗi
  /// chứ KHÔNG chuyển sang enum: backend thêm loại mới bất cứ lúc nào mà không
  /// báo trước, mà enum thì gặp giá trị lạ là ném lỗi lúc phân giải — cả hộp
  /// thư trắng trơn chỉ vì một thư kiểu mới.
  final String type;

  /// `Low` / `Medium` / `High`. Cũng giữ dạng chuỗi, cùng lý do như [type].
  final String severity;

  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  /// Dữ liệu điều hướng: có giá trị thì mở được ca thi tương ứng.
  final String? examSessionSubjectId;
  final String? studentExamSessionId;

  /// Bản sao có sửa vài trường.
  ///
  /// Dùng khi đánh dấu đã đọc: sửa tại chỗ trong danh sách đang hiện, khỏi phải
  /// tải lại cả trang chỉ vì một lá thư đổi trạng thái.
  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      type: type,
      severity: severity,
      title: title,
      message: message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      examSessionSubjectId: examSessionSubjectId,
      studentExamSessionId: studentExamSessionId,
    );
  }

  /// Dựng từ JSON của máy chủ. Trả `null` nếu thiếu trường bắt buộc.
  ///
  /// Trả null thay vì ném lỗi để nơi gọi bỏ qua đúng dòng hỏng: một thư dị dạng
  /// không đáng làm hỏng cả hộp thư.
  static AppNotification? fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString();
    if (id == null || id.isEmpty) return null;

    // `createdAt` từ máy chủ là chuỗi UTC có hậu tố Z. Đổi sang giờ máy ngay ở
    // đây, để mọi chỗ hiển thị khỏi phải nhớ tự đổi — quên một chỗ là lệch bảy
    // tiếng mà nhìn vẫn ra một mốc giờ hợp lý.
    final createdRaw = json['createdAt']?.toString();
    final created = createdRaw == null ? null : DateTime.tryParse(createdRaw);
    if (created == null) return null;

    return AppNotification(
      id: id,
      type: json['type']?.toString() ?? '',
      severity: json['severity']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      isRead: json['isRead'] == true,
      createdAt: created.toLocal(),
      examSessionSubjectId: json['examSessionSubjectId']?.toString(),
      studentExamSessionId: json['studentExamSessionId']?.toString(),
    );
  }

  /// Đóng gói để cất xuống máy. Giờ ghi lại dạng UTC cho khỏi lệch khi máy đổi
  /// múi giờ giữa hai lần mở app.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'severity': severity,
      'title': title,
      'message': message,
      'isRead': isRead,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'examSessionSubjectId': examSessionSubjectId,
      'studentExamSessionId': studentExamSessionId,
    };
  }
}
