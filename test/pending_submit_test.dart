import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quizz_mobile/services/auth/user_services.dart';
import 'package:quizz_mobile/services/pending_submit_service.dart';

/// Nộp bài lúc MẤT MẠNG.
///
/// Thứ được kiểm ở đây là cái duy nhất không sửa lại được sau khi hỏng: mốc giờ
/// nộp. Backend lấy `clientSubmittedAt` làm giờ nộp thật và chỉ nhận bài trễ của
/// một phòng đã đóng khi mốc đó sớm hơn giờ đóng phòng ít nhất 30 giây — gửi
/// lại bằng giờ hiện tại là sinh viên mất bài đúng lúc cần nó nhất.
class _FakeUserService extends UserService {
  /// Thân của từng request `submit-exam` đã gửi, theo thứ tự.
  final List<Map<String, dynamic>> submitBodies = [];

  /// Các phiên đã bị hỏi điểm (`my-grades`).
  final List<String> gradeLookups = [];

  /// Mã trạng thái trả về cho từng lần gọi `submit-exam`, theo thứ tự.
  /// Hết kịch bản thì mặc định 200. Giá trị 0 nghĩa là NÉM ngoại lệ — đúng
  /// hình hài của việc mất mạng (`http` ném `ClientException`, không trả về mã).
  final List<int> submitStatusPlan = [];

  double gradeScore = 8.5;

  @override
  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    if (endpoint != 'api/student/submit-exam') {
      return http.Response('{}', 404);
    }

    submitBodies.add(Map<String, dynamic>.from(body));

    final status = submitStatusPlan.isEmpty ? 200 : submitStatusPlan.removeAt(0);
    if (status == 0) {
      throw const _FakeOfflineException();
    }

    if (status == 200) {
      return http.Response(
        jsonEncode(<String, dynamic>{
          'success': true,
          'code': 'STUDENT_EXAM_SUBMIT_SUCCESS',
          'resultToken': 'token-123',
        }),
        200,
      );
    }

    return http.Response(
      jsonEncode(<String, dynamic>{
        'success': false,
        'code': 'STUDENT_EXAM_SESSION_ALREADY_SUBMITTED',
      }),
      status,
    );
  }

  @override
  Future<http.Response> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async {
    if (endpoint.startsWith('api/student/my-grades/')) {
      gradeLookups.add(endpoint.split('/').last);
      // Điểm âm = kịch bản "backend chưa chấm xong".
      if (gradeScore < 0) return http.Response('{}', 404);
      return http.Response(
        jsonEncode(<String, dynamic>{
          'score': gradeScore,
          'totalQuestions': 40,
          'correctAnswers': 34,
        }),
        200,
      );
    }
    return http.Response('{}', 404);
  }
}

class _FakeOfflineException implements Exception {
  const _FakeOfflineException();
  @override
  String toString() => 'ClientException: Failed host lookup';
}

/// Mốc "lúc sinh viên bấm nộp": cố ý lùi lại 3 phút so với bây giờ để phân biệt
/// được với giờ của lần gửi lại.
final DateTime _tapMoment = DateTime.now()
    .toUtc()
    .subtract(const Duration(minutes: 3));

