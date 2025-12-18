import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../../models/student.dart';
import '../../services/auth/user_services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'dart:io';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final UserService _userhService = UserService();
  final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();
  student? _student;
  Map<String, dynamic> _deviceData = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Load device info trước
    await _loadDeviceInfo();
    // Load profile sau
    await _loadProfile();
  }

  Future<void> _loadDeviceInfo() async {
    var deviceData = <String, dynamic>{};

    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfoPlugin.androidInfo;
        deviceData = {
          'Hệ điều hành': 'Android ${androidInfo.version.release}',
          'Thiết bị': '${androidInfo.brand} ${androidInfo.model}',
          'SDK': 'API ${androidInfo.version.sdkInt}',
        };
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfoPlugin.iosInfo;
        deviceData = {
          'Hệ điều hành': '${iosInfo.systemName} ${iosInfo.systemVersion}',
          'Thiết bị': iosInfo.modelName,
          'Tên': iosInfo.name,
        };
      }
    } catch (e) {
      deviceData = {'Lỗi': 'Không thể lấy thông tin thiết bị'};
    }

    if (!mounted) return;

    setState(() {
      _deviceData = deviceData;
    });
  }

  Future<void> _loadProfile() async {
    final profile = await _userhService.getProfile();
    if (!mounted) return;

    setState(() {
      _student = profile;
      // Thêm đăng nhập cuối vào device data sau khi có student
      if (_student?.lastLoggedIn != null) {
        _deviceData['Đăng nhập cuối'] = DateFormat(
          'HH:mm dd/MM/yyyy',
        ).format(_student!.lastLoggedIn!);
      } else {
        _deviceData['Đăng nhập cuối'] = 'Chưa đăng nhập';
      }
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
              SizedBox(height: 20),
              // Thông tin thiết bị
              if (_deviceData.isNotEmpty)
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedSmartPhone01,
                            color: Colors.blue,
                            size: 24,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Thông tin thiết bị',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      ..._deviceData.entries.map((entry) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${entry.key}: ',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  '${entry.value}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
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
