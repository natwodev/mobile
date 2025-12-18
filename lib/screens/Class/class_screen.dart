import 'package:flutter/material.dart';

class ClassScreen extends StatelessWidget {
  const ClassScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Lớp học",
          style: TextStyle(
            fontSize: 22,
            color: Colors.white, // màu chữ
          ),
        ),
        backgroundColor: Colors.blue, // Đặt màu nền đúng định dạng ARGB
        centerTitle: true,
      ),
      body: const Center(child: Text("Danh sách lớp học\n(đang được phát triển)")),
    );
  }
}
