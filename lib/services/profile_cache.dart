import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/student.dart';

/// Giữ hồ sơ cá nhân của sinh viên ngay trên máy.
///
/// Ba lý do cần bản lưu này:
///   * màn Tài khoản hiện được NGAY thay vì quay vòng chờ mạng mỗi lần mở;
///   * mất mạng vẫn xem được thông tin của mình (đang trong phòng thi, mạng
///     chập chờn là chuyện thường);
///   * `userCode` và họ tên luôn sẵn sàng — hai trường này bắt buộc khi báo vi
///     phạm qua SignalR, mà API `resume-quiz` lại KHÔNG trả họ tên, nên vào lại
///     bài đang thi là mất.
///
/// Mọi lỗi đọc/ghi đều nuốt: đây là bản chép để dùng cho nhanh, hỏng thì tải
/// lại từ máy chủ, tuyệt đối không được chặn luồng chính.
class ProfileCache {
  const ProfileCache._();

  static const String _key = 'student_profile';

  /// Bản đang giữ trong RAM, tránh đọc đĩa nhiều lần trong một phiên.
  static Student? _memory;

  static Student? get cached => _memory;

  static Future<Student?> load() async {
    if (_memory != null) return _memory;

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return null;

      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;

      _memory = Student.fromJson(Map<String, dynamic>.from(decoded));
      return _memory;
    } catch (e) {
      debugPrint('Không đọc được hồ sơ đã lưu: $e');
      return null;
    }
  }

  static Future<void> save(Student student) async {
    _memory = student;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(student.toJson()));
    } catch (e) {
      debugPrint('Không lưu được hồ sơ: $e');
    }
  }

  /// Xoá khi đăng xuất. `prefs.clear()` cũng xoá được, nhưng còn bản trong RAM
  /// nên phải gọi hàm này để người sau đăng nhập không thấy hồ sơ người trước.
  static Future<void> clear() async {
    _memory = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (e) {
      debugPrint('Không xoá được hồ sơ đã lưu: $e');
    }
  }
}
