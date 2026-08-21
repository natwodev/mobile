import 'package:flutter/material.dart';

import '../../widget/common/app_top_bar.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/auth/user_services.dart';
import '../../services/exam_location_service.dart';
import '../../widget/common/app_buttons.dart';
import '../../widget/common/app_busy_overlay.dart';
import '../../widget/common/app_modal.dart';
import 'exam_screen.dart';

class QuickExamCodeScreen extends StatefulWidget {
  const QuickExamCodeScreen({super.key});

  @override
  State<QuickExamCodeScreen> createState() => _QuickExamCodeScreenState();
}

class _QuickExamCodeScreenState extends State<QuickExamCodeScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _codeController = TextEditingController();
  final FocusNode _codeFocusNode = FocusNode();
  final UserService _userService = UserService();
  bool _isLoading = false;

  /// Bước đang chạy, hiện trên lớp phủ. Null = không có gì đang chạy.
  ///
  /// Vào phòng thi có thể mất cả chục giây (bắt GPS 15 giây, rồi mới tạo phiên),
  /// mà nút bấm chỉ quay tròn thì sinh viên không biết máy đang làm gì và rất
  /// dễ bấm lại hoặc thoát ra giữa chừng.
  ({String title, String? hint})? _busyStep;

  @override
  void dispose() {
    _codeController.dispose();
    _codeFocusNode.dispose();
    super.dispose();
  }

  /// Mã người dùng đã nhập (độ dài tự do).
  // Web chuẩn hoá mã bằng `trim().toUpperCase()` trước khi gọi API
  // (ExamSessionStudent.tsx:49) — giữ y hệt để hai nền tảng tra cùng một mã.
  String get _examCode => _codeController.text.trim().toUpperCase();

  bool get _hasCode => _examCode.isNotEmpty;

  /// Luồng 2 bước, giống trang web của sinh viên:
  /// 1. `GET api/ExamSessionSubject/cores/{core}` để tìm ca thi theo mã.
  /// 2. `POST api/student/create-exam-session` để tạo phiên rồi vào làm bài.
  ///
  /// Giữa hai bước có một hộp xác nhận: tạo phiên là đã tiêu một lượt làm bài
  /// nên không được tự động chạy tiếp khi sinh viên gõ nhầm mã.
  Future<void> _submitCode() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _busyStep = (
        title: AppLocalizations.of(context).examLookupOverlayTitle,
        hint: null,
      );
    });

    final lookup = await _userService.findExamSessionByCore(_examCode);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _busyStep = null;
    });

    final session = lookup.session;
    if (session == null) {
      _showError(
        lookup.error ?? AppLocalizations.of(context).msgExamSessionNotFound,
      );
      return;
    }

    final confirmed = await _confirmSession(session);
    if (!mounted || confirmed != true) return;

    // Ca thi bắt buộc định vị thì phải có GPS hợp lệ mới gọi API — backend
    // từ chối thẳng khi thiếu (`StudentController.cs:115-122`). Ca KHÔNG yêu
    // cầu thì không đụng tới GPS, giữ sentinel {0,0} như web: không hiện hộp
    // xin quyền, không bắt sinh viên chờ.
    double latitude = 0;
    double longitude = 0;

    final l10n = AppLocalizations.of(context);

    if (session.requireLocationOnExamStart) {
      setState(() {
        _isLoading = true;
        _busyStep = (
          title: l10n.examLocationGetting,
          hint: l10n.examLocationGettingHint,
        );
      });

      final location = await ExamLocationService.current();
      if (!mounted) return;

      if (!location.isSuccess) {
        // Giống hqsoft.esales.sfa (check_in_store_screen.dart:165-197): chỉ nói
        // rõ vướng ở đâu rồi dừng. Sinh viên bật định vị / cấp quyền xong bấm
        // lại nút bắt đầu — không giữ họ trong một vòng lặp hộp thoại.
        setState(() {
          _isLoading = false;
          _busyStep = null;
        });
        _showError(examLocationErrorMessage(l10n, location.error!));
        return;
      }

      latitude = location.latitude!;
      longitude = location.longitude!;
    }

    setState(() {
      _isLoading = true;
      _busyStep = (
        title: l10n.examEnterOverlayTitle,
        hint: l10n.examEnterOverlayHint,
      );
    });

    final start = await _userService.createExamSessionDetailed(
      examSessionSubjectId: session.examSessionSubjectId,
      latitude: latitude,
      longitude: longitude,
    );
    if (!mounted) return;

    final examData = start.data;
    if (examData == null) {
      // CHỈ tắt lớp phủ ở nhánh hỏng. Nhánh thành công phải GIỮ lớp phủ cho
      // tới lúc màn làm bài thế chỗ: tắt trước rồi mới điều hướng thì màn
      // "Làm kiểm tra" hiện trơ ra một nhịp, trông như app đứng lại giữa chừng.
      setState(() {
        _isLoading = false;
        _busyStep = null;
      });
      _showError(
        start.error ??
            AppLocalizations.of(context).msgStudentExamSessionCreateFailed,
      );
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ExamScreen(
          sessionId: examData.studentSession.studentExamSessionId,
          initialData: examData,
        ),
      ),
    );
  }

  /// Hộp xác nhận thông tin ca thi vừa tìm được. Trả `true` khi sinh viên
  /// đồng ý bắt đầu làm bài.
  Future<bool?> _confirmSession(ExamSessionSummary session) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx);
        return AppModal(
          title: l10n.examCodeConfirmTitle,
          icon: HugeIcons.strokeRoundedTaskDone01,
          // barrierDismissible: false nên dấu X là đường thoát duy nhất, thay
          // cho nút Huỷ trước đây ở thanh nút.
          onClose: () => Navigator.of(ctx).pop(false),
          children: [
            Text(
              l10n.examCodeSessionInfoTitle,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            // Thứ tự các dòng lấy theo web (ExamSessionStudent.tsx:199-212):
            // Mã ca thi → Môn thi → Thời lượng → Bắt đầu → Kết thúc.
            _buildInfoRow(
              l10n.examCodeCodeLabel,
              session.examSessionSubjectCore,
            ),
            _buildInfoRow(l10n.examCodeSubjectLabel, session.subjectName),
            // Ca không giới hạn thì hiện "Không giới hạn" thay cho số phút,
            // đúng như web (ExamSessionStudent.tsx:202-206).
            _buildInfoRow(
              l10n.examCodeDurationLabel,
              session.isUnlimitedTime
                  ? l10n.examUnlimitedTime
                  : l10n.examCodeDurationMinutes(session.duration),
            ),
            _buildInfoRow(
              l10n.examCodeStartTimeLabel,
              _formatDateTime(session.startTime),
            ),
            // Ca không giới hạn được backend lưu EndTime = DateTime.MaxValue
            // (31/12/9999), đem hiện ra thì sinh viên đọc thành một ngày vô
            // nghĩa. Web ẩn hẳn dòng này (ExamSessionStudent.tsx:208).
            if (!session.isUnlimitedTime && _hasRealEndTime(session.endTime))
              _buildInfoRow(
                l10n.examCodeEndTimeLabel,
                _formatDateTime(session.endTime),
              ),
            const SizedBox(height: 12),
            Text(
              l10n.examCodeConfirmMessage,
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
            if (session.requireLocationOnExamStart) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedLocationOffline01,
                      size: 18,
                      color: Colors.orange[800],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.examCodeLocationRequiredNotice,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              // Không khai style: theme lo nền, bo góc, chiều cao và cỡ chữ.
              child: Text(l10n.examCodeStartButton),
            ),
          ],
        );
      },
    );
  }

  /// Một dòng thông tin ca thi.
  ///
  /// Dùng inline `**Nhãn:** giá trị` giống hệt web
  /// (ExamSessionStudent.tsx:199-212) thay vì cột nhãn rộng cố định. Cột cứng
  /// 92px trước đây bóp nghẹt phần giá trị trong hộp thoại hẹp: nhãn dài như
  /// "Thời gian bắt đầu" bị xuống dòng, còn mã ca thi dạng
  /// ESS-3-20260819183000 phải vắt qua nhiều dòng. Inline thì chữ tự ngắt dòng
  /// theo bề rộng thật, không có kích thước nào ghim cứng để mà tràn.
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// `HH:mm dd/MM/yyyy` theo giờ máy. Backend trả ISO-8601 nên đổi sang giờ
  /// địa phương trước khi hiển thị.
  /// Chốt chặn thứ hai cho mốc kết thúc "vô tận".
  ///
  /// Cờ [ExamSessionSummary.isUnlimitedTime] mới là căn cứ chính, nhưng ca thi
  /// tạo từ trước hoặc dữ liệu lệch vẫn có thể mang `EndTime` =
  /// `DateTime.MaxValue` (31/12/9999) mà cờ lại false. Hiện một cái mốc như vậy
  /// cho sinh viên thì vô nghĩa, nên chặn luôn theo mốc năm.
  static bool _hasRealEndTime(DateTime? endTime) {
    if (endTime == null) return false;
    return endTime.year < 9999;
  }

  String _formatDateTime(DateTime? value) {
    if (value == null) return '';
    final local = value.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(local.hour)}:${two(local.minute)} '
        '${two(local.day)}/${two(local.month)}/${local.year}';
  }

  void _showError(String message) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx);
        return AppModal(
          title: l10n.examCodeErrorTitle,
          icon: HugeIcons.strokeRoundedAlert01,
          accentColor: Colors.red,
          children: [Text(message)],
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.commonClose),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppTopBar(title: l10n.examCodeAppBarTitle, showBack: true),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const HugeIcon(
                      icon: HugeIcons.strokeRoundedKey01,
                      size: 44.0,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  Text(
                    l10n.examCodeHeading,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.examCodeSubtitle,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),

                  // Ô nhập mã: một ô duy nhất, độ dài tự do.
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 340),
                      child: Form(
                        key: _formKey,
                        child: TextFormField(
                          controller: _codeController,
                          focusNode: _codeFocusNode,
                          textAlign: TextAlign.center,
                          maxLength: 50,
                          autocorrect: false,
                          enableSuggestions: false,
                          textInputAction: TextInputAction.done,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            color: Colors.black87,
                          ),
                          textCapitalization: TextCapitalization.characters,
                          inputFormatters: [
                            // Mã ca thi là varchar(50) không ràng buộc bộ ký tự.
                            // Backend tự sinh mã dạng ESS-{SubjectId}-{yyyyMMddHHmmss}
                            // nên PHẢI cho gõ dấu gạch ngang, nếu không loại mã này
                            // không ai nhập nổi. Gạch dưới cho thêm vì giáo viên đặt
                            // mã tay được tự do.
                            // Luật lấy theo web (student_exam.form.helper_text):
                            // chỉ chữ cái, số và dấu gạch nối. Dấu gạch nối là bắt
                            // buộc vì backend tự sinh mã dạng
                            // ESS-{SubjectId}-{yyyyMMddHHmmss}.
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[a-zA-Z0-9-]'),
                            ),
                            UpperCaseTextFormatter(),
                          ],
                          decoration: InputDecoration(
                            counterText: '',
                            hintText: l10n.examCodeFieldHint,
                            hintStyle: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.normal,
                              letterSpacing: 0,
                              color: Colors.grey[400],
                            ),
                            filled: true,
                            fillColor: _hasCode
                                ? AppColors.accent.withOpacity(0.1)
                                : Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 18,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: _hasCode
                                    ? AppColors.accent
                                    : Colors.grey[300]!,
                                width: _hasCode ? 2 : 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.accent,
                                width: 2,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if ((value ?? '').trim().isEmpty) {
                              return l10n.examCodeEmptyError;
                            }
                            return null;
                          },
                          onChanged: (_) => setState(() {}),
                          onFieldSubmitted: (_) {
                            if (_hasCode && !_isLoading) _submitCode();
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 56),

                  // Submit button
                  SizedBox(
                    // Chỉ còn ghim bề rộng: chiều cao 48 đã nằm sẵn trong theme
                    // nút, ghim thêm ở đây là hai chỗ cùng quyết định một số đo.
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _hasCode && !_isLoading ? _submitCode : null,
                      child: _isLoading
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Flexible + ellipsis: bề rộng nút cố định, chữ
                                // "Đang kiểm tra..." lại dài ngắn theo ngôn ngữ và
                                // theo cỡ chữ hệ thống. Không có nó thì máy hẹp
                                // hoặc người dùng phóng to chữ là tràn ngang.
                                Flexible(
                                  child: Text(
                                    l10n.examCodeCheckingButton,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              l10n.examCodeEnterRoomButton,
                              overflow: TextOverflow.ellipsis,
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Help text
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedInformationCircle,
                          color: Colors.amber[700],
                          size: 18,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l10n.examCodeHelpText,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.amber[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Lớp phủ cho cả ba bước chờ lâu: tra mã, lấy vị trí, tạo phiên.
          if (_busyStep != null)
            Positioned.fill(
              child: AppBusyOverlay(
                title: _busyStep!.title,
                hint: _busyStep!.hint,
              ),
            ),
        ],
      ),
    );
  }
}

/// Formatter để chuyển text thành chữ hoa
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
