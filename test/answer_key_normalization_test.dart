import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:quizz_mobile/services/auth/user_services.dart';

/// UserService giả lập tầng HTTP để soi CHÍNH XÁC body đã đi lên máy chủ.
///
/// Kỹ thuật giống `test/save_answer_queue_test.dart`: ghi đè `post` nên không
/// cần mạng thật.
class _CapturingUserService extends UserService {
  /// Body của từng request đã gửi, theo đúng thứ tự.
  final List<Map<String, dynamic>> sentBodies = [];

  /// Endpoint của từng request, song song với [sentBodies].
  final List<String> sentEndpoints = [];

  /// Mã trạng thái sẽ trả về cho từng khoá ĐÃ GỬI, theo thứ tự các lần gọi.
  /// Hết kịch bản thì mặc định 200.
  final Map<String, List<int>> statusPlan = {};

  @override
  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    sentBodies.add(Map<String, dynamic>.from(body));
    sentEndpoints.add(endpoint);

    // Endpoint gộp (đường ĐỔ HÀNG ĐỢI): xác nhận đúng các khoá đã nhận được.
    if (endpoint == 'api/student/save-answers') {
      final saved = (body['items'] as List)
          .map((dynamic e) => (e as Map)['key'].toString())
          .toList();
      return http.Response(
        jsonEncode({
          'success': true,
          'code': 'STUDENT_ANSWERS_SAVE_SUCCESS',
          'data': {'savedKeys': saved, 'failed': <dynamic>[]},
        }),
        200,
      );
    }

    final key = body['key']?.toString() ?? '';
    final plan = statusPlan[key];
    final status = (plan == null || plan.isEmpty) ? 200 : plan.removeAt(0);

    return http.Response(
      jsonEncode({'success': status == 200, 'code': 'CODE_$status'}),
      status,
    );
  }
}

void main() {
  late _CapturingUserService service;

  setUp(() {
    service = _CapturingUserService();
  });

  // Khoá thật là GUID; ở đây cố tình viết HOA để tái hiện đúng cái bẫy.
  const guidUpper = '3F2504E0-4F89-11D3-9A0C-0305E82C3301';
  const guidLower = '3f2504e0-4f89-11d3-9a0c-0305e82c3301';

  test('khoá GUID viết HOA đi lên máy chủ dưới dạng chữ THƯỜNG', () async {
    const sessionId = 'session-hoa-thuong';
    addTearDown(() => service.forgetFailedAnswers(sessionId));

    final result = await service.saveAnswer(
      studentExamSessionId: sessionId,
      key: guidUpper,
      value: 'answer-1',
    );

    expect(result, isNotNull);
    expect(service.sentBodies, hasLength(1));
    // Đây là điều kiện sống còn: backend hạ chữ thường khi ĐỌC
    // (StudentAnswerHelper.cs:215) nhưng giữ khoá thô khi GHI
    // (StudentAnswerHelper.cs:186).
    expect(service.sentBodies.single['key'], guidLower);
    expect(service.sentBodies.single['value'], 'answer-1');
    expect(service.sentBodies.single['StudentExamSessionId'], sessionId);
  });

  test(
    'cùng một câu gửi hai lần khác kiểu chữ vẫn chỉ ra MỘT khoá duy nhất',
    () async {
      const sessionId = 'session-trung-khoa';
      addTearDown(() => service.forgetFailedAnswers(sessionId));

      await service.saveAnswer(
        studentExamSessionId: sessionId,
        key: guidUpper,
        value: 'A',
      );
      await service.saveAnswer(
        studentExamSessionId: sessionId,
        key: guidLower,
        value: 'B',
      );

      final keys = service.sentBodies
          .map((body) => body['key']?.toString())
          .toList();

      // Hai khoá khác kiểu chữ trong cùng chuỗi bài làm ⇒ ScoreCalculator
      // ParseAnswerKey (ScoreCalculator.cs:20-31) ném ArgumentException, bị
      // catch và trả dictionary RỖNG ⇒ chấm 0 điểm cả bài.
      expect(keys, [guidLower, guidLower]);
      expect(keys.toSet(), hasLength(1));
    },
  );

  test('khoá thừa khoảng trắng cũng được chuẩn hoá trước khi gửi', () async {
    const sessionId = 'session-khoang-trang';
    addTearDown(() => service.forgetFailedAnswers(sessionId));

    await service.saveAnswer(
      studentExamSessionId: sessionId,
      key: '  $guidUpper  ',
      value: 'A',
    );

    expect(service.sentBodies.single['key'], guidLower);
  });

  test('đường GỬI LẠI cũng mang khoá chữ thường', () async {
    const sessionId = 'session-retry-hoa';
    addTearDown(() => service.forgetFailedAnswers(sessionId));

    // Lần đầu 400 -> không thử lại, được ghi nhận là chưa lưu.
    service.statusPlan[guidLower] = [400];

    await service.saveAnswer(
      studentExamSessionId: sessionId,
      key: guidUpper,
      value: 'A',
    );
    expect(service.failedAnswerCount(sessionId), 1);

    await service.retryFailedAnswers(sessionId);

    // Lần lưu đầu đi endpoint số ít, lần gửi lại đi endpoint GỘP — cả hai đường
    // đều phải hạ chữ thường, không được có đường nào lọt khoá viết hoa.
    expect(service.sentEndpoints, [
      'api/student/save-answer',
      'api/student/save-answers',
    ]);
    expect(service.sentBodies.first['key'], guidLower);
    final retriedKeys = (service.sentBodies.last['items'] as List)
        .map((dynamic e) => (e as Map)['key']?.toString())
        .toList();
    expect(retriedKeys, [guidLower]);
    expect(service.failedAnswerCount(sessionId), 0);
  });

  test(
    'trạng thái báo về màn thi vẫn giữ id GỐC để tra được câu hỏi',
    () async {
      const sessionId = 'session-status-goc';
      addTearDown(() => service.forgetFailedAnswers(sessionId));

      final statuses = <AnswerSaveStatus>[];
      final subscription = service.answerSaveStatuses.listen(statuses.add);
      addTearDown(subscription.cancel);

      await service.saveAnswer(
        studentExamSessionId: sessionId,
        key: guidUpper,
        value: 'A',
      );

      // exam_screen tra ExamProgress.questionIndexOf bằng ĐÚNG id mà API trả
      // về. Nếu ở đây trả id đã hạ chữ thường thì lưới điều hướng và cảnh báo
      // "chưa lưu" sẽ không khớp được câu nào nữa.
      expect(statuses, isNotEmpty);
      expect(statuses.every((s) => s.questionId == guidUpper), isTrue);
      expect(service.sentBodies.single['key'], guidLower);
    },
  );

  test('giá trị đáp án được gửi NGUYÊN VĂN, không lọc ký tự nào', () async {
    const sessionId = 'session-nguyen-van';
    addTearDown(() => service.forgetFailedAnswers(sessionId));

    // Web (ShortAnswerQuiz.tsx:85-90 + studentService.ts:115-119) gửi văn bản
    // thô. Mobile phải gửi y hệt, nếu không hai nền tảng sẽ chấm lệch nhau.
    const rawText = '1:a;b (c) d|2:e';

    await service.saveAnswer(
      studentExamSessionId: sessionId,
      key: guidUpper,
      value: rawText,
    );

    expect(service.sentBodies.single['value'], rawText);
  });
}
