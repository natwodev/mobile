import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/app_l10n.dart';
import '../base_service.dart';
import '../profile_cache.dart';
import '../../models/login.dart';
import '../../models/api_result.dart';
import '../../helpers/error_message_helper.dart';
import '../../helpers/jwt_helper.dart';
import '../../models/student.dart';
import '../../models/exam_history_item.dart';
import '../../models/DTOs/originalExamPaperDto.dart';
import '../../models/DTOs/ExamSubmissionDto.dart';
import '../../models/saveAnswerResponse.dart';
import '../../models/submitExamResponse.dart';
import '../notification/push_service.dart';

/// Trạng thái lưu MỘT đáp án lên máy chủ.
///
/// Màn thi dùng bộ trạng thái này để không bao giờ hiển thị một đáp án như đã
/// lưu trong khi máy chủ chưa nhận được nó.
enum AnswerSaveState {
  /// Đang gửi (kể cả đang chờ lượt trong hàng đợi hoặc đang thử lại).
  saving,

  /// Máy chủ đã xác nhận nhận đáp án.
  saved,

  /// Đã thử hết số lần cho phép mà vẫn không lưu được.
  failed,
}

/// Một sự kiện thay đổi trạng thái lưu đáp án.
class AnswerSaveStatus {
  final String studentExamSessionId;

  /// Id câu hỏi được lưu — có thể là id CÂU CON (Matching / TFNG).
  final String questionId;
  final String value;
  final AnswerSaveState state;

  /// Câu lỗi đã dịch, chỉ có khi [state] là [AnswerSaveState.failed].
  final String? error;

  /// Số lần đã gửi thử (1 = lần đầu).
  final int attempts;

  const AnswerSaveStatus({
    required this.studentExamSessionId,
    required this.questionId,
    required this.value,
    required this.state,
    this.error,
    this.attempts = 0,
  });
}

/// Máy chủ đã trả lời thế nào cho MỘT lần gọi `api/student/submit-exam`.
///
/// Phân biệt được ba trạng thái này là điều kiện cần để nộp bài lúc mất mạng:
/// chỉ [retryable] mới đáng xếp vào hàng chờ, còn [rejected] mà cứ gửi lại thì
/// sinh viên ngồi nhìn vòng xoay quay mãi.
enum SubmitExamStatus {
  /// Máy chủ đã ghi nhận bài.
  accepted,

  /// Chưa tới được máy chủ, hoặc máy chủ đang hỏng tạm thời — còn gửi lại được.
  retryable,

  /// Máy chủ trả lời rõ ràng là KHÔNG nhận. Gửi lại cũng chỉ nhận đúng câu đó.
  rejected,
}

/// Kết quả một lần gọi `submit-exam`, kèm lý do khi bị từ chối.
class SubmitExamOutcome {
  const SubmitExamOutcome(this.status, {this.response, this.message});

  final SubmitExamStatus status;

  /// Thân tin máy chủ trả về, chỉ có khi [status] là [SubmitExamStatus.accepted].
  final SubmitExamResponse? response;

  /// Lý do đã dịch, chỉ có khi [status] là [SubmitExamStatus.rejected].
  final String? message;
}

/// Một đáp án trong lô gửi lên `api/student/save-answers`.
///
/// [key] là khoá GỐC (giữ nguyên hoa/thường) — chính là thứ [BulkSaveAnswersResult]
/// trả về, để nơi gọi đối chiếu thẳng với hàng đợi của mình. Việc hạ chữ
/// thường trước khi lên dây do [UserService.saveAnswersBulk] tự làm.
class BulkAnswerItem {
  final String key;
  final String value;

  const BulkAnswerItem({required this.key, required this.value});
}

/// Một câu bị máy chủ từ chối RIÊNG LẺ trong một lô (lô vẫn lưu các câu khác).
class BulkSaveAnswerFailure {
  /// Khoá GỐC do nơi gọi truyền vào (không phải bản đã hạ chữ thường).
  final String key;

  /// Mã lỗi backend trả (`STUDENT_ANSWER_EMPTY`...), rỗng nếu máy chủ im lặng.
  final String code;

  const BulkSaveAnswerFailure({required this.key, required this.code});
}

/// Kết quả MỘT lần gửi lô `api/student/save-answers`.
///
/// Chỉ tồn tại khi máy chủ đã nhận và xử lý lô. Lô hỏng ở mức request (mất
/// mạng, 4xx, 5xx) thì [UserService.saveAnswersBulk] trả `null` chứ không trả
/// một kết quả rỗng — hai chuyện này KHÁC nhau: kết quả rỗng nghĩa là máy chủ
/// đã trả lời, còn `null` nghĩa là chưa biết gì cả và phải đi đường lui.
class BulkSaveAnswersResult {
  /// Các khoá GỐC mà máy chủ xác nhận đã lưu.
  final List<String> savedKeys;

  /// Các câu máy chủ từ chối; vẫn còn nợ, nơi gọi phải giữ lại trong hàng đợi.
  final List<BulkSaveAnswerFailure> failed;

  const BulkSaveAnswersResult({required this.savedKeys, required this.failed});

  List<String> get failedKeys =>
      failed.map((f) => f.key).toList(growable: false);
}

/// Chuẩn hoá khoá đáp án về CHỮ THƯỜNG trước khi gửi lên máy chủ.
///
/// ĐỪNG XOÁ HÀM NÀY. Đây không phải "làm cho đẹp" mà là chốt chặn một lỗi
/// khiến SINH VIÊN MẤT TRẮNG CẢ BÀI THI:
///
/// - Khi GHI, backend nhét thẳng khoá thô client gửi lên vào chuỗi bài làm:
///   `answersDict[key] = value` — `StudentAnswerHelper.cs:186`.
/// - Khi ĐỌC, backend lại hạ chữ thường khoá:
///   `var key = subParts[0].Trim().ToLower();` — `StudentAnswerHelper.cs:215`.
/// - Lúc CHẤM, `ScoreCalculator.ParseAnswerKey` (`ScoreCalculator.cs:20-31`)
///   cũng hạ chữ thường rồi dồn vào `ToDictionary`. Nếu sau khi hạ chữ thường
///   có HAI khoá trùng nhau, `ToDictionary` ném `ArgumentException`; khối
///   `catch` nuốt lỗi và trả về DICTIONARY RỖNG.
///
/// Hậu quả: chỉ cần app lỡ gửi cùng một câu hai lần với GUID lúc hoa lúc
/// thường (ví dụ `A1B2...` rồi `a1b2...`), chuỗi bài làm sẽ chứa hai bản ghi
/// mà backend coi là trùng khoá ⇒ bảng đáp án của sinh viên rỗng ⇒ TOÀN BỘ
/// bài thi bị chấm 0 điểm, và không có thông báo lỗi nào cho ai biết.
///
/// Backend không sửa được từ phía app, nên app phải bảo đảm mỗi câu chỉ tồn
/// tại dưới ĐÚNG MỘT dạng khoá: chữ thường, đúng như dạng backend đọc ra.
String normalizeAnswerKey(String key) => key.trim().toLowerCase();

