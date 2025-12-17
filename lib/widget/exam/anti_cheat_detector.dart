import 'package:flutter/material.dart';

/// Widget phát hiện gian lận khi user rời khỏi app
/// Tự động nộp bài sau 3 lần vi phạm
class AntiCheatDetector extends StatefulWidget {
  final Widget child;
  final VoidCallback onAutoSubmit; // Callback khi tự động nộp bài

  const AntiCheatDetector({
    Key? key,
    required this.child,
    required this.onAutoSubmit,
  }) : super(key: key);

  @override
  State<AntiCheatDetector> createState() => _AntiCheatDetectorState();
}

class _AntiCheatDetectorState extends State<AntiCheatDetector>
    with WidgetsBindingObserver {
  int _violationCount = 0; // Số lần vi phạm
  static const int _maxViolations = 3; // Số lần vi phạm tối đa
  bool _isShowingWarning = false; // Đang hiển thị cảnh báo

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Phát hiện khi app chuyển sang background
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _onAppLeftDetected();
    }
  }

  void _onAppLeftDetected() {
    if (_isShowingWarning) return; // Tránh hiển thị nhiều dialog cùng lúc

    setState(() {
      _violationCount++;
      print('🚨 Phát hiện gian lận! Số lần: $_violationCount/$_maxViolations');
    });

    // Nếu đã đủ 3 lần → tự động nộp bài
    if (_violationCount >= _maxViolations) {
      _autoSubmitExam();
    } else {
      _showWarningDialog();
    }
  }

  void _showWarningDialog() {
    _isShowingWarning = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return WillPopScope(
          onWillPop: () async => false, // Không cho đóng dialog bằng back
          child: AlertDialog(
            backgroundColor: Colors.red[50],
            title: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red, size: 30),
                SizedBox(width: 12),
                Text(
                  'Cảnh báo gian lận!',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hệ thống phát hiện bạn đã rời khỏi ứng dụng thi!',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange[900]),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Vi phạm: $_violationCount/$_maxViolations lần\n'
                          'Còn ${_maxViolations - _violationCount} lần, bài thi sẽ tự động nộp!',
                          style: TextStyle(
                            color: Colors.orange[900],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  '⚠️ Vui lòng không rời khỏi ứng dụng trong lúc thi!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.red[700],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  _isShowingWarning = false;
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: Text('Tôi hiểu'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _autoSubmitExam() {
    // Tự động nộp bài ngay lập tức, không hiện dialog
    print('🚫 Tự động nộp bài do vi phạm $_maxViolations lần!');
    widget.onAutoSubmit();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
