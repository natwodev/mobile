import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quizz_mobile/helpers/jwt_helper.dart';
import 'package:quizz_mobile/services/auth/user_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Dựng một JWT giả chỉ đủ để đọc `exp` — chữ ký không quan trọng vì app chỉ
/// đọc payload tại máy.
String fakeJwt({DateTime? expiresAt}) {
  String encode(Map<String, dynamic> part) =>
      base64Url.encode(utf8.encode(jsonEncode(part))).replaceAll('=', '');

  final payload = <String, dynamic>{
    'nameid': '11111111-1111-1111-1111-111111111111',
    if (expiresAt != null)
      'exp': expiresAt.toUtc().millisecondsSinceEpoch ~/ 1000,
  };
  return '${encode({'alg': 'HS256'})}.${encode(payload)}.chu-ky-gia';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('JwtHelper', () {
    test('đọc được hạn của token', () {
      final expiry = DateTime.utc(2030, 1, 2, 3, 4, 5);
      expect(JwtHelper.expiryOf(fakeJwt(expiresAt: expiry)), expiry);
    });

    test('token còn hạn thì không bị coi là hết hạn', () {
      final token = fakeJwt(expiresAt: DateTime.now().add(const Duration(days: 7)));
      expect(JwtHelper.isExpired(token), isFalse);
    });

    test('token quá hạn bị phát hiện', () {
      final token = fakeJwt(expiresAt: DateTime.now().subtract(const Duration(minutes: 5)));
      expect(JwtHelper.isExpired(token), isTrue);
    });

    test('token sắp hết hạn trong vùng đệm cũng coi là hết', () {
      final token = fakeJwt(expiresAt: DateTime.now().add(const Duration(seconds: 20)));
      expect(JwtHelper.isExpired(token), isTrue);
    });

    test('token không có exp thì để máy chủ quyết, không tự đá ra', () {
      expect(JwtHelper.isExpired(fakeJwt()), isFalse);
    });

    test('chuỗi rác không làm sập app', () {
      expect(JwtHelper.payloadOf('không-phải-jwt'), isNull);
      expect(JwtHelper.isExpired('a.b.c'), isFalse);
    });
  });

  group('Khôi phục phiên đăng nhập', () {
    test('không có token thì phải đăng nhập', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      expect(await UserService().isLoggedIn(), isFalse);
    });

    test('token còn hạn thì vào thẳng app', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'token': fakeJwt(expiresAt: DateTime.now().add(const Duration(days: 3))),
      });
      expect(await UserService().isLoggedIn(), isTrue);
    });

    test('token hết hạn thì phải đăng nhập lại VÀ token bị dọn khỏi máy',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'token': fakeJwt(expiresAt: DateTime.now().subtract(const Duration(days: 1))),
      });

      final service = UserService();
      expect(await service.isLoggedIn(), isFalse);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('token'), isNull);
    });
  });
}
