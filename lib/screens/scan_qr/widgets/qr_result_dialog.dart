import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../services/auth/user_services.dart';
import '../../../services/exam_location_service.dart';
import '../../../widget/common/app_modal.dart';
import '../../Exam/exam_screen.dart';

class QrResultDialog extends StatefulWidget {
  final Map<String, String> examData;
  final VoidCallback onCancel;
  final BuildContext parentContext;

  const QrResultDialog({
    super.key,
    required this.examData,
    required this.onCancel,
    required this.parentContext,
  });

  @override
  State<QrResultDialog> createState() => _QrResultDialogState();
}

class _QrResultDialogState extends State<QrResultDialog> {
  /// Chặn bấm Xác nhận hai lần: mỗi lần vào thi có thể trừ một lượt làm bài.
  bool _isStarting = false;

  Map<String, String> get examData => widget.examData;
  BuildContext get parentContext => widget.parentContext;

  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) return '';

    try {
      final dateTime = DateTime.parse(dateTimeStr);
      final day = dateTime.day.toString().padLeft(2, '0');
      final month = dateTime.month.toString().padLeft(2, '0');
      final year = dateTime.year;
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');

      return ' $hour:$minute $day/$month/$year';
    } catch (e) {
      return dateTimeStr;
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  /// Vào phòng thi từ mã vừa quét.
  ///
  /// Đi ĐÚNG con đường của màn "nhập mã nhanh": tra ca thi theo mã → xin GPS nếu
  /// ca thi bắt buộc → gọi `create-exam-session`. Bản cũ gọi thẳng API với
  /// `originalExamPaperId`, mà backend chỉ đọc `ExamSessionSubjectId` nên nhận
  /// Guid rỗng và KHÔNG BAO GIỜ mở được phiên thi; nó cũng không gửi GPS nên ca
  /// thi bắt buộc định vị thì chặn thêm lần nữa.
  Future<void> _handleConfirm(BuildContext dialogContext) async {
    if (_isStarting) return;

    final l10n = AppLocalizations.of(parentContext);
    final core = examData['core']?.trim() ?? '';
    if (core.isEmpty) {
      Navigator.of(dialogContext).pop();
      _showError(parentContext, l10n.homeQrMissingExamCode);
      return;
    }

    setState(() => _isStarting = true);
    debugPrint('[QR] Tra ca thi theo mã: "$core"');

    final lookup = await UserService().findExamSessionByCore(core);
    if (!mounted) return;

    final session = lookup.session;
    if (session == null) {
      debugPrint('[QR] Không tra được ca thi: ${lookup.error}');
      setState(() => _isStarting = false);
      Navigator.of(dialogContext).pop();
      _showError(parentContext, lookup.error ?? l10n.msgExamSessionNotFound);
      return;
    }

    // Ca KHÔNG bắt buộc định vị thì không đụng tới GPS: giữ sentinel {0,0} như
    // web, không hiện hộp xin quyền, không bắt sinh viên chờ.
    double latitude = 0;
    double longitude = 0;

    if (session.requireLocationOnExamStart) {
      final location = await ExamLocationService.current();
      if (!mounted) return;

      if (!location.isSuccess) {
        debugPrint('[QR] Không lấy được vị trí: ${location.error}');
        setState(() => _isStarting = false);
        Navigator.of(dialogContext).pop();
        _showError(
          parentContext,
          examLocationErrorMessage(l10n, location.error!),
        );
        return;
      }

      latitude = location.latitude!;
      longitude = location.longitude!;
    }

    final start = await UserService().createExamSessionDetailed(
      examSessionSubjectId: session.examSessionSubjectId,
      latitude: latitude,
      longitude: longitude,
    );
    if (!mounted) return;

    final examResult = start.data;
    if (examResult == null) {
      debugPrint('[QR] Không mở được phiên thi: ${start.error}');
      setState(() => _isStarting = false);
      Navigator.of(dialogContext).pop();
      _showError(
        parentContext,
        start.error ?? l10n.msgStudentExamSessionCreateFailed,
      );
      return;
    }

    debugPrint(
      '[QR] Vào phòng thi OK: ${examResult.studentSession.studentExamSessionId}',
    );
    Navigator.of(dialogContext).pop();

    Navigator.of(parentContext).pushReplacement(
      MaterialPageRoute(
        builder: (context) => ExamScreen(
          sessionId: examResult.studentSession.studentExamSessionId,
          initialData: examResult,
        ),
      ),
    );
  }

  void _showError(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AppModal(
        title: AppLocalizations.of(context).homeQrInvalidTitle,
        icon: HugeIcons.strokeRoundedAlert01,
        accentColor: Colors.red,
        children: [Text(message)],
        actions: [
          // ElevatedButton chứ không phải TextButton: đây là lối thoát DUY
          // NHẤT của hộp thoại lỗi, để nút chữ mờ thì nó đọc ra như một dòng
          // phụ chứ không phải việc người dùng buộc phải bấm.
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppLocalizations.of(context).commonRetry),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AppModal(
      title: l10n.homeQrExamInfoLabel,
      icon: HugeIcons.strokeRoundedTaskDone01,
      onClose: () {
        Navigator.of(context).pop();
        widget.onCancel();
      },
      children: [
        Text(
          examData['title'] ?? l10n.homeQrExamFallbackTitle,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildInfoRow(l10n.homeQrExamSubject, examData['sub'] ?? ''),
        _buildInfoRow(l10n.homeQrExamDescription, examData['desc'] ?? ''),
        _buildInfoRow(
          l10n.homeQrExamDuration,
          l10n.homeQrExamDurationMinutes(examData['dur'] ?? ''),
        ),
        _buildInfoRow(
          l10n.homeQrExamCreatedAt,
          _formatDateTime(examData['created']),
        ),
      ],
      actions: [
        ElevatedButton(
          onPressed: _isStarting ? null : () => _handleConfirm(context),
          // Không khai style: theme đã lo nền #2563EB, chữ trắng, bo 8, cao 48.
          child: _isStarting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(l10n.commonConfirm),
        ),
      ],
    );
  }
}
