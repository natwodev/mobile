import 'package:hugeicons/hugeicons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/support_config.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../services/device_report_service.dart';
import '../../widget/common/app_buttons.dart';
import '../../widget/common/app_toast.dart';

/// Màn "Báo lỗi / góp ý".
///
/// App chưa có API nhận phản hồi nên nội dung được đẩy sang ứng dụng email của
/// máy kèm sẵn thông tin thiết bị. Máy không có ứng dụng email thì chép vào
/// bộ nhớ tạm để người dùng gửi bằng cách khác, thay vì báo lỗi cụt.
class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final TextEditingController _content = TextEditingController();
  final TextEditingController _contact = TextEditingController();

  bool _isBug = true;
  bool _sending = false;
  String? _contentError;

  @override
  void dispose() {
    _content.dispose();
    _contact.dispose();
    super.dispose();
  }

  /// Uri.encodeComponent thay vì queryParameters: bộ mã hoá mặc định đổi dấu
  /// cách thành "+", một số ứng dụng mail hiện nguyên dấu cộng trong nội dung.
  String _encodeQuery(Map<String, String> params) => params.entries
      .map(
        (MapEntry<String, String> e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
      )
      .join('&');

  Future<void> _send() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String content = _content.text.trim();

    if (content.isEmpty) {
      setState(() => _contentError = l10n.feedbackContentRequired);
      return;
    }

    setState(() {
      _contentError = null;
      _sending = true;
    });

    final DeviceReport report = await DeviceReportService.load();
    final String subject =
        '[${_isBug ? l10n.feedbackTypeBug : l10n.feedbackTypeIdea}] '
        '${report.appName} ${report.version}';

    final StringBuffer body = StringBuffer()
      ..writeln(content)
      ..writeln();
    final String contact = _contact.text.trim();
    if (contact.isNotEmpty) {
      body
        ..writeln('${l10n.feedbackContactLabel}: $contact')
        ..writeln();
    }
    body
      ..writeln('---')
      ..write(report.toPlainText());

    final Uri mail = Uri(
      scheme: 'mailto',
      path: SupportConfig.email,
      query: _encodeQuery(<String, String>{
        'subject': subject,
        'body': body.toString(),
      }),
    );

    bool opened = false;
    try {
      opened = await launchUrl(mail, mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }

    if (!mounted) return;
    setState(() => _sending = false);

    if (opened) {
      Navigator.pop(context);
      return;
    }

    await Clipboard.setData(ClipboardData(text: '$subject\n\n$body'));
    if (!mounted) return;
    AppToast.show(
      context,
      kind: AppToastKind.warning,
      title: l10n.feedbackMailFallback(SupportConfig.email),
      duration: const Duration(seconds: 5),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          l10n.feedbackTitle,
          style: const TextStyle(fontSize: 20, color: Colors.white),
        ),
        backgroundColor: AppColors.barBg,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildTypeChip(
                    label: l10n.feedbackTypeBug,
                    selected: _isBug,
                    onTap: () => setState(() => _isBug = true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTypeChip(
                    label: l10n.feedbackTypeIdea,
                    selected: !_isBug,
                    onTap: () => setState(() => _isBug = false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              l10n.feedbackContentLabel,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _content,
              maxLines: 7,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: l10n.feedbackContentHint,
                errorText: _contentError,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.feedbackContactLabel,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _contact,
              decoration: InputDecoration(
                hintText: l10n.feedbackContactHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const HugeIcon(
                    icon: HugeIcons.strokeRoundedInformationCircle,
                    size: 18,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.feedbackAttachNote,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Gửi phản hồi là hành động chính của màn này nên để nguyên
            // [ElevatedButton] không style — theme đã lo nền, bo góc, cỡ chữ và
            // chiều cao 48; `SizedBox` chỉ còn giữ ý đồ giãn ngang.
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _sending ? null : _send,
                child: _sending
                    // Lúc gửi thì nút bị vô hiệu hoá, nền chuyển sang xám nhạt
                    // `AppColors.line` — vòng quay màu trắng sẽ tàng hình trên
                    // nền đó, nên tô bằng màu chữ của trạng thái tắt.
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.disabledInk,
                        ),
                      )
                    : Text(l10n.feedbackSend),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Ô chọn loại phản hồi (lỗi / góp ý).
  ///
  /// Giữ nguyên dạng `InkWell` + `Container` chứ không đổi sang một biến thể
  /// [AppButtons]: đây là lựa chọn hai trạng thái có nhớ trạng thái đang chọn,
  /// không phải nút bấm để chạy một hành động. Chỉ màu là kéo về bảng chung.
  Widget _buildTypeChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.accent : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            color: selected ? AppColors.accent : Colors.black87,
          ),
        ),
      ),
    );
  }
}
