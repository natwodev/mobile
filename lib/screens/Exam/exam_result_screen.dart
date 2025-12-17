import 'package:flutter/material.dart';
import '../../widget/exam_result/score_card.dart';
import '../../widget/exam_result/exam_info_card.dart';
import '../../widget/exam_result/exam_notice.dart';
import '../../widget/exam_result/home_button.dart';

class ExamResultScreen extends StatelessWidget {
  final String examTitle;
  final int totalQuestions;
  final int answeredQuestions;
  final int timeSpent;
  final int totalTime;
  final double score;

  const ExamResultScreen({
    Key? key,
    required this.examTitle,
    required this.totalQuestions,
    required this.answeredQuestions,
    required this.timeSpent,
    required this.totalTime,
    this.score = 0.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Kết quả bài thi', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.blue,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              // Điểm số lớn
              ScoreCard(score: score),
              SizedBox(height: 16),

              // Tên bài thi
              Text(
                examTitle,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),

              // Card thông tin
              ExamInfoCard(
                totalQuestions: totalQuestions,
                answeredQuestions: answeredQuestions,
                timeSpent: timeSpent,
                totalTime: totalTime,
              ),
              SizedBox(height: 16),

              // Thông báo
              ExamNotice(),
              SizedBox(height: 24),

              // Nút về trang chủ
              HomeButton(),
            ],
          ),
        ),
      ),
    );
  }
}
