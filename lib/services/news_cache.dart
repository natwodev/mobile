import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/news_item.dart';

/// Giữ mẻ tin giáo dục đã tải được lần gần nhất ngay trên máy.
///
/// Cùng khuôn với [ProfileCache] và cùng lý do: mở Trang chủ là thấy tin ngay
/// thay vì nhìn vòng quay chờ mạng, và MẤT MẠNG VẪN CÒN TIN ĐỂ ĐỌC. Trước bản
/// lưu này, rớt mạng là dải tin trắng trơn chỉ còn mỗi nút "Thử lại" — trong
/// khi tin vừa đọc cách đó một phút vẫn còn nguyên giá trị.
///
/// KHÔNG xoá khi đăng xuất, khác [ProfileCache]: đây là tin công khai của
/// VnExpress, ai đọc cũng được, không dính gì tới tài khoản đang đăng nhập.
///
/// Mọi lỗi đọc/ghi đều nuốt: đây là bản chép để dùng cho nhanh, hỏng thì tải
/// lại từ mạng, tuyệt đối không được chặn luồng chính.
class NewsCache {
  const NewsCache._();

  static const String _key = 'education_news';

  /// Số tin cất tối đa. Bằng đúng số tin một lần tải về — cất nhiều hơn cũng
  /// không hiện thêm được, mà `SharedPreferences` thì đọc/ghi cả chuỗi một lần.
  static const int _limit = 12;

  /// Bản đang giữ trong RAM, tránh đọc đĩa nhiều lần trong một phiên.
  static List<NewsItem>? _memory;

  static Future<List<NewsItem>> load() async {
    final cached = _memory;
    if (cached != null) return cached;

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return const [];

      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];

      final items = <NewsItem>[];
      for (final entry in decoded) {
        if (entry is! Map) continue;
        final item = NewsItem.fromJson(Map<String, dynamic>.from(entry));
        // Bỏ qua dòng hỏng thay vì vứt cả mẻ: bản lưu từ phiên bản cũ có thể
        // thiếu trường, mất một tin còn hơn mất sạch.
        if (item != null) items.add(item);
      }

      _memory = items;
      return items;
    } catch (e) {
      debugPrint('Không đọc được tin đã lưu: $e');
      return const [];
    }
  }

  static Future<void> save(List<NewsItem> items) async {
    if (items.isEmpty) return;

    final trimmed = items.take(_limit).toList();
    _memory = trimmed;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key,
        jsonEncode(trimmed.map((item) => item.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('Không lưu được tin: $e');
    }
  }
}
