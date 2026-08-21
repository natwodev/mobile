import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/auth/user_services.dart';
import '../../widget/common/app_banner.dart';
import '../../widget/common/app_buttons.dart';
import '../../widget/common/app_inputs.dart';
import '../../widget/common/app_sheet.dart';
import '../../widget/common/app_surfaces.dart';

/// Mở tấm "Quên mật khẩu" trượt lên từ đáy màn Đăng nhập.
Future<void> showForgotPasswordSheet(BuildContext context) {
  return showAppSheet<void>(
    context: context,
    title: AppLocalizations.of(context).authForgotPasswordTitle,
    icon: HugeIcons.strokeRoundedSquareLockPassword,
    children: const [_ForgotPasswordForm()],
  );
}

/// Xin máy chủ gửi email khôi phục mật khẩu.
///
/// App CHỈ làm bước này. Bước đặt lại mật khẩu cần mã nằm trong đường dẫn của
/// email nên diễn ra trên web — nhét cả luồng đó vào app thì phải dựng thêm màn
/// nhận mã, mà người dùng vẫn phải mở email ra chép mã sang.
class _ForgotPasswordForm extends StatefulWidget {
  const _ForgotPasswordForm();

  @override
  State<_ForgotPasswordForm> createState() => _ForgotPasswordFormState();
}

class _ForgotPasswordFormState extends State<_ForgotPasswordForm> {
  final TextEditingController _email = TextEditingController();
  final UserService _userService = UserService();

  bool _sending = false;
  String? _error;

  /// Đã gửi xong. Đổi hẳn nội dung tấm sheet thay vì chỉ hiện một thanh báo rồi
  /// đóng: người dùng cần biết PHẢI ĐI MỞ EMAIL, mà thanh báo thì trôi mất sau
  /// vài giây.
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final String email = _email.text.trim();

    if (email.isEmpty) {
      setState(() => _error = l10n.authEmailRequired);
      return;
    }
    // Cùng biểu thức với màn Sửa hồ sơ. Kiểm ở máy trước khi gọi mạng: gõ thiếu
    // dấu @ mà vẫn bắt chờ một vòng gọi mạng rồi mới báo thì vô ích.
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      setState(() => _error = l10n.authEmailInvalid);
      return;
    }

    setState(() {
      _error = null;
      _sending = true;
    });

    final result = await _userService.forgotPassword(email);
    if (!mounted) return;

    setState(() {
      _sending = false;
      _sent = result.success;
    });

    if (!result.success) {
      showErrorBanner(
        context,
        result.error ?? AppLocalizations.of(context).authForgotPasswordFailed,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_sent) return _buildSent(l10n);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.authForgotPasswordMessage,
          style: const TextStyle(
            fontSize: 14,
            height: 1.45,
            color: AppColors.inkMuted,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          autofocus: true,
          onSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            labelText: l10n.authEmailLabel,
            hintText: l10n.authEmailHint,
            errorText: _error,
            prefixIcon: AppInputs.icon(HugeIcons.strokeRoundedMail01),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _sending ? null : _submit,
            child: _sending
                // Nút đang khoá nên nền xám nhạt — vòng quay trắng sẽ tàng hình
                // trên nền đó, phải lấy màu chữ của trạng thái khoá.
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.disabledInk,
                    ),
                  )
                : Text(l10n.authForgotPasswordSend),
          ),
        ),
      ],
    );
  }

  /// Màn sau khi gửi xong.
  ///
  /// KHÔNG nói "email đã được gửi tới <địa chỉ>" như một lời khẳng định: máy chủ
  /// cố tình trả về thành công kể cả khi email không có trong hệ thống, để người
  /// lạ không dò được ai đang có tài khoản. Nên câu chữ ở đây phải đúng với
  /// những gì thật sự biết — đã gửi YÊU CẦU, còn hòm thư có gì thì mở ra xem.
  Widget _buildSent(AppLocalizations l10n) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: const HugeIcon(
            icon: HugeIcons.strokeRoundedMailValidation01,
            color: AppColors.accent,
            size: 36,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.authForgotPasswordSentTitle,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.authForgotPasswordSentMessage,
          style: const TextStyle(
            fontSize: 13,
            height: 1.45,
            color: AppColors.inkMuted,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: AppSurfaces.card(color: AppColors.accentBg, soft: true),
          child: Text(
            _email.text.trim(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.accent,
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.commonClose),
          ),
        ),
      ],
    );
  }
}
