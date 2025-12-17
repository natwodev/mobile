class AuthResult {
  final bool success;
  final String? token;
  final String? error;

  AuthResult({required this.success, this.token, this.error});
}

class StudentLoginModel {
  final String studentCode1;
  final String studentCode2;

  StudentLoginModel({required this.studentCode1, required this.studentCode2});

  /// Convert sang JSON để gửi lên API
  /// Format: {"studentCode1": "...", "studentCode2": "..."}
  Map<String, dynamic> toJson() {
    return {
      'studentCode1': studentCode1.trim(),
      'studentCode2': studentCode2.trim(),
    };
  }

  /// Validation theo logic backend
  ///
  /// Returns:
  /// - null: Hợp lệ
  /// - String: Thông báo lỗi nếu không hợp lệ
  String? validate() {
    // Kiểm tra không rỗng
    if (studentCode1.isEmpty) {
      return 'Vui lòng nhập mã sinh viên';
    }
    if (studentCode2.isEmpty) {
      return 'Vui lòng nhập mã sinh viên lần 2';
    }

    // Kiểm tra format (chỉ chữ cái và số) - giống frontend web
    final regex = RegExp(r'^[a-zA-Z0-9]+$');
    if (!regex.hasMatch(studentCode1)) {
      return 'Mã sinh viên chỉ được chứa chữ cái và số';
    }
    if (!regex.hasMatch(studentCode2)) {
      return 'Mã sinh viên chỉ được chứa chữ cái và số';
    }

    // Kiểm tra 2 mã phải giống nhau (logic backend)
    if (studentCode1 != studentCode2) {
      return 'Mã sinh viên nhập không khớp. Vui lòng kiểm tra lại.';
    }

    return null; // Hợp lệ
  }
}
