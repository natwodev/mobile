import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quizz_mobile/services/auth/user_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Hàng đợi đáp án offline phải sống sót qua việc app bị tắt giữa giờ thi.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const String sessionId = '11111111-1111-1111-1111-111111111111';
  const String prefsKey = 'pending_answers_$sessionId';

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('đọc lại được đáp án còn nợ từ lần chạy trước', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      prefsKey: jsonEncode(<Map<String, String>>[
        <String, String>{'key': 'Q1', 'value': 'a'},
        <String, String>{'key': 'Q2', 'value': 'b;c'},
      ]),
    });

    final service = UserService();
    final restored = await service.restorePendingAnswers(sessionId);

    expect(restored, 2);
    expect(service.failedAnswerCount(sessionId), 2);
    expect(service.pendingAnswerValues(sessionId), <String, String>{
      'Q1': 'a',
      // Giá trị có dấu ; phải nguyên vẹn — đây là ký tự phân tách của bài làm.
      'Q2': 'b;c',
    });

    service.forgetFailedAnswers(sessionId);
  });

  test('không có gì đã lưu thì trả 0 và không dựng hàng đợi rỗng', () async {
    final service = UserService();
    expect(await service.restorePendingAnswers(sessionId), 0);
    expect(service.failedAnswerCount(sessionId), 0);
  });

  test('dữ liệu hỏng trên đĩa không làm sập màn thi', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      prefsKey: 'không phải json',
    });

    final service = UserService();
    expect(await service.restorePendingAnswers(sessionId), 0);
    expect(service.failedAnswerCount(sessionId), 0);
  });

  test('quên phiên thi thì xoá luôn bản ghi trên đĩa', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      prefsKey: jsonEncode(<Map<String, String>>[
        <String, String>{'key': 'Q1', 'value': 'a'},
      ]),
    });

    final service = UserService();
    await service.restorePendingAnswers(sessionId);
    expect(service.failedAnswerCount(sessionId), 1);

    service.forgetFailedAnswers(sessionId);
    expect(service.failedAnswerCount(sessionId), 0);

    // Xoá đĩa chạy bất đồng bộ, chờ một nhịp rồi kiểm.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(prefsKey), isNull);

    // Và lần vào lại sau đó không đọc ra gì nữa.
    expect(await service.restorePendingAnswers(sessionId), 0);
  });
}
