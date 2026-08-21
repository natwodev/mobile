import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../controller/session_controller.dart';
import '../base_service.dart';
import '../device_report_service.dart';
import 'local_notification_service.dart';

/// Tin đến trong lúc app đã tắt hẳn hoặc đang ở nền.
///
/// Phải là hàm top-level và phải có `@pragma('vm:entry-point')`: hàm này chỉ
/// được gọi từ phía native, nên bản release tree-shaking sẽ cắt mất nếu thiếu
/// chú thích — debug chạy tốt, release im lặng, kiểu lỗi chỉ lộ sau khi phát
/// hành.
///
/// Chạy trong isolate RIÊNG: không có state của app, không có Navigator, không
/// đụng được UI. Android/iOS đã tự vẽ thông báo ở trạng thái này rồi nên ở đây
/// không cần (và không nên) vẽ lại.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (error) {
    debugPrint('[push] nền: khởi tạo Firebase lỗi: $error');
  }
}

/// Thông báo đẩy qua FCM — tầng duy nhất tới được máy khi app đã tắt hẳn.
///
/// Toàn bộ lớp này được viết để CHỊU ĐƯỢC việc chưa có cấu hình Firebase.
/// Chưa bỏ `google-services.json` vào `android/app/` thì `Firebase.initializeApp()`
/// ném lỗi; khi đó [available] là false và mọi hàm còn lại thành no-op — app
/// vẫn đăng nhập và vào thi bình thường. Thông báo là tính năng phụ, không được
/// phép kéo sập thứ chính.
class PushService {
  PushService._();

  static final PushService instance = PushService._();

  FirebaseMessaging? _fcm;
  bool _available = false;

  /// Firebase đã cấu hình và khởi tạo được hay chưa.
  bool get available => _available;

  /// Payload `data` của thông báo người dùng vừa bấm, để tầng UI điều hướng.
  final ValueNotifier<Map<String, dynamic>?> lastTappedData =
      ValueNotifier<Map<String, dynamic>?>(null);

  /// Gọi trong `main()`, SAU [LocalNotificationService.init].
  Future<void> init() async {
    try {
      await Firebase.initializeApp();
      _fcm = FirebaseMessaging.instance;
      _available = true;
    } catch (error) {
      // Đường đi bình thường khi chưa gắn Firebase — không phải sự cố.
      debugPrint(
        '[push] chưa cấu hình Firebase (thiếu google-services.json?): $error',
      );
      return;
    }

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // CHỈ bản debug: in token ra để dán vào Firebase Console → Cloud Messaging
    // → "Send test message". Nhờ đó thử được đường dây FCM mà không cần backend
    // và không cần đăng nhập — bước cô lập lỗi hữu ích nhất khi mới gắn Firebase.
    //
    // Không in ở bản phát hành: ai đọc được token là gửi thông báo tới đúng máy
    // đó được.
    if (kDebugMode) {
      try {
        debugPrint('[push] FCM token: ${await _fcm!.getToken()}');
      } catch (error) {
        debugPrint('[push] không lấy được token: $error');
      }
    }

    // App ĐANG MỞ: hệ điều hành giao thẳng dữ liệu cho app và KHÔNG tự vẽ gì.
    // Không tự gọi local ở đây thì người dùng đang mở app sẽ chẳng thấy thông
    // báo nào — và đây là điều hay bị tưởng nhầm là lỗi cấu hình.
    FirebaseMessaging.onMessage.listen(_showWhileForeground);

    // Bấm vào thông báo lúc app đang ở nền.
    FirebaseMessaging.onMessageOpenedApp.listen(
      (message) => lastTappedData.value = message.data,
    );

    // Bấm vào thông báo lúc app đã TẮT HẲN: `onMessageOpenedApp` KHÔNG bắn
    // trong trường hợp này, phải đọc riêng qua getInitialMessage.
    try {
      final initial = await _fcm!.getInitialMessage();
      if (initial != null) lastTappedData.value = initial.data;
    } catch (error) {
      debugPrint('[push] đọc tin mở app lỗi: $error');
    }

    await syncToken();

    // Token FCM có thể bị Google cấp lại bất cứ lúc nào (khôi phục máy, xoá dữ
    // liệu app...). Không nghe sự kiện này thì backend giữ token chết và thông
    // báo lặng lẽ không tới nữa.
    _fcm!.onTokenRefresh.listen((_) => syncToken());
  }

  Future<void> _showWhileForeground(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await LocalNotificationService.instance.show(
      // hashCode của message làm id: mỗi tin một thông báo riêng, tin tới sau
      // không đè mất tin trước.
      id: message.hashCode,
      title: notification.title ?? '',
      body: notification.body ?? '',
      payload: jsonEncode(message.data),
    );
  }

  /// Xin quyền nhận thông báo đẩy phía FCM.
  Future<void> requestPermission() async {
    if (!_available) return;

    try {
      await _fcm!.requestPermission(alert: true, badge: true, sound: true);
    } catch (error) {
      debugPrint('[push] xin quyền lỗi: $error');
    }
  }

  /// Đăng ký token của máy với backend.
  ///
  /// Gọi ở HAI chỗ: lúc [init], và ngay sau khi đăng nhập thành công. Lần đầu
  /// cài app thì [init] chạy lúc chưa có JWT nên sẽ bị bỏ qua ở nhánh dưới —
  /// thiếu lần gọi sau đăng nhập là máy không bao giờ nhận được thông báo nào.
  ///
  /// Backend đã làm idempotent: gọi lại bao nhiêu lần cũng chỉ giữ một dòng.
  Future<bool> syncToken() async {
    if (!_available) return false;

    // Chưa đăng nhập thì đăng ký chắc chắn 401, gọi chỉ tổ phí một vòng mạng.
    if (!SessionController.instance.signedIn) return false;

    try {
      final token = await _fcm!.getToken();
      if (token == null || token.isEmpty) return false;

      final response = await BaseService().post('api/push/register', {
        'token': token,
        'platform': Platform.isIOS ? 'ios' : 'android',
        'deviceInfo': await _deviceLabel(),
      });

      final ok = response.statusCode >= 200 && response.statusCode < 300;
      if (!ok) {
        debugPrint('[push] đăng ký token trả HTTP ${response.statusCode}');
      }
      return ok;
    } catch (error) {
      debugPrint('[push] đăng ký token lỗi: $error');
      return false;
    }
  }

  /// Gỡ token khỏi tài khoản đang đăng nhập.
  ///
  /// PHẢI gọi TRƯỚC khi xoá JWT: xoá token xong thì request nào cũng 401 và
  /// backend không gỡ được gì. Bỏ bước này thì máy vẫn nhận thông báo của tài
  /// khoản vừa thoát — chuyện nghiêm trọng với máy dùng chung ở phòng thi.
  Future<void> unregister() async {
    if (!_available) return;

    try {
      final token = await _fcm!.getToken();
      if (token == null || token.isEmpty) return;

      await BaseService().post('api/push/unregister', {'token': token});
    } catch (error) {
      // Nuốt lỗi: đăng xuất KHÔNG được phép thất bại chỉ vì gỡ token hỏng.
      debugPrint('[push] gỡ token lỗi: $error');
    }
  }

  /// Nhãn máy để người quản trị đọc được trong danh sách thiết bị.
  Future<String> _deviceLabel() async {
    try {
      final report = await DeviceReportService.load();
      return '${report.brand} ${report.model} · ${report.os}'.trim();
    } catch (_) {
      return Platform.operatingSystem;
    }
  }
}
