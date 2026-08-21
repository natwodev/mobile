import 'package:flutter/material.dart';

import '../../widget/common/app_top_bar.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../helpers/exam_result_helper.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../services/pending_submit_service.dart';
import '../../widget/exam_result/circle_score_display.dart';
import '../../widget/exam_result/exam_info_card.dart';
import '../../widget/exam_result/exam_notice.dart';
import '../../widget/exam_result/home_button.dart';

/// Trang kết quả sau khi nộp bài.
///
/// Bố cục và bảng màu bám theo trang kết quả của web
/// (`frontend_manage/src/pages/ExamResult.tsx` + `styles/exam-results.css`):
/// nền xám nhạt, một thẻ trắng bo góc, tên đề mờ ở trên, vòng điểm ở giữa,
/// bảng số liệu bên dưới.
///
/// Khác web đúng một chỗ: không có lưới câu đúng/sai, vì màn này chỉ nhận
/// được số câu và thời gian chứ backend không trả đáp án đúng về máy học sinh.
class ExamResultScreen extends StatelessWidget {
  const ExamResultScreen({
    super.key,
    required this.examTitle,
    required this.totalQuestions,
    required this.answeredQuestions,
    required this.timeSpent,
    required this.totalTime,
    this.score = 0.0,
    this.pendingOutcome,
    this.pendingSubmittedAt,
  });

  final String examTitle;
  final int totalQuestions;
  final int answeredQuestions;
  final int timeSpent;
  final int totalTime;
  final double score;

  /// Bài nộp lúc MẤT MẠNG: kết cục sẽ có sau, khi máy gửi lại được.
  ///
  /// Khác `null` nghĩa là chưa có điểm để hiện — chỗ vòng điểm quay vòng chờ
  /// cho tới khi Future này xong. Sinh viên vẫn được sang màn này ngay thay vì
  /// nhận một hộp thoại "nộp bài thất bại" mà bấm bao nhiêu lần cũng vô ích.
  final Future<PendingSubmitOutcome>? pendingOutcome;

  /// Mốc đã chốt làm giờ nộp (giờ UTC), chỉ để hiện cho sinh viên yên tâm.
  /// Bỏ trống thì lấy giờ máy — màn này được dựng ngay sau lúc bấm nộp nên hai
  /// giá trị chênh nhau chưa tới một giây.
  final DateTime? pendingSubmittedAt;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: ExamResultHelper.slate50,
      appBar: AppTopBar(title: l10n.examResultTitle),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildResultCard(context),
              const SizedBox(height: 16),
              const ExamNotice(),
              const SizedBox(height: 24),
              const HomeButton(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard(BuildContext context) {
    // Tên đề đóng vai `.subject-name` của web: chữ mờ dưới tiêu đề trang. Tiêu
    // đề "Kết quả bài thi" đã nằm ở AppBar nên không lặp lại lần nữa ở đây.
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ExamResultHelper.slate200),
      ),
      child: Column(
        children: [
          Text(
            examTitle,
            style: const TextStyle(
              fontSize: 16,
              color: ExamResultHelper.slate500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ..._buildScoreArea(context),
          const SizedBox(height: 24),
          ExamInfoCard(
            totalQuestions: totalQuestions,
            answeredQuestions: answeredQuestions,
            timeSpent: timeSpent,
            totalTime: totalTime,
          ),
        ],
      ),
    );
  }

  /// Phần "vòng điểm + lời nhận xét" của thẻ kết quả.
  ///
  /// Trả về DANH SÁCH widget chứ không phải một Column bọc ngoài: đường thường
  /// (đã có điểm) vì thế nằm nguyên vẹn trong Column của thẻ, không thêm một
  /// cấp bố cục nào so với trước.
  List<Widget> _buildScoreArea(BuildContext context) {
    final pending = pendingOutcome;
    if (pending == null) return _scoreWidgets(context, score);

    return [
      FutureBuilder<PendingSubmitOutcome>(
        future: pending,
        builder: (context, snapshot) {
          final outcome = snapshot.data;

          // Future này không bao giờ hoàn tất bằng lỗi, nhưng nếu có thì vẫn
          // phải dừng vòng xoay lại: quay mãi là lừa sinh viên.
          if (snapshot.hasError) return _buildSubmitFailed(context, null);
          if (outcome == null) return _buildSubmitWaiting(context);
          if (!outcome.accepted) {
            return _buildSubmitFailed(context, outcome.message);
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: _scoreWidgets(context, outcome.score ?? 0.0),
          );
        },
      ),
    ];
  }

  List<Widget> _scoreWidgets(BuildContext context, double value) {
    return [
      CircleScoreDisplay(score: value),
      const SizedBox(height: 16),
      Text(
        ExamResultHelper.getScoreComment(context, value),
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: ExamResultHelper.getScoreRingColor(value),
        ),
        textAlign: TextAlign.center,
      ),
    ];
  }

  /// Đang chờ mạng để gửi bài: vòng xoay đúng chỗ vòng điểm sẽ hiện ra.
  Widget _buildSubmitWaiting(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 160,
          height: 160,
          child: Center(
            child: SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(strokeWidth: 5),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.examResultPendingSubmitTitle,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: ExamResultHelper.slate500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.examResultPendingSubmitHint(_submittedAtLabel()),
          style: const TextStyle(
            fontSize: 13,
            color: ExamResultHelper.slate500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Máy chủ từ chối hẳn: nói thật lý do thay vì để vòng xoay quay tiếp.
  Widget _buildSubmitFailed(BuildContext context, String? message) {
    final l10n = AppLocalizations.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 160,
          height: 160,
          child: Center(
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedNoInternet,
              size: 72,
              color: Color(0xFFDC2626),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.examResultPendingSubmitFailed,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFFDC2626),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          message ?? l10n.examResultPendingSubmitFailedHint,
          style: const TextStyle(
            fontSize: 13,
            color: ExamResultHelper.slate500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Giờ nộp đã chốt, viết theo giờ MÁY của sinh viên (mốc gửi lên máy chủ là
  /// UTC, nhưng hiện giờ UTC cho sinh viên thì chỉ tổ làm họ hoảng).
  String _submittedAtLabel() {
    final at = (pendingSubmittedAt ?? DateTime.now()).toLocal();
    final hh = at.hour.toString().padLeft(2, '0');
    final mm = at.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}
