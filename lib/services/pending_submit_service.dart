import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth/user_services.dart';

/// MỘT lệnh nộp bài đã được sinh viên chốt nhưng máy chủ chưa nhận.
///
/// Đây là toàn bộ những gì cần để gửi lại `api/student/submit-exam` sau này —
/// kể cả sau khi app bị tắt hẳn — nên phải ghi xuống đĩa nguyên vẹn.
class PendingSubmit {
  const PendingSubmit({
    required this.studentExamSessionId,
    required this.studentAnswersString,
    required this.clientSubmittedAt,
    this.deviceInfo,
  });

  final String studentExamSessionId;

  /// TOÀN BỘ bài làm, dựng bằng `serializeAnswers`. `submit-exam` GHI ĐÈ chuỗi
  /// trên máy chủ nên đây là bản đầy đủ, không phải phần chênh lệch.
  final String studentAnswersString;

  final String? deviceInfo;

  /// Mốc UTC của đúng giây sinh viên bấm "Nộp bài".
  ///
  /// KHÔNG BAO GIỜ được cập nhật khi gửi lại: backend lấy chính mốc này làm giờ
  /// nộp thật, và chỉ nhận bài trễ của một phòng đã đóng khi mốc này sớm hơn
  /// giờ đóng phòng ít nhất 30 giây. Gửi lại bằng giờ hiện tại là sinh viên mất
  /// bài đúng lúc cần nó nhất.
  final DateTime clientSubmittedAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'studentExamSessionId': studentExamSessionId,
    'studentAnswersString': studentAnswersString,
    if (deviceInfo != null) 'deviceInfo': deviceInfo,
    'clientSubmittedAt': clientSubmittedAt.toUtc().toIso8601String(),
  };

  /// Trả `null` cho bản ghi hỏng thay vì ném: một dòng rác trên đĩa không được
  /// phép làm hỏng cả hàng chờ.
  static PendingSubmit? fromJson(Map<dynamic, dynamic> json) {
    final sessionId = json['studentExamSessionId']?.toString();
    final stamp = json['clientSubmittedAt']?.toString();
    if (sessionId == null || sessionId.isEmpty) return null;
    if (stamp == null || stamp.isEmpty) return null;

    final parsed = DateTime.tryParse(stamp);
    if (parsed == null) return null;

    return PendingSubmit(
      studentExamSessionId: sessionId,
      studentAnswersString: json['studentAnswersString']?.toString() ?? '',
      deviceInfo: json['deviceInfo']?.toString(),
      clientSubmittedAt: parsed.toUtc(),
    );
  }
}

/// Kết cục của một lệnh nộp đang chờ, dùng để điền vào màn kết quả.
class PendingSubmitOutcome {
  const PendingSubmitOutcome.accepted({this.score})
    : accepted = true,
      message = null;

  const PendingSubmitOutcome.rejected(this.message)
    : accepted = false,
      score = null;

  /// Máy chủ đã nhận bài.
  final bool accepted;

  /// Điểm lấy được sau khi nộp; `null` khi máy chủ chưa chấm xong.
  final double? score;

  /// Lý do bị từ chối (đã dịch), chỉ có khi [accepted] là `false`.
  final String? message;
}

/// Nơi cất các lệnh nộp đang chờ trên đĩa.
///
/// Cả hàng chờ nằm trong MỘT khoá dạng danh sách JSON, khác với hàng đợi đáp án
/// (mỗi phiên một khoá): lúc mở lại app không ai biết trước sessionId nào còn
/// nợ, nên phải đọc được cả danh sách chỉ bằng một khoá cố định.
class PendingSubmitStore {
  const PendingSubmitStore._();

  static const String storageKey = 'pending_submits';

  static Future<List<PendingSubmit>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(storageKey);
      if (raw == null || raw.isEmpty) return const <PendingSubmit>[];

      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <PendingSubmit>[];

