// services/auth_service.dart
import 'dart:convert';
import '../base_service.dart';
import '../../models/login.dart';
import '../../models/student.dart';
import '../../models/studentExamSession.dart';
import '../../models/studentExamSessionHistory.dart';
import '../../models/DTOs/originalExamPaperDto.dart';
import '../../models/saveAnswerResponse.dart';
import '../../models/submitExamResponse.dart';

class UserService extends BaseService {
  // Đăng nhập
  Future<AuthResult> login(String code1, String code2) async {
    try {
      final response = await post('api/student/login-mobile', {
        'studentCode1': code1,
        'studentCode2': code2,
      });

      final data = jsonDecode(response.body);

      if (data['token'] != null) {
        await saveToken(data['token']);
        return AuthResult(token: data['token'], success: true);
      } else {
        return AuthResult(
          success: false,
          error: data['errorMessage'] ?? 'Đăng nhập thất bại',
        );
      }
    } catch (e) {
      return AuthResult(success: false, error: e.toString());
    }
  }

  // Đăng xuất
  Future<void> logout() async {
    await removeToken();
  }

  // Kiểm tra đã đăng nhập
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Lấy thông tin profile
  Future<student?> getProfile() async {
    try {
      final response = await get('api/student/profile');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return student.fromJson(data); // map JSON sang object Dart
      } else if (response.statusCode == 401) {
        throw Exception('Token không hợp lệ hoặc hết hạn.');
      } else if (response.statusCode == 404) {
        throw Exception('Sinh viên không tồn tại.');
      } else {
        throw Exception('Lỗi API: ${response.statusCode}');
      }
    } catch (e) {
      print('Lỗi getProfile: $e');
      return null;
    }
  }

  Future<List<StudentExamSession>?> getExamSession() async {
    try {
      final response = await get('api/Student/exam-sessions');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return (data as List)
            .map((item) => StudentExamSession.fromJson(item))
            .toList();
      }

      return null;
    } catch (e) {
      print('Lỗi getExamSession: $e');
      return null;
    }
  }

  Future<List<StudentExamSessionHistory>?> getExamSessionByStudent() async {
    try {
      final response = await get('api/Student/ExamSession-by-student-code');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return (data as List)
            .map((item) => StudentExamSessionHistory.fromJson(item))
            .toList();
      }

      return null;
    } catch (e) {
      print('Lỗi getExamSession: $e');
      return null;
    }
  }

  // Start Exam
  Future<StartExamResponseDto?> startExam(int studentExamSessionId) async {
    try {
      final response = await postForm('api/Student/start-exam-original', {
        'studentExamSessionId': studentExamSessionId.toString(),
      });
      print("Sending studentExamSessionId: $studentExamSessionId");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = StartExamResponseDto.fromJson(data);

        return result;
      } else {
        print('StartExam failed: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('Lỗi startExam: $e');
      return null;
    }
  }

  // Start Exam QR
  Future<StartExamResponseDto?> startExamQR(int originalExamPaperId) async {
    try {
      final response = await postForm('api/Student/create-session-original', {
        'originalExamPaperId': originalExamPaperId.toString(),
      });
      print("Sending originalExamPaperId: $originalExamPaperId");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = StartExamResponseDto.fromJson(data);

        return result;
      } else {
        print('StartExam failed: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('Lỗi startExam: $e');
      return null;
    }
  }

  // Start Exam Core (Create Session with Original Paper Core)
  Future<StartExamResponseDto?> startExamCore(
    String originalExamPaperCore,
  ) async {
    try {
      final response = await postForm(
        'api/Student/create-session-original-core',
        {'originalExamPaperCore': originalExamPaperCore},
      );
      print("Sending originalExamPaperCore: $originalExamPaperCore");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = StartExamResponseDto.fromJson(data);

        return result;
      } else {
        print('startExamCore failed: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('Lỗi startExamCore: $e');
      return null;
    }
  }

  Future<bool> resetExamSessionStartTime() async {
    try {
      final response = await post(
        'api/Lecturer/reset-exam-session-start-time',
        {}, // body rỗng
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print(
          'resetExamSessionStartTime failed: ${response.statusCode} ${response.body}',
        );
        return false;
      }
    } catch (e) {
      print('Lỗi resetExamSessionStartTime: $e');
      return false;
    }
  }

  // Save Answer
  Future<SaveAnswerResponse?> saveAnswer({
    required int studentExamSessionId,
    required int key,
    required dynamic value,
  }) async {
    try {
      final response = await post('api/Student/save-answer', {
        'StudentExamSessionId': studentExamSessionId,
        'key': key,
        'value': value,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return SaveAnswerResponse.fromJson(data);
      } else {
        print('saveAnswer failed: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('Lỗi saveAnswer: $e');
      return null;
    }
  }

  // Submit Exam
  Future<SubmitExamResponse?> submitExam(int studentExamSessionId) async {
    try {
      final response = await post('api/Student/submit-exam', {
        'studentExamSessionId': studentExamSessionId,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return SubmitExamResponse.fromJson(data);
      } else {
        print('submitExam failed: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('Lỗi submitExam: $e');
      return null;
    }
  }
}
