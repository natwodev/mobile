import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/app_notification.dart';

/// Giữ TRANG ĐẦU hộp thư của lần mở gần nhất ngay trên máy.
///
/// Cùng khuôn với `NewsCache` và cùng lý do: mở chuông là thấy thư ngay thay vì
/// nhìn vòng quay chờ mạng, và mất mạng vẫn còn thư cũ để đọc lại.
///
/// Đây là BẢN CHÉP, không phải nguồn sự thật. Có mạng là ghi đè bằng dữ liệu
/// máy chủ, KHÔNG trộn hai bên: trộn thì thư đã đọc trên web lại hiện chưa đọc
/// trong app, và thư giáo viên thu hồi vẫn nằm nguyên đó.
///
/// KHÁC `NewsCache` ở chỗ PHẢI xoá khi đăng xuất: đây là thư riêng của một sinh
/// viên, để lại là người đăng nhập sau mở chuông ra đọc được thư của người
/// trước.
class NotificationCache {
  const NotificationCache._();

  static const String _key = 'notification_inbox';
  static const String _unreadKey = 'notification_unread_count';

  /// Chỉ cất trang đầu, bằng đúng `pageSize` mặc định của máy chủ. Cất nhiều
  /// hơn cũng vô ích: mất mạng thì không tải thêm trang được, mà thư cũ quá
  /// cũng chẳng ai cần lật lại lúc offline.
  static const int _limit = 20;

  /// Bản đang giữ trong RAM, tránh đọc đĩa nhiều lần trong một phiên.
  static List<AppNotification>? _memory;
  static int? _unreadMemory;

  static Future<List<AppNotification>> load() async {
    final cached = _memory;
    if (cached != null) return cached;

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return const [];

      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];

      final items = <AppNotification>[];
      for (final entry in decoded) {
        if (entry is! Map) continue;
        final item = AppNotification.fromJson(Map<String, dynamic>.from(entry));
        // Bỏ qua dòng hỏng thay vì vứt cả mẻ: bản lưu từ phiên bản cũ có thể
        // thiếu trường, mất một thư còn hơn mất sạch.
        if (item != null) items.add(item);
      }

      _memory = items;
      return items;
    } catch (e) {
      debugPrint('Không đọc được hộp thư đã lưu: $e');
      return const [];
    }
  }

  /// Số thư chưa đọc của lần mở gần nhất, để badge trên nút chuông có số hiện
  /// ngay lúc mở app thay vì nhấp nháy từ 0 lên.
  static Future<int> loadUnreadCount() async {
    final cached = _unreadMemory;
    if (cached != null) return cached;

    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getInt(_unreadKey) ?? 0;
      _unreadMemory = value;
      return value;
    } catch (e) {
      debugPrint('Không đọc được số thư chưa đọc đã lưu: $e');
      return 0;
    }
  }

  static Future<void> save(List<AppNotification> items, int unreadCount) async {
    final trimmed = items.take(_limit).toList();
    _memory = trimmed;
    _unreadMemory = unreadCount;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key,
        jsonEncode(trimmed.map((item) => item.toJson()).toList()),
      );
      await prefs.setInt(_unreadKey, unreadCount);
    } catch (e) {
      debugPrint('Không lưu được hộp thư: $e');
    }
  }

  /// Xoá khi đăng xuất.
  ///
  /// Phải xoá cả bản trong RAM chứ không chỉ trên đĩa: người dùng đăng xuất rồi
  /// đăng nhập tài khoản khác mà app không tắt, thì `_memory` vẫn còn nguyên
  /// thư của người trước.
  static Future<void> clear() async {
    _memory = null;
    _unreadMemory = null;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
      await prefs.remove(_unreadKey);
    } catch (e) {
      debugPrint('Không xoá được hộp thư đã lưu: $e');
    }
  }
}
