import 'package:flutter/material.dart';
import 'package:quizz_mobile/screens/exam/exam_screen.dart';
import '../../models/studentExamSession.dart';
import '../../services/auth/user_services.dart';
import 'package:intl/intl.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:marquee/marquee.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionExamScreen extends StatefulWidget {
  SessionExamScreen({super.key});

  @override
  State<SessionExamScreen> createState() => _SessionExamScreenState();
}

Future<void> _exam(BuildContext context, int sessionId) async {
  try {
    await SharedPreferences.getInstance();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ExamScreen(sessionId: sessionId)),
    );
  } catch (e) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Vào trang thi thất bại: $e')));
  }
}

class _SessionExamScreenState extends State<SessionExamScreen> {
  late Future<List<StudentExamSession>?> _futureSessions;
  int? selectedIndex;

  @override
  void initState() {
    super.initState();
    _futureSessions = UserService().getExamSession();
  }

  String formatDate(DateTime? dt) {
    if (dt == null) return "Chưa có";
    return DateFormat("HH:mm | dd/MM/yyyy").format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          "Danh sách kiểm tra",
          style: TextStyle(fontSize: 22, color: Colors.white),
        ),
        backgroundColor: Colors.blue,

        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: () async {
              // Gọi API reset trước
              await UserService().resetExamSessionStartTime();

              // Sau khi reset xong mới gọi setState
              setState(() {
                _futureSessions = UserService().getExamSession();
              });
            },
          ),
        ],
      ),

      body: FutureBuilder<List<StudentExamSession>?>(
        future: _futureSessions,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: Colors.lightBlueAccent),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("Không có ca thi nào"));
          }

          final sessions = snapshot.data!;

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index];

              return Card(
                elevation: 2,
                shadowColor: Colors.blue,
                color: Colors.white,
                margin: EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: EdgeInsets.all(10),

                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Color(0x4F75E4FF), // Đặt màu nền
                          borderRadius: BorderRadius.circular(
                            12,
                          ), // Bo góc 12px
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
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
                                    icon: HugeIcons.strokeRoundedBook04,
                                    color: Colors.black,
                                    size: 24.0,
                                  ),
                                ),
                                SizedBox(width: 8),
                                /*
                                Expanded(
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      return buildMarqueeOrText(
                                        session.subjectName ?? "Không tên môn",
                                        constraints.maxWidth,
                                      );
                                    },
                                  ),
                                ),

                                 */
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
                                      pauseAfterRound: Duration(seconds: 0),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 7),
                      Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  HugeIcon(
                                    icon: HugeIcons.strokeRoundedDigitalClock,
                                    color: Colors.black,
                                    size: 21.0,
                                  ),
                                  SizedBox(width: 4),

                                  Text(
                                    "${session.duration ?? 0}'",
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  HugeIcon(
                                    icon: HugeIcons.strokeRoundedTime04,
                                    color: Colors.black,
                                    size: 21.0,
                                  ),
                                  SizedBox(width: 4),

                                  Text(
                                    "${formatDate(session.startTime)}",
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: 4),
                              Row(
                                children: [
                                  HugeIcon(
                                    icon:
                                        HugeIcons.strokeRoundedTimeQuarterPass,
                                    color: Colors.black,
                                    size: 21.0,
                                  ),
                                  SizedBox(width: 4),

                                  Text(
                                    "${formatDate(session.endTime)}",
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Spacer(), //dùng sizebox cũng được nhưng phải canh px
                          ElevatedButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text("Xác nhận"),
                                    content: Text(
                                      "Bạn có chắc chắn muốn vào làm bài kiểm tra này không?",
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    actions: [
                                      TextButton(
                                        child: Text("Hủy"),
                                        onPressed: () {
                                          Navigator.of(
                                            context,
                                          ).pop(); // Đóng dialog
                                        },
                                      ),
                                      TextButton(
                                        child: Text("Xác nhận"),
                                        onPressed: () {
                                          Navigator.of(
                                            context,
                                          ).pop(); // đóng dialog
                                          _exam(
                                            context,
                                            session.studentExamSessionId!,
                                          ); // truyền sessionId
                                        },
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                HugeIcon(
                                  icon: HugeIcons.strokeRoundedPlay,
                                  color: Colors.white,
                                  size: 30.0,
                                ),
                                SizedBox(width: 6),
                                Text("Vào làm"),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
