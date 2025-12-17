import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/student.dart';
import '../../services/auth/user_services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final UserService _userhService = UserService();
  student? _student;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await _userhService.getProfile();
    setState(() {
      _student = profile;
    });
  }

  Future<void> _logout(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      Navigator.pushNamedAndRemoveUntil(context, "/login", (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Đăng xuất thất bại: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.grey[300],
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedUser,
                        color: Colors.white,
                        size: 30.0,
                      ),
                    ),
                    SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _student != null
                              ? '${_student!.firstName} ${_student!.lastName}'
                              : 'Đang tải...',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(width: 8), // khoảng cách giữa icon và text
                        Row(
                          children: [
                            HugeIcon(
                              icon: HugeIcons.strokeRoundedIdentityCard,
                              color: Colors.black,
                              size: 30.0,
                            ),
                            SizedBox(width: 4),
                            Text(
                              _student?.studentCode ?? "Đang tải...",
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 60),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _student != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          //HugeIcons.strokeRoundedLogin02
                          SizedBox(height: 8),
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.grey[300],
                                child: HugeIcon(
                                  icon: HugeIcons.strokeRoundedLoginSquare02,
                                  color: Colors.black,
                                  size: 30.0,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                "Đăng nhập cuối: " +
                                    (_student?.lastLoggedIn != null
                                        ? DateFormat(
                                            'dd/MM/yyyy HH:mm',
                                          ).format(_student!.lastLoggedIn!)
                                        : 'Chưa đăng nhập'),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    : Text(
                        "Đang tải...",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
              ),
              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    _logout(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  child: const Text(
                    "Đăng xuất",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
