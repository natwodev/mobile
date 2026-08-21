import 'dart:async';

import 'package:flutter/foundation.dart';
// signalr_client.dart không export IRetryPolicy nên phải lấy thẳng từ file gốc.
import 'package:signalr_netcore/iretry_policy.dart';
import 'package:signalr_netcore/signalr_client.dart';

import '../base_service.dart';
import 'exam_realtime_events.dart';

/// Kết nối SignalR tới `NotificationHub` cho MỘT phiên thi.
///
/// Vòng đời gắn với màn làm bài: [connect] ở initState, [disconnect] ở dispose.
///
/// Ba điểm cố ý làm KHÁC frontend web (đã đối chiếu
/// `frontend_manage/src/hooks/useSignalR.ts`):
///
///  1. **Join lại nhóm trong `onreconnected`.** Web chỉ set cờ `isConnected`
///     (useSignalR.ts:79-82) — mà SignalR reconnect là sinh connectionId mới,
///     server không giữ lại group cũ. Hệ quả bên web: sau một lần rớt mạng,
///     sinh viên im lặng không nhận thêm sự kiện nào. Ở đây join lại ngay.
///  2. **Tên sự kiện chép nguyên văn từ backend.** Gói `signalr_netcore` có hạ
///     chữ thường ở cả hai đầu (hub_connection.dart:483 và :694) nên viết sai
///     hoa/thường vẫn chạy, nhưng chép đúng thì người đọc sau đối chiếu được
///     thẳng với `SendAsync(...)` bên C#.
///  3. **Có gọi `Leave*` khi rời màn thi.** Web không gọi bao giờ, phó mặc cho
///     server dọn khi ngắt kết nối.
class ExamRealtimeService {
  ExamRealtimeService({
    required this.studentExamSessionId,
    required this.examSessionSubjectId,
    required this.studentId,
    String? baseUrl,
  }) : _baseUrl = baseUrl ?? BaseService.baseUrl;

  final String studentExamSessionId;
  final String examSessionSubjectId;

  /// Guid của sinh viên — chính là `NameIdentifier` trong JWT.
  ///
  /// Máy chủ đặt tên nhóm theo `StudentExamSession.StudentId`, KHÔNG phải Id
  /// của ApplicationUser (comment trong NotificationHub.cs ghi nhầm). Gửi sai
  /// giá trị này thì kết nối vẫn "thành công" nhưng không nhận được gì cả.
  final String studentId;

  final String _baseUrl;

  HubConnection? _connection;
  Timer? _watchdog;
  bool _disposed = false;

  /// Đang trong một lần [connect]. Thiếu cờ này thì watchdog (20 giây/lần) có
  /// thể gọi chồng khi `start()` treo lâu — mỗi lần gọi dựng thêm một
  /// HubConnection đăng ký đủ bộ handler, và MỘT sự kiện cộng giờ sẽ được xử lý
  /// nhiều lần.
  bool _connecting = false;

  final StreamController<ExamRealtimeEvent> _events =
      StreamController<ExamRealtimeEvent>.broadcast();

  /// Sự kiện đã bóc tách kiểu, phát cho màn thi.
  Stream<ExamRealtimeEvent> get events => _events.stream;

  /// Trạng thái kết nối, để màn thi hiện chấm xanh/xám nếu cần.
  final ValueNotifier<bool> connected = ValueNotifier<bool>(false);

  String get _hubUrl => '$_baseUrl/api/notificationHub';

  /// Khoá nhóm riêng của sinh viên trong ca thi này.
  String get _userKey => '${studentId}_$examSessionSubjectId';

