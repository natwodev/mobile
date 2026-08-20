import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quizz_mobile/services/auth/user_services.dart';

/// Đổ hàng đợi đáp án offline bằng MỘT request gộp (`api/student/save-answers`).
///
/// Tầng HTTP bị ghi đè nên không có mạng thật; phần được kiểm là logic chia lô,
/// khớp khoá và cập nhật hàng đợi — đúng những chỗ mà sai một li là sinh viên
/// mất bài.
class _FakeUserService extends UserService {
  /// Thân của từng request gộp đã gửi, theo thứ tự.
  final List<List<Map<String, String>>> bulkBatches = [];

  /// Các khoá đã gửi qua đường CŨ (`api/student/save-answer`, số ít).
  final List<String> singleKeys = [];

  /// Mã trạng thái trả cho endpoint gộp (404 = backend chưa deploy).
  int bulkStatus = 200;

  /// Các wireKey mà máy chủ sẽ báo hỏng LẺ trong lô (nằm trong `failed`).
  final Set<String> rejectKeys = {};

  /// Các wireKey mà máy chủ lờ đi hoàn toàn: không saved, không failed.
  final Set<String> silentKeys = {};

  @override
  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    if (endpoint == 'api/student/save-answers') {
      final items = (body['items'] as List)
          .map(
            (dynamic e) => <String, String>{
              'key': (e as Map)['key'].toString(),
              'value': e['value'].toString(),
            },
          )
          .toList();
      bulkBatches.add(items);

      if (bulkStatus != 200) {
        return http.Response(
          jsonEncode(<String, dynamic>{
            'success': false,
            'code': 'STUDENT_EXAM_SESSION_ID_INVALID',
          }),
          bulkStatus,
        );
      }

      final saved = <String>[];
      final failed = <Map<String, String>>[];
      for (final item in items) {
        final key = item['key']!;
        if (silentKeys.contains(key)) continue;
        if (rejectKeys.contains(key)) {
          failed.add(<String, String>{
            'key': key,
            'code': 'STUDENT_ANSWER_EMPTY',
          });
        } else {
          saved.add(key);
        }
      }

      return http.Response(
        jsonEncode(<String, dynamic>{
          'success': true,
          'code': 'STUDENT_ANSWERS_SAVE_SUCCESS',
          'data': <String, dynamic>{'savedKeys': saved, 'failed': failed},
        }),
        200,
      );
    }

    if (endpoint == 'api/student/save-answer') {
      singleKeys.add(body['key'].toString());
      return http.Response(
        jsonEncode(<String, dynamic>{'success': true, 'code': 'OK'}),
        200,
      );
    }

    return http.Response('{}', 404);
  }
}

/// Nạp sẵn [keys] vào hàng đợi qua đúng đường app dùng: đọc lại từ đĩa.
Future<void> _seedQueue(
  UserService service,
  String sessionId,
  List<String> keys,
) async {
  SharedPreferences.setMockInitialValues(<String, Object>{
    'pending_answers_$sessionId': jsonEncode(<Map<String, String>>[
      for (final key in keys) <String, String>{'key': key, 'value': 'V-$key'},
    ]),
  });
  final restored = await service.restorePendingAnswers(sessionId);
  expect(restored, keys.length);
}

