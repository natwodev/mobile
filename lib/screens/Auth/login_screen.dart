import 'dart:async';

import 'package:flutter/material.dart';

import '../../widget/common/app_inputs.dart';
import '../../controller/user_controller.dart';
import '../../component/HomeNavigation.dart';
import '../../controller/session_controller.dart';
import '../../services/notification/local_notification_service.dart';
import '../../services/notification/push_service.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widget/common/app_buttons.dart';
import '../../widget/common/app_toast.dart';
import 'forgot_password_sheet.dart';
import '../../widget/language_selector.dart';
import 'package:hugeicons/hugeicons.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late final UserController _userController;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _userController = UserController();
    _userController.addListener(_onAuthStateChanged);
  }

  @override
  void dispose() {
    _userController.removeListener(_onAuthStateChanged);
    _userNameController.dispose();
    _passwordController.dispose();
    _userController.dispose();
    super.dispose();
  }

  void _onAuthStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _onLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Cập nhật giá trị vào controller
    _userController.setUserName(_userNameController.text);
    _userController.setPassword(_passwordController.text);

    // Thực hiện đăng nhập
    final success = await _userController.login();

    if (success && mounted) {
      // Đăng nhập thành công: ghi nhận phiên rồi chuyển đến màn hình chính.
      // Không có dòng markSignedIn thì lần mở app sau vẫn vào đúng (vì đọc lại
      // token từ máy), nhưng trạng thái trong bộ nhớ sẽ lệch với thực tế.
      SessionController.instance.markSignedIn();

      // Xin quyền hiện thông báo NGAY SAU khi đăng nhập, không phải lúc vừa mở
      // app: tới đây người dùng đã là sinh viên có ca thi nên lời xin mới có
      // nghĩa. Hỏi khi vừa mở app thì đa số bấm từ chối, mà từ chối một lần là
      // phải vào Cài đặt hệ thống mới bật lại được.
      //
      // Không chặn luồng vào màn chính: từ chối quyền vẫn phải vào thi được.
      unawaited(LocalNotificationService.instance.requestPermissions());

      // Đăng ký token FCM với backend NGAY SAU khi có JWT. Lần đầu cài app thì
      // PushService.init() chạy lúc chưa đăng nhập nên đã bỏ qua bước này —
      // thiếu lần gọi ở đây là máy không bao giờ nhận được thông báo đẩy nào.
      unawaited(PushService.instance.syncToken());

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeNavigation()),
      );
    } else if (mounted && _userController.error != null) {
      // Hiển thị lỗi
      AppToast.show(
        context,
        kind: AppToastKind.error,
        title: _userController.error!,
        duration: const Duration(seconds: 3),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedMortarboard02,
                          color: AppColors.accent,
                          size: 110.0,
                        ),
                        Text(
                          l10n.authLoginTitle,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accent,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Text(
                          l10n.authLoginSubtitle,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 35),

                        // TÊN ĐĂNG NHẬP / MSSV
                        TextFormField(
                          controller: _userNameController,
                          decoration: InputDecoration(
                            labelText: l10n.authUsernameLabel,
                            hintText: l10n.authUsernameHint,
                            prefixIcon: AppInputs.icon(
                              HugeIcons.strokeRoundedUserCircle,
                            ),
                          ),
                          textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.text,
                          textCapitalization: TextCapitalization.none,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return l10n.authUsernameRequired;
                            }
                            return null;
                          },
                          onChanged: (value) {
                            _userController.setUserName(value);
                          },
                        ),

                        const SizedBox(height: 15),

                        // MẬT KHẨU
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: l10n.authPasswordLabel,
                            hintText: l10n.authPasswordHint,
                            prefixIcon: AppInputs.icon(
                              HugeIcons.strokeRoundedSquareLock01,
                            ),
                            suffixIcon: IconButton(
                              icon: AppInputs.icon(
                                _obscurePassword
                                    ? HugeIcons.strokeRoundedViewOff
                                    : HugeIcons.strokeRoundedView,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          textInputAction: TextInputAction.done,
                          keyboardType: TextInputType.text,
                          textCapitalization: TextCapitalization.none,
                          onFieldSubmitted: (_) => _onLogin(),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return l10n.authPasswordRequired;
                            }
                            if (value.trim().length < 6) {
                              return l10n.authPasswordMinLength;
                            }
                            return null;
                          },
                          onChanged: (value) {
                            _userController.setPassword(value);
                          },
                        ),

                        // Quên mật khẩu: nằm NGAY DƯỚI ô mật khẩu và căn phải.
                        //
                        // Đây là chỗ người dùng nhìn tới đúng vào lúc cần nó —
                        // sau khi gõ sai mật khẩu. Đặt dưới nút Đăng nhập thì
                        // họ đã bấm nút và nhận lỗi rồi mới thấy.
                        //
                        // Chữ nhỏ, không viền: đây là lối thoát phụ, không được
                        // tranh chấp với nút Đăng nhập ngay bên dưới.
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => showForgotPasswordSheet(context),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              l10n.authForgotPasswordLink,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 18),

                        // BUTTON LOGIN
                        // Chỉ giữ `width` — chiếm trọn bề ngang là ý đồ bố cục;
                        // màu/bo góc/chiều cao/cỡ chữ đã do theme lo.
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _userController.loading
                                ? null
                                : _onLogin,
                            // Vòng quay thay chỗ cho chữ nên phải lấy MÀU CHỮ
                            // lúc nút bị khoá: trong lúc tải nút đang disabled,
                            // nền chuyển xám nhạt và vòng quay trắng biến mất.
                            child: _userController.loading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: AppColors.disabledInk,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(l10n.authLoginTitle),
                          ),
                        ),

                        SizedBox(height: 150),
                        Row(
                          mainAxisAlignment: MainAxisAlignment
                              .center, // Căn giữa theo hàng ngang
                          crossAxisAlignment: CrossAxisAlignment
                              .center, // Căn giữa theo trục dọc
                          children: [
                            CircleAvatar(
                              radius: 17,
                              backgroundColor: Colors.grey[500],
                              child: HugeIcon(
                                icon: HugeIcons.strokeRoundedGithub,
                                color: Colors.white,
                                size: 26.0,
                              ),
                            ),
                            SizedBox(width: 5),
                            Text(
                              "developed by Natwo",
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Cho phép đổi ngôn ngữ ngay ở màn đăng nhập, trước khi có tài khoản.
            const Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: EdgeInsets.only(top: 8, right: 8),
                child: LanguageToggleButton(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