// KÝ TỰ PHÂN TÁCH TRONG GIÁ TRỊ ĐÁP ÁN — CỐ Ý KHÔNG LỌC. ĐỪNG THÊM BỘ LỌC.
//
// Chuỗi bài làm của backend là `(khoá:giá_trị);(khoá:giá_trị)`
// (`CreateStudentAnswersString`, StudentAnswerHelper.cs:195) và được tách lại
// bằng `Split(';')` + `Trim('(', ')')` (StudentAnswerHelper.cs:205-215, y hệt
// trong `ScoreCalculator.ParseAnswerKey`, ScoreCalculator.cs:20-31) — không hề
// có cơ chế escape. Sinh viên gõ `;` `(` `)` vào ô "trả lời ngắn" thì chuỗi
// vỡ. Đây là lỗi CÓ THẬT, nhưng KHÔNG được vá riêng ở mobile:
//
// Frontend web (`csharp_manage/frontend_manage`) là bản đang chạy thật và nó
// gửi văn bản NGUYÊN VĂN, không lọc, không escape:
//   - `ShortAnswerQuiz.tsx:85-90` ghép `${idx}:${text}` rồi `join('|')`
//   - `studentService.ts:115-119` POST thẳng `{ key, value }`
// Nếu mobile tự lọc, cùng một câu trả lời sẽ thành hai chuỗi khác nhau giữa
// hai nền tảng ⇒ so khớp đáp án (`[SHORT]`, ScoreCalculator.cs:157-190 dùng
// `Equals(..., OrdinalIgnoreCase)`) cho kết quả lệch nhau. Lệch điểm giữa web
// và mobile còn khó truy hơn lỗi vỡ chuỗi.
//
// Chỗ sửa đúng là BACKEND (escape khi ghi/đọc chuỗi bài làm) hoặc sửa ĐỒNG
// THỜI cả web lẫn mobile theo cùng một quy tắc — không phải ở đây.

/// Một đáp án đang chờ được ghi nhận trên máy chủ.
class _PendingAnswer {
  final String studentExamSessionId;

  /// Khoá GỐC do màn thi truyền vào, GIỮ NGUYÊN chữ hoa/thường.
  ///
  /// Chỉ dùng để đối chiếu ngược với id câu hỏi trong đề (lưới điều hướng và
  /// cảnh báo "chưa lưu" của `exam_screen` tra `ExamProgress.questionIndexOf`
  /// theo đúng id mà API trả về). TUYỆT ĐỐI không dùng khoá này để gửi lên
  /// máy chủ — xem [wireKey].
  final String key;

  /// Khoá THẬT SỰ gửi lên `save-answer`: đã chuẩn hoá chữ thường.
  final String wireKey;

  /// Giá trị đáp án, gửi NGUYÊN VĂN đúng như web (xem khối ghi chú "KÝ TỰ
  /// PHÂN TÁCH TRONG GIÁ TRỊ ĐÁP ÁN" ở trên).
  final String value;

  /// Chuẩn hoá khoá được đặt ngay trong hàm dựng để KHÔNG có đường nào tạo
  /// được một [_PendingAnswer] chưa chuẩn hoá — kể cả đường gửi lại
  /// ([UserService.retryFailedAnswers]) hay bất kỳ nơi gọi nào thêm về sau.
  _PendingAnswer({
    required this.studentExamSessionId,
    required this.key,
    required this.value,
  }) : wireKey = normalizeAnswerKey(key);
}

class UserService extends BaseService {
  // ===== HÀNG ĐỢI LƯU ĐÁP ÁN =====
  //
  // Toàn bộ state dưới đây là `static` một cách CỐ Ý: backend tích luỹ bài làm
  // từ chính các lần `save-answer`, nên hai request của cùng một phiên thi mà
  // chạy chồng chéo có thể ghi đè nhau. Hàng đợi phải theo PHIÊN THI, không
  // theo instance UserService — trong app hiện tại mỗi màn tự `UserService()`
  // riêng, nếu để state ở instance thì hai instance vẫn bắn song song.

  /// Đuôi của dây chuyền request theo từng studentExamSessionId.
  static final Map<String, Future<void>> _saveAnswerQueues = {};

  /// Các đáp án rốt cuộc không lưu được: sessionId -> (questionId -> đáp án).
  /// Giữ theo questionId nên chỉ còn GIÁ TRỊ MỚI NHẤT của câu đó — thử lại sẽ
  /// không bao giờ ghi đè bằng một lựa chọn cũ.
  static final Map<String, Map<String, _PendingAnswer>> _failedAnswers = {};

  static final StreamController<AnswerSaveStatus> _saveAnswerStatusController =
      StreamController<AnswerSaveStatus>.broadcast();

  /// Tiền tố khoá lưu hàng đợi xuống đĩa: `pending_answers_{sessionId}`.
  ///
  /// Vì sao phải ghi đĩa: [_failedAnswers] nằm trong RAM, hệ điều hành thu hồi
  /// app đang chạy nền (rất hay gặp khi sinh viên bị gọi điện giữa giờ thi) là
  /// mất sạch những câu chưa kịp lưu, mà sinh viên thì tưởng đã chọn xong.
  static const String _pendingAnswersPrefix = 'pending_answers_';

  /// Theo dõi mạng để gửi lại: sessionId -> subscription.
  static final Map<String, StreamSubscription<List<ConnectivityResult>>>
  _connectivityWatchers = {};

  /// Nhịp gõ lại phòng khi hệ điều hành báo "có mạng" mà thực tế không ra được
  /// Internet (wifi cổng đăng nhập, 4G chập chờn).
  static final Map<String, Timer> _pendingRetryTimers = {};
  static const Duration _pendingRetryInterval = Duration(seconds: 20);

  /// Số câu tối đa trong MỘT request `api/student/save-answers`.
  ///
  /// Backend chặn ở 200 và trả 400 cho CẢ lô nếu vượt (`STUDENT_ANSWERS_TOO_MANY`),
  /// nên client phải tự chia lô — không được đẩy nguyên hàng đợi lên.
  static const int bulkSaveAnswersMaxItems = 200;

  /// Số lần gửi tối đa cho một đáp án (1 lần đầu + 2 lần thử lại).
  static const int _saveAnswerMaxAttempts = 3;

  /// Giãn cách giữa các lần thử lại (lùi dần).
  static const List<Duration> _saveAnswerRetryDelays = [
    Duration(milliseconds: 600),
    Duration(milliseconds: 1800),
  ];

  /// Dòng sự kiện trạng thái lưu đáp án, dùng chung cho mọi instance.
  Stream<AnswerSaveStatus> get answerSaveStatuses =>
      _saveAnswerStatusController.stream;

  /// Các câu của phiên [studentExamSessionId] hiện chưa lưu được.
  List<String> failedAnswerKeys(String studentExamSessionId) =>
      _failedAnswers[studentExamSessionId]?.keys.toList(growable: false) ??
      const <String>[];

  int failedAnswerCount(String studentExamSessionId) =>
      _failedAnswers[studentExamSessionId]?.length ?? 0;

  /// Các đáp án đang nợ máy chủ: questionId -> giá trị.
  ///
  /// Màn thi dùng để đè lên bài làm tải từ máy chủ — đây là lựa chọn mới nhất
  /// của sinh viên, máy chủ chưa kịp nhận.
  Map<String, String> pendingAnswerValues(String studentExamSessionId) {
    final pending = _failedAnswers[studentExamSessionId];
    if (pending == null) return const <String, String>{};
    return <String, String>{
      for (final entry in pending.entries) entry.key: entry.value.value,
    };
  }

  /// Gửi lại toàn bộ đáp án chưa lưu được của một phiên thi.
  ///
  /// Đi bằng `api/student/save-answers` (số nhiều): cả hàng đợi gói vào các lô
  /// tối đa [bulkSaveAnswersMaxItems] câu thay vì N request tuần tự. Sinh viên
  /// vừa có mạng lại giữa giờ thi mà phải chờ vài trăm request nối đuôi nhau là
  /// hết giờ trước khi lưu xong.
  ///
  /// Lô hỏng ở mức request (endpoint chưa deploy, mất mạng, 5xx) thì QUAY VỀ
  /// đường cũ — gửi từng câu qua [_enqueueSaveAnswer], vốn có sẵn retry. Không
  /// bao giờ được để việc thêm endpoint mới làm mất đường lưu bài.
  Future<void> retryFailedAnswers(String studentExamSessionId) async {
    final pending = _failedAnswers[studentExamSessionId];
    if (pending == null || pending.isEmpty) return;

    // Chốt danh sách KHOÁ (không phải giá trị) ngay lúc này. Giá trị được đọc
    // lại sát lúc gửi, để không đẩy lên máy chủ một lựa chọn đã cũ trong khi
    // sinh viên vừa chọn lại câu đó.
    final keys = pending.keys.toList(growable: false);

    for (var start = 0; start < keys.length; start += bulkSaveAnswersMaxItems) {
      final end = start + bulkSaveAnswersMaxItems < keys.length
          ? start + bulkSaveAnswersMaxItems
          : keys.length;
      await _retryFailedAnswersChunk(
        studentExamSessionId,
        keys.sublist(start, end),
      );
    }
  }

