import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:quizz_mobile/services/auth/user_services.dart';

/// UserService giả lập tầng HTTP: `post` được ghi đè nên không cần mạng thật,
/// nhờ đó kiểm chứng được hàng đợi + retry của [UserService.saveAnswer].
class _FakeUserService extends UserService {
  /// Độ trễ giả lập của mỗi request, đủ để phát hiện request chạy chồng chéo.
  static const Duration latency = Duration(milliseconds: 20);

  /// Mã trạng thái sẽ trả về cho từng khoá, theo thứ tự các lần gọi.
  /// Hết kịch bản thì mặc định 200.
  final Map<String, List<int>> statusPlan = {};

  /// Thứ tự các khoá đã thực sự được gửi lên máy chủ.
  final List<String> sentKeys = [];

  int _inFlight = 0;
  int maxConcurrentRequests = 0;

  @override
  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final key = body['key']?.toString() ?? '';

    _inFlight++;
    if (_inFlight > maxConcurrentRequests) maxConcurrentRequests = _inFlight;
    sentKeys.add(key);

    await Future<void>.delayed(latency);
    _inFlight--;

    final plan = statusPlan[key];
    final status = (plan == null || plan.isEmpty) ? 200 : plan.removeAt(0);

    return http.Response(
      jsonEncode({'success': status == 200, 'code': 'CODE_$status'}),
      status,
    );
  }
}

void main() {
  late _FakeUserService service;
  late List<AnswerSaveStatus> statuses;
  late StreamSubscription<AnswerSaveStatus> subscription;

  setUp(() {
    service = _FakeUserService();
    statuses = [];
    subscription = service.answerSaveStatuses.listen(statuses.add);
  });

  tearDown(() async {
    await subscription.cancel();
  });

  test('các lần lưu của cùng một phiên chạy tuần tự, đúng thứ tự', () async {
    const sessionId = 'session-tuan-tu';
    addTearDown(() => service.forgetFailedAnswers(sessionId));

    final futures = [
      service.saveAnswer(
        studentExamSessionId: sessionId,
        key: 'q1',
        value: 'A',
      ),
      service.saveAnswer(
        studentExamSessionId: sessionId,
        key: 'q2',
        value: 'B',
      ),
      service.saveAnswer(
        studentExamSessionId: sessionId,
        key: 'q3',
        value: 'C',
      ),
    ];
    final results = await Future.wait(futures);

    expect(service.sentKeys, ['q1', 'q2', 'q3']);
    expect(service.maxConcurrentRequests, 1);
    expect(results.every((r) => r != null && r.success), isTrue);
    expect(service.failedAnswerCount(sessionId), 0);
  });

  test(
    'lỗi 5xx được thử lại và lần sau thành công thì coi như đã lưu',
    () async {
      const sessionId = 'session-5xx';
      addTearDown(() => service.forgetFailedAnswers(sessionId));
      service.statusPlan['q1'] = [500, 200];

      final result = await service.saveAnswer(
        studentExamSessionId: sessionId,
        key: 'q1',
        value: 'A',
      );

      expect(result, isNotNull);
      expect(result!.success, isTrue);
      expect(service.sentKeys.where((k) => k == 'q1').length, 2);
      expect(service.failedAnswerCount(sessionId), 0);
      expect(statuses.any((s) => s.state == AnswerSaveState.failed), isFalse);
    },
  );

  test('lỗi 4xx KHÔNG thử lại và được báo là lưu thất bại', () async {
    const sessionId = 'session-4xx';
    addTearDown(() => service.forgetFailedAnswers(sessionId));
    service.statusPlan['q1'] = [400];

    final result = await service.saveAnswer(
      studentExamSessionId: sessionId,
      key: 'q1',
      value: 'A',
    );

    expect(result, isNull);
    expect(service.sentKeys.where((k) => k == 'q1').length, 1);
    expect(service.failedAnswerCount(sessionId), 1);
    expect(service.failedAnswerKeys(sessionId), ['q1']);

    final states = statuses.map((s) => s.state).toList();
    expect(states.first, AnswerSaveState.saving);
    expect(states.last, AnswerSaveState.failed);
    expect(statuses.last.error, isNotNull);
  });

  test('thử lại thủ công gửi lại đúng các câu còn thiếu', () async {
    const sessionId = 'session-retry';
    addTearDown(() => service.forgetFailedAnswers(sessionId));
    service.statusPlan['q1'] = [400];

    await service.saveAnswer(
      studentExamSessionId: sessionId,
      key: 'q1',
      value: 'A',
    );
    expect(service.failedAnswerCount(sessionId), 1);

    await service.retryFailedAnswers(sessionId);

    expect(service.sentKeys.where((k) => k == 'q1').length, 2);
    expect(service.failedAnswerCount(sessionId), 0);
    expect(statuses.last.state, AnswerSaveState.saved);
  });

  test('giá trị mới lưu thành công thì xoá cảnh báo của giá trị cũ', () async {
    const sessionId = 'session-ghi-de';
    addTearDown(() => service.forgetFailedAnswers(sessionId));
    service.statusPlan['q1'] = [400];

    await service.saveAnswer(
      studentExamSessionId: sessionId,
      key: 'q1',
      value: 'A',
    );
    expect(service.failedAnswerCount(sessionId), 1);

    await service.saveAnswer(
      studentExamSessionId: sessionId,
      key: 'q1',
      value: 'B',
    );

    expect(service.failedAnswerCount(sessionId), 0);
  });
}
