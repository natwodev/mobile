import 'package:xml/xml.dart';

/// Một tin trong dải "Tin giáo dục" ở màn Trang chủ.
///
/// Nguồn là RSS công khai mục Giáo dục của VnExpress. Chọn RSS thay vì một
/// dịch vụ tin tức có khoá API vì hai lẽ: không phải nhét khoá vào bản đóng
/// gói (ai giải nén APK cũng đọc được khoá đó), và không dính hạn mức gọi của
/// gói miễn phí — thứ sẽ hỏng đúng vào lúc đông người dùng nhất.
class NewsItem {
  const NewsItem({
    required this.title,
    required this.summary,
    required this.link,
    this.imageUrl,
    this.publishedAt,
  });

  final String title;

  /// Tóm tắt ĐÃ gỡ hết thẻ HTML. `<description>` của VnExpress là CDATA gói cả
  /// thẻ `<a>`, `<img>` lẫn chữ; đổ thẳng vào `Text` là người đọc thấy mã HTML.
  final String summary;

  /// Link bài gốc, mở bằng trình duyệt ngoài.
  final String link;

  /// Ảnh đại diện; null thì thẻ tin vẽ ô giữ chỗ thay vì chừa khoảng trống.
  final String? imageUrl;

  final DateTime? publishedAt;

  /// Dựng một tin từ thẻ `<item>` của RSS.
  ///
  /// Trả về null khi thiếu tiêu đề hoặc link: thẻ tin không tiêu đề thì chẳng
  /// nói lên điều gì, còn không link thì bấm vào không mở được bài — vẽ ra chỉ
  /// tổ làm người dùng bấm hụt.
  static NewsItem? fromRssItem(XmlElement item) {
    final title = _childText(item, 'title');
    final link = _childText(item, 'link');
    if (title.isEmpty || link.isEmpty) return null;

    final rawDescription = _childText(item, 'description');

    return NewsItem(
      title: title,
      summary: stripHtml(rawDescription),
      link: link,
      imageUrl: _imageUrl(item, rawDescription),
      publishedAt: parseRfc822(_childText(item, 'pubDate')),
    );
  }

  static String _childText(XmlElement item, String name) =>
      item.getElement(name)?.innerText.trim() ?? '';

  /// Ảnh: ưu tiên `<enclosure url="...">` vì đó là URL sạch do VnExpress khai
  /// riêng cho máy đọc. Không có thì mò `<img src="...">` trong phần mô tả.
  static String? _imageUrl(XmlElement item, String rawDescription) {
    final enclosure = item.getElement('enclosure')?.getAttribute('url');
    if (enclosure != null && enclosure.isNotEmpty) return enclosure;

    final match = RegExp(
      r'''<img[^>]+src\s*=\s*["']([^"']+)["']''',
    ).firstMatch(rawDescription);
    return match?.group(1);
  }

  /// Gỡ thẻ HTML và trả lại các thực thể thường gặp về ký tự thật.
  static String stripHtml(String raw) {
    if (raw.isEmpty) return '';

    final withoutTags = raw.replaceAll(RegExp(r'<[^>]*>'), ' ');
    final decoded = withoutTags
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'");

    // Gỡ thẻ xong còn lại một rừng khoảng trắng và xuống dòng; ép về một dấu
    // cách để `maxLines` đếm đúng số dòng chữ thật.
    return decoded.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static const Map<String, int> _months = {
    'Jan': 1,
    'Feb': 2,
    'Mar': 3,
    'Apr': 4,
    'May': 5,
    'Jun': 6,
    'Jul': 7,
    'Aug': 8,
    'Sep': 9,
    'Oct': 10,
    'Nov': 11,
    'Dec': 12,
  };

  /// Đọc ngày kiểu RFC-822 của RSS, ví dụ `Thu, 20 Aug 2026 16:28:07 +0700`.
  ///
  /// `DateTime.parse` KHÔNG đọc được dạng này (nó chờ ISO-8601), còn
  /// `DateFormat` của intl thì không nuốt phần lệch giờ `+0700` — bỏ qua phần
  /// đó là mọi tin lệch 7 tiếng, hiện thành "7 giờ trước" ngay khi vừa đăng.
  /// Nên tự tách bằng regex và quy về giờ máy.
  static DateTime? parseRfc822(String raw) {
    if (raw.isEmpty) return null;

    final match = RegExp(
      r'(\d{1,2})\s+([A-Za-z]{3})\s+(\d{4})\s+(\d{1,2}):(\d{2})(?::(\d{2}))?(?:\s+([+-]\d{4}))?',
    ).firstMatch(raw);
    if (match == null) return null;

    final month = _months[match.group(2)!];
    if (month == null) return null;

    var moment = DateTime.utc(
      int.parse(match.group(3)!),
      month,
      int.parse(match.group(1)!),
      int.parse(match.group(4)!),
      int.parse(match.group(5)!),
      int.parse(match.group(6) ?? '0'),
    );

    final offset = match.group(7);
    if (offset != null) {
      final sign = offset.startsWith('-') ? -1 : 1;
      moment = moment.subtract(
        Duration(
          hours: sign * int.parse(offset.substring(1, 3)),
          minutes: sign * int.parse(offset.substring(3, 5)),
        ),
      );
    }

    return moment.toLocal();
  }
}