  /// Gửi MỘT lô đáp án còn nợ và cập nhật lại hàng đợi theo câu trả lời.
  Future<void> _retryFailedAnswersChunk(
    String studentExamSessionId,
    List<String> keys,
  ) async {
    final pending = _failedAnswers[studentExamSessionId];
    if (pending == null || pending.isEmpty) return;

    final answers = <String, _PendingAnswer>{};
    for (final key in keys) {
      final answer = pending[key];
      if (answer != null) answers[key] = answer;
    }
    if (answers.isEmpty) return;

    // Banner "còn N câu chưa lưu" ở màn thi nghe stream này chứ không hỏi hàng
    // đợi, nên mỗi câu vẫn phải có đủ nhịp saving -> saved/failed dù cả lô chỉ
    // đi bằng MỘT request.
    for (final answer in answers.values) {
      _emitSaveAnswerStatus(answer, AnswerSaveState.saving);
    }

    final result = await saveAnswersBulk(
      studentExamSessionId: studentExamSessionId,
      items: answers.values
          .map((a) => BulkAnswerItem(key: a.key, value: a.value))
          .toList(growable: false),
    );

    if (result == null) {
      // ĐƯỜNG LUI: máy chủ chưa có endpoint gộp (backend cũ) hoặc lô hỏng ở
      // mức request. Gửi lại từng câu đúng như trước đây — chậm nhưng chắc.
      await Future.wait(answers.values.map(_enqueueSaveAnswer));
      return;
    }

    var queueChanged = false;

    for (final key in result.savedKeys) {
      final answer = answers[key];
      if (answer == null) continue;

      final current = _failedAnswers[studentExamSessionId]?[key];
      if (current != null && current.value != answer.value) {
        // Sinh viên đã chọn lại câu này trong lúc lô đang bay: giá trị MỚI vẫn
        // còn nợ máy chủ. Xoá khỏi hàng đợi ở đây là mất luôn lựa chọn mới.
        _emitSaveAnswerStatus(
          current,
          AnswerSaveState.failed,
          error: AppL10n.current.msgSaveAnswerFailed,
          attempts: 1,
        );
        continue;
      }

      if (current != null) {
        pending.remove(key);
        queueChanged = true;
      }
      _emitSaveAnswerStatus(answer, AnswerSaveState.saved, attempts: 1);
    }

    if (pending.isEmpty) _failedAnswers.remove(studentExamSessionId);

    for (final failure in result.failed) {
      final answer = answers[failure.key];
      if (answer == null) continue;
      // GIỮ NGUYÊN trong hàng đợi: máy chủ nói rõ là chưa nhận câu này.
      _emitSaveAnswerStatus(
        answer,
        AnswerSaveState.failed,
        error: _errorMessage(<String, dynamic>{
          'code': failure.code,
        }, AppL10n.current.msgSaveAnswerFailed),
        attempts: 1,
      );
    }

    if (queueChanged) await _persistPendingAnswers(studentExamSessionId);
  }

  /// Xoá dấu vết của một phiên thi (gọi khi rời màn thi) để không giữ lại
  /// cảnh báo của bài thi cũ.
  void forgetFailedAnswers(String studentExamSessionId) {
    _failedAnswers.remove(studentExamSessionId);
    stopPendingAnswerSync(studentExamSessionId);
    unawaited(_erasePendingAnswers(studentExamSessionId));
  }

  // ================= HÀNG ĐỢI OFFLINE =================

