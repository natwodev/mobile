import '../l10n/app_l10n.dart';

class AuthResult {
  final bool success;
  final String? token;
  final String? error;
  final String? id;
  final String? userName;
  final String? userCode;
  final String? fullName;
  final String? avatarUrl;
  final String? role;

  AuthResult({
    required this.success,
    this.token,
    this.error,
    this.id,
    this.userName,
    this.userCode,
    this.fullName,
    this.avatarUrl,
    this.role,
  });
}

class StudentLoginModel {
  final String userName;
  final String password;

  StudentLoginModel({required this.userName, required this.password});

  Map<String, dynamic> toJson() {
    return {'userName': userName.trim(), 'password': password.trim()};
  }

  String? validate() {
    final l10n = AppL10n.current;
    if (userName.trim().isEmpty) {
      return l10n.msgLoginUserNameRequired;
    }
    if (password.trim().isEmpty) {
      return l10n.msgLoginPasswordRequired;
    }
    if (password.length < 6) {
      return l10n.msgLoginPasswordTooShort;
    }
    return null;
  }
}
