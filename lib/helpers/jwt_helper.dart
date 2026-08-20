import 'dart:convert';

/// Đọc phần payload của JWT ngay tại máy.
///
/// Chỉ để TRẢ LỜI SỚM câu "token còn dùng được không" khi mở app — chữ ký
/// không được kiểm ở đây và cũng không cần: mọi quyết định thật vẫn nằm ở máy
/// chủ, đây chỉ là bước tránh đưa sinh viên vào trong rồi mới báo 401.
class JwtHelper {
  const JwtHelper._();

  static Map<String, dynamic>? payloadOf(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      // base64url trong JWT bị cắt phần đệm '=' nên phải bù lại trước khi giải.
      final decoded = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final payload = jsonDecode(decoded);
      return payload is Map<String, dynamic> ? payload : null;
    } catch (_) {
      return null;
    }
  }

  /// Hạn của token (UTC), null khi token không có `exp` hoặc không đọc được.
  static DateTime? expiryOf(String token) {
    final exp = payloadOf(token)?['exp'];
    if (exp is! num) return null;
    return DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000, isUtc: true);
  }

  /// Token đã hết hạn, hoặc sắp hết trong [leeway].
  ///
  /// Token không đọc được `exp` thì coi là CÒN HẠN: thà để máy chủ từ chối còn
  /// hơn tự đá người dùng ra ngoài vì một định dạng mình chưa biết.
  static bool isExpired(
    String token, {
    Duration leeway = const Duration(minutes: 1),
  }) {
    final expiry = expiryOf(token);
    if (expiry == null) return false;
    return DateTime.now().toUtc().add(leeway).isAfter(expiry);
  }
}
