import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

import '../models/news_item.dart';

/// Lấy tin giáo dục cho màn Trang chủ.
///
/// KHÔNG dùng chung `BaseService`: đó là lớp gọi API của hệ thống thi, mỗi
/// request đều kèm token và trỏ về `API_BASE_URL`. Tin tức là host ngoài,
/// không cần đăng nhập — gắn token của sinh viên vào request sang bên thứ ba
/// là gửi thông tin đăng nhập đi nơi không liên quan.
class NewsService {
  /// RSS mục Giáo dục của VnExpress: miễn phí, không cần khoá, không hạn mức.
  static const String feedUrl = 'https://vnexpress.net/rss/giao-duc.rss';

  /// Cắt ngắn thời gian chờ: đây là nội dung phụ của Trang chủ. Chờ theo mặc
  /// định của `http` (không giới hạn) là mạng chập chờn thì vòng quay tải cứ
  /// quay mãi, đúng kiểu người dùng tưởng app treo.
  static const Duration timeout = Duration(seconds: 12);

  const NewsService();

  /// Trả về [limit] tin mới nhất.
  ///
  /// Ném lỗi khi tải/đọc hỏng — phần giao diện bắt lấy để hiện nút "thử lại",
  /// vì tin tức hỏng KHÔNG được phép làm hỏng cả Trang chủ.
  Future<List<NewsItem>> fetchEducationNews({int limit = 60}) async {
    final response = await http.get(Uri.parse(feedUrl)).timeout(timeout);

    if (response.statusCode != 200) {
      throw Exception('RSS trả về HTTP ${response.statusCode}');
    }

    // Giải mã UTF-8 từ bodyBytes, KHÔNG dùng `response.body`: VnExpress không
    // khai charset trong Content-Type, mà `http` thiếu charset thì mặc định
    // latin-1 — tiếng Việt vỡ dấu thành "Ä'áº¡i há»c".
    final document = XmlDocument.parse(utf8.decode(response.bodyBytes));

    final items = <NewsItem>[];
    for (final element in document.findAllElements('item')) {
      final item = NewsItem.fromRssItem(element);
      if (item != null) items.add(item);
      if (items.length >= limit) break;
    }

    return items;
  }
}
