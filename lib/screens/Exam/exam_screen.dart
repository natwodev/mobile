import 'dart:async';
import 'package:flutter/material.dart';

import '../../widget/common/app_top_bar.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/auth/user_services.dart';
import '../../services/base_service.dart';
import '../../services/notification_sound_service.dart';
import '../../services/pending_submit_service.dart';
import '../../services/realtime/exam_realtime_events.dart';
import '../../services/realtime/exam_realtime_service.dart';
import '../../models/DTOs/originalExamPaperDto.dart';
import '../../widget/common/app_buttons.dart';
import '../../widget/common/app_busy_overlay.dart';
import '../../widget/common/app_modal.dart';
import '../../widget/common/app_toast.dart';
import '../../widget/common/marquee_text.dart';
import '../../widget/exam/flatten_questions.dart';
import '../../widget/exam/question_card.dart';
import '../../widget/exam/pinned_questions_store.dart';
import '../../widget/exam/answers_serializer.dart';
import '../../widget/exam/question_navigator.dart';
import '../../widget/exam/quiz_theme.dart';
import 'exam_result_screen.dart';

/// Ai ra lệnh nộp bài.
enum ExamSubmitTrigger {
  /// Sinh viên tự bấm "Nộp bài".
  manual,

  /// Đồng hồ đếm ngược về 0.
  timeUp,
}

/// Kết quả của MỘT lời đề nghị nộp bài gửi tới [ExamSubmitCoordinator].
enum ExamSubmitOutcome {
  /// Đã gửi lên máy chủ và máy chủ ghi nhận.
  submitted,

  /// Đã gửi (kể cả sau khi thử lại) nhưng máy chủ không ghi nhận.
  failed,

  /// Có một lần nộp khác đang chạy — lời đề nghị này bị bỏ qua.
  alreadyRunning,

  /// Bài đã nộp thành công trước đó — không gửi lại nữa.
  alreadySubmitted,
}

/// Cổng chống nộp trùng: đảm bảo `submit-exam` chỉ được gửi MỘT lần dù đồng hồ
/// về 0 và sinh viên bấm "Nộp bài" gần như cùng lúc.
///
/// Lớp này cố ý KHÔNG biết gì về Flutter để kiểm chứng được bằng unit test.
/// Toàn bộ quyết định "có được gửi hay không" nằm ở đây, màn thi chỉ lo phần
/// hiển thị.
///
/// Vì sao phải chặt chẽ: `submit-exam` của backend đóng phiên thi, gửi hai lần
/// vừa vô nghĩa vừa tạo ra hai luồng điều hướng cùng đẩy sinh viên sang màn kết
/// quả.
///
/// Web chống nộp trùng bằng đúng hai cờ này:
/// `frontend_manage/src/hooks/useQuiz.ts:962-963` — `if (isSubmitting ||
/// submitted) return;` — kèm khoá nút ở
/// `src/components/quiz/QuestionSidebar.tsx:130-136` (`disabled={isSubmitting}`,
/// ẩn hẳn nút khi `submitted`). Mobile giữ nguyên mô hình đó, chỉ tách phần
/// quyết định ra khỏi `State` để unit test được.
class ExamSubmitCoordinator {
  ExamSubmitCoordinator(this._send);

  /// Hàm thực sự gửi bài lên máy chủ; trả `true` khi máy chủ đã ghi nhận.
  final Future<bool> Function(ExamSubmitTrigger trigger) _send;

  bool _inFlight = false;
  bool _submitted = false;
  ExamSubmitTrigger? _activeTrigger;

  /// Đang có một lần nộp chạy dở.
  bool get isSubmitting => _inFlight;

  /// Bài đã được máy chủ ghi nhận.
  bool get hasSubmitted => _submitted;

  /// Không được phép làm bài / gửi thêm lần nộp nào nữa.
  bool get isLocked => _inFlight || _submitted;

  /// Nguồn phát của lần nộp đang chạy (null nếu đang rảnh).
  ExamSubmitTrigger? get activeTrigger => _activeTrigger;

  /// Máy chủ đã tự đóng bài (giám thị nộp hộ, tự nộp do vi phạm, bị chặn).
  ///
  /// Khoá luôn cổng này để mọi nguồn nộp còn lại — đồng hồ về 0 hay sinh viên
  /// bấm "Nộp bài" — không gửi thêm `submit-exam` vào một phiên đã đóng.
  void markClosedByServer() {
    _submitted = true;
  }

  /// Xin phép nộp bài.
  ///
  /// Cờ [_inFlight] được bật NGAY trong nhịp đồng bộ đầu tiên (trước `await`),
  /// nhờ đó hai lời gọi trong cùng một vòng lặp sự kiện — đúng tình huống "hết
  /// giờ trùng lúc bấm nộp" — chỉ có một lời được đi tiếp.
  Future<ExamSubmitOutcome> submit(ExamSubmitTrigger trigger) async {
    if (_submitted) return ExamSubmitOutcome.alreadySubmitted;
    if (_inFlight) return ExamSubmitOutcome.alreadyRunning;

    _inFlight = true;
    _activeTrigger = trigger;

    try {
      final accepted = await _send(trigger);
      if (accepted) {
        _submitted = true;
        return ExamSubmitOutcome.submitted;
      }
      // Máy chủ đã đóng bài NGAY TRONG LÚC request đang bay (giám thị nộp hộ,
      // hoặc tự nộp do vi phạm): backend trả "đã nộp bài thi trước đó" — đó
      // không phải nộp hỏng. Báo hỏng ở đây là dựng hộp thoại "Thử lại" cho
      // một bài đã nộp xong, bấm bao nhiêu lần cũng không đi tới đâu.
      if (_submitted) return ExamSubmitOutcome.alreadySubmitted;
      return ExamSubmitOutcome.failed;
    } finally {
      // Nộp hỏng thì mở khoá để sinh viên còn thử lại được; nộp xong thì
      // [_submitted] mới là cái khoá vĩnh viễn.
      _inFlight = false;
      _activeTrigger = null;
    }
  }
}

class ExamScreen extends StatefulWidget {
  final String sessionId; // String (Guid)
  final StartExamResponseDto? initialData;