Future<List<Map<String, String>>> _diskQueue(String sessionId) async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString('pending_answers_$sessionId');
  if (raw == null) return <Map<String, String>>[];
  return (jsonDecode(raw) as List)
      .map(
        (dynamic e) => <String, String>{
          'key': (e as Map)['key'].toString(),
          'value': e['value'].toString(),
        },
      )
      .toList();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeUserService service;
  late List<AnswerSaveStatus> statuses;
  late StreamSubscription<AnswerSaveStatus> subscription;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    service = _FakeUserService();
    statuses = [];
    subscription = service.answerSaveStatuses.listen(statuses.add);
  });

  tearDown(() async {
    await subscription.cancel();
  });

  test('hàng đợi hơn 200 câu được chia thành các lô tối đa 200', () async {
    const sessionId = 'session-chia-lo';
    addTearDown(() => service.forgetFailedAnswers(sessionId));

    final keys = List<String>.generate(450, (i) => 'q$i');
    await _seedQueue(service, sessionId, keys);

    await service.retryFailedAnswers(sessionId);

    expect(service.bulkBatches.length, 3);
    expect(
      service.bulkBatches.map((b) => b.length).toList(),
      <int>[UserService.bulkSaveAnswersMaxItems, 200, 50],
    );
    // Không có câu nào lọt qua đường cũ khi endpoint gộp chạy được.
    expect(service.singleKeys, isEmpty);
    // Đủ 450 câu, không trùng, không thiếu.
    final sent = service.bulkBatches
        .expand((b) => b.map((i) => i['key']!))
        .toList();
    expect(sent.length, 450);
    expect(sent.toSet().length, 450);
    expect(service.failedAnswerCount(sessionId), 0);
  });

  test('câu trong savedKeys bị xoá khỏi hàng đợi VÀ khỏi đĩa', () async {
    const sessionId = 'session-saved';
    addTearDown(() => service.forgetFailedAnswers(sessionId));

    await _seedQueue(service, sessionId, <String>['q1', 'q2', 'q3']);
    service.rejectKeys.add('q3');

    await service.retryFailedAnswers(sessionId);

    // q1, q2 đã lưu -> biến khỏi hàng đợi; q3 bị từ chối -> GIỮ NGUYÊN.
    expect(service.failedAnswerKeys(sessionId), <String>['q3']);
    expect(service.pendingAnswerValues(sessionId), <String, String>{
      'q3': 'V-q3',
    });

    final disk = await _diskQueue(sessionId);
    expect(disk, <Map<String, String>>[
      <String, String>{'key': 'q3', 'value': 'V-q3'},
    ]);
  });

  test('mỗi câu vẫn được phát trạng thái saving rồi saved/failed', () async {
    const sessionId = 'session-status';
    addTearDown(() => service.forgetFailedAnswers(sessionId));

    await _seedQueue(service, sessionId, <String>['q1', 'q2']);
    service.rejectKeys.add('q2');

    await service.retryFailedAnswers(sessionId);

    List<AnswerSaveState> statesOf(String key) => statuses
        .where((s) => s.questionId == key)
        .map((s) => s.state)
        .toList();

    expect(statesOf('q1'), <AnswerSaveState>[
      AnswerSaveState.saving,
      AnswerSaveState.saved,
    ]);
    expect(statesOf('q2'), <AnswerSaveState>[
      AnswerSaveState.saving,
      AnswerSaveState.failed,
    ]);
    expect(
      statuses
          .lastWhere((s) => s.questionId == 'q2')
          .error
          ?.isNotEmpty,
      isTrue,
    );
  });

  test('máy chủ lờ một câu thì câu đó được GIỮ LẠI chứ không xoá', () async {
    const sessionId = 'session-im-lang';
    addTearDown(() => service.forgetFailedAnswers(sessionId));

    await _seedQueue(service, sessionId, <String>['q1', 'q2']);
    service.silentKeys.add('q2');

    await service.retryFailedAnswers(sessionId);

    expect(service.failedAnswerKeys(sessionId), <String>['q2']);
  });

  test('gửi lên máy chủ là wireKey, nhưng hàng đợi khớp theo khoá gốc', () async {
    const sessionId = 'session-wire-key';
    addTearDown(() => service.forgetFailedAnswers(sessionId));

    await _seedQueue(service, sessionId, <String>['A1B2', 'C3D4']);

    await service.retryFailedAnswers(sessionId);

    // Lên dây luôn là chữ thường — đây là chốt chặn lỗi chấm 0 điểm toàn bài.
    expect(service.bulkBatches.single.map((i) => i['key']).toList(), <String>[
      'a1b2',
      'c3d4',
    ]);
    // Nhưng khoá gốc trong hàng đợi vẫn được xoá đúng.
    expect(service.failedAnswerCount(sessionId), 0);
    expect(
      statuses.map((s) => s.questionId).toSet(),
      <String>{'A1B2', 'C3D4'},
    );
    expect(await _diskQueue(sessionId), isEmpty);
  });

  test('endpoint gộp hỏng thì quay về gửi từng câu, không ném lỗi', () async {
    const sessionId = 'session-duong-lui';
    addTearDown(() => service.forgetFailedAnswers(sessionId));

    // 404 = backend cũ chưa deploy `save-answers`.
    service.bulkStatus = 404;
    await _seedQueue(service, sessionId, <String>['q1', 'q2', 'q3']);

    await expectLater(service.retryFailedAnswers(sessionId), completes);

    expect(service.bulkBatches.length, 1);
    expect(service.singleKeys, <String>['q1', 'q2', 'q3']);
    expect(service.failedAnswerCount(sessionId), 0);
    expect(await _diskQueue(sessionId), isEmpty);
  });

  test('saveAnswersBulk trả null khi lô vượt hạn mức, không gửi gì', () async {
    const sessionId = 'session-qua-han';
    addTearDown(() => service.forgetFailedAnswers(sessionId));

    final result = await service.saveAnswersBulk(
      studentExamSessionId: sessionId,
      items: List<BulkAnswerItem>.generate(
        UserService.bulkSaveAnswersMaxItems + 1,
        (i) => BulkAnswerItem(key: 'q$i', value: 'A'),
      ),
    );

    expect(result, isNull);
    expect(service.bulkBatches, isEmpty);
  });

  test('lô rỗng trả kết quả rỗng chứ không phải null', () async {
    final result = await service.saveAnswersBulk(
      studentExamSessionId: 'session-rong',
      items: const <BulkAnswerItem>[],
    );

    expect(result, isNotNull);
    expect(result!.savedKeys, isEmpty);
    expect(result.failed, isEmpty);
    expect(service.bulkBatches, isEmpty);
  });

  test('hàng đợi rỗng thì không gửi request nào', () async {
    await service.retryFailedAnswers('session-khong-co-gi');
    expect(service.bulkBatches, isEmpty);
    expect(service.singleKeys, isEmpty);
  });

  test('lưu một câu lúc đang online vẫn đi endpoint số ít như cũ', () async {
    const sessionId = 'session-online';
    addTearDown(() => service.forgetFailedAnswers(sessionId));

    final result = await service.saveAnswer(
      studentExamSessionId: sessionId,
      key: 'Q1',
      value: 'A',
    );

    expect(result, isNotNull);
    expect(service.singleKeys, <String>['q1']);
    expect(service.bulkBatches, isEmpty);
  });
}