  /// Đọc lại các đáp án chưa lưu được từ lần chạy trước.
  ///
  /// Gọi khi vào màn thi: app bị tắt giữa chừng thì những câu này vẫn còn nợ
  /// máy chủ, không đọc lại là mất luôn.
  Future<int> restorePendingAnswers(String studentExamSessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(
        '$_pendingAnswersPrefix$studentExamSessionId',
      );
      if (raw == null || raw.isEmpty) return 0;

      final decoded = jsonDecode(raw);
      if (decoded is! List) return 0;

      final restored = <String, _PendingAnswer>{};
      for (final item in decoded) {
        if (item is! Map) continue;
        final key = item['key']?.toString();
        final value = item['value']?.toString();
        if (key == null || key.isEmpty || value == null) continue;
        restored[key] = _PendingAnswer(
          studentExamSessionId: studentExamSessionId,
          key: key,
          value: value,
        );
      }

      if (restored.isEmpty) return 0;

      // Đáp án đang có trong RAM là mới hơn (sinh viên vừa chọn) nên phải đè
      // lên bản đọc từ đĩa, không phải ngược lại.
      final current = _failedAnswers[studentExamSessionId];
      if (current != null) restored.addAll(current);
      _failedAnswers[studentExamSessionId] = restored;

      return restored.length;
    } catch (e) {
      print('Không đọc được hàng đợi đáp án: $e');
      return 0;
    }
  }

  /// Bật tự động gửi lại: nghe sự kiện đổi mạng + gõ lại theo nhịp.
  void startPendingAnswerSync(String studentExamSessionId) {
    stopPendingAnswerSync(studentExamSessionId);

    _connectivityWatchers[studentExamSessionId] = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
          final online = results.any((r) => r != ConnectivityResult.none);
          if (!online) return;
          unawaited(retryFailedAnswers(studentExamSessionId));
        });

    _pendingRetryTimers[studentExamSessionId] = Timer.periodic(
      _pendingRetryInterval,
      (_) {
        if (failedAnswerCount(studentExamSessionId) == 0) return;
        unawaited(retryFailedAnswers(studentExamSessionId));
      },
    );
  }

  void stopPendingAnswerSync(String studentExamSessionId) {
    _connectivityWatchers.remove(studentExamSessionId)?.cancel();
    _pendingRetryTimers.remove(studentExamSessionId)?.cancel();
  }

  Future<void> _persistPendingAnswers(String studentExamSessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pending = _failedAnswers[studentExamSessionId];

      if (pending == null || pending.isEmpty) {
        await prefs.remove('$_pendingAnswersPrefix$studentExamSessionId');
        return;
      }

      final payload = pending.values
          .map((a) => <String, String>{'key': a.key, 'value': a.value})
          .toList(growable: false);
      await prefs.setString(
        '$_pendingAnswersPrefix$studentExamSessionId',
        jsonEncode(payload),
      );
    } catch (e) {
      print('Không ghi được hàng đợi đáp án: $e');
    }
  }

  Future<void> _erasePendingAnswers(String studentExamSessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_pendingAnswersPrefix$studentExamSessionId');
    } catch (e) {
      print('Không xoá được hàng đợi đáp án: $e');
    }
  }

  // Đăng nhập Sinh viên (csharp_manage BE)
  Future<AuthResult> login(String userName, String password) async {
    try {
      final response = await post('api/auth/sessions/student', {
        'userName': userName.trim(),
        'password': password.trim(),
      });

      final data = jsonDecode(response.body);

      if (data['success'] == true &&
          data['data'] != null &&
          data['data']['token'] != null) {
        final token = data['data']['token'];
        await saveToken(token);
        return AuthResult(
          token: token,
          success: true,
          id: data['data']['id']?.toString(),
          userName: data['data']['userName'],
          userCode: data['data']['userCode'],
          fullName: data['data']['fullName'],
          avatarUrl: data['data']['avatarUrl'],
          role: data['data']['role'],
        );
      } else {
        return AuthResult(
          success: false,
          error: _errorMessage(data, AppL10n.current.msgLoginFailed),
        );
      }
    } catch (e) {
      return AuthResult(success: false, error: e.toString());
    }
  }

  // Đăng xuất
  Future<void> logout() async {
    // Gỡ token FCM TRƯỚC khi xoá JWT: xoá xong thì request nào cũng 401, backend
    // không gỡ được gì, và máy tiếp tục nhận thông báo của tài khoản vừa thoát —
    // chuyện nghiêm trọng với máy dùng chung ở phòng thi.
    await PushService.instance.unregister();

    try {
      await post('api/auth/sessions/logout/student', {});
    } catch (_) {}
    await removeToken();
    // Xoá hồ sơ đã lưu: máy dùng chung mà giữ lại là người sau đăng nhập vẫn
    // thấy tên người trước cho tới khi mạng trả về hồ sơ mới.
    await ProfileCache.clear();
  }

  // Kiểm tra đã đăng nhập
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    if (token == null || token.isEmpty) return false;

    // Token của sinh viên sống 7 ngày (JwtTokenGenerator.cs). Hết hạn mà vẫn
    // cho vào thì mọi màn đều nhận 401 và sinh viên không hiểu vì sao — dọn
    // luôn để lần mở sau không phải kiểm lại.
    if (JwtHelper.isExpired(token)) {
      await removeToken();
      return false;
    }
    return true;
  }

  /// Hồ sơ đã lưu trên máy, có ngay không cần mạng (null nếu chưa từng tải).
  Future<Student?> getCachedProfile() => ProfileCache.load();

  // Lấy thông tin profile sinh viên
  Future<Student?> getProfile() async {
    try {
      final response = await get('api/student/profile');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final student = (data['success'] == true && data['data'] != null)
            ? Student.fromJson(data['data'])
            : Student.fromJson(data);

        // Lưu lại để lần sau mở màn Tài khoản hiện được ngay, và để có
        // userCode + họ tên ngay cả khi mất mạng.
        unawaited(ProfileCache.save(student));
        return student;
      } else if (response.statusCode == 401) {
        throw Exception('Token không hợp lệ hoặc hết hạn.');
      } else if (response.statusCode == 404) {
        throw Exception('Sinh viên không tồn tại.');
      } else {
        throw Exception('Lỗi API: ${response.statusCode}');
      }
    } catch (e) {
      print('Lỗi getProfile: $e');
      return null;
    }
  }

  // Cập nhật thông tin cá nhân (PATCH api/user/profile)
  // Chỉ gửi các trường được truyền vào -> backend giữ nguyên phần còn lại.
  Future<ProfileUpdateResult> updateProfile({
    String? fullName,
    String? email,
    String? phoneNumber,
    DateTime? dateOfBirth,
    bool? gender,
  }) async {
    try {
      final response = await patch('api/user/profile', {
        if (fullName != null) 'fullName': fullName.trim(),
        if (email != null) 'email': email.trim(),
        if (phoneNumber != null) 'phoneNumber': phoneNumber.trim(),
        if (dateOfBirth != null) 'dateOfBirth': dateOfBirth.toIso8601String(),
        if (gender != null) 'gender': gender,
      });

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return ProfileUpdateResult(success: true);
      }

      return ProfileUpdateResult(
        success: false,
        error: _errorMessage(data, AppL10n.current.msgProfileUpdateFailed),
      );
    } catch (e) {
      print('Lỗi updateProfile: $e');
      return ProfileUpdateResult(
        success: false,
        error: AppL10n.current.msgServerUnreachable,
      );
    }
  }

  /// Đuôi tệp backend chấp nhận cho ảnh.
  ///
  /// Chép đúng `MediaUploadService.AllowedImageFormats` bên
  /// `csharp_manage/backend_manage.core/Services/MediaService/`. Backend lọc
  /// theo ĐUÔI TỆP chứ không đọc nội dung, nên danh sách này phải khớp từng
  /// chữ — lệch một đuôi là người dùng chọn xong mới bị từ chối.
  static const Set<String> _avatarAllowedExtensions = {
    '.jpg',
    '.jpeg',
    '.png',
    '.gif',
    '.webp',
    '.bmp',
  };

  /// Trần dung lượng ảnh, khớp `MediaUploadService.MaxImageSizeBytes` và
  /// `UserController.AvatarUploadMaxBytes` (cả hai đều 10MB).
  static const int _avatarMaxBytes = 10 * 1024 * 1024;

  /// Tải ảnh đại diện lên (POST api/user/profile/avatar).
  ///
  /// Hai chốt chặn ở đây KHÔNG thừa dù backend cũng kiểm tra:
  ///   * Quá 10MB mà cứ gửi thì người dùng ngồi chờ hết cả một lần tải lên qua
  ///     4G rồi mới nhận lỗi — mà `RequestSizeLimit` của ASP.NET cắt phăng
  ///     request giữa chừng nên câu trả lời về thường là 413 không thân
  ///     thiện, không phải mã lỗi có nghĩa.
  ///   * Sai đuôi tệp thì backend trả về `USER_AVATAR_UPLOAD_FAILED` chung
  ///     chung, không nói được là do định dạng.
  Future<ProfileUpdateResult> uploadAvatar(String filePath) async {
    final filename = filePath.split(Platform.pathSeparator).last;
    final dotIndex = filename.lastIndexOf('.');
    final extension = dotIndex == -1
        ? ''
        : filename.substring(dotIndex).toLowerCase();

    if (!_avatarAllowedExtensions.contains(extension)) {
      return ProfileUpdateResult(
        success: false,
        error: AppL10n.current.msgAvatarFormatUnsupported,
      );
    }

    try {
      final length = await File(filePath).length();
      if (length > _avatarMaxBytes) {
        return ProfileUpdateResult(
          success: false,
          error: AppL10n.current.msgAvatarFileTooLarge,
        );
      }
    } catch (e) {
      print('Lỗi đọc tệp ảnh đại diện: $e');
      return ProfileUpdateResult(
        success: false,
        error: AppL10n.current.msgAvatarUploadFailed,
      );
    }

    try {
      final response = await postMultipartFile(
        'api/user/profile/avatar',
        // Tên trường PHẢI là `file`: khớp tham số `IFormFile file` của
        // `UserController.UploadAvatar`.
        field: 'file',
        filePath: filePath,
        filename: filename,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return ProfileUpdateResult(success: true);
      }

      return ProfileUpdateResult(
        success: false,
        error: _errorMessage(data, AppL10n.current.msgAvatarUploadFailed),
      );
    } catch (e) {
      print('Lỗi uploadAvatar: $e');
      return ProfileUpdateResult(
        success: false,
        error: AppL10n.current.msgServerUnreachable,
      );
    }
  }

  /// Lịch sử làm bài của sinh viên đang đăng nhập
  /// (`GET api/student/exam-history`).
  Future<ExamHistoryResult> getExamHistory() async {
    try {
      final response = await get('api/student/exam-history');
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final raw = data['data'];
        final items = raw is List
            ? raw
                  .whereType<Map<String, dynamic>>()
                  .map(ExamHistoryItem.fromJson)
                  .toList()
            : <ExamHistoryItem>[];
        return ExamHistoryResult(success: true, items: items);
      }

      return ExamHistoryResult(
        success: false,
        error: _errorMessage(data, AppL10n.current.msgExamHistoryFetchFailed),
      );
    } catch (e) {
      print('Lỗi getExamHistory: $e');
      return ExamHistoryResult(
        success: false,
        error: AppL10n.current.msgServerUnreachable,
      );
    }
  }

  /// Xin phiếu mở lại một bài
  /// (`POST api/student/exam-history/{id}/open-review`).
  ///
  /// Quyền xem lại phụ thuộc cấu hình ca thi VÀ thời điểm hiện tại, nên nó có
  /// thể đã đổi kể từ lúc tải danh sách. Vì vậy khi bị từ chối, backend trả
  /// 403 kèm `data.reason` và hàm này chuyển tiếp nguyên vẹn qua
  /// [ExamReviewOpenResult.blockedReason] — màn hình phải nói ĐÚNG lý do đó
  /// thay vì một câu lỗi chung, rồi tải lại danh sách cho khớp thực tế.
  Future<ExamReviewOpenResult> openExamReview(
    String studentExamSessionId,
  ) async {
    try {
      final response = await post(
        'api/student/exam-history/$studentExamSessionId/open-review',
        const {},
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return const ExamReviewOpenResult(success: true);
      }

      // Tách hai bước: `cond ? a?[k] : b` làm bộ phân tích Dart lẫn dấu `?`
      // của toán tử ba ngôi với `?[` truy cập an toàn.
      final dynamic payload = data is Map ? data['data'] : null;
      final dynamic reason = payload is Map ? payload['reason'] : null;
      return ExamReviewOpenResult(
        success: false,
        blockedReason: reason == null
            ? null
            : ExamReviewBlockedReason.fromCode(reason.toString()),
        error: _errorMessage(data, AppL10n.current.msgExamReviewOpenFailed),
      );
    } catch (e) {
      print('Lỗi openExamReview: $e');
      return ExamReviewOpenResult(
        success: false,
        error: AppL10n.current.msgServerUnreachable,
      );
    }
  }

  // Đổi mật khẩu (PATCH api/user/password)
  Future<ProfileUpdateResult> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    try {
      final response = await patch('api/user/password', {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
        'confirmNewPassword': confirmNewPassword,
      });

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return ProfileUpdateResult(success: true);
      }

      return ProfileUpdateResult(
        success: false,
        error: _errorMessage(data, AppL10n.current.msgChangePasswordFailed),
      );
    } catch (e) {
      print('Lỗi changePassword: $e');
      return ProfileUpdateResult(
        success: false,
        error: AppL10n.current.msgServerUnreachable,
      );
    }
  }

  // jsonDecode ném lỗi khi body rỗng hoặc không phải JSON (proxy trả HTML,
  // 502 của gateway...). Ở nhánh xử lý lỗi ta chỉ cần "có thì đọc, không thì
  // thôi" nên nuốt lỗi tại đây và để caller tự chọn câu fallback.
  dynamic _decodeBody(String body) {
    if (body.trim().isEmpty) return null;
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  // Backend trả lỗi dạng { success, code } hoặc { success, code, errors: {...} }.
  // Mã trong `errors` cụ thể hơn `code` nên được ưu tiên.
  String _errorMessage(dynamic data, String fallback) {
    if (data is! Map) return fallback;

    final errors = data['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final first = errors.values.first;
      final code = (first is List && first.isNotEmpty)
          ? first.first?.toString()
          : first?.toString();
      if (code != null && code.isNotEmpty) {
        return ErrorMessageHelper.translate(code, fallback: fallback);
      }
    }

    final code = data['code'] ?? data['errorMessage'];
    return ErrorMessageHelper.translate(code?.toString(), fallback: fallback);
  }

  // Bắt đầu / Resume bài thi
  Future<StartExamResponseDto?> startExam(String studentExamSessionId) async {
    try {
      final response = await get(
        'api/student/resume-quiz/$studentExamSessionId',
      );
      print("Resume exam session ID: $studentExamSessionId");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final payload = data['data'] ?? data;
        return StartExamResponseDto.fromJson(payload);
      } else {
        print(
          'StartExam/Resume failed: ${response.statusCode} ${response.body}',
        );
        return null;
      }
    } on FormatException catch (e) {
      // Phản hồi không có đề thi -> lệch hợp đồng API, không phải lỗi mạng.
      print('Lỗi đọc dữ liệu đề khi khôi phục bài thi: $e');
      return null;
    } catch (e) {
      print('Lỗi startExam: $e');
      return null;
    }
  }

  // Tra ca thi theo mã sinh viên nhập (ExamSessionSubjectCore).
  //
  // GET api/ExamSessionSubject/cores/{core} là endpoint [AllowAnonymous] và
  // KHÔNG bọc envelope: thành công trả thẳng object ExamSessionSubjectDto,
  // thất bại mới trả { success: false, code: ... }. Mã có độ dài tự do
  // (varchar(50)) nên client không đặt thêm ràng buộc độ dài nào.
  Future<ExamSessionLookupResult> findExamSessionByCore(String core) async {
    final trimmed = core.trim();
    if (trimmed.isEmpty) {
      return ExamSessionLookupResult.failure(
        AppL10n.current.msgExamSessionCoreRequired,
      );
    }

    try {
      final response = await get(
        'api/ExamSessionSubject/cores/${Uri.encodeComponent(trimmed)}',
      );
      final data = _decodeBody(response.body);

      if (response.statusCode == 200) {
        if (data is Map<String, dynamic> &&
            data['examSessionSubjectId'] != null) {
          return ExamSessionLookupResult.success(
            ExamSessionSummary.fromJson(data),
          );
        }
        return ExamSessionLookupResult.failure(
          AppL10n.current.msgExamSessionFetchFailed,
        );
      }

      final fallback = response.statusCode == 404
          ? AppL10n.current.msgExamSessionNotFound
          : AppL10n.current.msgExamSessionFetchFailed;
      return ExamSessionLookupResult.failure(_errorMessage(data, fallback));
    } catch (e) {
      print('Lỗi findExamSessionByCore: $e');
      return ExamSessionLookupResult.failure(
        AppL10n.current.msgServerUnreachable,
      );
    }
  }

  // Tạo phiên thi từ ExamSessionSubject (Tạo mới phiên thi).
  //
  // Toạ độ mặc định {0,0} là sentinel "không có GPS" mà backend hiểu (xem
  // `hasValidGps` trong StudentController). App chưa có package định vị nên
  // không được bịa toạ độ thật: ca thi bắt buộc định vị sẽ bị từ chối bằng
  // STUDENT_LOCATION_REQUIRED và sinh viên được báo rõ, thay vì lặng lẽ ghi
  // một vị trí sai vào hồ sơ chống gian lận.
  Future<StartExamResponseDto?> createExamSession({
    required String examSessionSubjectId,
    double latitude = 0,
    double longitude = 0,
    String? address,
    String? deviceInfo = 'Mobile | Flutter App',
  }) async {
    final result = await createExamSessionDetailed(
      examSessionSubjectId: examSessionSubjectId,
      latitude: latitude,
      longitude: longitude,
      address: address,
      deviceInfo: deviceInfo,
    );
    return result.data;
  }

  // Như [createExamSession] nhưng giữ lại câu lỗi đã dịch để màn hình phân
  // biệt được "ca thi bắt buộc định vị" với "không vào được vì lý do nghiệp vụ".
  Future<ExamSessionStartResult> createExamSessionDetailed({
    required String examSessionSubjectId,
    double latitude = 0,
    double longitude = 0,
    String? address,
    String? deviceInfo = 'Mobile | Flutter App',
  }) async {
    try {
      final response = await post('api/student/create-exam-session', {
        'examSessionSubjectId': examSessionSubjectId,
        'latitude': latitude,
        'longitude': longitude,
        if (address != null) 'address': address,
        if (deviceInfo != null) 'deviceInfo': deviceInfo,
      });

      final data = _decodeBody(response.body);

      if (response.statusCode == 200) {
        if (data is Map<String, dynamic>) {
          return ExamSessionStartResult.success(
            StartExamResponseDto.fromJson(data),
          );
        }
        return ExamSessionStartResult.failure(
          AppL10n.current.msgStudentExamSessionCreateServerError,
        );
      }

      print(
        'createExamSession failed: ${response.statusCode} ${response.body}',
      );
      final fallback = response.statusCode >= 500
          ? AppL10n.current.msgStudentExamSessionCreateServerError
          : AppL10n.current.msgStudentExamSessionCreateFailed;
      return ExamSessionStartResult.failure(_errorMessage(data, fallback));
    } on FormatException catch (e) {
      // Phiên thi ĐÃ được tạo trên server (và có thể đã trừ một lượt làm bài),
      // chỉ là app không dựng nổi đề. Báo "mất mạng" ở đây là sai sự thật và
      // đẩy sinh viên vào vòng bấm lại — mỗi lần lại tốn thêm một lượt.
      print('Lỗi đọc dữ liệu đề khi tạo phiên thi: $e');
      return ExamSessionStartResult.failure(
        AppL10n.current.msgExamDataUnreadable,
      );
    } catch (e) {
      print('Lỗi createExamSession: $e');
      return ExamSessionStartResult.failure(
        AppL10n.current.msgServerUnreachable,
      );
    }
  }

  // Lưu đáp án (saveAnswer)
  //
  // Trả về `null` khi máy chủ KHÔNG ghi nhận được đáp án (đã thử lại xong).
  // Nơi gọi tuyệt đối không được coi đáp án là đã lưu khi nhận `null`.
  //
  // ĐÂY LÀ CỬA DUY NHẤT ra `save-answer` của toàn app, nên việc chuẩn hoá khoá
  // đặt ở đây (chính xác hơn: trong hàm dựng [_PendingAnswer]) để MỌI nơi gọi
  // đều được bảo vệ, kể cả các nơi gọi thêm sau này. Đọc kỹ ghi chú của
  // [normalizeAnswerKey] trước khi động vào: bỏ bước này đi là mở lại đường
  // cho lỗi chấm 0 điểm toàn bài.
  Future<SaveAnswerResponse?> saveAnswer({
    required String studentExamSessionId,
    required String key,
    required dynamic value,
  }) {
    return _enqueueSaveAnswer(
      _PendingAnswer(
        studentExamSessionId: studentExamSessionId,
        key: key.toString(),
        value: value?.toString() ?? '',
      ),
    );
  }

  /// Nối một đáp án vào cuối hàng đợi của phiên thi.
  ///
  /// Request sau chỉ chạy khi request trước đã xong (giống web tham chiếu),
  /// nhờ vậy thứ tự ghi trên máy chủ luôn khớp thứ tự sinh viên chọn.
  Future<SaveAnswerResponse?> _enqueueSaveAnswer(_PendingAnswer answer) {
    return _enqueueOnSaveQueue<SaveAnswerResponse?>(
      answer.studentExamSessionId,
      () => _runSaveAnswer(answer),
      null,
    );
  }

  /// Nối MỘT việc ghi lên máy chủ vào cuối hàng đợi của phiên thi.
  ///
  /// Dùng chung cho cả `save-answer` (một câu) lẫn `save-answers` (cả lô): hai
  /// đường này cùng ghi vào MỘT chuỗi bài làm trên máy chủ, chạy chồng chéo là
  /// đè mất nhau. [onError] là giá trị trả về khi việc ghi ném lỗi ngoài dự
  /// kiến — hàng đợi vẫn phải chảy tiếp cho các câu sau.
  ///
  /// KHÔNG được gọi hàm này từ bên trong một [task] đã nằm trên hàng đợi: việc
  /// mới sẽ chờ chính việc đang chạy, tức là treo vĩnh viễn.
  Future<T> _enqueueOnSaveQueue<T>(
    String sessionId,
    Future<T> Function() task,
    T onError,
  ) {
    final previous = _saveAnswerQueues[sessionId] ?? Future<void>.value();

    // Completer tách kết quả của caller khỏi dây chuyền: dù lần lưu này hỏng,
    // dây chuyền vẫn phải tiếp tục cho các câu sau.
    final completer = Completer<T>();
    final Future<void> chained = previous
        .then((_) => task())
        .then((T value) => completer.complete(value))
        .catchError((Object error) {
          // task đã nuốt mọi lỗi; nhánh này chỉ để hàng đợi không đứt.
          print('Lỗi ngoài dự kiến khi lưu đáp án: $error');
          completer.complete(onError);
        });

    _saveAnswerQueues[sessionId] = chained;
    chained.whenComplete(() {
      // Chỉ dọn khi mình vẫn là đuôi hàng đợi, tránh xoá nhầm request đang chờ.
      if (identical(_saveAnswerQueues[sessionId], chained)) {
        _saveAnswerQueues.remove(sessionId);
      }
    });

    return completer.future;
  }

  /// Gửi MỘT LÔ đáp án lên `api/student/save-answers` (endpoint số nhiều).
  ///
  /// Đây KHÔNG phải đường lưu lúc đang thi bình thường — một câu vừa chọn vẫn
  /// đi bằng [saveAnswer] / `api/student/save-answer` như cũ. Hàm này chỉ dùng
  /// để đổ hàng đợi offline.
  ///
  /// Trả về `null` khi lô hỏng ở MỨC REQUEST (mất mạng, 4xx, 5xx, thân trả về
  /// không đọc được) — máy chủ khi đó KHÔNG lưu gì cả, nơi gọi phải đi đường
  /// lui. Trả về [BulkSaveAnswersResult] khi máy chủ đã xử lý: câu nào lưu
  /// được nằm trong `savedKeys`, câu nào bị từ chối lẻ nằm trong `failed`.
  ///
  /// Quá [bulkSaveAnswersMaxItems] câu thì trả `null` ngay mà không gửi: backend
  /// sẽ trả 400 cho cả lô, gửi lên chỉ tổ mất một vòng mạng.
  Future<BulkSaveAnswersResult?> saveAnswersBulk({
    required String studentExamSessionId,
    required List<BulkAnswerItem> items,
  }) {
    if (items.isEmpty) {
      return Future<BulkSaveAnswersResult?>.value(
        const BulkSaveAnswersResult(
          savedKeys: <String>[],
          failed: <BulkSaveAnswerFailure>[],
        ),
      );
    }
    if (items.length > bulkSaveAnswersMaxItems) {
      print(
        'saveAnswersBulk: lô ${items.length} câu vượt '
        '$bulkSaveAnswersMaxItems, nơi gọi phải tự chia lô',
      );
      return Future<BulkSaveAnswersResult?>.value(null);
    }

    return _enqueueOnSaveQueue<BulkSaveAnswersResult?>(
      studentExamSessionId,
      () => _runSaveAnswersBulk(studentExamSessionId, items),
      null,
    );
  }

  /// Thân của [saveAnswersBulk]: dựng thân request, gửi, đọc kết quả.
  ///
  /// KHÔNG thử lại: nơi gọi đã có đường lui gửi từng câu, mà đường đó tự retry
  /// rồi. Thử lại ở cả hai tầng chỉ làm sinh viên chờ gấp đôi.
  Future<BulkSaveAnswersResult?> _runSaveAnswersBulk(
    String studentExamSessionId,
    List<BulkAnswerItem> items,
  ) async {
    // wireKey -> các khoá GỐC đổ về nó. Máy chủ chỉ biết wireKey, còn hàng đợi
    // đánh dấu theo khoá gốc, nên phải giữ được đường về (xem [normalizeAnswerKey]).
    final originKeysByWireKey = <String, List<String>>{};
    final payload = <Map<String, String>>[];
    final payloadIndexByWireKey = <String, int>{};
    final failed = <BulkSaveAnswerFailure>[];

    for (final item in items) {
      final wireKey = normalizeAnswerKey(item.key);
      if (wireKey.isEmpty) {
        // Máy chủ sẽ từ chối khoá rỗng; báo hỏng ngay, khỏi tốn chỗ trong lô.
        failed.add(
          BulkSaveAnswerFailure(key: item.key, code: 'STUDENT_ANSWER_EMPTY'),
        );
        continue;
      }

      originKeysByWireKey.putIfAbsent(wireKey, () => <String>[]).add(item.key);

      final at = payloadIndexByWireKey[wireKey];
      if (at != null) {
        // Cùng một câu xuất hiện hai lần trong MỘT lô (ví dụ `Q1` và `q1`) là
        // đúng cái sinh ra lỗi chấm 0 điểm toàn bài — chỉ giữ giá trị mới nhất.
        payload[at] = <String, String>{'key': wireKey, 'value': item.value};
      } else {
        payloadIndexByWireKey[wireKey] = payload.length;
        payload.add(<String, String>{'key': wireKey, 'value': item.value});
      }
    }

    if (payload.isEmpty) {
      return BulkSaveAnswersResult(savedKeys: const <String>[], failed: failed);
    }

    try {
      final response = await post('api/student/save-answers', {
        'studentExamSessionId': studentExamSessionId,
        'items': payload,
      });

      if (response.statusCode != 200) {
        // Gồm cả 404 khi backend chưa deploy endpoint gộp.
        print('saveAnswersBulk hỏng: ${response.statusCode} ${response.body}');
        return null;
      }

      final data = _decodeBody(response.body);
      if (data is! Map || data['success'] == false) {
        print('saveAnswersBulk bị từ chối cả lô: ${response.body}');
        return null;
      }

      final payloadData = data['data'];
      if (payloadData is! Map) {
        print('saveAnswersBulk trả thân lạ: ${response.body}');
        return null;
      }

      final savedKeys = <String>[];
      final answered = <String>{};

      final savedRaw = payloadData['savedKeys'];
      if (savedRaw is List) {
        for (final entry in savedRaw) {
          // Máy chủ trả lại đúng chuỗi đã gửi (tức wireKey); chuẩn hoá thêm một
          // lần nữa để không phụ thuộc vào việc backend có đổi hoa/thường không.
          final wireKey = normalizeAnswerKey(entry?.toString() ?? '');
          if (wireKey.isEmpty) continue;
          final origins = originKeysByWireKey[wireKey];
          if (origins == null) continue;
          answered.add(wireKey);
          savedKeys.addAll(origins);
        }
      }

      final failedRaw = payloadData['failed'];
      if (failedRaw is List) {
        for (final entry in failedRaw) {
          if (entry is! Map) continue;
          final wireKey = normalizeAnswerKey(entry['key']?.toString() ?? '');
          if (wireKey.isEmpty) continue;
          final origins = originKeysByWireKey[wireKey];
          if (origins == null) continue;
          answered.add(wireKey);
          final code = entry['code']?.toString() ?? '';
          for (final origin in origins) {
            failed.add(BulkSaveAnswerFailure(key: origin, code: code));
          }
        }
      }

      // Câu nào máy chủ không nhắc tới thì COI NHƯ CHƯA LƯU. Giữ lại một câu đã
      // lưu rồi chỉ tốn thêm một request; xoá nhầm một câu chưa lưu là sinh
      // viên mất câu đó.
      for (final entry in originKeysByWireKey.entries) {
        if (answered.contains(entry.key)) continue;
        for (final origin in entry.value) {
          failed.add(BulkSaveAnswerFailure(key: origin, code: ''));
        }
      }

      return BulkSaveAnswersResult(savedKeys: savedKeys, failed: failed);
    } catch (e) {
      print('Lỗi saveAnswersBulk: $e');
      return null;
    }
  }

  /// Máy có đang mất mạng hoàn toàn hay không.
  ///
  /// Chỉ dùng để BỎ QUA việc thử lại — có mạng vẫn có thể hỏng vì lý do khác,
  /// nên không dùng cái này để kết luận "gửi được".
  static Future<bool> _isOffline() async {
    try {
      final results = await Connectivity().checkConnectivity();
      return results.every((r) => r == ConnectivityResult.none);
    } catch (_) {
      // Không hỏi được trạng thái mạng thì cứ thử lại như cũ.
      return false;
    }
  }

  /// Gửi một đáp án, có thử lại với lỗi mạng và lỗi 5xx.
  ///
  /// KHÔNG thử lại với 4xx: đó là lỗi dữ liệu / phiên thi (hết hạn, đã nộp,
  /// sai khoá) nên gửi lại bao nhiêu lần cũng vẫn hỏng, chỉ làm sinh viên chờ.
  Future<SaveAnswerResponse?> _runSaveAnswer(_PendingAnswer answer) async {
    _emitSaveAnswerStatus(answer, AnswerSaveState.saving);

    String? lastError;

    for (var attempt = 1; attempt <= _saveAnswerMaxAttempts; attempt++) {
      var retryable = false;

      try {
        // `wireKey` chứ KHÔNG phải `key`: khoá lên máy chủ luôn là chữ thường
        // (xem [normalizeAnswerKey]). Đây là chốt chặn cuối, mọi lần thử lại
        // cũng đi qua đúng chỗ này.
        final response = await post('api/student/save-answer', {
          'StudentExamSessionId': answer.studentExamSessionId,
          'key': answer.wireKey,
          'value': answer.value,
        });

        final data = _decodeBody(response.body);

        if (response.statusCode == 200) {
          // Body rỗng/không phải JSON ở mã 200 vẫn coi là đã lưu — backend
          // hiện luôn trả envelope, nhưng không được vì thế mà báo lỗi giả.
          final success = data is! Map || data['success'] != false;
          if (success) {
            _clearFailedAnswer(answer);
            _emitSaveAnswerStatus(
              answer,
              AnswerSaveState.saved,
              attempts: attempt,
            );
            return SaveAnswerResponse(
              success: true,
              message: data is Map ? (data['code']?.toString() ?? '') : '',
              data: SaveAnswerData(
                newAnswersString: '',
                key: answer.key,
                value: answer.value,
              ),
            );
          }

          // 200 nhưng success=false -> lỗi nghiệp vụ, thử lại vô ích.
          lastError = _errorMessage(data, AppL10n.current.msgSaveAnswerFailed);
        } else if (response.statusCode >= 500) {
          retryable = true;
          lastError = AppL10n.current.msgSaveAnswerServerError;
          print('saveAnswer 5xx: ${response.statusCode} ${response.body}');
        } else {
          lastError = _errorMessage(data, AppL10n.current.msgSaveAnswerFailed);
          print('saveAnswer failed: ${response.statusCode} ${response.body}');
        }
      } catch (e) {
        // Mất mạng / timeout / DNS: đúng loại lỗi đáng thử lại.
        retryable = true;
        lastError = AppL10n.current.msgSaveAnswerOffline;
        print('Lỗi saveAnswer (lần $attempt): $e');

        // Máy đang KHÔNG có mạng thì thử lại là vô ích: mỗi câu ngốn thêm 2,4
        // giây chờ rồi cũng vào hàng đợi, mà sinh viên chọn liên tục nhiều câu
        // thì cộng dồn thành đứng máy. Vào hàng đợi ngay, để trình đồng bộ lo
        // khi có mạng lại.
        if (await _isOffline()) {
          break;
        }
      }

      if (!retryable) break;
      if (attempt >= _saveAnswerMaxAttempts) break;

      await Future<void>.delayed(_saveAnswerRetryDelay(attempt));
    }

    _rememberFailedAnswer(answer);
    _emitSaveAnswerStatus(
      answer,
      AnswerSaveState.failed,
      error: lastError ?? AppL10n.current.msgSaveAnswerFailed,
      attempts: _saveAnswerMaxAttempts,
    );
    return null;
  }

  Duration _saveAnswerRetryDelay(int attempt) {
    final index = attempt - 1;
    if (index < 0) return _saveAnswerRetryDelays.first;
    if (index >= _saveAnswerRetryDelays.length) {
      return _saveAnswerRetryDelays.last;
    }
    return _saveAnswerRetryDelays[index];
  }

  void _rememberFailedAnswer(_PendingAnswer answer) {
    _failedAnswers.putIfAbsent(
      answer.studentExamSessionId,
      () => <String, _PendingAnswer>{},
    )[answer.key] = answer;
    unawaited(_persistPendingAnswers(answer.studentExamSessionId));
  }

  void _clearFailedAnswer(_PendingAnswer answer) {
    final pending = _failedAnswers[answer.studentExamSessionId];
    if (pending == null) return;
    pending.remove(answer.key);
    if (pending.isEmpty) _failedAnswers.remove(answer.studentExamSessionId);
    unawaited(_persistPendingAnswers(answer.studentExamSessionId));
  }

  void _emitSaveAnswerStatus(
    _PendingAnswer answer,
    AnswerSaveState state, {
    String? error,
    int attempts = 0,
  }) {
    if (_saveAnswerStatusController.isClosed) return;
    _saveAnswerStatusController.add(
      AnswerSaveStatus(
        studentExamSessionId: answer.studentExamSessionId,
        questionId: answer.key,
        value: answer.value,
        state: state,
        error: error,
        attempts: attempts,
      ),
    );
  }

  // Nộp bài (submitExam)
  //
  // [clientSubmittedAt] là mốc UTC của đúng giây sinh viên bấm "Nộp bài", KHÔNG
  // phải giờ gửi request. Backend lấy mốc này làm giờ nộp thật (cửa sổ chấp
  // nhận: lệch tối đa 60 phút so với giờ máy chủ) và nhờ nó mà một bài bị giám
  // thị đóng phòng vẫn được nhận trễ rồi chấm lại, miễn là sinh viên đã bấm nộp
  // trước lúc đóng phòng ít nhất 30 giây. Vì vậy đường gửi lại
  // ([PendingSubmitService]) phải mang theo mốc CŨ chứ không được lấy giờ mới.
  Future<SubmitExamOutcome> submitExam(
    String studentExamSessionId, {
    String? deviceInfo,
    String? studentAnswersString,
    DateTime? clientSubmittedAt,
  }) async {
    try {
      final response = await post('api/student/submit-exam', {
        'StudentExamSessionId': studentExamSessionId,
        if (deviceInfo != null) 'DeviceInfo': deviceInfo,
        if (studentAnswersString != null)
          'StudentAnswersString': studentAnswersString,
        if (clientSubmittedAt != null)
          'ClientSubmittedAt': clientSubmittedAt.toUtc().toIso8601String(),
      });

      if (response.statusCode == 200) {
        // Thân tin hỏng KHÔNG được coi là nộp hỏng: máy chủ đã ghi nhận rồi,
        // gửi lại chỉ tổ nhận về "đã nộp bài thi trước đó".
        SubmitExamResponse? parsed;
        try {
          final data = jsonDecode(response.body);
          parsed = SubmitExamResponse(
            success: data['success'] == true,
            message: data['code'] ?? AppL10n.current.msgSubmitExamSuccess,
            data: SubmitExamData(resultToken: data['resultToken'] ?? ''),
          );
        } catch (e) {
          print('submitExam: không đọc được thân tin trả về: $e');
        }
        return SubmitExamOutcome(
          SubmitExamStatus.accepted,
          response:
              parsed ??
              SubmitExamResponse(
                success: true,
                message: AppL10n.current.msgSubmitExamSuccess,
              ),
        );
      }

      print('submitExam failed: ${response.statusCode} ${response.body}');

      if (_isRetryableSubmitStatus(response.statusCode)) {
        return const SubmitExamOutcome(SubmitExamStatus.retryable);
      }

      dynamic data;
      try {
        data = jsonDecode(response.body);
      } catch (_) {
        data = null;
      }
      return SubmitExamOutcome(
        SubmitExamStatus.rejected,
        message: _errorMessage(data, AppL10n.current.msgSubmitExamRejected),
      );
    } catch (e) {
      // Không tới được máy chủ (mất mạng, DNS hỏng, hết hạn chờ). Đây chính là
      // trường hợp mà hàng chờ nộp bài sinh ra để cứu.
      print('Lỗi submitExam: $e');
      return const SubmitExamOutcome(SubmitExamStatus.retryable);
    }
  }

  /// Mã trạng thái nào còn đáng gửi lại.
  ///
  /// 401/403 nằm trong danh sách này một cách CỐ Ý: token hết hạn là lỗi tạm
  /// thời của client, vứt bỏ lệnh nộp vì nó thì sinh viên mất trắng bài.
  bool _isRetryableSubmitStatus(int statusCode) =>
      statusCode >= 500 ||
      statusCode == 401 ||
      statusCode == 403 ||
      statusCode == 408 ||
      statusCode == 429;

  // Lấy kết quả điểm bài thi đã nộp
  Future<ExamSubmissionDto?> getSubmissionResult(
    String studentExamSessionId,
  ) async {
    try {
      final response = await get('api/student/my-grades/$studentExamSessionId');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final payload = data['data'] ?? data;
        return ExamSubmissionDto.fromJson(payload);
      } else {
        print(
          'getSubmissionResult failed: ${response.statusCode} ${response.body}',
        );
        return null;
      }
    } catch (e) {
      print('Lỗi getSubmissionResult: $e');
      return null;
    }
  }
}