  const ExamScreen({super.key, required this.sessionId, this.initialData});

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> {
  late Future<StartExamResponseDto?> _futureSessions;
  Map<String, String> selectedAnswers = {}; // Map: questionId -> answerValue
  int currentQuestionIndex = 0;
  late PageController _pageController;

  int _secondsLeft = 0;
  Timer? _timer;
  int _initialTime = 0;

  String? _cachedToken;
  Future<String?>? _tokenFuture;

  /// Đề thi đang làm, giữ lại để các handler realtime dùng.
  StartExamResponseDto? _examData;

  ExamRealtimeService? _realtime;
  StreamSubscription<ExamRealtimeEvent>? _realtimeSub;

  /// Máy chủ đã đóng bài từ xa — chặn xử lý trùng khi có nhiều sự kiện dội về.
  bool _closedByServer = false;

  /// Giám thị CHẶN thí sinh. Tách khỏi [_closedByServer] vì backend nộp bài hộ
  /// rồi mới bắn `StudentBlocked`: dùng chung một cờ thì thứ tự hai gói tin
  /// quyết định sinh viên bị đá về trang chủ hay được xem kết quả.
  bool _blockedByProctor = false;

  /// Đang rời màn thi — chốt chống điều hướng hai lần.
  bool _leaving = false;

  /// Hộp thoại cảnh báo vi phạm đang mở.
  bool _violationDialogOpen = false;

  /// Mốc thời gian các sự kiện cộng/trừ giờ đã xử lý, để không cộng hai lần.
  final Set<String> _handledExtraTimeStamps = <String>{};

  /// Câu đã ghim để quay lại xem sau. Chỉ lưu ở máy, không gửi lên máy chủ —
  /// giống hệt bản web (`useQuiz.ts:56-79`).
  Set<String> _pinnedQuestions = <String>{};

  late final UserService userService;

  /// Danh sách ĐƠN VỊ HIỂN THỊ của đề (xem [FlattenedQuestionUnit]).
  ///
  /// Làm phẳng đúng MỘT lần cho mỗi đề rồi giữ lại: `_buildBody` chạy sau mọi
  /// `setState` (mỗi lần gõ một ký tự vào câu điền chỗ trống cũng vậy), làm
  /// phẳng lại mỗi lần vừa tốn công vừa dựng lại DTO mới khiến các widget câu
  /// hỏi có trạng thái (Matching, Ordering) bị coi là "câu khác".
  List<FlattenedQuestionUnit> _units = const <FlattenedQuestionUnit>[];
  StartExamResponseDto? _unitsSource;

  List<FlattenedQuestionUnit> _unitsOf(StartExamResponseDto examData) {
    if (!identical(_unitsSource, examData)) {
      _unitsSource = examData;
      _units = flattenQuestions(examData.originalExamPaper.details);
    }
    return _units;
  }

  /// Trạng thái lưu của TỪNG đáp án (khoá có thể là id câu con).
  ///
  /// Giao diện vẫn hiện lựa chọn của sinh viên ngay lập tức, nhưng bảng này là
  /// nguồn sự thật cho câu hỏi "máy chủ đã nhận chưa?" — nhờ đó không còn cảnh
  /// mất đáp án âm thầm.
  final Map<String, AnswerSaveState> _answerSaveStates = {};
  StreamSubscription<AnswerSaveStatus>? _saveStatusSubscription;
  bool _isRetryingSaves = false;

  // ================= HẾT GIỜ & NỘP BÀI =================

  /// Đồng hồ đã về 0 — từ lúc này giao diện làm bài bị khoá.
  bool _timeExpired = false;

  /// Đang gửi `submit-exam` (dùng để phủ lớp chờ lên màn hình).
  bool _isSubmitting = false;

  /// Lần nộp gần nhất thất bại — banner "thử lại" đang hiện.
  bool _submitFailed = false;

  /// Ngoại lệ của lần nộp gần nhất, nếu có (để báo đúng nguyên nhân).
  String? _submitError;

  /// Nguồn phát của lần nộp gần nhất, dùng cho nút "Thử lại".
  ExamSubmitTrigger _lastSubmitTrigger = ExamSubmitTrigger.manual;

  late final ExamSubmitCoordinator _submitCoordinator;

  /// Số lần gửi `submit-exam` khi TỰ ĐỘNG nộp (1 lần đầu + 2 lần thử lại).
  /// Nộp tay chỉ gửi một lần rồi hỏi ý sinh viên, vì sinh viên đang ngồi trước
  /// màn hình và tự quyết định được.
  static const int _autoSubmitMaxAttempts = 3;

  static const List<Duration> _autoSubmitRetryDelays = [
    Duration(seconds: 1),
    Duration(seconds: 3),
  ];

  /// Chuỗi nhận dạng thiết bị gửi kèm `submit-exam`.
  ///
  /// Phải TRÙNG với chuỗi đã dùng lúc tạo phiên, nếu không backend tách
  /// `StudentExamSessionDevices` thành hai dòng cho cùng một máy.
  static const String _deviceInfo = 'Mobile | Flutter App';

  /// Giao diện làm bài đã bị khoá (hết giờ hoặc đang/đã nộp).
  bool get _examLocked => _timeExpired || _submitCoordinator.isLocked;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    userService = UserService();
    _submitCoordinator = ExamSubmitCoordinator(_sendSubmitRequest);
    _saveStatusSubscription = userService.answerSaveStatuses.listen(
      _onAnswerSaveStatus,
    );

    final baseService = BaseService();
    _tokenFuture = baseService.getToken().then((token) {
      _cachedToken = token;
      return token;
    });

    if (widget.initialData != null) {
      _futureSessions = Future.value(widget.initialData);
      _examData = widget.initialData;
      _setupCountdown(widget.initialData!);
      _setupRealtime(widget.initialData!);
      _loadPreviousAnswers(widget.initialData!);
    } else {
      _futureSessions = userService.startExam(widget.sessionId);
      _futureSessions.then((examData) {
        if (examData != null) {
          _examData = examData;
          _setupCountdown(examData);
          _setupRealtime(examData);
          _loadPreviousAnswers(examData);
        }
      });
    }

    // Chạy sau cùng: _loadPreviousAnswers ở trên là đồng bộ, nên các đáp án
    // còn nợ (mới hơn) sẽ đè lên bài làm tải từ máy chủ chứ không bị ngược lại.
    unawaited(_restorePendingAnswers());
    unawaited(_loadPinnedQuestions());
  }

  Future<void> _loadPinnedQuestions() async {
    final pinned = await PinnedQuestionsStore.load(widget.sessionId);
    if (!mounted || pinned.isEmpty) return;
    setState(() => _pinnedQuestions = pinned);
  }

  /// Bật/tắt ghim cho một câu, lưu xuống máy ngay như web.
  void _togglePin(String questionId) {
    if (questionId.isEmpty) return;

    setState(() {
      if (!_pinnedQuestions.remove(questionId)) {
        _pinnedQuestions.add(questionId);
      }
    });
    unawaited(PinnedQuestionsStore.save(widget.sessionId, _pinnedQuestions));
  }

  /// Đọc lại các câu còn nợ máy chủ từ lần chạy trước và bật tự động gửi lại.
  ///
  /// Có hai kịch bản thật: mất mạng giữa giờ thi (đáp án nằm trong hàng đợi),
  /// và app bị hệ điều hành thu hồi khi chạy nền (hàng đợi đã ghi xuống đĩa).
  Future<void> _restorePendingAnswers() async {
    final restored = await userService.restorePendingAnswers(widget.sessionId);

    // Bật theo dõi mạng dù không có câu nào nợ: mất mạng có thể xảy ra sau đó.
    userService.startPendingAnswerSync(widget.sessionId);

    if (restored == 0 || !mounted) return;

    final pending = userService.pendingAnswerValues(widget.sessionId);
    setState(() {
      selectedAnswers.addAll(pending);
    });

    // Thử gửi ngay: mạng có thể đã trở lại từ trước khi mở app.
    unawaited(userService.retryFailedAnswers(widget.sessionId));
  }

