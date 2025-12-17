import 'package:flutter/material.dart';
import 'package:quizz_mobile/helpers/exam_result_helper.dart';

/// Widget hiển thị card thông tin bài thi
class ExamInfoCard extends StatelessWidget {
  final int totalQuestions;
  final int answeredQuestions;
  final int timeSpent;
  final int totalTime;

  const ExamInfoCard({
    Key? key,
    required this.totalQuestions,
    required this.answeredQuestions,
    required this.timeSpent,
    required this.totalTime,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildCompactRow(
              'Câu hỏi',
              '$answeredQuestions/$totalQuestions',
              Icons.assignment,
              Colors.blue,
            ),
            Divider(height: 20),
            _buildCompactRow(
              'Chi tiết',
              'Đã làm: $answeredQuestions | Chưa làm: ${totalQuestions - answeredQuestions} | Sai: 0',
              Icons.checklist,
              Colors.green,
            ),
            Divider(height: 20),
            _buildCompactRow(
              'Thời gian',
              '${ExamResultHelper.formatTime(timeSpent)}/${ExamResultHelper.formatTime(totalTime)}',
              Icons.access_time,
              Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactRow(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        SizedBox(width: 12),
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        Spacer(),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
