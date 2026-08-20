import 'package:flutter/material.dart';
import '../l10n/app_l10n.dart';
import '../models/login.dart';
import '../services/auth/user_services.dart';

class UserController with ChangeNotifier {
  final UserService _authService = UserService();

  // State
  bool _loading = false;
  String? _error;
  String _userName = '';
  String _password = '';

  // Getters
  bool get loading => _loading;
  String? get error => _error;
  String get userName => _userName;
  String get password => _password;

  // Setters
  void setUserName(String value) {
    _userName = value;
    notifyListeners();
  }

  void setPassword(String value) {
    _password = value;
    notifyListeners();
  }

  /// Xử lý đăng nhập
  Future<bool> login() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final request = StudentLoginModel(
        userName: _userName,
        password: _password,
      );

      final validationError = request.validate();
      if (validationError != null) {
        _loading = false;
        _error = validationError;
        notifyListeners();
        return false;
      }

      final result = await _authService.login(_userName, _password);
      _loading = false;

      if (result.success) {
        notifyListeners();
        return true;
      } else {
        _error = result.error ?? AppL10n.current.msgLoginFailed;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _loading = false;
      _error = AppL10n.current.msgErrorWithDetail(e.toString());
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
    _userName = '';
    _password = '';
    _error = null;
    _loading = false;
    notifyListeners();
  }
}
