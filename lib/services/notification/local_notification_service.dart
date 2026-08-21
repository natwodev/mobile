import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Kênh thông báo của app.
///
/// Id PHẢI trùng backend: `PushNotificationService.cs` gửi kèm
/// `ChannelId = "exam_notifications"`. Lệch một ký tự thì từ Android 8 trở lên
/// máy vẫn NHẬN được tin nhưng không vẽ ra gì cả — không lỗi, không log, không
/// dấu hiệu nào. Đây là kiểu hỏng tốn nhiều giờ nhất để tìm ra.
///
/// Lưu ý thêm: Android KHOÁ cấu hình kênh sau lần tạo đầu tiên. Muốn đổi âm
/// thanh hay mức độ ưu tiên thì phải đặt id kênh mới, hoặc gỡ app cài lại —
/// sửa mấy dòng dưới đây rồi chạy lại là không ăn.
const AndroidNotificationChannel kExamChannel = AndroidNotificationChannel(
  'exam_notifications',
  'Thông báo kỳ thi',
  description: 'Nhắc lịch thi, kết quả và thông báo từ giám thị',
  importance: Importance.high,
  sound: kExamSound,
);

/// Âm báo riêng, nằm ở `android/app/src/main/res/raw/notification_sound.mp3`.
///
/// Tên tài nguyên KHÔNG kèm đuôi `.mp3`, và tên file phải toàn chữ thường kèm
/// gạch dưới — aapt từ chối biên dịch res có gạch ngang hay chữ hoa.
const RawResourceAndroidNotificationSound kExamSound =
    RawResourceAndroidNotificationSound('notification_sound');

/// Chi tiết dùng chung cho mọi thông báo của app, để một chỗ cho khỏi trôi dạt.
const NotificationDetails kExamNotificationDetails = NotificationDetails(
  android: AndroidNotificationDetails(
    'exam_notifications',
    'Thông báo kỳ thi',
    channelDescription: 'Nhắc lịch thi, kết quả và thông báo từ giám thị',
    importance: Importance.high,
    priority: Priority.high,
    // Nhắc lại cho Android 7 trở xuống: bản cũ chưa có khái niệm kênh nên âm
    // báo phải khai ở từng thông báo, không thừa.
    sound: kExamSound,
  ),
  iOS: DarwinNotificationDetails(),
);

/// Người dùng bấm vào thông báo trong lúc app đã tắt hẳn.
///
/// Phải là hàm top-level và phải có `@pragma('vm:entry-point')`: bản release
/// bị tree-shaking cắt mọi thứ không ai gọi tới từ Dart, mà hàm này chỉ được
/// gọi từ phía native — thiếu chú thích là im lặng ở release còn debug vẫn
/// chạy tốt, đúng kiểu lỗi chỉ lộ ra sau khi phát hành.
@pragma('vm:entry-point')
void onBackgroundNotificationTap(NotificationResponse response) {
  // Chạy trong isolate riêng: không có state, không có UI, không đụng được
  // Navigator. Muốn điều hướng thì lưu payload lại rồi xử lý khi app mở.
}

/// Thông báo do CHÍNH MÁY bắn ra: hẹn giờ được, chạy cả khi không có mạng.
///
/// Khác hẳn push của FCM (cần mạng và cần server). Nhắc "còn 15 phút nữa tới
/// ca thi" bắt buộc phải đi đường này, không có đường vòng.
///
/// Lớp này cũng chính là thứ mà FCM sẽ gọi tới khi app ĐANG MỞ: Android và iOS
/// chỉ tự vẽ thông báo lúc app ở nền hoặc đã tắt, còn app đang mở thì hệ điều
/// hành giao thẳng dữ liệu cho app và im lặng.
class LocalNotificationService {
  LocalNotificationService._();

  static final LocalNotificationService instance = LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _ready = false;

  /// Payload của thông báo mà người dùng vừa bấm, để tầng UI đọc và điều hướng.
  final ValueNotifier<String?> lastTappedPayload = ValueNotifier<String?>(null);

  /// Khởi tạo. Gọi trong `main()` trước `runApp()`.
  ///
  /// Nuốt mọi lỗi: thông báo là tính năng phụ, hỏng thì app vẫn phải vào thi
  /// được. Ném lỗi ở đây là chặn luôn `main()`.
  Future<void> init() async {
    if (_ready) return;

    try {
      await _initTimezone();

      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/launcher_icon'),
          iOS: DarwinInitializationSettings(
            // Xin quyền RIÊNG ở requestPermissions(), đúng lúc người dùng hiểu
            // vì sao cần — hỏi ngay khi vừa mở app lần đầu thì đa số bấm từ
            // chối, mà iOS từ chối một lần là phải vào Cài đặt mới bật lại.
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: (response) {
          lastTappedPayload.value = response.payload;
        },
        onDidReceiveBackgroundNotificationResponse: onBackgroundNotificationTap,
      );

      // Tạo kênh TRƯỚC khi có tin nào tới. Tin đến mà kênh chưa tồn tại thì
      // Android bỏ qua luôn tin đó.
      if (!kIsWeb && Platform.isAndroid) {
        await _android?.createNotificationChannel(kExamChannel);
      }

      _ready = true;
    } catch (error, stack) {
      debugPrint('[notification] init lỗi: $error\n$stack');
    }
  }