  Future<void> connect() async {
    if (_disposed || _connecting) return;
    if (_connection?.state == HubConnectionState.Connected) return;

    _connecting = true;
    try {
      // Dọn kết nối cũ trước khi dựng cái mới (web làm ở useSignalR.ts:53-55).
      final HubConnection? previous = _connection;
      _connection = null;
      if (previous != null) {
        try {
          await previous.stop();
        } catch (_) {
          // Kết nối cũ đã chết sẵn thì thôi.
        }
      }

      final HubConnection connection = HubConnectionBuilder()
          .withUrl(
            _hubUrl,
            options: HttpConnectionOptions(
              // Đọc token ở MỖI lần negotiate: token đổi giữa chừng vẫn dùng
              // được mà không phải dựng lại kết nối.
              accessTokenFactory: () async =>
                  await BaseService().getToken() ?? '',
              // Mặc định của gói là 2000ms và áp cho cả bước negotiate — trên
              // 3G/4G hoặc qua tunnel là timeout ngay, realtime chết im lặng.
              requestTimeout: 15000,
            ),
          )
          .withAutomaticReconnect(reconnectPolicy: _ForeverRetryPolicy())
          .build();

      // Đăng ký TOÀN BỘ handler TRƯỚC khi start, giống thứ tự bên web.
      _registerHandlers(connection);

      // Mọi callback đều phải kiểm [_disposed] trước: chúng có thể nổ SAU khi
      // màn thi đã đóng, mà lúc đó [connected] đã bị dispose — gán giá trị vào
      // ValueNotifier đã dispose là ném lỗi.
      connection.onclose(({Exception? error}) {
        if (_disposed) return;
        connected.value = false;
        debugPrint('SignalR đóng kết nối: $error');
      });
      connection.onreconnecting(({Exception? error}) {
        if (_disposed) return;
        connected.value = false;
        debugPrint('SignalR đang nối lại: $error');
      });
      connection.onreconnected(({String? connectionId}) {
        if (_disposed) return;
        connected.value = true;
        debugPrint('SignalR đã nối lại: $connectionId');
        // Bắt buộc: connectionId mới chưa thuộc nhóm nào.
        unawaited(_joinGroups(connection));
      });

      await connection.start();
      if (_disposed) {
        // Màn thi đóng ngay trong lúc đang bắt tay: dọn luôn, đừng để lại một
        // kết nối mồ côi vẫn nhận sự kiện.
        await connection.stop();
        return;
      }
      _connection = connection;
      connected.value = true;

      await _joinGroups(connection);
      // Có thể vừa bị dispose trong lúc chờ join xong — không kiểm là để lại
      // một Timer.periodic chạy mãi tới hết đời tiến trình.
      if (_disposed) return;
      _startWatchdog();
    } catch (e) {
      // Không nhận được realtime thì bài thi vẫn phải làm được như thường.
      debugPrint('Không kết nối được SignalR: $e');
      if (_disposed) return;
      connected.value = false;
      _startWatchdog();
    } finally {
      _connecting = false;
    }
  }

  Future<void> disconnect() async {
    if (_disposed) return;
    _disposed = true;
    _watchdog?.cancel();
    _watchdog = null;

    final HubConnection? connection = _connection;
    _connection = null;
    connected.value = false;

    if (connection != null) {
      try {
        if (connection.state == HubConnectionState.Connected) {
          await connection.invoke('LeaveStudentExamGroup', args: [_userKey]);
          await connection.invoke('LeaveStudentSystemGroup', args: [studentId]);
        }
        await connection.stop();
      } catch (e) {
        debugPrint('Lỗi khi ngắt SignalR: $e');
      }
    }

    await _events.close();
    connected.dispose();
  }

