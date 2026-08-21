import 'package:hugeicons/hugeicons.dart';
import 'package:flutter/material.dart';

import '../../widget/common/app_top_bar.dart';

import '../../widget/common/app_inputs.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/auth/user_services.dart';
import '../../widget/common/app_buttons.dart';
import '../../widget/common/app_toast.dart';

/// Đổi mật khẩu cho sinh viên đang đăng nhập.
/// Trả về `true` qua Navigator.pop khi đổi thành công.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final UserService _userService = UserService();

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _saving = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final result = await _userService.changePassword(
      currentPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
      confirmNewPassword: _confirmPasswordController.text,
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (result.success) {
      Navigator.pop(context, true);
      return;
    }

    AppToast.show(
      context,
      kind: AppToastKind.error,
      title:
          result.error ?? AppLocalizations.of(context).authChangePasswordFailed,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppTopBar(title: l10n.authChangePasswordTitle, showBack: true),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildPasswordField(
                controller: _currentPasswordController,
                label: l10n.authCurrentPasswordLabel,
                hint: l10n.authCurrentPasswordHint,
                obscure: _obscureCurrent,
                onToggle: () =>
                    setState(() => _obscureCurrent = !_obscureCurrent),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.authCurrentPasswordRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildPasswordField(
                controller: _newPasswordController,
                label: l10n.authNewPasswordLabel,
                hint: l10n.authNewPasswordHint,
                obscure: _obscureNew,
                onToggle: () => setState(() => _obscureNew = !_obscureNew),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.authNewPasswordRequired;
                  }
                  if (value.length < 6) {
                    return l10n.authPasswordMinLength;
                  }
                  if (value == _currentPasswordController.text) {
                    return l10n.authNewPasswordSameAsCurrent;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildPasswordField(
                controller: _confirmPasswordController,
                label: l10n.authConfirmPasswordLabel,
                hint: l10n.authConfirmPasswordHint,
                obscure: _obscureConfirm,
                textInputAction: TextInputAction.done,
                onToggle: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.authConfirmPasswordRequired;
                  }
                  if (value != _newPasswordController.text) {
                    return l10n.authConfirmPasswordMismatch;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 28),

              // Giữ `width` cho nút chiếm trọn bề ngang, phần còn lại theo theme.
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  // Nút đang bị khoá trong lúc lưu -> nền xám nhạt, nên vòng
                  // quay phải lấy màu chữ lúc khoá chứ không phải màu trắng.
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: AppColors.disabledInk,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(l10n.authChangePasswordTitle),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
    TextInputAction textInputAction = TextInputAction.next,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      textInputAction: textInputAction,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: AppInputs.icon(HugeIcons.strokeRoundedSquareLock01),
        suffixIcon: IconButton(
          icon: AppInputs.icon(
            obscure
                ? HugeIcons.strokeRoundedViewOff
                : HugeIcons.strokeRoundedView,
          ),
          onPressed: onToggle,
        ),
      ),
      validator: validator,
    );
  }
}
