import 'package:flutter/material.dart';
import '../../services/auth/user_services.dart';
import 'package:intl/intl.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:marquee/marquee.dart';
import '../../models/studentExamSessionHistory.dart';

class ExamHistoryScreen extends StatefulWidget {
  ExamHistoryScreen({super.key});

  @override
  State<ExamHistoryScreen> createState() => _ExamHistoryState();
}

class _ExamHistoryState extends State<ExamHistoryScreen> {
  late Future<List<StudentExamSessionHistory>?> _futureSessions;
  int? selectedIndex;

  @override
  void initState() {
    super.initState();
    _futureSessions = UserService().getExamSessionByStudent();
  }

  String formatDate(DateTime? dt) {
    if (dt == null) return "Chưa có";
    return DateFormat("HH:mm dd/MM/yyyy").format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Bài kiểm tra đã làm",
          style: TextStyle(
            fontSize: 22,
            color: Colors.white, // màu chữ
          ),
        ),
        backgroundColor: Colors.blue, // Đặt màu nền đúng định dạng ARGB
        centerTitle: true,
      ),

      body: FutureBuilder<List<StudentExamSessionHistory>?>(
        future: _futureSessions,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: Colors.lightBlueAccent),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("Không có bài đã làm"));
          }

          final sessions = snapshot.data!;

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index];

              return Container(
                margin: EdgeInsets.only(bottom: 10),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Card(
                      elevation: 1,
                      shadowColor: const Color.fromARGB(255, 250, 63, 63),
                      color: Colors.grey[10],
                      child: Padding(
                        padding: EdgeInsets.all(10),

                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Color.fromARGB(
                                  79,
                                  161,
                                  234,
                                  253,
                                ), // Đặt màu nền
                                borderRadius: BorderRadius.circular(
                                  12,
                                ), // Bo góc 12px
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(
                                          2,
                                        ), // khoảng cách icon với khung
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.black,
                                            width: 2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ), // bo góc
                                        ),
                                        child: HugeIcon(
                                          icon: HugeIcons.strokeRoundedFile01,
                                          color: Colors.black,
                                          size: 24.0,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: SizedBox(
                                          height: 30,
                                          child: Marquee(
                                            text:
                                                session.subjectName ??
                                                "Không tên môn",
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            scrollAxis: Axis.horizontal,
                                            blankSpace: 70.0,
                                            velocity: 30,
                                            pauseAfterRound: Duration(
                                              seconds: 0,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 15),
                            Row(
                              children: [
                                SizedBox(width: 10),

                                CircleAvatar(
                                  radius: 23,
                                  backgroundColor: Colors.grey[300],
                                  child: Text(
                                    "${session.score?.toStringAsFixed(1) ?? "0.0"}",
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),

                                Expanded(
                                  child: Center(
                                    child: Text(
                                      "Số câu đúng: ${session.correctAnswers ?? 0}/${session.totalQuestions ?? 0}",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 20,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "${formatDate(session.examSessionStartTime)}  |  ${formatDate(session.examSessionEndTime)}",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
