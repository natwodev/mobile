import 'package:flutter/material.dart';

import '../../helpers/exam_result_helper.dart';
import '../../l10n/generated/app_localizations.dart';

/// Bảng số liệu bài làm, đặt trong thẻ kết quả.
///
/// Dựng theo lối của web: nhãn xám bên trái, số đậm bên phải, ngăn nhau bằng
/// đường kẻ mảnh — không icon màu mè, để vòng điểm phía trên là thứ duy nhất
/// bắt mắt.
class ExamInfoCard extends StatelessWidget {
  const ExamInfoCard({
    super.key,
    required this.totalQuestions,
    required this.answeredQuestions,
    required this.timeSpent,
    required this.totalTime,
  });

  final int totalQuestions;
  final int answeredQuestions;
  final int timeSpent;
  final int totalTime;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final unanswered = (totalQuestions - answeredQuestions).clamp(
      0,
      totalQuestions,
    );

    return Column(
      children: [
        _row(l10n.examInfoQuestionsLabel, '$totalQuestions'),
        _divider(),
        _row(l10n.questionStatAnswered, '$answeredQuestions'),
        _divider(),
        _row(l10n.questionStatUnanswered, '$unanswered'),
        _divider(),
        _row(
          l10n.examInfoTimeLabel,
          // Ca không giới hạn giờ thì `totalTime` bằng 0; ghép mẫu số "00:00"
          // vào chỉ làm sinh viên tưởng ca thi hỏng.
          totalTime > 0
              ? '${ExamResultHelper.formatTime(timeSpent)} / ${ExamResultHelper.formatTime(totalTime)}'
              : ExamResultHelper.formatTime(timeSpent),
        ),
      ],
    );
  }

  Widget _divider() =>
      const Divider(height: 20, thickness: 1, color: ExamResultHelper.slate100);

  Widget _row(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: ExamResultHelper.slate500,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: ExamResultHelper.slate900,
          ),
          textAlign: TextAlign.right,
        ),
      ],
    );
  }
}
