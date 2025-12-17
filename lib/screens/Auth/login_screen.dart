import 'package:flutter/material.dart';
import '../../controller/user_controller.dart';
import '../../component/HomeNavigation.dart';
import 'package:hugeicons/hugeicons.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _code1Controller = TextEditingController();
  final _code2Controller = TextEditingController();
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
    _code1Controller.dispose();
    _code2Controller.dispose();
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
    _userController.setCode1(_code1Controller.text);
    _userController.setCode2(_code2Controller.text);

    // Thực hiện đăng nhập
    final success = await _userController.login();

    if (success && mounted) {
      // Đăng nhập thành công, chuyển đến màn hình chính
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeNavigation()),
      );
    } else if (mounted && _userController.error != null) {
      // Hiển thị lỗi
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_userController.error!),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
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
                      color: Colors.blue,
                      size: 110.0,
                    ),
                    const Text(
                      "Đăng nhập",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      "Nhập mã sinh viên và mật khẩu để đăng nhập",
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 35),

                    // MÃ SINH VIÊN LẦN 1
                    TextFormField(
                      controller: _code1Controller,
                      decoration: const InputDecoration(
                        labelText: "Mã sinh viên",
                        hintText: "Nhập mã sinh viên...",
                        prefixIcon: Icon(Icons.account_circle_outlined),
                        border: OutlineInputBorder(),
                      ),
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.text,
                      textCapitalization: TextCapitalization.none,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập mã sinh viên';
                        }
                        final regex = RegExp(r'^[a-zA-Z0-9]+$');
                        if (!regex.hasMatch(value)) {
                          return 'Mã sinh viên chỉ được chứa chữ cái và số';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        _userController.setCode1(value);
                      },
                    ),

                    const SizedBox(height: 15),

                    // MẬT KHẨU
                    TextFormField(
                      controller: _code2Controller,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: "Mật khẩu",
                        hintText: "Nhập mật khẩu...",
                        prefixIcon: Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(),
                      ),
                      textInputAction: TextInputAction.done,
                      keyboardType: TextInputType.text,
                      textCapitalization: TextCapitalization.none,
                      onFieldSubmitted: (_) => _onLogin(),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập mật khẩu';
                        }
                        final regex = RegExp(r'^[a-zA-Z0-9]+$');
                        if (!regex.hasMatch(value)) {
                          return 'Mật khẩu chỉ được chứa chữ cái và số';
                        }
                        if (value != _code1Controller.text) {
                          return 'Mật khẩu không khớp với mã sinh viên. Vui lòng kiểm tra lại.';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        _userController.setCode2(value);
                      },
                    ),

                    SizedBox(height: 30),

                    // BUTTON LOGIN
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _userController.loading ? null : _onLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        child: _userController.loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                "Đăng nhập",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),

                    SizedBox(height: 150),
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center, // Căn giữa theo hàng ngang
                      crossAxisAlignment:
                          CrossAxisAlignment.center, // Căn giữa theo trục dọc
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
                          "developed by Juo and Natwo",
                          style: TextStyle(color: Colors.black, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