  /// Dựng đồng hồ đếm ngược theo ĐÚNG công thức của frontend web
  /// (`frontend_manage/src/hooks/useQuiz.ts:383-391`):
  ///
  ///   startTime = studentSession.startTime ?? bây giờ
  ///   tổng      = (duration + extraMinutes) * 60
  ///   còn lại   = max(0, tổng - đã trôi qua)
  ///
  /// Trước đây mobile lệch web ở BỐN điểm, và cả bốn đều trở thành nguy hiểm
  /// từ khi có tự động nộp bài khi hết giờ:
  ///  1. Không cộng `extraMinutes` → sinh viên được giáo viên cộng giờ bị nộp SỚM.
  ///  2. Mốc theo `examSessionStartTime` (giờ mở CA THI) thay vì giờ sinh viên
  ///     thực sự vào thi → vào muộn là mất trắng phần thời gian đó.
  ///  3. Không xét `isUnlimitedTime` → ca không giới hạn giờ vẫn bị đếm và tự nộp.
  ///  4. Nhánh QR lấy thời lượng từ ĐỀ thay vì từ PHIÊN THI.
  /// Hai nhánh cũ (`_setupCountdownFromSession` / `_setupCountdownFromQr`) đã
  /// được gộp làm một vì cùng một phiên thi thì không có lý do gì đếm khác nhau.
  void _setupCountdown(StartExamResponseDto examData) {
    final session = examData.studentSession;

    // Ca thi không giới hạn thời gian thì không có đồng hồ, và tuyệt đối
    // không được tự nộp bài.
    if (session.isUnlimitedTime) return;

    final totalMinutes = session.duration + session.extraMinutes;
    if (totalMinutes <= 0) return;

    final now = DateTime.now();
    final startTime = session.startTime ?? now;

    final totalSeconds = totalMinutes * 60;
    final elapsedSeconds = now.difference(startTime).inSeconds;
    final remainSeconds = totalSeconds - elapsedSeconds;

    _initialTime = totalSeconds;

    if (remainSeconds > 0) {
      _startCountDown(remainSeconds);
    }
  }