/// Thông tin ca thi mà màn "Nhập mã kiểm tra" cần, rút gọn từ
/// `ExamSessionSubjectDto` của backend.
class ExamSessionSummary {
  final String examSessionSubjectId;
  final String subjectName;
  final int duration;
  final DateTime? startTime;
  final DateTime? endTime;

  /// Ca thi bắt buộc gửi toạ độ GPS hợp lệ mới cho vào. App chưa định vị được
  /// nên cờ này chỉ dùng để cảnh báo trước, quyết định cuối vẫn là của backend.
  final bool requireLocationOnExamStart;
  final String examSessionSubjectCore;

  /// Ca thi không giới hạn thời gian làm bài.
  ///
  /// Quan trọng khi hiển thị: với ca này backend gán
  /// `EndTime = DateTime.MaxValue` (ExamSessionSubjectService.cs:321) tức
  /// 31/12/9999, nên KHÔNG được đem `endTime` ra hiện cho sinh viên — web cũng
  /// ẩn hẳn dòng đó (ExamSessionStudent.tsx:208).
  final bool isUnlimitedTime;

  const ExamSessionSummary({
    required this.examSessionSubjectId,
    required this.subjectName,
    required this.duration,
    required this.startTime,
    required this.endTime,
    required this.requireLocationOnExamStart,
    required this.examSessionSubjectCore,
    required this.isUnlimitedTime,
  });