      final result = <PendingSubmit>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        final submit = PendingSubmit.fromJson(item);
        if (submit != null) result.add(submit);
      }
      return result;
    } catch (e) {
      debugPrint('Không đọc được hàng chờ nộp bài: $e');
      return const <PendingSubmit>[];
    }
  }

  /// Ghi (hoặc ghi đè) lệnh nộp của một phiên thi.
  ///
  /// Ghi đè theo `studentExamSessionId` để một phiên chỉ có đúng một lệnh chờ —
  /// nộp hai lần cùng một phiên là vô nghĩa với backend.
  static Future<void> save(PendingSubmit submit) async {
    try {
      final current = await load();
      final next = <PendingSubmit>[
        for (final item in current)
          if (item.studentExamSessionId != submit.studentExamSessionId) item,
        submit,
      ];
      await _write(next);
    } catch (e) {
      debugPrint('Không ghi được lệnh nộp đang chờ: $e');
    }
  }

  static Future<void> remove(String studentExamSessionId) async {
    try {
      final current = await load();
      final next = <PendingSubmit>[
        for (final item in current)
          if (item.studentExamSessionId != studentExamSessionId) item,
      ];
      if (next.length == current.length) return;
      await _write(next);
    } catch (e) {
      debugPrint('Không xoá được lệnh nộp đang chờ: $e');
    }
  }

  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(storageKey);
    } catch (e) {
      debugPrint('Không xoá được hàng chờ nộp bài: $e');
    }
  }

  static Future<void> _write(List<PendingSubmit> items) async {
    final prefs = await SharedPreferences.getInstance();
    if (items.isEmpty) {
      await prefs.remove(storageKey);
      return;
    }
    await prefs.setString(
      storageKey,
      jsonEncode(items.map((e) => e.toJson()).toList(growable: false)),
    );
  }
}

/// Gửi lại các lệnh nộp bài còn nợ máy chủ.
///
/// Vì sao cần: mất mạng đúng lúc bấm "Nộp bài" là chuyện thường trong phòng
/// thi, mà báo "nộp bài thất bại" thì sinh viên chỉ còn cách ngồi bấm lại. Thay
/// vào đó lệnh nộp được ghi xuống đĩa kèm ĐÚNG mốc lúc bấm, rồi tự gửi lại khi
/// mạng trở lại — kể cả sau khi app bị tắt.
///
/// Mô hình theo dõi mạng lấy đúng của [UserService.startPendingAnswerSync]:
/// nghe `onConnectivityChanged` cộng thêm một nhịp gõ lại, vì hệ điều hành báo
/// "có mạng" không đồng nghĩa với ra được Internet (wifi có cổng đăng nhập).
class PendingSubmitService {
  PendingSubmitService({UserService? userService})
    : _userService = userService ?? UserService();

  /// Bản dùng chung của cả app. Hàng chờ nằm trên đĩa nên phải có đúng một
  /// người gửi, nếu không hai bản sẽ cùng gửi một lệnh nộp.
  static final PendingSubmitService instance = PendingSubmitService();

  /// Nhịp gõ lại, giống hàng đợi đáp án.
  static const Duration retryInterval = Duration(seconds: 20);

  final UserService _userService;

  /// Ai đang đợi kết cục của phiên nào (màn kết quả đang quay vòng chờ).
  final Map<String, Completer<PendingSubmitOutcome>> _waiters = {};

  StreamSubscription<List<ConnectivityResult>>? _connectivity;
  Timer? _timer;
  bool _watching = false;
  bool _flushing = false;
  bool _flushAgain = false;

  /// Còn lệnh nộp nào chưa gửi được không (đọc từ đĩa).
  Future<bool> get hasPending async =>
      (await PendingSubmitStore.load()).isNotEmpty;

  /// Future sẽ hoàn tất khi phiên [studentExamSessionId] có kết cục.
  ///
  /// Gọi trước [save] để chắc chắn không lỡ mất kết cục của một lần gửi rất
  /// nhanh. Nếu app bị tắt thì chẳng ai đợi Future này — hàng chờ trên đĩa mới
  /// là thứ giữ cho bài không mất.
  Future<PendingSubmitOutcome> outcomeFor(String studentExamSessionId) =>
      _waiters
          .putIfAbsent(
            studentExamSessionId,
            () => Completer<PendingSubmitOutcome>(),
          )
          .future;

  /// Ghi lệnh nộp xuống đĩa. Tách khỏi [queue] để test điều khiển được thời
  /// điểm gửi.
  Future<void> save(PendingSubmit submit) => PendingSubmitStore.save(submit);

  /// Ghi lệnh nộp xuống đĩa rồi thử gửi ngay.
  ///
  /// Trả về Future kết cục để màn kết quả điền điểm vào khi gửi xong. CỐ Ý
  /// không `await` phần ghi đĩa: sinh viên phải được sang màn kết quả ngay, còn
  /// việc gửi thì máy tự lo.
  Future<PendingSubmitOutcome> queue(PendingSubmit submit) {
    final outcome = outcomeFor(submit.studentExamSessionId);
    // [startAutoRetry] tự gõ một nhát đầu tiên, nên không gọi thêm [flush] ở
    // đây: hai lượt chồng nhau lúc đang mất mạng chỉ tổ gửi hai request hỏng.
    unawaited(save(submit).then((_) => startAutoRetry()));
    return outcome;
  }

