import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:quizz_mobile/services/auth/user_services.dart';

/// [UserService.uploadAvatar] có hai chốt chặn CHẠY TRƯỚC khi đụng mạng: đuôi
/// tệp và dung lượng. Chúng không phải để thay backend kiểm tra — backend vẫn
/// kiểm — mà để người dùng biết vì sao bị từ chối:
///   * `MediaUploadService.ValidateFile` lọc theo ĐUÔI TỆP, sai đuôi thì trả về
///     `USER_AVATAR_UPLOAD_FAILED` chung chung, không nói được là do định dạng.
///   * `RequestSizeLimit` của ASP.NET cắt request quá 10MB giữa chừng, người
///     dùng ngồi chờ hết một lần tải lên qua 4G rồi mới nhận về một lỗi 413.
///
/// Vì vậy điều bộ test này canh không chỉ là "trả về thất bại", mà là **không
/// có request nào được gửi đi** trong hai trường hợp đó.
class _FakeUserService extends UserService {
  /// Ghi lại từng lần gọi tầng mạng: rỗng nghĩa là đã chặn từ phía máy.
  final List<Map<String, String>> calls = [];

  /// Thân phản hồi giả và mã trạng thái kèm theo.
  int status = 200;
  Map<String, dynamic> body = const {
    'success': true,
    'code': 'USER_AVATAR_UPDATE_SUCCESS',
  };

  @override
  Future<http.Response> postMultipartFile(
    String endpoint, {
    required String field,
    required String filePath,
    required String filename,
  }) async {
    calls.add({
      'endpoint': endpoint,
      'field': field,
      'filePath': filePath,
      'filename': filename,
    });
    return http.Response(jsonEncode(body), status);
  }
}

late Directory _tempDir;

File _makeFile(String name, {int bytes = 16}) {
  final file = File('${_tempDir.path}${Platform.pathSeparator}$name');
  file.writeAsBytesSync(Uint8List(bytes));
  return file;
}

void main() {
  late _FakeUserService service;

  setUp(() {
    service = _FakeUserService();
    _tempDir = Directory.systemTemp.createTempSync('avatar_test');
  });

  tearDown(() {
    if (_tempDir.existsSync()) _tempDir.deleteSync(recursive: true);
  });

  test('Đuôi tệp lạ bị chặn tại máy, không gửi request nào', () async {
    final file = _makeFile('cv.txt');

    final result = await service.uploadAvatar(file.path);

    expect(result.success, isFalse);
    expect(result.error, isNotNull);
    expect(
      service.calls,
      isEmpty,
      reason: 'đã gửi lên máy chủ dù biết chắc sẽ bị từ chối',
    );
  });

  test('Tệp không có đuôi cũng bị chặn', () async {
    final file = _makeFile('anh_dai_dien');

    final result = await service.uploadAvatar(file.path);

    expect(result.success, isFalse);
    expect(service.calls, isEmpty);
  });

  test('Ảnh quá 10MB bị chặn tại máy, không gửi request nào', () async {
    // 10MB + 1 byte: ngay trên trần của `UserController.AvatarUploadMaxBytes`.
    final file = _makeFile('to.jpg', bytes: 10 * 1024 * 1024 + 1);

    final result = await service.uploadAvatar(file.path);

    expect(result.success, isFalse);
    expect(service.calls, isEmpty);
  });

  test('Đúng 10MB thì vẫn cho qua — trần là "tối đa", không phải "dưới"', () async {
    final file = _makeFile('vua_du.jpg', bytes: 10 * 1024 * 1024);

    final result = await service.uploadAvatar(file.path);

    expect(result.success, isTrue);
    expect(service.calls, hasLength(1));
  });

  test('Ảnh hợp lệ gửi đúng endpoint, đúng tên trường và giữ nguyên đuôi tệp', () async {
    final file = _makeFile('chan_dung.PNG');

    final result = await service.uploadAvatar(file.path);

    expect(result.success, isTrue);
    expect(service.calls, hasLength(1));

    final call = service.calls.single;
    expect(call['endpoint'], 'api/user/profile/avatar');
    // Tên trường phải khớp tham số `IFormFile file` của UserController.
    expect(call['field'], 'file');
    // Đuôi phải đi kèm tên tệp, nếu không backend lọc theo đuôi sẽ từ chối.
    expect(call['filename'], 'chan_dung.PNG');
  });

  test('Đuôi viết hoa vẫn được chấp nhận', () async {
    final file = _makeFile('anh.JPEG');

    final result = await service.uploadAvatar(file.path);

    expect(result.success, isTrue);
  });

  test('Mã lỗi của máy chủ được dịch, không lộ SCREAMING_SNAKE_CASE ra màn hình', () async {
    final file = _makeFile('anh.jpg');
    service.status = 400;
    service.body = const {
      'success': false,
      'code': 'USER_AVATAR_UPLOAD_FAILED',
    };

    final result = await service.uploadAvatar(file.path);

    expect(result.success, isFalse);
    expect(result.error, isNotNull);
    expect(
      result.error,
      isNot(contains('USER_AVATAR')),
      reason: 'mã máy bị đẩy thẳng ra cho người dùng đọc',
    );
  });

  test('Tệp không tồn tại thì báo lỗi chứ không ném ra ngoài', () async {
    final result = await service.uploadAvatar(
      '${_tempDir.path}${Platform.pathSeparator}khong_co.jpg',
    );

    expect(result.success, isFalse);
    expect(service.calls, isEmpty);
  });
}
