import 'package:flutter/material.dart';
import '../../services/auth/user_services.dart';
import '../../models/DTOs/originalExamPaperDto.dart';
import '../../widget/exam/question_card.dart';
import '../../widget/exam/question_navigator.dart';
import '../../widget/exam/anti_cheat_detector.dart';
import 'exam_result_screen.dart';
import 'dart:async';
import 'package:toastification/toastification.dart';

class ExamScreen extends StatefulWidget {
  // Trường hợp 1: vào từ danh sách ca thi -> dùng sessionId và gọi startExam
  // Trường hợp 2: vào từ quét mã QR -> vẫn truyền sessionId (từ result.startExamQR),
  // nhưng đồng thời truyền thêm initialData để KHÔNG gọi lại startExam nữa.
  final int sessionId; // nhận sessionId từ màn trước

  /// Nếu được truyền sẵn dữ liệu (trường hợp đi từ QR với startExamQR),
  /// màn này sẽ dùng luôn mà KHÔNG gọi lại startExam lần nữa.
  final StartExamResponseDto? initialData;

  ExamScreen({super.key, required this.sessionId, this.initialData});

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> {
  late Future<StartExamResponseDto?> _futureSessions;
  Map<int, int> selectedAnswers = {}; // Map: questionId -> answerId
  int currentQuestionIndex = 0; // Chỉ số câu hỏi hiện tại
  late PageController _pageController;
  bool autoNext = false; // Tự động chuyển câu

  int _secondsLeft = 0; // biến đếm ngược
  Timer? _timer;
  int _initialTime = 0; // Tổng thời gian ban đầu

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // Nếu đã có dữ liệu từ QR (startExamQR) thì dùng luôn,
    // KHÔNG gọi lại UserService().startExam để tránh lệch thời gian / tạo ca thi mới.
    if (widget.initialData != null) {
      _futureSessions = Future.value(widget.initialData);
      _setupCountdownFromQr(widget.initialData!);
      _loadPreviousAnswers(widget.initialData!);
    } else {
      // Trường hợp bình thường: vào từ danh sách ca thi
      _futureSessions = UserService().startExam(widget.sessionId);

      // Bắt đầu đếm ngược khi có dữ liệu
      _futureSessions.then((examData) {
        if (examData != null) {
          _setupCountdownFromSession(examData);
          _loadPreviousAnswers(examData);
        }
      });
    }
  }

  /// Parse và load lại các câu trả lời đã chọn từ studentAnswersString
  /// Format: "(key:value);(key:value);..."
  void _loadPreviousAnswers(StartExamResponseDto examData) {
    final answersString = examData.studentSession.studentAnswersString;
    if (answersString == null || answersString.isEmpty) {
      return;
    }

    try {
      // Parse chuỗi dạng: "(123:456);(789:101);..."
      final pairs = answersString.split(';');

      for (final pair in pairs) {
        if (pair.isEmpty) continue;

        // Loại bỏ dấu ngoặc đơn nếu có
        final cleanPair = pair.replaceAll('(', '').replaceAll(')', '').trim();
        if (cleanPair.isEmpty) continue;

        final parts = cleanPair.split(':');
        if (parts.length == 2) {
          final key = int.tryParse(parts[0].trim());
          final value = int.tryParse(parts[1].trim());

          if (key != null && value != null) {
            setState(() {
              selectedAnswers[key] = value;
            });
          }
        }
      }

      debugPrint(
        '✅ Đã khôi phục ${selectedAnswers.length} câu trả lời từ studentAnswersString',
      );
    } catch (e) {
      debugPrint('❌ Lỗi parse studentAnswersString: $e');
    }
  }

  /// Case 1: Vào từ danh sách ca thi (startExam)
  /// Đếm ngược theo: (duration trong studentSession) - (thời gian đã trôi từ examSessionStartTime)
  void _setupCountdownFromSession(StartExamResponseDto examData) {
    int durationMinutes = examData.studentSession.duration;

    print("DEBUG - duration từ studentSession (startExam): $durationMinutes");

    if (durationMinutes <= 0) {
      print("DEBUG - durationMinutes trong studentSession = 0");
      return;
    }

    final startTime = examData.studentSession.examSessionStartTime;
    final now = DateTime.now();

    final elapsedSeconds = now.difference(startTime).inSeconds;
    final totalSeconds = durationMinutes * 60;
    final remainSeconds = totalSeconds - elapsedSeconds;

    _initialTime = totalSeconds; // Lưu tổng thời gian ban đầu

    if (remainSeconds > 0) {
      _startCountDown(remainSeconds);
    } else {
      print("Hết giờ từ trước rồi (startExam)!");
    }
  }