  /// Bật theo dõi mạng + nhịp gõ lại, rồi thử gửi ngay một lần.
  ///
  /// Gọi được nhiều lần (lúc mở app, lúc xếp thêm lệnh nộp): lần thứ hai trở đi
  /// không dựng thêm subscription nào.
  void startAutoRetry() {
    if (!_watching) {
      _watching = true;
      try {
        _connectivity = Connectivity().onConnectivityChanged.listen(
          (List<ConnectivityResult> results) {
            final online = results.any((r) => r != ConnectivityResult.none);
            if (!online) return;
            unawaited(flush());
          },
          // Máy không có plugin connectivity (test, nền tảng lạ) thì vẫn còn
          // nhịp gõ lại bên dưới — không được để cả cơ chế chết theo.
          onError: (Object e) =>
              debugPrint('Không theo dõi được kết nối mạng: $e'),
        );
      } catch (e) {
        debugPrint('Không theo dõi được kết nối mạng: $e');
      }

      _timer = Timer.periodic(retryInterval, (_) => unawaited(flush()));
    }

    unawaited(flush());
  }

  void stopAutoRetry() {
    _connectivity?.cancel();
    _connectivity = null;
    _timer?.cancel();
    _timer = null;
    _watching = false;
  }

  /// Thử gửi toàn bộ hàng chờ MỘT lượt.
  ///
  /// Chạy một mình một cõi ([_flushing]): hai lượt chạy chồng nhau sẽ cùng đọc
  /// một lệnh nộp rồi gửi hai lần.
  Future<void> flush() async {
    if (_flushing) {
      // Có lệnh nộp mới xếp vào giữa lượt đang chạy: chạy thêm một lượt nữa
      // ngay sau đó thay vì bắt sinh viên chờ hết nhịp gõ lại.
      _flushAgain = true;
      return;
    }

    _flushing = true;
    try {
      do {
        _flushAgain = false;
        await _flushOnce();
      } while (_flushAgain);
    } finally {
      _flushing = false;
    }

    // Hết nợ thì tắt luôn bộ theo dõi: không có lý do gì để giữ một
    // subscription mạng và một Timer chạy suốt phần đời còn lại của app.
    if (_watching && !await hasPending) stopAutoRetry();
  }

  Future<void> _flushOnce() async {
    final pending = await PendingSubmitStore.load();
    if (pending.isEmpty) return;

    for (final submit in pending) {
      final outcome = await _userService.submitExam(
        submit.studentExamSessionId,
        deviceInfo: submit.deviceInfo,
        studentAnswersString: submit.studentAnswersString,
        // Mốc GỐC, không phải giờ gửi lại — xem [PendingSubmit.clientSubmittedAt].
        clientSubmittedAt: submit.clientSubmittedAt,
      );

      switch (outcome.status) {
        case SubmitExamStatus.retryable:
          // Vẫn chưa tới được máy chủ: GIỮ NGUYÊN trên đĩa, thử lại lượt sau.
          break;

        case SubmitExamStatus.accepted:
          await PendingSubmitStore.remove(submit.studentExamSessionId);
          // Xoá khỏi đĩa TRƯỚC khi hỏi điểm: bài đã nằm trên máy chủ rồi, lấy
          // điểm hỏng cũng tuyệt đối không được gửi lại lần hai.
          double? score;
          try {
            final grade = await _userService.getSubmissionResult(
              submit.studentExamSessionId,
            );
            score = grade?.score;
          } catch (e) {
            debugPrint('Nộp xong nhưng chưa lấy được điểm: $e');
          }
          _complete(
            submit.studentExamSessionId,
            PendingSubmitOutcome.accepted(score: score),
          );

        case SubmitExamStatus.rejected:
          // Máy chủ nói thẳng là không nhận (phòng đã đóng và bài không đủ điều
          // kiện nhận trễ). Thử lại cũng chỉ nhận đúng câu trả lời đó, nên xoá
          // khỏi hàng chờ và nói thật với sinh viên.
          await PendingSubmitStore.remove(submit.studentExamSessionId);
          _complete(
            submit.studentExamSessionId,
            PendingSubmitOutcome.rejected(outcome.message),
          );
      }
    }
  }

  void _complete(String studentExamSessionId, PendingSubmitOutcome outcome) {
    final waiter = _waiters.remove(studentExamSessionId);
    if (waiter != null && !waiter.isCompleted) waiter.complete(outcome);
  }
}