  factory ExamSessionSummary.fromJson(Map<String, dynamic> json) {
    return ExamSessionSummary(
      examSessionSubjectId: json['examSessionSubjectId']?.toString() ?? '',
      subjectName: json['subjectName']?.toString() ?? '',
      duration: (json['duration'] as num?)?.toInt() ?? 0,
      startTime: DateTime.tryParse(json['startTime']?.toString() ?? ''),
      endTime: DateTime.tryParse(json['endTime']?.toString() ?? ''),
      requireLocationOnExamStart: json['requireLocationOnExamStart'] == true,
      examSessionSubjectCore: json['examSessionSubjectCore']?.toString() ?? '',
      isUnlimitedTime: json['isUnlimitedTime'] == true,
    );
  }
}

/// Kết quả tra ca thi theo mã: hoặc có [session], hoặc có [error] đã dịch.
class ExamSessionLookupResult {
  final ExamSessionSummary? session;
  final String? error;

  const ExamSessionLookupResult._({this.session, this.error});

  factory ExamSessionLookupResult.success(ExamSessionSummary session) =>
      ExamSessionLookupResult._(session: session);

  factory ExamSessionLookupResult.failure(String error) =>
      ExamSessionLookupResult._(error: error);
}

/// Kết quả tạo phiên thi: hoặc có [data] để mở màn làm bài, hoặc có [error]
/// đã dịch để hiển thị nguyên nhân.
class ExamSessionStartResult {
  final StartExamResponseDto? data;
  final String? error;

  const ExamSessionStartResult._({this.data, this.error});

  factory ExamSessionStartResult.success(StartExamResponseDto data) =>
      ExamSessionStartResult._(data: data);

  factory ExamSessionStartResult.failure(String error) =>
      ExamSessionStartResult._(error: error);
}
