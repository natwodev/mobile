import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'auth/login_screen.dart';
import '../component/HomeNavigation.dart';
import '../controller/user_controller.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    // Đợi 2 giây để hiển thị splash screen
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    try {
      // Kiểm tra xem đã đăng nhập chưa
      final authController = UserController();
      final isLoggedIn = await authController.isLoggedIn();
      authController.dispose();

      if (!mounted) return;

      // Chuyển đến màn hình tiếp theo
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) =>
              isLoggedIn ? const HomeNavigation() : const LoginScreen(),
        ),
      );
    } catch (e) {
      // Nếu có lỗi, chuyển đến màn hình login
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade400, Colors.blue.shade600],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo hoặc icon
              const HugeIcon(
                icon: HugeIcons.strokeRoundedMortarboard02,
                size: 100,
                color: Colors.white,
              ),
              const SizedBox(height: 20),

              // Tên app
              const Text(
                'HUTECH Campus',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),

              const Text(
                'Quiz Mobile',
                style: TextStyle(fontSize: 18, color: Colors.white70),
              ),
              const SizedBox(height: 50),

              // Loading indicator
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
