import 'package:flutter_test/flutter_test.dart';
import 'package:quizz_mobile/services/auth/user_services.dart';

/// Ca thi không giới hạn thời gian được backend lưu
/// `EndTime = DateTime.MaxValue` (ExamSessionSubjectService.cs:321), tức
/// 31/12/9999. Popup vào thi phải đọc được cờ `isUnlimitedTime` để không đem
/// cái mốc vô nghĩa đó ra hiện cho sinh viên.
void main() {
  Map<String, dynamic> payload({
    required bool isUnlimitedTime,
    required String endTime,
  }) => {
    'examSessionSubjectId': '11111111-1111-1111-1111-111111111111',
    'subjectName': 'Tiếng Anh',
    'duration': 45,
    'startTime': '2026-08-19T02:00:00Z',
    'endTime': endTime,
    'requireLocationOnExamStart': false,
    'examSessionSubjectCore': 'ESS-3-20260819183000',
    'isUnlimitedTime': isUnlimitedTime,
  };

  group('ExamSessionSummary đọc cấu hình thời gian', () {
    test('ca không giới hạn: giữ đúng cờ và mốc 9999 của backend', () {
      final s = ExamSessionSummary.fromJson(
        payload(isUnlimitedTime: true, endTime: '9999-12-31T23:59:59.9999999'),
      );

      expect(s.isUnlimitedTime, isTrue);
      expect(s.endTime!.year, 9999);
    });

    test('ca thường: cờ tắt và có mốc kết thúc thật', () {
      final s = ExamSessionSummary.fromJson(
        payload(isUnlimitedTime: false, endTime: '2026-08-19T02:45:00Z'),
      );

      expect(s.isUnlimitedTime, isFalse);
      expect(s.endTime!.year, 2026);
    });

    test('thiếu cờ trong phản hồi thì coi như ca có giới hạn', () {
      final json = payload(
        isUnlimitedTime: false,
        endTime: '2026-08-19T02:45:00Z',
      )..remove('isUnlimitedTime');

      expect(ExamSessionSummary.fromJson(json).isUnlimitedTime, isFalse);
    });
  });
}
