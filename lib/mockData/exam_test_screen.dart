import 'package:flutter/material.dart';
import '../models/DTOs/originalExamPaperDto.dart';
import 'examData.dart';
import '../widget/exam/question_card.dart';
import '../widget/exam/question_navigator.dart';
import 'dart:async';

/// Màn hình test LaTeX với mock data - KHÔNG ảnh hưởng đến API
class ExamTestScreen extends StatefulWidget {
  const ExamTestScreen({super.key});

  @override
  State<ExamTestScreen> createState() => _ExamTestScreenState();
}

class _ExamTestScreenState extends State<ExamTestScreen> {
  Map<int, int> selectedAnswers = {};
  int currentQuestionIndex = 0;
  late PageController _pageController;
  bool autoNext = false;

  int _secondsLeft = 30 * 60; // 30 phút test
  Timer? _timer;
  final int _initialTime = 30 * 60;

  late List<OriginalExamPaperDetailDto> questions;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    questions = MockExamData.getMathQuestions();
    _startCountDown();
  }

  void _startCountDown() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        setState(() {
          _secondsLeft--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  String _formatTime(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalQuestions = questions.length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          '🧪 Test LaTeX (Mock Data)',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            margin: EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.timer, color: Colors.deepPurple, size: 20),
                SizedBox(width: 6),
                Text(
                  _formatTime(_secondsLeft),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              // Banner test mode
              Container(
                padding: EdgeInsets.all(8),
                margin: EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: Row(
                  children: [
                    Icon(Icons.science, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Chế độ TEST - Dữ liệu mock, không gọi API',
                        style: TextStyle(
                          color: Colors.orange[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Hiển thị tiến độ
              Container(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Câu ${currentQuestionIndex + 1}/$totalQuestions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    Text(
                      'Đã trả lời: ${selectedAnswers.length}/$totalQuestions',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),

              // PageView chứa các câu hỏi
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      currentQuestionIndex = index;
                    });
                  },
                  itemCount: questions.length,
                  itemBuilder: (context, index) {
                    final question = questions[index];
                    return SingleChildScrollView(
                      child: QuestionCard(
                        question: question,
                        questionNumber: index + 1,
                        selectedAnswerId:
                            selectedAnswers[question.originalExamPaperDetailId],
                        onAnswerSelected: (answerId) {
                          setState(() {
                            selectedAnswers[question
                                    .originalExamPaperDetailId] =
                                answerId;
                          });

                          if (autoNext && index < questions.length - 1) {
                            Future.delayed(Duration(milliseconds: 300), () {
                              _pageController.nextPage(
                                duration: Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            });
                          }
                        },
                      ),
                    );
                  },
                ),
              ),

              // Nút điều hướng
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: QuestionNavigator(
                  totalQuestions: totalQuestions,
                  answeredQuestions: selectedAnswers,
                  questionIds: questions
                      .map((q) => q.originalExamPaperDetailId)
                      .toList(),
                  currentIndex: currentQuestionIndex,
                  autoNext: autoNext,
                  onAutoNextChanged: (value) {
                    setState(() {
                      autoNext = value;
                    });
                  },
                  onQuestionTap: (index) {
                    _pageController.animateToPage(
                      index,
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  onPrevious: () {
                    _pageController.previousPage(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  onNext: () {
                    _pageController.nextPage(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  onSubmit: () {
                    _showResultDialog();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showResultDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('🎉 Kết quả Test'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tổng câu hỏi: ${questions.length}'),
            Text('Đã trả lời: ${selectedAnswers.length}'),
            Text('Thời gian còn lại: ${_formatTime(_secondsLeft)}'),
            SizedBox(height: 12),
            Text(
              '✅ LaTeX đã render thành công!',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tiếp tục test'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text('Thoát'),
          ),
        ],
      ),
    );
  }
}
