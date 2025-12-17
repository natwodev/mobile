import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:quizz_mobile/mockData/exam_test_screen.dart';

import '../models/newsmock.dart';
import '../component/HomeNavigation.dart';
import '../screens/scan_qr/scan_exam_qr_screen.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ExamTestScreen()),
          );
        },
        backgroundColor: Colors.deepPurple,
        icon: Icon(Icons.science, color: Colors.white),
        label: Text('Test LaTeX', style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header với Banner + 3 nút nhanh
            _buildHeader(context),
            // Danh sách bài báo
            _buildNewsList(),
          ],
        ),
      ),
    );
  }

  // Header: Banner + 3 nút nhanh đè lên (Stack)
  Widget _buildHeader(BuildContext context) {
    // Tăng chiều cao Stack để vùng 3 nút nhanh nằm TRONG vùng hit-test,
    // tránh bị widget phía dưới "ăn" mất sự kiện chạm.
    return SizedBox(
      height: 330,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 280,
            width: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/backgrondH.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Container 3 nút nhanh đè lên banner với bóng xanh
          Positioned(
            bottom: -50,
            left: 16,
            right: 16,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.18),
                    blurRadius: 25,
                    offset: Offset(0, 5),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildQuickButton(
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedMortarboard02,
                      color: Colors.blue,
                      size: 32,
                    ),
                    label: "Lớp học",
                    color: Colors.blue,
                    onTap: () {
                      // Chuyển sang tab "Bài kiểm tra" (index 3) trong bottom navigation
                      final navigationState = HomeNavigation.of(context);
                      if (navigationState != null) {
                        navigationState.changeTab(2);
                      }
                    },
                  ),
                  _buildQuickButton(
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedQrCode01,
                      color: Colors.blue,
                      size: 32,
                    ),
                    label: "Quéc mã bài thi",
                    color: Colors.blue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ScanExamQrScreen()),
                      );
                    },
                  ),
                  _buildQuickButton(
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedQuiz03,
                      color: Colors.blue,
                      size: 32,
                    ),
                    label: "Bài đã làm",
                    color: Colors.blue,
                    onTap: () {
                      // Chuyển sang tab "Bài kiểm tra" (index 3) trong bottom navigation
                      final navigationState = HomeNavigation.of(context);
                      if (navigationState != null) {
                        navigationState.changeTab(3);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Nút nhanh
  Widget _buildQuickButton({
    IconData? icon,
    Widget? child,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    // Ưu tiên widget tùy biến nếu được truyền, fallback dùng IconData
    final Widget iconWidget = child ?? Icon(icon, color: color, size: 32);

    return InkWell(
      onTap: () {
        // Log chung cho tất cả nút nhanh
        print('QuickButton tapped: $label');
        onTap();
      },
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color.fromARGB(255, 19, 131, 223), // màu viền
                width: 4, // độ dày viền
              ),
            ),
            child: Center(child: iconWidget),
          ),

          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // Danh sách bài báo
  Widget _buildNewsList() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: ListView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: newsMockData.length,
        itemBuilder: (context, index) {
          final news = newsMockData[index];
          return _buildNewsCard(news);
        },
      ),
    );
  }

  // Card bài báo
  Widget _buildNewsCard(NewsMock news) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            news.title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8),
          Text(
            news.content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.person_outline, size: 16, color: Colors.grey.shade500),
              SizedBox(width: 4),
              Text(
                news.author,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
              SizedBox(width: 16),
              Icon(
                Icons.access_time_outlined,
                size: 16,
                color: Colors.grey.shade500,
              ),
              SizedBox(width: 4),
              Text(
                '${news.publishedAt.day}/${news.publishedAt.month}/${news.publishedAt.year}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