  /// Case 2: Vào từ QR (startExamQR)
  /// Đếm ngược theo durationMinutes của đề gốc, trừ phần đã trôi qua theo examSessionStartTime
  void _setupCountdownFromQr(StartExamResponseDto examData) {
    int durationMinutes = examData.originalExamPaper.durationMinutes;

    print(
      "DEBUG - durationMinutes từ originalExamPaper (startExamQR): $durationMinutes",
    );
    print(
      "DEBUG - duration từ studentSession: ${examData.studentSession.duration}",
    );

    // không dùng parse nữa vì nó đã là DateTime
    final startTime = examData.studentSession.examSessionStartTime;
    final now = DateTime.now();

    final elapsedSeconds = now.difference(startTime).inSeconds;
    final totalSeconds = durationMinutes * 60;
    final remainSeconds = totalSeconds - elapsedSeconds;

    _initialTime = totalSeconds; // Lưu tổng thời gian

    if (remainSeconds > 0) {
      _startCountDown(remainSeconds);
    } else {
      print("Hết giờ từ trước rồi!");
    }
  }

  void _startCountDown(int seconds) {
    setState(() {
      _secondsLeft = seconds;
    });

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        setState(() {
          _secondsLeft--;
        });
        print("Thời gian còn lại: ${_formatTime(_secondsLeft)}"); // Debug
      } else {
        timer.cancel();
        print("Hết giờ!");
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
    _timer?.cancel(); // hủy timer khi màn hình bị dispose
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AntiCheatDetector(
      onAutoSubmit: () {
        // Tự động nộp bài khi phát hiện gian lận 3 lần
        _autoSubmitExam();
      },
      child: FutureBuilder<StartExamResponseDto?>(
        future: _futureSessions,
        builder: (context, snapshot) {
          String title = 'Bài kiểm tra'; // fallback tạm thời
          if (snapshot.hasData && snapshot.data != null) {
            final data = snapshot.data!;

            // Nếu đi từ QR (có initialData) -> ưu tiên dùng tiêu đề đề thi gốc
            if (widget.initialData != null) {
              title = data.originalExamPaper.title;
            } else {
              // Trường hợp bình thường: ưu tiên tên môn, nếu rỗng thì fallback về title đề thi
              final subjectName = data.studentSession.subjectName;
              title = subjectName.isNotEmpty
                  ? subjectName
                  : data.originalExamPaper.title;
            }
          }

          return WillPopScope(
            onWillPop: () async {
              // Chặn nút back của hệ thống
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Không thể thoát khi đang làm bài! Vui lòng nộp bài để kết thúc.',
                  ),
                  duration: Duration(seconds: 2),
                ),
              );
              return false; // Không cho phép back
            },
            child: Scaffold(
              backgroundColor: Colors.white,
              appBar: AppBar(
                title: Text(title, style: TextStyle(color: Colors.white)),
                centerTitle: true,
                backgroundColor: Colors.blue,
                automaticallyImplyLeading: false, // Ẩn nút back
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
                        Icon(Icons.timer, color: Colors.blue, size: 20),
                        SizedBox(width: 6),
                        Text(
                          _formatTime(_secondsLeft),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
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
                  child: _buildBody(snapshot),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(AsyncSnapshot<StartExamResponseDto?> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return Center(child: CircularProgressIndicator());
    } else if (snapshot.hasError) {
      return Center(child: Text('Lỗi: ${snapshot.error}'));
    } else if (!snapshot.hasData || snapshot.data == null) {
      return Center(child: Text('Không có dữ liệu bài kiểm tra'));
    }

    final examData = snapshot.data!;
    final questions = examData.originalExamPaper.details;

    if (questions.isEmpty) {
      return Center(child: Text('Đề thi không có câu hỏi'));
    }

    final totalQuestions = questions.length;

    return Column(
      children: [
        // Hiển thị tiến độ
        Container(
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
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
                  color: Colors.blue,
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
                      selectedAnswers[question.originalExamPaperDetailId] =
                          answerId;
                    });

                    // Tự động chuyển câu nếu bật
                    if (autoNext && index < questions.length - 1) {
                      Future.delayed(Duration(milliseconds: 300), () {
                        _pageController.nextPage(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      });
                    }
                  },
                  studentExamSessionId: widget.sessionId,
                  userService: UserService(),
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
              _showSubmitDialog(context);
            },
          ),
        ),
      ],
    );
  }