  /// Báo vi phạm lên giám thị theo thời gian thực.
  ///
  /// Hub bỏ qua IM LẶNG nếu thiếu [userCode]/[firstName]/[lastName] hoặc hai id
  /// rỗng — không có lỗi trả về, nên phải chặn ngay tại đây.
  Future<bool> reportViolation({
    required String violationType,
    required String description,
    required String userCode,
    required String firstName,
    required String lastName,
    String? fullName,
    String deviceInfo = '',
  }) async {
    final HubConnection? connection = _connection;
    if (connection == null ||
        connection.state != HubConnectionState.Connected) {
      return false;
    }
    if (userCode.isEmpty || firstName.isEmpty || lastName.isEmpty) {
      debugPrint('Bỏ qua ReportViolation: thiếu thông tin sinh viên');
      return false;
    }

    try {
      await connection.invoke(
        'ReportViolation',
        args: <Object>[
          <String, dynamic>{
            'studentExamSessionId': studentExamSessionId,
            'examSessionSubjectId': examSessionSubjectId,
            'applicationUserId': studentId,
            'userCode': userCode,
            'firstName': firstName,
            'lastName': lastName,
            'fullName': fullName ?? '$firstName $lastName'.trim(),
            'violationType': violationType,
            'description': description,
            // Hub giới hạn 32KB mỗi tin nhắn nên cắt ngắn cho chắc.
            'deviceInfo': deviceInfo.length > 512
                ? deviceInfo.substring(0, 512)
                : deviceInfo,
          },
        ],
      );
      return true;
    } catch (e) {
      debugPrint('Gửi ReportViolation hỏng: $e');
      return false;
    }
  }

  // ----------------------------------------------------------------- nội bộ

  Future<void> _joinGroups(HubConnection connection) async {
    try {
      await connection.invoke('JoinStudentExamGroup', args: [_userKey]);
      await connection.invoke('JoinStudentSystemGroup', args: [studentId]);
      debugPrint('SignalR đã vào nhóm student_$_userKey');
    } catch (e) {
      debugPrint('Không vào được nhóm SignalR: $e');
    }
  }

  /// Máy chủ ngắt client sau 30 giây không thấy tín hiệu (ClientTimeoutInterval).
  /// App bị đưa vào nền là timer Dart đóng băng, tỉnh dậy có thể đã mất kết nối
  /// mà chính sách reconnect cũng đã bỏ cuộc — nên soi lại mỗi 20 giây.
  void _startWatchdog() {
    _watchdog?.cancel();
    _watchdog = Timer.periodic(const Duration(seconds: 20), (_) {
      if (_disposed) return;

      final HubConnectionState? state = _connection?.state;
      // Đang tự nối lại thì để yên, cắt ngang là hỏng chuỗi retry.
      if (state == HubConnectionState.Connecting ||
          state == HubConnectionState.Reconnecting ||
          state == HubConnectionState.Disconnecting) {
        return;
      }
      if (state == HubConnectionState.Connected) return;

      debugPrint('Watchdog: SignalR mất kết nối, thử nối lại');
      unawaited(connect());
    });
  }

