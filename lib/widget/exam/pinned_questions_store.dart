import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ghim câu hỏi — lưu ở MÁY, không đồng bộ lên máy chủ.
///
/// Dùng đúng khoá của bản web (`quiz_pinned_{studentExamSessionId}`, xem
/// `frontend_manage/src/hooks/useQuiz.ts:56-79`) và cùng định dạng mảng id, để
/// sau này có đồng bộ hai đầu thì không phải chuyển đổi gì.
///
/// Ghim là tiện ích phụ: mọi lỗi đọc/ghi đều nuốt và coi như "chưa ghim gì",
/// tuyệt đối không được làm gián đoạn bài thi.
class PinnedQuestionsStore {
  const PinnedQuestionsStore._();

  static const String _prefix = 'quiz_pinned_';

  static Future<Set<String>> load(String studentExamSessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_prefix$studentExamSessionId');
      if (raw == null || raw.isEmpty) return <String>{};

      final decoded = jsonDecode(raw);
      if (decoded is! List) return <String>{};

      return decoded.whereType<String>().where((id) => id.isNotEmpty).toSet();
    } catch (e) {
      debugPrint('Không đọc được danh sách câu đã ghim: $e');
      return <String>{};
    }
  }

  static Future<void> save(
    String studentExamSessionId,
    Set<String> pinned,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_prefix$studentExamSessionId';

      if (pinned.isEmpty) {
        await prefs.remove(key);
        return;
      }
      await prefs.setString(key, jsonEncode(pinned.toList(growable: false)));
    } catch (e) {
      debugPrint('Không lưu được danh sách câu đã ghim: $e');
    }
  }

  static Future<void> clear(String studentExamSessionId) =>
      save(studentExamSessionId, <String>{});
}
