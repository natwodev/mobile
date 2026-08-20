import 'package:flutter/material.dart';

import '../../helpers/exam_result_helper.dart';
import '../../l10n/generated/app_localizations.dart';

/// Lời nhắn sau khi nộp bài.
///
/// Giữ tông trầm của web: nền xám nhạt, chữ xám, không tranh sự chú ý với
/// vòng điểm.
class ExamNotice extends StatelessWidget {
  const ExamNotice({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ExamResultHelper.slate200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            size: 20,
            color: ExamResultHelper.slate500,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message ?? AppLocalizations.of(context).examNoticeDefaultMessage,
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: ExamResultHelper.slate500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
