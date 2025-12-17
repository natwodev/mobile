import 'package:flutter/material.dart';

/// Widget hiển thị thông báo sau khi nộp bài
class ExamNotice extends StatelessWidget {
  final String message;

  const ExamNotice({
    Key? key,
    this.message =
        'Nếu bạn kiểm tra điểm cao thì chúc mừng bạn, nếu bạn kiểm tra không được tốt thì cũng đừng buồn chúng ta còn cơ hội cho lần sau. À làm gì có lần sau :>>>',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 14, color: Colors.blue[800]),
            ),
          ),
        ],
      ),
    );
  }
}