  /// Nạp bảng múi giờ và chốt múi giờ của máy.
  ///
  /// `zonedSchedule` cần `TZDateTime`. Không đặt đúng múi giờ máy thì lịch nhắc
  /// lệch đúng bằng khoảng cách tới UTC — ở Việt Nam là 7 tiếng, tức thông báo
  /// "sắp tới giờ thi" nổ khi ca thi đã xong từ lâu.
  Future<void> _initTimezone() async {
    tz_data.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (error) {
      // Máy trả về tên múi giờ lạ thì giữ nguyên mặc định của gói (UTC) còn hơn
      // để nguyên exception làm hỏng cả init.
      debugPrint('[notification] không lấy được múi giờ máy: $error');
    }
  }

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

  /// Xin quyền hiện thông báo. Gọi khi người dùng đã hiểu vì sao cần.
  ///
  /// Trả về true nếu được phép hiện thông báo.
  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;

    try {
      if (Platform.isAndroid) {
        // Android 13+ mới cần xin; bản cũ hơn trả null và mặc định là có quyền.
        return await _android?.requestNotificationsPermission() ?? true;
      }

      if (Platform.isIOS) {
        return await _plugin
                .resolvePlatformSpecificImplementation<
                  IOSFlutterLocalNotificationsPlugin
                >()
                ?.requestPermissions(alert: true, badge: true, sound: true) ??
            false;
      }
    } catch (error) {
      debugPrint('[notification] xin quyền lỗi: $error');
    }

    return false;
  }

  /// Hiện một thông báo NGAY.
  ///
  /// Đây là hàm mà tầng FCM sẽ gọi khi app đang mở.
  Future<void> show({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_ready) await init();

    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: kExamNotificationDetails,
        payload: payload,
      );
    } catch (error) {
      debugPrint('[notification] show lỗi: $error');
    }
  }

  /// Hẹn một thông báo vào [when].
  ///
  /// Trả về false nếu mốc thời gian đã trôi qua hoặc đặt lịch thất bại — người
  /// gọi cần biết để còn báo lại, chứ nuốt im thì tưởng đã đặt được.
  Future<bool> scheduleAt({
    required int id,
    required String title,
    required String body,
    required DateTime when,
    String? payload,
  }) async {
    if (!_ready) await init();

    final target = tz.TZDateTime.from(when, tz.local);
    // Hẹn vào quá khứ thì flutter_local_notifications bắn ngay lập tức — nhắc
    // "sắp tới giờ thi" cho một ca đã kết thúc còn tệ hơn là không nhắc.
    if (!target.isAfter(tz.TZDateTime.now(tz.local))) return false;

    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: target,
        notificationDetails: kExamNotificationDetails,
        androidScheduleMode: await _scheduleMode(),
        payload: payload,
      );
      return true;
    } catch (error) {
      debugPrint('[notification] đặt lịch lỗi: $error');
      return false;
    }
  }

  /// Chọn kiểu báo thức, có nhánh lui cho Android 14+.
  ///
  /// Từ Android 14, SCHEDULE_EXACT_ALARM khai trong manifest KHÔNG còn được tự
  /// cấp nữa. Cứ đòi báo thức chính xác khi chưa được phép là ăn
  /// `ExactAlarmPermissionException` và mất trắng lịch. Không xin được thì hạ
  /// xuống inexact: nhắc trễ vài phút vẫn hơn là không nhắc gì.
  Future<AndroidScheduleMode> _scheduleMode() async {
    if (kIsWeb || !Platform.isAndroid) {
      return AndroidScheduleMode.exactAllowWhileIdle;
    }

    try {
      if (await _android?.canScheduleExactNotifications() ?? false) {
        return AndroidScheduleMode.exactAllowWhileIdle;
      }
      if (await _android?.requestExactAlarmsPermission() ?? false) {
        return AndroidScheduleMode.exactAllowWhileIdle;
      }
    } catch (error) {
      debugPrint('[notification] hỏi quyền báo thức lỗi: $error');
    }

    return AndroidScheduleMode.inexactAllowWhileIdle;
  }

  Future<void> cancel(int id) async {
    try {
      await _plugin.cancel(id: id);
    } catch (error) {
      debugPrint('[notification] huỷ lỗi: $error');
    }
  }

  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (error) {
      debugPrint('[notification] huỷ tất cả lỗi: $error');
    }
  }

  /// Các thông báo đang chờ tới giờ. Dùng để kiểm tra lúc phát triển.
  Future<List<PendingNotificationRequest>> pending() async {
    try {
      return await _plugin.pendingNotificationRequests();
    } catch (error) {
      debugPrint('[notification] đọc hàng chờ lỗi: $error');
      return const [];
    }
  }
}
