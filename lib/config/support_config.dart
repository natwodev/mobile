/// Đầu mối liên hệ hỗ trợ của app.
///
/// TODO(hutech): thay bằng số/hòm thư thật của bộ phận hỗ trợ trước khi phát
/// hành — mấy giá trị dưới đây chỉ là chỗ giữ chỗ.
class SupportConfig {
  const SupportConfig._();

  /// Hòm thư nhận báo lỗi và góp ý.
  static const String email = 'hotro@tracnghiem.online';

  /// Hotline hiển thị cho người dùng.
  static const String hotlineDisplay = '1900 1234';

  /// Hotline dạng chỉ số để nạp vào `tel:`.
  static const String hotlineDial = '19001234';

  static const String website = 'https://tracnghiem.online';
}
