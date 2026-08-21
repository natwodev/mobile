import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../models/app_notification.dart';
import '../base_service.dart';

/// Một trang thư lấy từ máy chủ.
class NotificationPage {
  const NotificationPage({
    required this.items,
    required this.unreadCount,
    required this.page,
    required this.total,
  });

  final List<AppNotification> items;
  final int unreadCount;
  final int page;

  /// TỔNG số thư khớp điều kiện lọc, không phải số thư trong trang này. Dùng để
  /// biết còn trang sau hay không.
  final int total;

  bool get hasMore => items.length < total;
}

/// Hộp thư của sinh viên.
///
/// Máy chủ giữ bản thật, đây chỉ là lớp gọi API. Push của FCM không mang nội
/// dung để app tự dựng danh sách: tin gửi kèm phần `notification` nên khi app ở
/// nền hoặc đã tắt thì hệ điều hành xử lý trọn, app không chạy dòng nào. Sinh
/// viên không bấm vào thông báo là app không bao giờ biết tin đó tồn tại.
class NotificationService extends BaseService {
  static const String _base = 'api/notification';

  /// Lấy một trang thư, mới nhất trước (máy chủ đã sắp sẵn).
  ///
  /// Trả `null` khi gọi hỏng, để nơi gọi phân biệt được "hỏng mạng" với "không
  /// có thư nào" — hai thứ này hiện ra màn hình phải khác nhau.
  Future<NotificationPage?> fetch({
    int page = 1,
    int pageSize = 20,
    bool unreadOnly = false,
  }) async {
    try {
      final response = await get(
        _base,
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
          if (unreadOnly) 'unread': true,
        },
      );

      if (response.statusCode != 200) {
        debugPrint('Lấy hộp thư hỏng: HTTP ${response.statusCode}');
        return null;
      }

      // `bodyBytes` chứ không phải `body`: tiêu đề thư có dấu tiếng Việt, mà
      // `body` giải mã theo latin1 khi máy chủ không ghi rõ charset — chữ ra
      // dạng "Ã¡Â»".
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map || decoded['success'] != true) return null;

      final data = decoded['data'];
      if (data is! Map) return null;

      final rawItems = data['items'];
      final items = <AppNotification>[];
      if (rawItems is List) {
        for (final entry in rawItems) {
          if (entry is! Map) continue;
          final item = AppNotification.fromJson(
            Map<String, dynamic>.from(entry),
          );
          // Bỏ qua đúng dòng hỏng thay vì vứt cả trang.
          if (item != null) items.add(item);
        }
      }

      return NotificationPage(
        items: items,
        unreadCount: _asInt(data['unreadCount']),
        page: _asInt(data['page'], fallback: page),
        total: _asInt(data['total'], fallback: items.length),
      );
    } catch (e) {
      debugPrint('Lấy hộp thư hỏng: $e');
      return null;
    }
  }

  /// Số thư chưa đọc. Trả `null` khi gọi hỏng.
  Future<int?> unreadCount() async {
    try {
      final response = await get('$_base/unread-count');
      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map || decoded['success'] != true) return null;

      final data = decoded['data'];
      if (data is! Map) return null;

      return _asInt(data['unreadCount']);
    } catch (e) {
      debugPrint('Đếm thư chưa đọc hỏng: $e');
      return null;
    }
  }

  /// Đánh dấu một thư đã đọc.
  Future<bool> markRead(String id) async {
    try {
      final response = await patch('$_base/$id/read', const {});

      // 403 khi đụng vào thư của người khác, và thân phản hồi RỖNG chứ không
      // phải JSON — nên chỉ xét mã trạng thái, tuyệt đối không parse ở đây.
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Đánh dấu đã đọc hỏng: $e');
      return false;
    }
  }

  /// Đánh dấu toàn bộ thư đã đọc.
  Future<bool> markAllRead() async {
    try {
      final response = await patch('$_base/read-all', const {});
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Đánh dấu đã đọc tất cả hỏng: $e');
      return false;
    }
  }

  /// Đọc số nguyên từ JSON chịu được cả kiểu số lẫn kiểu chuỗi.
  static int _asInt(Object? value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }
}