  void _showSubmitDialog(BuildContext context) async {
    final examData = await _futureSessions;
    if (examData == null) return;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Nộp bài thi'),
          content: Text(
            'Bạn đã trả lời ${selectedAnswers.length} câu.\n'
            'Bạn có chắc chắn muốn nộp bài không?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);

                // Hiển thị loading
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) =>
                      Center(child: CircularProgressIndicator()),
                );

                try {
                  // Gọi API submitExam
                  final submitResult = await UserService().submitExam(
                    widget.sessionId,
                  );

                  // Đóng loading
                  if (mounted) Navigator.pop(context);

                  if (submitResult != null) {
                    // Nộp bài thành công, hiển thị toast
                    debugPrint('✅ Nộp bài thành công: ${submitResult.message}');
                    
                    if (mounted) {
                      toastification.show(
                        context: context,
                        type: ToastificationType.success,
                        style: ToastificationStyle.fillColored,
                        title: Text('Nộp bài thành công'),
                        description: Text(submitResult.message),
                        alignment: Alignment.topCenter,
                        autoCloseDuration: Duration(seconds: 3),
                        showProgressBar: true,
                      );
                    }

                    // Gọi API lấy kết quả chi tiết
                    final submissionData = await UserService()
                        .getSubmissionResult(widget.sessionId);

                    if (submissionData != null) {
                      final timeSpent = _initialTime - _secondsLeft;

                      // Chuyển sang trang kết quả với dữ liệu từ server
                      if (mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ExamResultScreen(
                              examTitle: examData.originalExamPaper.title,
                              totalQuestions:
                                  submissionData.totalQuestions ??
                                  examData.originalExamPaper.details.length,
                              answeredQuestions: selectedAnswers.length,
                              timeSpent: timeSpent,
                              totalTime: _initialTime,
                              score: submissionData.score ?? 0.0,
                            ),
                          ),
                        );
                      }
                    } else {
                      // Không lấy được kết quả chi tiết, dùng dữ liệu tạm
                      debugPrint('⚠️ Không lấy được kết quả chi tiết');
                      final timeSpent = _initialTime - _secondsLeft;

                      if (mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ExamResultScreen(
                              examTitle: examData.originalExamPaper.title,
                              totalQuestions:
                                  examData.originalExamPaper.details.length,
                              answeredQuestions: selectedAnswers.length,
                              timeSpent: timeSpent,
                              totalTime: _initialTime,
                              score: 0.0,
                            ),
                          ),
                        );
                      }
                    }
                  }
                } catch (e) {
                  // Đóng loading
                  if (mounted) Navigator.pop(context);

                  debugPrint('❌ Lỗi khi nộp bài: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Có lỗi xảy ra khi nộp bài: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: Text('Nộp bài'),
            ),
          ],
        );
      },
    );
  }

  // Hàm tự động nộp bài khi phát hiện gian lận
  void _autoSubmitExam() async {
    final examData = await _futureSessions;
    if (examData == null) return;

    final totalQuestions = examData.originalExamPaper.details.length;
    final correctAnswers = selectedAnswers.length;
    final score = totalQuestions > 0
        ? (correctAnswers / totalQuestions * 10)
        : 0.0;

    final timeSpent = _initialTime - _secondsLeft;

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ExamResultScreen(
          examTitle: examData.originalExamPaper.title,
          totalQuestions: totalQuestions,
          answeredQuestions: selectedAnswers.length,
          timeSpent: timeSpent,
          totalTime: _initialTime,
          score: score,
        ),
      ),
    );
  }
}
