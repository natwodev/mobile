import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/account_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load file .env với xử lý lỗi encoding
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print("Không thể load file .env: $e");
    print("Sử dụng giá trị mặc định từ base_service");
  }

  runApp(HutechCampusApp()); // Chạy ứng dụng Flutter
}

class HutechCampusApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HUTECH Campus Info',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/login', // Route mặc định
      routes: {
        '/login': (context) => LoginScreen(),
        '/account': (context) => AccountScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
