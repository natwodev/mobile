// controllers/login_controller.dart
import 'package:flutter/material.dart';
import '../models/login.dart';
import '../services/auth/user_services.dart';

/// Controller xử lý logic đăng nhập
/// Sử dụng AuthService để gọi API (composition thay vì inheritance)
class UserController with ChangeNotifier {
  final UserService _authService = UserService();

  // State
  bool _loading = false;
  String? _error;
  String _code1 = '';
  String _code2 = '';

  // Getters
  bool get loading => _loading;
  String? get error => _error;
  String get code1 => _code1;
  String get code2 => _code2;

  // Setters
  void setCode1(String value) {
    _code1 = value;
    notifyListeners();
  }

  void setCode2(String value) {
    _code2 = value;
    notifyListeners();
  }

  /// Xử lý đăng nhập
  /// Gọi AuthService để xử lý logic API
  Future<bool> login() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      // Validation
      final request = StudentLoginModel(
        studentCode1: _code1,
        studentCode2: _code2,
      );

      final validationError = request.validate();
      if (validationError != null) {
        _loading = false;
        _error = validationError;
        notifyListeners();
        return false;
      }

      // Gọi AuthService
      final result = await _authService.login(_code1, _code2);
      _loading = false;

      if (result.success) {
        notifyListeners();
        return true;
      } else {
        _error = result.error ?? 'Đăng nhập thất bại';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _loading = false;
      _error = 'Lỗi: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Đăng xuất
  Future<void> logout() async {
    await _authService.logout();
    notifyListeners();
  }

  /// Kiểm tra đã đăng nhập
  Future<bool> isLoggedIn() async {
    return await _authService.isLoggedIn();
  }

  /// Reset form
  void reset() {
    _code1 = '';
    _code2 = '';
    _error = null;
    _loading = false;
    notifyListeners();
  }
}
