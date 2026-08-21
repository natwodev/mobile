// services/base_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class BaseService {
  static String get baseUrl {
    final envUrl = dotenv.env['API_BASE_URL'];
    if (envUrl != null && envUrl.isNotEmpty) {
      return envUrl;
    }
    // Địa chỉ máy chủ thật, dùng khi .env không nạp được (đóng gói thiếu, file
    // hỏng...). Trước đây là IP máy cá nhân trong mạng LAN — bản phát hành mà
    // rơi vào nhánh này thì không gọi được API nào và không ai biết vì sao.
    return 'https://api.tracnghiem.online';
  }

  // ===== TOKEN =====
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  // ===== GET (HỖ TRỢ QUERY PARAMS) =====
  Future<http.Response> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final token = await getToken();

    final uri = Uri.parse('$baseUrl/$endpoint').replace(
      queryParameters: queryParameters?.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
    );

    return await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
  }

  // ===== POST JSON =====
  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final token = await getToken();

    return await http.post(
      Uri.parse('$baseUrl/$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
  }

  // ===== PATCH JSON =====
  Future<http.Response> patch(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final token = await getToken();

    return await http.patch(
      Uri.parse('$baseUrl/$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
  }

  // ===== POST MULTIPART (TẢI TỆP LÊN) =====
  //
  // Tách riêng khỏi [postForm] vì `http.post` với `body` là Map chỉ sinh ra
  // `application/x-www-form-urlencoded` — backend nhận `IFormFile` thì bỏ qua
  // hoàn toàn, request đi lọt nhưng `file` luôn null.
  //
  // [filename] PHẢI mang phần mở rộng thật (.jpg/.png/...): backend
  // (`MediaUploadService.ValidateFile`) chặn theo ĐUÔI TỆP chứ không đọc nội
  // dung, nên tên không có đuôi là bị từ chối dù ảnh hợp lệ.
  //
  // Hàm này là điểm ghi đè cho test — xem `test/upload_avatar_test.dart`.
  Future<http.Response> postMultipartFile(
    String endpoint, {
    required String field,
    required String filePath,
    required String filename,
  }) async {
    final token = await getToken();

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/$endpoint'),
    );
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.files.add(
      await http.MultipartFile.fromPath(field, filePath, filename: filename),
    );

    return http.Response.fromStream(await request.send());
  }

  // ===== POST FORM =====
  Future<http.Response> postForm(
    String endpoint,
    Map<String, String> body,
  ) async {
    final token = await getToken();

    return await http.post(
      Uri.parse('$baseUrl/$endpoint'),
      headers: {if (token != null) 'Authorization': 'Bearer $token'},
      body: body,
    );
  }
}