  void _startCountDown(int seconds) {
    setState(() {
      _secondsLeft = seconds;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_secondsLeft > 1) {
        setState(() {
          _secondsLeft--;
        });
        return;
      }

      // Nhịp đưa đồng hồ về đúng 00:00 cũng là nhịp kích hoạt tự nộp bài.
      timer.cancel();
      setState(() {
        _secondsLeft = 0;
      });
      _handleTimeUp();
    });
  }

  String _formatTime(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  void dispose() {
    _timer?.cancel();
    _saveStatusSubscription?.cancel();
    _realtimeSub?.cancel();
    // Rời nhóm rồi đóng kết nối; không chờ vì dispose không được async.
    unawaited(_realtime?.disconnect() ?? Future<void>.value());
    _realtime = null;
    unawaited(NotificationSoundService.dispose());
    userService.forgetFailedAnswers(widget.sessionId);
    _pageController.dispose();
    super.dispose();
  }

  // ================= TRẠNG THÁI LƯU ĐÁP ÁN =================

  void _onAnswerSaveStatus(AnswerSaveStatus status) {
    if (status.studentExamSessionId != widget.sessionId) return;
    if (!mounted) return;

    if (status.state == AnswerSaveState.failed && status.error != null) {
      // Chỉ ghi log: dải báo cố tình không đổi chữ theo từng lỗi để khỏi nhấp nháy.
      debugPrint('Lưu đáp án thất bại: ${status.error}');
    }

    setState(() {
      _answerSaveStates[status.questionId] = status.state;
    });
  }

  bool get _hasSaveInFlight =>
      _answerSaveStates.values.any((state) => state == AnswerSaveState.saving);

  /// Id câu CẤP 1 có ít nhất một đáp án chưa lưu được lên máy chủ.
  Set<String> _unsavedQuestionIds(ExamProgress progress) {
    final result = <String>{};
    _answerSaveStates.forEach((answerId, state) {
      if (state != AnswerSaveState.failed) return;
      final index = progress.questionIndexOf(answerId);
      if (index == null) return;
      result.add(progress.questionIdAt(index));
    });
    return result;
  }

  Future<void> _retryUnsavedAnswers() async {
    if (_isRetryingSaves) return;

    final l10n = AppLocalizations.of(context);
    setState(() => _isRetryingSaves = true);

    await userService.retryFailedAnswers(widget.sessionId);

    if (!mounted) return;
    final remaining = userService.failedAnswerCount(widget.sessionId);
    setState(() => _isRetryingSaves = false);

    AppToast.show(
      context,
      kind: remaining == 0 ? AppToastKind.success : AppToastKind.error,
      title: remaining == 0
          ? l10n.examAllAnswersSaved
          : l10n.examOfflineRetryFailed,
    );
  }

  /// Dải báo mất kết nối.
  ///
  /// KHÔNG hiện số câu và KHÔNG hiện thông báo lỗi thay đổi theo từng lần lưu:
  /// con số tụt dần khi hàng đợi được gửi đi (6 → 1 → hết) làm dải báo nhấp
  /// nháy ngay giữa lúc sinh viên đang làm bài. Sinh viên chỉ cần biết đúng hai
  /// điều: đang mất kết nối, và đáp án không mất đi đâu cả.
  Widget _buildUnsavedBanner(AppLocalizations l10n) {
    // Khi đang nộp / đã nộp thì gửi lại đáp án không còn ý nghĩa (phiên thi đã
    // đóng), nên chỉ giữ lại phần thông tin.
    final canRetry = !_isRetryingSaves && !_examLocked;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedNoInternet,
            color: Colors.red.shade700,
            size: 22.0,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.examOfflineBannerTitle,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.examOfflineBannerHint,
                  style: TextStyle(fontSize: 12, color: Colors.red.shade700),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _isRetryingSaves
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : TextButton(
                  onPressed: canRetry ? _retryUnsavedAnswers : null,
                  // Banner này chỉ có một sắc đỏ, nên lấy thẳng biến thể đỏ
                  // dùng chung thay vì tự chọn một sắc độ riêng cho mỗi nút.
                  style: AppButtons.quietDanger,
                  child: Text(l10n.commonRetry),
                ),
        ],
      ),
    );
  }

  // ================= HẾT GIỜ =================

  // ================= REALTIME: SỰ KIỆN TỪ GIÁM THỊ =================

  /// Nối SignalR cho phiên thi này.
  void _setupRealtime(StartExamResponseDto examData) {
    final session = examData.studentSession;

    // Thiếu một trong hai id là tên nhóm sai; máy chủ vẫn nhận kết nối nhưng
    // sẽ không đẩy sự kiện nào về, nên thà không nối còn hơn nối vô ích.
    if (session.studentId.isEmpty || session.examSessionSubjectId.isEmpty) {
      debugPrint('Bỏ qua realtime: thiếu studentId hoặc examSessionSubjectId');
      return;
    }

    final service = ExamRealtimeService(
      studentExamSessionId: widget.sessionId,
      examSessionSubjectId: session.examSessionSubjectId,
      studentId: session.studentId,
    );

    _realtime = service;
    _realtimeSub = service.events.listen(_onRealtimeEvent);
    unawaited(service.connect());
  }

  void _onRealtimeEvent(ExamRealtimeEvent event) {
    if (!mounted) return;

    // Một ngoại lệ lọt ra từ đây không giết subscription, nhưng nó cắt handler
    // giữa chừng: cờ đã bật mà điều hướng chưa chạy là sinh viên kẹt trên màn
    // thi bị khoá, nút back lại đang bị WillPopScope chặn.
    try {
      switch (event) {
        case ExtraTimeEvent():
          _applyExtraTime(event);
        case TeacherSubmittedEvent():
          unawaited(_onExamClosedByServer(event));
        case StudentBlockedEvent():
          unawaited(_onBlockedByProctor(event));
        case ViolationWarningEvent():
          _showViolationWarning(event);
        case TeacherMessageEvent():
          _showTeacherMessage(event);
        case ExamScoreEvent():
        case ViolationConfigChangedEvent():
          // Điểm vẫn lấy bằng HTTP ở màn kết quả cho thống nhất một đường; cấu
          // hình cảnh báo chỉ có tác dụng khi bật phát hiện vi phạm phía máy —
          // mobile chưa bật (xem widget/exam/anti_cheat_detector.dart).
          break;
      }
    } catch (e, stack) {
      debugPrint('Lỗi khi xử lý sự kiện realtime: $e\n$stack');
    }
  }

  /// Giám thị cộng/trừ giờ: sửa thẳng bộ đếm đang chạy.
  ///
  /// Cộng cả vào [_initialTime] để `timeSpent = _initialTime - _secondsLeft`
  /// ở màn kết quả không lệch đúng bằng lượng thời gian vừa thay đổi.
  void _applyExtraTime(ExtraTimeEvent event) {
    if (event.minutes == 0) return;

    // KHỬ TRÙNG: backend có hai đường xử lý song song (consumer RabbitMQ và
    // bản đồng bộ dự phòng) nên một lần cộng giờ có thể dội về hai lần — cộng
    // hai lần là sinh viên được gấp đôi thời gian.
    final String? stamp = event.timestamp;
    if (stamp != null && !_handledExtraTimeStamps.add(stamp)) return;

    final l10n = AppLocalizations.of(context);
    final session = _examData?.studentSession;
    final bool hasClock = session != null && !session.isUnlimitedTime;

    // Đã nộp xong thì không còn gì để cộng.
    if (!hasClock || _submitCoordinator.hasSubmitted || _closedByServer) return;

    final int delta = event.minutes * 60;
    _timer?.cancel();
    final int next = _secondsLeft + delta;

    setState(() {
      // Chặn cận dưới: trừ quá tay làm _initialTime âm thì màn kết quả hiện
      // thời gian làm bài âm.
      final int elapsed = _initialTime - _secondsLeft;
      final int grown = _initialTime + delta;
      _initialTime = grown < elapsed ? elapsed : grown;
      _secondsLeft = next > 0 ? next : 0;

      // Được cộng giờ sau khi đã hết giờ mà bài CHƯA nộp được (nộp hỏng) thì
      // mở khoá cho làm tiếp — đây chính là lý do giám thị cộng giờ.
      if (_secondsLeft > 0 && _timeExpired) _timeExpired = false;
    });

    if (_secondsLeft <= 0) {
      unawaited(_handleTimeUp());
      return;
    }
    _startCountDown(_secondsLeft);

    AppToast.show(
      context,
      kind: event.isAdded ? AppToastKind.success : AppToastKind.warning,
      title: event.isAdded
          ? l10n.examRealtimeExtraTimeAdded(event.minutes)
          : l10n.examRealtimeExtraTimeSubtracted(event.minutes.abs()),
      description: event.reason.isEmpty ? null : event.reason,
      duration: const Duration(seconds: 5),
    );
  }

  /// Máy chủ đã đóng bài: giám thị nộp hộ, hoặc tự nộp do vi phạm.
  ///
  /// Ở đây TUYỆT ĐỐI không gọi `submit-exam` nữa — phiên đã đóng, gọi thêm chỉ
  /// nhận lỗi rồi rơi vào hộp thoại "Thử lại" mà bấm bao nhiêu lần cũng hỏng.
  Future<void> _onExamClosedByServer(TeacherSubmittedEvent event) async {
    if (_closedByServer || _blockedByProctor || _leaving) return;
    _closedByServer = true;
    _submitCoordinator.markClosedByServer();
    _timer?.cancel();

    setState(() {
      _timeExpired = true;
    });

    final l10n = AppLocalizations.of(context);
    AppToast.show(
      context,
      kind: event.forced ? AppToastKind.error : AppToastKind.warning,
      title: event.forced
          ? l10n.examRealtimeAutoSubmittedTitle
          : l10n.examRealtimeTeacherSubmittedTitle,
      description: event.reason.isEmpty ? null : event.reason,
      duration: const Duration(seconds: 5),
    );

    // Chờ một nhịp cho sinh viên kịp đọc rồi mới chuyển màn.
    await Future<void>.delayed(const Duration(seconds: 2));
    // Trong 2 giây đó có thể đã bị chặn hẳn, hoặc một nhánh khác đã chuyển màn.
    if (!mounted || _blockedByProctor || _leaving) return;

    final examData = _examData;
    if (examData == null) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }
    await _openResultScreen(examData);
  }

  /// Giám thị chặn thí sinh. Máy chủ đã nộp bài hộ trước khi bắn sự kiện này.
  ///
  /// Ưu tiên hơn [_onExamClosedByServer]: bị chặn thì về thẳng trang chủ, không
  /// có kết quả để xem, kể cả khi sự kiện nộp hộ tới trước.
  Future<void> _onBlockedByProctor(StudentBlockedEvent event) async {
    if (_blockedByProctor || _leaving) return;

    // Còn join cả nhóm `student_all` nên phải chắc chắn đúng ca thi của mình.
    final String? current = _examData?.studentSession.examSessionSubjectId;
    if (event.examSessionSubjectId.isNotEmpty &&
        current != null &&
        current.isNotEmpty &&
        event.examSessionSubjectId.toLowerCase() != current.toLowerCase()) {
      return;
    }

    _blockedByProctor = true;
    _submitCoordinator.markClosedByServer();
    _timer?.cancel();

    setState(() {
      _timeExpired = true;
    });

    final l10n = AppLocalizations.of(context);
    // Web cho thông báo này một kiểu riêng, KHÁC hẳn toast thường: nền đỏ đặc
    // #ef4444, chữ trắng in đậm 18px, canh GIỮA TRÊN, 5 giây
    // (`useQuiz.ts:787-797`). Đây là thông báo nặng nhất của cả màn thi nên
    // không để nó trôi lẫn với đám toast góc phải.
    AppToast.show(
      context,
      kind: AppToastKind.error,
      title: l10n.examRealtimeBlockedTitle,
      description: l10n.examRealtimeBlockedMessage,
      duration: const Duration(seconds: 5),
      alignment: Alignment.topCenter,
      backgroundColor: const Color(0xFFEF4444),
      foregroundColor: Colors.white,
      titleTextStyle: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.bold,
      ),
    );

    await Future<void>.delayed(const Duration(seconds: 3));
    if (!mounted || _leaving) return;
    _leaving = true;
    // Về thẳng màn đầu: bài đã bị dừng, không có kết quả để xem.
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  /// Chạm ngưỡng vi phạm. Máy chủ chỉ gửi MỘT lần cho mỗi phiên thi, nhưng hai
  /// đường xử lý song song bên backend vẫn có thể làm nó dội về hai lần.
  void _showViolationWarning(ViolationWarningEvent event) {
    if (_violationDialogOpen || _closedByServer || _blockedByProctor) return;
    _violationDialogOpen = true;

    // Web mở modal im lặng; mobile có kêu vì màn nhỏ, sinh viên đang cắm mặt
    // vào câu hỏi rất dễ không thấy hộp thoại vừa bật.
    unawaited(NotificationSoundService.play(NotificationSound.error));

    final l10n = AppLocalizations.of(context);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AppModal(
        title: l10n.examRealtimeViolationWarningTitle,
        icon: HugeIcons.strokeRoundedAlert01,
        accentColor: Colors.red,
        onClose: () => Navigator.pop(dialogContext),
        children: [
          Text(
            l10n.examRealtimeViolationWarningMessage(
              event.violationCount,
              event.threshold,
            ),
          ),
        ],
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.examRealtimeViolationWarningUnderstood),
          ),
        ],
      ),
    ).whenComplete(() {
      if (mounted) _violationDialogOpen = false;
    });
  }

  /// Tin nhắn của giám thị.
  ///
  /// Ánh xạ ĐÚNG theo cấu hình của web (`frontend_manage/src/hooks/useQuiz.ts:
  /// 569-641`): `toastStyle` chọn kiểu, `toastDuration` mặc định 3000ms,
  /// `toastPosition` mặc định "top-right".
  void _showTeacherMessage(TeacherMessageEvent event) {
    final l10n = AppLocalizations.of(context);
    final int duration = (event.durationMs == null || event.durationMs! <= 0)
        ? 3000
        : event.durationMs!;

    // Nhánh gửi cho riêng một sinh viên không kèm tiêu đề nên phải có sẵn chuỗi
    // thay thế, không ghép cứng như bản web (hiện ra "undefined: ...").
    final String title = event.title ?? l10n.examRealtimeTeacherMessageTitle;
    final AppToastKind kind = AppToast.kindFromStyle(event.style);

    // Màu nền giám thị chọn. Chuỗi rỗng/sai định dạng cho ra null, khi đó
    // AppToast dùng lại đúng màu mặc định của `kind` như trước giờ.
    final Color? background = AppToast.parseHexColor(event.color);

    // `promise` là hai pha: vòng xoay "Đang xử lý..." rồi mới tới nội dung.
    if (kind == AppToastKind.promise) {
      unawaited(
        AppToast.showPromise(
          context,
          title: title,
          description: event.message,
          duration: Duration(milliseconds: duration),
          alignment: _toastAlignment(event.position),
          // Chỉ toast KẾT QUẢ mang màu; pha vòng xoay vẫn nền trắng như web.
          backgroundColor: background,
        ),
      );
      return;
    }

    AppToast.show(
      context,
      kind: kind,
      title: title,
      description: event.message,
      duration: Duration(milliseconds: duration),
      alignment: _toastAlignment(event.position),
      backgroundColor: background,
    );
  }

  /// Đổi `toastPosition` của web sang Alignment của Flutter.
  Alignment _toastAlignment(String? position) {
    switch (position) {
      case 'top-left':
        return Alignment.topLeft;
      case 'top-center':
        return Alignment.topCenter;
      case 'bottom-left':
        return Alignment.bottomLeft;
      case 'bottom-center':
        return Alignment.bottomCenter;
      case 'bottom-right':
        return Alignment.bottomRight;
      case 'top-right':
      default:
        return Alignment.topRight;
    }
  }

  /// Đồng hồ về 0: khoá bài, báo cho sinh viên, rồi tự nộp.
  ///
  /// Bản web làm y hệt ở `frontend_manage/src/hooks/useQuiz.ts:868-888` (timer
  /// chạm 0 -> `handleAutoSubmit`) và `:863-867` (`handleAutoSubmit` gọi thẳng
  /// `handleSubmitExam`, KHÔNG hỏi xác nhận).
  Future<void> _handleTimeUp() async {
    if (!mounted || _timeExpired) return;

    setState(() {
      _timeExpired = true;
    });

    final l10n = AppLocalizations.of(context);
    AppToast.show(
      context,
      kind: AppToastKind.warning,
      title: l10n.examTimeUpBannerTitle,
      description: l10n.examTimeUpToastMessage,
      duration: const Duration(seconds: 4),
    );

    await _submitExam(ExamSubmitTrigger.timeUp);
  }

  // ================= NỘP BÀI =================

  /// Vứt hàng đợi đáp án của phiên này đi.
  ///
  /// Gọi ngay khi lần nộp đã chốt (máy chủ nhận, hoặc đã xếp vào hàng chờ):
  /// `submit-exam` mang theo TOÀN BỘ bài làm qua `StudentAnswersString`, nên từ
  /// giây phút đó những câu còn nằm trong hàng đợi `save-answer` không còn nợ
  /// gì nữa. Không dọn thì banner "còn N câu chưa lưu" treo lại trên một bài đã
  /// nộp xong — vừa sai vừa làm sinh viên hoảng.
  void _dropPendingAnswerQueue() {
    userService.forgetFailedAnswers(widget.sessionId);
    if (!mounted) return;
    setState(() {
      _answerSaveStates.clear();
    });
  }

  /// Điểm vào duy nhất của việc nộp bài (cả tự động lẫn bấm tay).
  Future<void> _submitExam(ExamSubmitTrigger trigger) async {
    _lastSubmitTrigger = trigger;

    final outcome = await _submitCoordinator.submit(trigger);
    if (!mounted) return;

    if (outcome == ExamSubmitOutcome.alreadySubmitted) {
      // Bài đã nằm trên máy chủ: gỡ trạng thái hỏng (nếu có) rồi đi tiếp.
      if (_submitFailed) setState(() => _submitFailed = false);

      // Máy chủ tự đóng bài thì nhánh realtime lo phần chuyển màn.
      final examData = _examData;
      if (!_closedByServer && !_blockedByProctor && examData != null) {
        await _openResultScreen(examData);
      }
      return;
    }

    if (outcome == ExamSubmitOutcome.failed) {
      setState(() => _submitFailed = true);
      _showSubmitFailureDialog(trigger);
    }
  }

  /// Gửi `submit-exam` lên máy chủ. Trả `true` khi máy chủ đã ghi nhận.
  ///
  /// GỬI kèm `StudentAnswersString`, giống hệt web (`useQuiz.ts:1017-1022`).
  ///
  /// Endpoint này GHI ĐÈ chứ không gộp, nên chuỗi gửi lên phải là TOÀN BỘ bài
  /// làm. Điều đó đúng: [selectedAnswers] chứa cả đáp án tải về từ máy chủ lúc
  /// vào bài (`_loadPreviousAnswers`) lẫn mọi lựa chọn trong phiên này, kể cả
  /// những câu chưa kịp lưu.
  ///
  /// Trước đây mobile cố ý bỏ trống field này và dựa hẳn vào các lần
  /// `save-answer`. Cách đó chỉ đúng khi mạng ổn định; mất mạng là những câu
  /// còn nằm trong hàng đợi không có mặt trong chuỗi trên máy chủ, nộp xong
  /// mới phát hiện thì đã muộn.
  Future<bool> _sendSubmitRequest(ExamSubmitTrigger trigger) async {
    // CHỐT GIỜ NỘP ngay tại đây, trước mọi `await`: đây vẫn là cùng một nhịp sự
    // kiện với cú bấm "Nộp bài" (hoặc với giây đồng hồ về 0). Mốc này đi theo
    // suốt cả các lần gửi lại — kể cả đường gửi lại sau khi mở lại app — vì
    // backend lấy chính nó làm giờ nộp thật.
    final submittedAt = DateTime.now().toUtc();

    final examData = await _futureSessions;
    if (examData == null) return false;

    if (mounted) {
      setState(() {
        _isSubmitting = true;
        _submitFailed = false;
        _submitError = null;
      });
    }

    // KHÔNG còn chờ hàng đợi `save-answer` lắng xuống trước khi nộp: request
    // nộp đã mang theo cả bài làm qua `StudentAnswersString`, nên chờ thêm chỉ
    // làm sinh viên đứng nhìn màn hình mà không được gì.
    final maxAttempts = trigger == ExamSubmitTrigger.timeUp
        ? _autoSubmitMaxAttempts
        : 1;

    try {
      for (var attempt = 1; attempt <= maxAttempts; attempt++) {
        if (await _postSubmitOnce(examData, submittedAt)) return true;

        if (attempt < maxAttempts) {
          await Future<void>.delayed(_autoSubmitRetryDelay(attempt));
        }
      }
      return false;
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Duration _autoSubmitRetryDelay(int attempt) {
    final index = attempt - 1;
    if (index < 0) return _autoSubmitRetryDelays.first;
    if (index >= _autoSubmitRetryDelays.length) {
      return _autoSubmitRetryDelays.last;
    }
    return _autoSubmitRetryDelays[index];
  }

  Future<bool> _postSubmitOnce(
    StartExamResponseDto examData,
    DateTime submittedAt,
  ) async {
    // Gửi CẢ bài làm, giống web (useQuiz.ts:1017-1022). Trước đây mobile bỏ
    // trống field này và dựa hẳn vào các lần `save-answer` — cách đó sập ngay
    // khi mạng chập chờn, vì câu chưa lưu kịp thì không có trong chuỗi trên máy
    // chủ.
    final answers = serializeAnswers(selectedAnswers);

    try {
      // `deviceInfo`: web gửi `navigator.userAgent` (useQuiz.ts:995-1001); bản
      // mobile gửi đúng chuỗi đã dùng lúc tạo phiên để backend không tách
      // StudentExamSessionDevices thành hai dòng cho cùng một thiết bị.
      final outcome = await userService.submitExam(
        widget.sessionId,
        deviceInfo: _deviceInfo,
        studentAnswersString: answers,
        clientSubmittedAt: submittedAt,
      );

      switch (outcome.status) {
        case SubmitExamStatus.accepted:
          await _onSubmitAccepted(examData);
          return true;

        case SubmitExamStatus.retryable:
          // KHÔNG báo "nộp bài thất bại" nữa: lệnh nộp được ghi xuống đĩa kèm
          // đúng mốc [submittedAt] rồi tự gửi lại khi có mạng. Trả `true` để
          // [ExamSubmitCoordinator] khoá bài lại — với sinh viên thì bài đã nộp
          // xong, chỉ còn máy lo phần đường truyền.
          await _onSubmitQueued(examData, submittedAt, answers);
          return true;

        case SubmitExamStatus.rejected:
          // Máy chủ nói thẳng là không nhận. Xếp hàng chờ ở đây chỉ tổ gửi lại
          // để nhận đúng câu trả lời đó, nên báo hỏng như cũ.
          _submitError = outcome.message;
          return false;
      }
    } catch (e) {
      debugPrint('❌ Lỗi khi nộp bài: $e');
      _submitError = e.toString();
      return false;
    }
  }

  /// Máy chủ đã nhận bài: báo kết quả rồi chuyển sang màn điểm.
  Future<void> _onSubmitAccepted(StartExamResponseDto examData) async {
    _timer?.cancel();
    _dropPendingAnswerQueue();

    final progress = ExamProgress.fromUnits(
      units: _unitsOf(examData),
      answers: selectedAnswers,
    );
    final unsavedCount = _unsavedQuestionIds(progress).length;

    if (mounted) {
      final l10n = AppLocalizations.of(context);
      AppToast.show(
        context,
        kind: unsavedCount > 0 ? AppToastKind.warning : AppToastKind.success,
        title: l10n.examSubmitSuccess,
        // Còn câu lưu hỏng thì phải nói thẳng số lượng: sinh viên có quyền biết
        // bài của mình có thể thiếu câu nào đó khi chấm.
        description: unsavedCount > 0
            ? l10n.examAutoSubmitUnsavedWarning(unsavedCount)
            : null,
        duration: Duration(seconds: unsavedCount > 0 ? 6 : 3),
      );
    }

    await _openResultScreen(examData);
  }

  /// Không gửi được vì mạng: cất lệnh nộp lại rồi vẫn cho sang màn kết quả.
  ///
  /// Sinh viên đã làm xong phần việc của mình, cái thiếu là đường truyền — nên
  /// màn kết quả mở ra ngay, chỗ điểm quay vòng chờ cho tới khi máy gửi được.
  Future<void> _onSubmitQueued(
    StartExamResponseDto examData,
    DateTime submittedAt,
    String answers,
  ) async {
    _timer?.cancel();
    _dropPendingAnswerQueue();

    final outcome = PendingSubmitService.instance.queue(
      PendingSubmit(
        studentExamSessionId: widget.sessionId,
        studentAnswersString: answers,
        deviceInfo: _deviceInfo,
        clientSubmittedAt: submittedAt,
      ),
    );

    if (mounted) {
      final l10n = AppLocalizations.of(context);
      AppToast.show(
        context,
        kind: AppToastKind.warning,
        title: l10n.examSubmitQueuedTitle,
        description: l10n.examSubmitQueuedMessage,
        duration: const Duration(seconds: 6),
      );
    }

    await _openResultScreen(
      examData,
      pendingOutcome: outcome,
      pendingSubmittedAt: submittedAt,
    );
  }

  /// Sang màn kết quả.
  ///
  /// Tách riêng vì có HAI đường dẫn tới đây: sinh viên/đồng hồ nộp bài, và máy
  /// chủ tự đóng bài (giám thị nộp hộ hoặc tự nộp do vi phạm).
  Future<void> _openResultScreen(
    StartExamResponseDto examData, {
    Future<PendingSubmitOutcome>? pendingOutcome,
    DateTime? pendingSubmittedAt,
  }) async {
    // Có tới ba nguồn gọi vào đây (sinh viên nộp, đồng hồ về 0, máy chủ đóng
    // bài) và chúng có thể chạy chồng nhau.
    if (_leaving) return;
    _leaving = true;

    final progress = ExamProgress.fromUnits(
      units: _unitsOf(examData),
      answers: selectedAnswers,
    );

    // Bài chưa lên tới máy chủ thì hỏi điểm cũng chỉ nhận về một lần chờ mạng
    // nữa; điểm sẽ do [PendingSubmitService] lấy hộ sau khi gửi được.
    final submissionData = pendingOutcome != null
        ? null
        : await userService.getSubmissionResult(widget.sessionId);

    if (!mounted) return;

    final timeSpent = _initialTime - _secondsLeft;

    // pushAndRemoveUntil chứ KHÔNG pushReplacement: nếu đang có hộp thoại mở
    // (cảnh báo vi phạm, xác nhận nộp bài) thì pushReplacement chỉ thay đúng
    // HỘP THOẠI đó — màn thi ở dưới sống tiếp, `dispose` không chạy, kết nối
    // SignalR không được đóng, và sự kiện của ca thi cũ còn dội về ca thi sau.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => ExamResultScreen(
          examTitle: examData.originalExamPaper.title,
          // Không có số của máy chủ thì lấy TỔNG SỐ ĐƠN VỊ — đúng tập mà
          // `answeredCount` đang đếm, để màn kết quả không hiện kiểu 3/12.
          totalQuestions: submissionData?.totalQuestions ?? progress.total,
          answeredQuestions: progress.answeredCount,
          timeSpent: timeSpent,
          totalTime: _initialTime,
          score: submissionData?.score ?? 0.0,
          pendingOutcome: pendingOutcome,
          pendingSubmittedAt: pendingSubmittedAt,
        ),
      ),
      (route) => route.isFirst,
    );
  }

  /// Nộp hỏng thì phải NÓI RA, kèm lối thoát là nút "Thử lại".
  void _showSubmitFailureDialog(ExamSubmitTrigger trigger) {
    final l10n = AppLocalizations.of(context);
    final error = _submitError;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AppModal(
          title: l10n.examSubmitFailedTitle,
          icon: HugeIcons.strokeRoundedAlert01,
          accentColor: Colors.red,
          onClose: () => Navigator.pop(dialogContext),
          children: [
            Text(
              error != null
                  ? '${l10n.examSubmitFailedMessage}\n\n${l10n.examSubmitError(error)}'
                  : l10n.examSubmitFailedMessage,
            ),
          ],
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _submitExam(trigger);
              },
              child: Text(l10n.commonRetry),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<StartExamResponseDto?>(
      future: _futureSessions,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          final l10n = AppLocalizations.of(context);
          return Scaffold(
            body: Center(
              child: Text(
                snapshot.hasError
                    ? l10n.examLoadError(snapshot.error.toString())
                    : l10n.examNoData,
              ),
            ),
          );
        }

        final examData = snapshot.data!;
        return _buildExamContent(examData);
      },
    );
  }

  Widget _buildExamContent(StartExamResponseDto examData) {
    final l10n = AppLocalizations.of(context);
    String title = l10n.examDefaultTitle;

    if (widget.initialData != null) {
      title = examData.originalExamPaper.title;
    } else {
      final subjectName = examData.studentSession.subjectName;
      title = subjectName.isNotEmpty
          ? subjectName
          : examData.originalExamPaper.title;
    }

    // Ca không giới hạn thời gian thì KHÔNG có đếm ngược: `_setupCountdown`
    // không chạy đồng hồ, nên `_secondsLeft` đứng yên ở 0. Cả ô đồng hồ được
    // giấu đi luôn — vẽ "00:00" thì sinh viên tưởng hết giờ, mà thay bằng chữ
    // "Không giới hạn" thì ô đó ăn gần nửa header, ép tiêu đề đề thi cụt lủn.
    final isUnlimitedTime = examData.studentSession.isUnlimitedTime;

    // Ngưỡng đổi màu lấy đúng của web: `QuizHeader.tsx:36-41`
    // (<= 5 phút: nguy hiểm, <= 10 phút: cảnh báo).
    final Color timerColor;
    if (_timeExpired) {
      timerColor = Colors.red;
    } else if (_secondsLeft <= 300) {
      timerColor = Colors.red;
    } else if (_secondsLeft <= 600) {
      timerColor = Colors.orange;
    } else {
      timerColor = AppColors.accent;
    }

    return WillPopScope(
      onWillPop: () async {
        AppToast.show(
          context,
          kind: AppToastKind.warning,
          title: l10n.examCannotExitWarning,
          duration: const Duration(seconds: 2),
        );
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppTopBar(
          // Tên đề dài thì chạy ngang mới đọc hết, nên tiêu đề ở đây là widget
          // chứ không phải một chuỗi.
          titleWidget: MarqueeText(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          // Không có nút quay lại: đang trong ca thi, thoát phải đi qua hộp
          // thoại xác nhận chứ không phải một cú bấm.
          actions: [
            if (!isUnlimitedTime)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    // Web dùng Clock01Icon cho đồng hồ (QuizHeader.tsx:63);
                    // hết giờ thì đổi sang Alert01 — cùng bộ icon cảnh báo.
                    HugeIcon(
                      icon: _timeExpired
                          ? HugeIcons.strokeRoundedAlert01
                          : HugeIcons.strokeRoundedClock01,
                      color: timerColor,
                      size: 20.0,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatTime(_secondsLeft),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: timerColor,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        body: Stack(
          children: [
            SafeArea(
              child: Padding(
                // Lề mỏng: nội dung câu hỏi cần bề ngang. Đây là lớp lề DUY
                // NHẤT ở mép màn hình — QuestionCard bên trong đã bỏ lề ngang
                // của nó, nếu không hai lớp cộng lại ăn gần 10% bề rộng máy
                // 360dp mà chẳng nói thêm điều gì.
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: _buildBody(examData),
              ),
            ),
            if (_isSubmitting)
              Positioned.fill(child: _buildSubmitOverlay(l10n)),
          ],
        ),
      ),
    );
  }

  /// Lớp phủ khi đang gửi bài — dùng chung một hình hài với lúc vào phòng thi.
  Widget _buildSubmitOverlay(AppLocalizations l10n) {
    return AppBusyOverlay(
      title: l10n.examSubmitOverlayTitle,
      hint: l10n.examSubmitOverlayHint,
    );
  }

  /// Banner trạng thái hết giờ / nộp hỏng.
  Widget _buildSubmitStatusBanner(AppLocalizations l10n) {
    final failed = _submitFailed;
    final MaterialColor color = failed ? Colors.red : Colors.orange;
    final busy = _isSubmitting;

    final String message;
    if (failed) {
      message = l10n.examSubmitFailedMessage;
    } else if (_isSubmitting) {
      message = l10n.examTimeUpSubmitting;
    } else {
      message = l10n.examTimeUpLockedHint;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.shade50,
        border: Border.all(color: color.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          HugeIcon(
            icon: failed
                ? HugeIcons.strokeRoundedAlert01
                : HugeIcons.strokeRoundedClock01,
            color: color.shade700,
            size: 22.0,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  failed
                      ? l10n.examSubmitFailedTitle
                      : l10n.examTimeUpBannerTitle,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color.shade800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: TextStyle(fontSize: 12, color: color.shade700),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (busy)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if (failed)
            TextButton(
              onPressed: () => _submitExam(_lastSubmitTrigger),
              // Nút này chỉ hiện ở nhánh `failed`, tức banner luôn đang đỏ —
              // dùng thẳng biến thể đỏ dùng chung, không tự pha màu nữa.
              style: AppButtons.quietDanger,
              child: Text(l10n.commonRetry),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(StartExamResponseDto examData) {
    final l10n = AppLocalizations.of(context);
    final folderName = examData.originalExamPaper.originalExamPaperCore
        .split('_')
        .first;
    final mediaBaseUrl = '${BaseService.baseUrl}/EPZ/$folderName';

    // MỌI phép đếm, đánh số và điều hướng chạy trên danh sách ĐÃ LÀM PHẲNG,
    // không còn chạy trên `originalExamPaper.details`: câu Reading đã được
    // tách thành mỗi câu con một trang, Matching/TFNG vẫn gộp một trang.
    final units = _unitsOf(examData);

    if (units.isEmpty) {
      return Center(child: Text(l10n.examNoQuestions));
    }

    final locked = _examLocked;

    // Tiến độ LUÔN được tính lại từ danh sách đơn vị: số "đã trả lời" và tổng
    // số câu vì thế luôn nằm trên cùng một tập, không bao giờ vượt tổng.
    final progress = ExamProgress.fromUnits(
      units: units,
      answers: selectedAnswers,
    );
    // Tổng số ô số thứ tự — mẫu số của nhãn "Câu 3-7 / 40" như web.
    final numberedTotal = progress.numberedTotal;
    final unsavedQuestionIds = _unsavedQuestionIds(progress);

    return Column(
      children: [
        if (_timeExpired || _submitFailed) _buildSubmitStatusBanner(l10n),

        if (unsavedQuestionIds.isNotEmpty) _buildUnsavedBanner(l10n),

        // Tiến độ
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.examQuestionProgress(
                  progress.labelAt(currentQuestionIndex),
                  numberedTotal,
                ),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_hasSaveInFlight) ...[
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l10n.examSavingIndicator,
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Text(
                    l10n.examAnsweredProgress(
                      progress.answeredCount,
                      progress.total,
                    ),
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // PageView câu hỏi
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                currentQuestionIndex = index;
              });
            },
            itemCount: units.length,
            itemBuilder: (context, index) {
              final unit = units[index];

              return SingleChildScrollView(
                child: QuestionCard(
                  unit: unit,
                  answersMap: selectedAnswers,
                  // `submitted: true` khoá mọi thao tác chọn đáp án của mọi
                  // loại câu hỏi — đây là cách khoá bài khi hết giờ.
                  submitted: locked,
                  onAnswerChanged: (qId, val) {
                    // Chốt chặn thứ hai: hết giờ thì không ghi nhận thêm lựa
                    // chọn nào, kể cả khi có widget nào đó quên đọc `submitted`.
                    if (_examLocked) return;

                    setState(() {
                      selectedAnswers[qId] = val;
                    });
                  },
                  mediaBaseUrl: mediaBaseUrl,
                  studentExamSessionId: widget.sessionId,
                  userService: userService,
                  isPinned: _pinnedQuestions.contains(unit.id),
                  onTogglePin: () => _togglePin(unit.id),
                ),
              );
            },
          ),
        ),

        // Điều hướng
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: QuestionNavigator(
            progress: progress,
            pinnedQuestionIds: _pinnedQuestions,
            currentIndex: currentQuestionIndex,
            onQuestionTap: (index) {
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            onPrevious: () {
              _pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            onNext: () {
              _pageController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            // Hết giờ / đang nộp thì không cho bấm nộp nữa.
            onSubmit: locked ? null : () => _showSubmitDialog(context),
          ),
        ),
      ],
    );
  }

  void _loadPreviousAnswers(StartExamResponseDto examData) {
    final answersString = examData.studentSession.studentAnswersString;
    if (answersString == null || answersString.isEmpty) {
      return;
    }

    try {
      final pairs = answersString.split(';');
      for (final pair in pairs) {
        if (pair.isEmpty) continue;

        final cleanPair = pair.replaceAll('(', '').replaceAll(')', '').trim();
        if (cleanPair.isEmpty) continue;

        final parts = cleanPair.split(':');
        if (parts.length >= 2) {
          final key = parts[0].trim();
          final value = parts.sublist(1).join(':').trim();

          if (key.isNotEmpty && value.isNotEmpty) {
            setState(() {
              selectedAnswers[key] = value;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Lỗi parse studentAnswersString: $e');
    }
  }

  /// Một ô số của hộp thoại nộp bài.
  Widget _submitStatTile({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: QuizColors.surfaceRest,
        borderRadius: BorderRadius.circular(QuizRadius.marker),
        border: Border.all(color: QuizColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: QuizColors.inkMuted,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Một dòng lưu ý có nền nhạt cùng tông với icon.
  Widget _submitNotice({
    required List<List<dynamic>> icon,
    required Color color,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(QuizRadius.marker),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HugeIcon(icon: icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: QuizColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSubmitDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context);

    // Đồng hồ vừa về 0 (hoặc một lần nộp đang chạy) thì không mở hộp thoại nữa.
    if (_examLocked) return;

    final examData = await _futureSessions;
    if (examData == null) return;

    final progress = ExamProgress.fromUnits(
      units: _unitsOf(examData),
      answers: selectedAnswers,
    );
    final answeredCount = progress.answeredCount;
    final unsavedCount = _unsavedQuestionIds(progress).length;

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        final total = progress.total;
        final unansweredCount = total - answeredCount;

        return AppModal(
          title: l10n.examSubmitDialogTitle,
          icon: HugeIcons.strokeRoundedSent02,
          onClose: () => Navigator.pop(dialogContext),
          children: [
            // Con số đứng trước câu chữ. Bản cũ gói tiến độ vào một câu văn
            // xuôi ("Bạn đã trả lời 0 câu.") — đọc lướt là trôi tuột, mà đây
            // đúng là thứ duy nhất cần cân nhắc trước khi nộp.
            Row(
              children: [
                Expanded(
                  child: _submitStatTile(
                    label: l10n.examSubmitDialogAnsweredLabel,
                    value: '$answeredCount/$total',
                    color: QuizColors.success,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _submitStatTile(
                    label: l10n.examSubmitDialogUnansweredLabel,
                    value: '$unansweredCount',
                    // Còn câu bỏ trống thì tô cam; hết rồi thì để xám, không
                    // dựng lên một cảnh báo giả cho con số 0.
                    color: unansweredCount > 0
                        ? QuizColors.warning
                        : QuizColors.inkMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (unansweredCount > 0)
              _submitNotice(
                icon: HugeIcons.strokeRoundedAlert01,
                color: QuizColors.warning,
                text: l10n.examSubmitDialogUnansweredWarning(unansweredCount),
              )
            else
              _submitNotice(
                icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                color: QuizColors.success,
                text: l10n.examSubmitDialogAllAnswered,
              ),

            // Cảnh báo "chưa lưu lên máy chủ" nặng hơn hẳn: câu chưa lưu thì
            // nộp xong cũng có thể không được chấm.
            if (unsavedCount > 0) ...[
              const SizedBox(height: 8),
              _submitNotice(
                icon: HugeIcons.strokeRoundedNoInternet,
                color: const Color(0xFFDC2626),
                text: l10n.examSubmitDialogUnsavedWarning(unsavedCount),
              ),
            ],

            const SizedBox(height: 14),
            Text(
              l10n.examSubmitDialogConfirmQuestion,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: QuizColors.ink,
              ),
            ),
          ],
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                // Nếu đồng hồ vừa về 0 trong lúc hộp thoại đang mở, lời gọi này
                // sẽ bị [ExamSubmitCoordinator] bỏ qua — không có lần gửi thứ hai.
                _submitExam(ExamSubmitTrigger.manual);
              },
              // Không khai style nữa: theme đã dựng sẵn nút chính (nền
              // #2563EB, bo 8, cao 48, chữ 15/w700) nên nút "Nộp bài" trong
              // hộp thoại giống hệt nút "Nộp bài" dưới thanh điều hướng.
              child: Text(l10n.examSubmitButton),
            ),
          ],
        );
      },
    );
  }
}
