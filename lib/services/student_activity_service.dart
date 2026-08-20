import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service để gửi hành động của sinh viên lên backend
class StudentActivityService {
  final String baseUrl;
  final String? authToken;

  StudentActivityService({
    required this.baseUrl,
    this.authToken,
  });

  /// Ghi nhận một hành động của sinh viên
  Future<bool> recordActivity({
    required String studentExamSessionId,
    required String studentCode,
    required String activityType,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/StudentActivity/record');

      final body = <String, dynamic>{
        'studentExamSessionId': studentExamSessionId,
        'studentCode': studentCode,
        'activityType': activityType,
        if (description != null) 'description': description,
        if (metadata != null) 'metadata': jsonEncode(metadata),
      };

      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      
      if (authToken != null && authToken!.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print('❌ Error recording activity: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Exception recording activity: $e');
      return false;
    }
  }

  /// Ghi nhận khi app vào background
  Future<bool> recordAppBackground({
    required String studentExamSessionId,
    required String studentCode,
  }) {
    return recordActivity(
      studentExamSessionId: studentExamSessionId,
      studentCode: studentCode,
      activityType: 'AppBackground',
      description: 'Ứng dụng chuyển sang background',
      metadata: {
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Ghi nhận khi app quay lại foreground
  Future<bool> recordAppForeground({
    required String studentExamSessionId,
    required String studentCode,
  }) {
    return recordActivity(
      studentExamSessionId: studentExamSessionId,
      studentCode: studentCode,
      activityType: 'AppForeground',
      description: 'Ứng dụng quay lại foreground',
      metadata: {
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Ghi nhận chụp màn hình
  Future<bool> recordScreenshot({
    required String studentExamSessionId,
    required String studentCode,
    String? method,
  }) {
    return recordActivity(
      studentExamSessionId: studentExamSessionId,
      studentCode: studentCode,
      activityType: 'Screenshot',
      description: 'Phát hiện chụp màn hình',
      metadata: {
        'timestamp': DateTime.now().toIso8601String(),
        if (method != null) 'method': method,
      },
    );
  }

  /// Ghi nhận chuyển ứng dụng
  Future<bool> recordAppSwitch({
    required String studentExamSessionId,
    required String studentCode,
  }) {
    return recordActivity(
      studentExamSessionId: studentExamSessionId,
      studentCode: studentCode,
      activityType: 'AppSwitch',
      description: 'Chuyển sang ứng dụng khác',
      metadata: {
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }
}