PendingSubmit _submitOf(String sessionId) => PendingSubmit(
  studentExamSessionId: sessionId,
  studentAnswersString: '(q1:A);(q2:B);(q3:-)',
  deviceInfo: 'Mobile | Flutter App',
  clientSubmittedAt: _tapMoment,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('PendingSubmitStore — lệnh nộp chờ sống trên đĩa', () {
    test('lưu rồi đọc lại được nguyên vẹn', () async {
      await PendingSubmitStore.save(_submitOf('phien-1'));

      final loaded = await PendingSubmitStore.load();

      expect(loaded, hasLength(1));
      expect(loaded.single.studentExamSessionId, 'phien-1');
      expect(loaded.single.studentAnswersString, '(q1:A);(q2:B);(q3:-)');
      expect(loaded.single.deviceInfo, 'Mobile | Flutter App');
      // Đọc lại phải ra ĐÚNG mốc đã lưu, tính tới từng mili giây.
      expect(
        loaded.single.clientSubmittedAt.toIso8601String(),
        _tapMoment.toIso8601String(),
      );
      expect(loaded.single.clientSubmittedAt.isUtc, isTrue);
    });

    test('xoá đúng phiên được chỉ định, các phiên khác giữ nguyên', () async {
      await PendingSubmitStore.save(_submitOf('phien-1'));
      await PendingSubmitStore.save(_submitOf('phien-2'));

      await PendingSubmitStore.remove('phien-1');

      final loaded = await PendingSubmitStore.load();
      expect(loaded.map((e) => e.studentExamSessionId), ['phien-2']);
    });

    test('lưu hai lần cùng một phiên chỉ để lại MỘT lệnh chờ', () async {
      await PendingSubmitStore.save(_submitOf('phien-1'));
      await PendingSubmitStore.save(
        PendingSubmit(
          studentExamSessionId: 'phien-1',
          studentAnswersString: '(q1:C)',
          clientSubmittedAt: _tapMoment,
        ),
      );

      final loaded = await PendingSubmitStore.load();
      expect(loaded, hasLength(1));
      expect(loaded.single.studentAnswersString, '(q1:C)');
    });

    test('xoá hết thì khoá trên đĩa cũng biến mất', () async {
      await PendingSubmitStore.save(_submitOf('phien-1'));
      await PendingSubmitStore.remove('phien-1');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(PendingSubmitStore.storageKey), isNull);
      expect(await PendingSubmitStore.load(), isEmpty);
    });

    test('bản ghi rác trên đĩa bị bỏ qua chứ không làm hỏng cả hàng chờ', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        PendingSubmitStore.storageKey: jsonEncode(<dynamic>[
          <String, dynamic>{'studentExamSessionId': 'phien-hong'},
          'chuoi rac',
          _submitOf('phien-tot').toJson(),
        ]),
      });

      final loaded = await PendingSubmitStore.load();
      expect(loaded.map((e) => e.studentExamSessionId), ['phien-tot']);
    });
  });

  group('PendingSubmitService — gửi lại giữ nguyên mốc giờ nộp', () {
    test('gửi hỏng lần đầu, lần sau mang ĐÚNG mốc cũ chứ không phải giờ gửi lại', () async {
      final api = _FakeUserService()..submitStatusPlan.addAll([0]);
      final service = PendingSubmitService(userService: api);

      final outcome = service.outcomeFor('phien-1');
      await service.save(_submitOf('phien-1'));

      // Lần 1: mất mạng.
      await service.flush();
      expect(api.submitBodies, hasLength(1));
      // Lệnh nộp vẫn còn trên đĩa để còn gửi lại.
      expect(await service.hasPending, isTrue);

      // Lần 2 (mạng đã về). Có thể là vài phút sau, hoặc sau khi app khởi động
      // lại — mốc gửi lên VẪN phải là giây sinh viên bấm nộp.
      await service.flush();
      expect(api.submitBodies, hasLength(2));

      final resent = api.submitBodies.last;
      expect(resent['ClientSubmittedAt'], _tapMoment.toIso8601String());
      expect(resent['StudentExamSessionId'], 'phien-1');
      expect(resent['StudentAnswersString'], '(q1:A);(q2:B);(q3:-)');
      expect(resent['DeviceInfo'], 'Mobile | Flutter App');

      // Mốc gửi lên phải LỆCH hẳn với giờ của lần gửi lại — nếu code lỡ lấy
      // `DateTime.now()` thì phép so sánh này là thứ bắt được.
      final sent = DateTime.parse(resent['ClientSubmittedAt'] as String);
      expect(
        DateTime.now().toUtc().difference(sent),
        greaterThanOrEqualTo(const Duration(minutes: 3)),
      );

      // Cả hai lần gửi đều mang cùng một mốc.
      expect(
        api.submitBodies.first['ClientSubmittedAt'],
        api.submitBodies.last['ClientSubmittedAt'],
      );

      final result = await outcome;
      expect(result.accepted, isTrue);
      expect(result.score, 8.5);
      expect(api.gradeLookups, ['phien-1']);
      expect(await service.hasPending, isFalse);
    });

    test('mốc giờ sống sót qua việc TẮT APP: đọc lại từ đĩa rồi gửi tiếp', () async {
      // "Lần chạy trước" chỉ kịp ghi lệnh nộp xuống đĩa.
      await PendingSubmitStore.save(_submitOf('phien-1'));

      // Mở lại app: service mới toanh, không giữ gì trong RAM.
      final api = _FakeUserService();
      final service = PendingSubmitService(userService: api);

      await service.flush();

      expect(api.submitBodies, hasLength(1));
      expect(
        api.submitBodies.single['ClientSubmittedAt'],
        _tapMoment.toIso8601String(),
      );
      expect(await service.hasPending, isFalse);
    });

    test('nộp được ngay lần đầu thì KHÔNG để lại lệnh chờ và không gửi lần hai', () async {
      final api = _FakeUserService();
      final service = PendingSubmitService(userService: api);
      addTearDown(service.stopAutoRetry);

      final result = await service.queue(_submitOf('phien-1'));

      expect(result.accepted, isTrue);
      expect(result.score, 8.5);
      expect(api.submitBodies, hasLength(1));

      // Không còn gì trên đĩa...
      expect(await service.hasPending, isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(PendingSubmitStore.storageKey), isNull);

      // ...nên mọi nhịp gõ lại sau đó đều không gửi thêm request nào.
      await service.flush();
      await service.flush();
      expect(api.submitBodies, hasLength(1));
    });

    test('máy chủ từ chối (400) thì xoá lệnh chờ và nói thật, không quay mãi', () async {
      final api = _FakeUserService()..submitStatusPlan.addAll([400]);
      final service = PendingSubmitService(userService: api);

      final outcome = service.outcomeFor('phien-1');
      await service.save(_submitOf('phien-1'));

      await service.flush();

      final result = await outcome;
      expect(result.accepted, isFalse);
      expect(result.message, isNotNull);
      expect(result.message, isNotEmpty);

      // Xoá khỏi đĩa: gửi lại cũng chỉ nhận đúng câu trả lời đó.
      expect(await service.hasPending, isFalse);
      await service.flush();
      expect(api.submitBodies, hasLength(1));
    });

    test('máy chủ 5xx vẫn được coi là còn gửi lại được', () async {
      final api = _FakeUserService()..submitStatusPlan.addAll([503]);
      final service = PendingSubmitService(userService: api);

      await service.save(_submitOf('phien-1'));
      await service.flush();

      expect(api.submitBodies, hasLength(1));
      expect(await service.hasPending, isTrue);
    });

    test('nộp xong mà chưa lấy được điểm thì vẫn KHÔNG gửi lại lần hai', () async {
      final api = _FakeUserService();
      final service = PendingSubmitService(userService: api);

      final outcome = service.outcomeFor('phien-1');
      await service.save(_submitOf('phien-1'));

      // `my-grades` của phiên này trả 404 (backend chưa chấm xong).
      api.gradeScore = -1;
      await service.flush();

      final result = await outcome;
      expect(result.accepted, isTrue);
      expect(await service.hasPending, isFalse);
      expect(api.submitBodies, hasLength(1));
    });
  });

  group('UserService.submitExam — hình hài request gửi lên', () {
    test('clientSubmittedAt đi lên dạng ISO-8601 UTC', () async {
      final api = _FakeUserService();

      final outcome = await api.submitExam(
        'phien-1',
        deviceInfo: 'Mobile | Flutter App',
        studentAnswersString: '(q1:A)',
        // Cố ý truyền giờ ĐỊA PHƯƠNG: service phải tự đổi sang UTC.
        clientSubmittedAt: DateTime.parse('2026-08-20T17:00:00+07:00'),
      );

      expect(outcome.status, SubmitExamStatus.accepted);
      expect(
        api.submitBodies.single['ClientSubmittedAt'],
        '2026-08-20T10:00:00.000Z',
      );
    });

    test('không truyền clientSubmittedAt thì không thêm field thừa', () async {
      final api = _FakeUserService();

      await api.submitExam('phien-1', studentAnswersString: '(q1:A)');

      expect(
        api.submitBodies.single.containsKey('ClientSubmittedAt'),
        isFalse,
      );
    });

    test('mất mạng trả về retryable chứ không phải rejected', () async {
      final api = _FakeUserService()..submitStatusPlan.addAll([0]);

      final outcome = await api.submitExam('phien-1');

      expect(outcome.status, SubmitExamStatus.retryable);
      expect(outcome.message, isNull);
    });
  });
}