  void _registerHandlers(HubConnection connection) {
    connection.on('ReceiveExtraTime', (List<Object?>? args) {
      final Map<String, dynamic>? data = _payload(args);
      if (data == null) return;
      _emit(
        ExtraTimeEvent(
          minutes: _asInt(data['minutes']),
          newEndTime: _asDate(data['newEndTime']),
          reason: _asString(data['extraTimeReason']),
          timestamp: data['timestamp']?.toString(),
        ),
      );
    });

    connection.on('ExamSubmittedByTeacher', (List<Object?>? args) {
      final Map<String, dynamic>? data = _payload(args);
      _emit(
        TeacherSubmittedEvent(
          // Chỉ nhánh tự nộp do vi phạm mới có field này.
          forced: _asBool(data?['forceSubmitted']),
          reason: _asString(data?['submitReason']),
          submittedTime: _asDate(data?['submittedTime']),
        ),
      );
    });

    connection.on('ReceiveViolationWarning', (List<Object?>? args) {
      final Map<String, dynamic>? data = _payload(args);
      if (data == null) return;
      _emit(
        ViolationWarningEvent(
          violationCount: _asInt(data['violationCount']),
          threshold: _asInt(data['threshold']),
        ),
      );
    });

    connection.on('StudentBlocked', (List<Object?>? args) {
      final Map<String, dynamic>? data = _payload(args);
      _emit(
        StudentBlockedEvent(
          examSessionSubjectId: _asString(data?['examSessionSubjectId']),
        ),
      );
    });

    connection.on('ReceiveNotification', (List<Object?>? args) {
      final Map<String, dynamic>? data = _payload(args);
      if (data == null) return;
      final String message = _asString(data['message']);
      if (message.isEmpty) return;

      final String title = _asString(data['title']);
      _emit(
        TeacherMessageEvent(
          message: message,
          // Nhánh gửi cho một sinh viên KHÔNG có title — web ghép cứng
          // `"${title}: ${message}"` nên hiện ra "undefined: ...", ở đây bỏ hẳn
          // khi rỗng. Đây là chỗ DUY NHẤT cố ý khác web.
          title: title.isEmpty ? null : title,
          durationMs: _asIntOrNull(data['toastDuration']),
          style: _asStringOrNull(data['toastStyle']),
          position: _asStringOrNull(data['toastPosition']),
          // Màu nền giám thị chọn (`#RRGGBB`). Chuỗi rỗng thành null ngay tại đây
          // nên phía màn hình chỉ còn một trường hợp "không có màu" duy nhất.
          color: _asStringOrNull(data['toastColor']),
        ),
      );
    });

    connection.on('ReceiveExamScore', (List<Object?>? args) {
      final Map<String, dynamic>? data = _payload(args);
      if (data == null) return;
      if (!_asBool(data['isSuccess'])) return;
      _emit(
        ExamScoreEvent(
          score: _asDouble(data['score']),
          resultToken: _asString(data['resultToken']),
        ),
      );
    });

    connection.on('ViolationWarningConfigChanged', (List<Object?>? args) {
      final Map<String, dynamic>? data = _payload(args);
      if (data == null) return;
      _emit(
        ViolationConfigChangedEvent(
          examSessionSubjectId: _asString(data['examSessionSubjectId']),
          enableWarnings: _asBool(data['enableViolationWarnings']),
          showWarningModal: _asBool(data['showViolationWarningModal']),
        ),
      );
    });

    // `Connected` (gửi riêng cho client) và `UserDisconnected` (broadcast cho
    // TOÀN BỘ client mỗi khi có ai đó rớt mạng) cố ý không xử lý.
  }

  void _emit(ExamRealtimeEvent event) {
    if (_disposed || _events.isClosed) return;
    _events.add(event);
  }

  Map<String, dynamic>? _payload(List<Object?>? args) {
    if (args == null || args.isEmpty) return null;
    final Object? first = args.first;
    return first is Map ? Map<String, dynamic>.from(first) : null;
  }

  static String _asString(Object? value) => value?.toString() ?? '';

  static String? _asStringOrNull(Object? value) {
    final String text = _asString(value);
    return text.isEmpty ? null : text;
  }

  /// Khác [_asInt] ở chỗ giữ được `null`: máy chủ không gửi `toastDuration` thì
  /// phải rơi về mặc định của web (3000ms), chứ không phải 0.
  static int? _asIntOrNull(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value.toString());
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _asDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static bool _asBool(Object? value) {
    if (value is bool) return value;
    final String text = value?.toString().toLowerCase() ?? '';
    return text == 'true' || text == '1';
  }

  static DateTime? _asDate(Object? value) {
    if (value is DateTime) return value;
    final String text = value?.toString() ?? '';
    if (text.isEmpty) return null;
    return DateTime.tryParse(text)?.toLocal();
  }
}

/// Thử lại KHÔNG BỎ CUỘC: 2 giây trong phút đầu, sau đó 10 giây một lần.
///
/// Chính sách mặc định của gói chỉ thử vài lần rồi thôi — giữa ca thi mà thôi
/// hẳn thì sinh viên mất mọi thông báo của giám thị. Bản web dùng đúng cặp số
/// này (useSignalR.ts:64-71).
class _ForeverRetryPolicy implements IRetryPolicy {
  @override
  int? nextRetryDelayInMilliseconds(RetryContext retryContext) {
    return retryContext.elapsedMilliseconds < 60000 ? 2000 : 10000;
  }
}
