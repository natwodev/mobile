import 'package:flutter/material.dart';

import '../../widget/common/app_sheet.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../l10n/locale_controller.dart';
import '../../services/device_report_service.dart';
import '../../widget/common/app_buttons.dart';
import '../../widget/common/app_surfaces.dart';
import '../../widget/common/app_toast.dart';
import '../../widget/language_selector.dart';

/// Mở tấm "Thông tin thiết bị" trượt lên từ đáy.
///
/// Trước đây đây là một TRANG riêng. Đẩy nguyên một trang chồng lên để hiện
/// mươi dòng chỉ-đọc là quá tay: người dùng mất ngữ cảnh đang đứng ở đâu, và
/// phải bấm nút quay lại mới thoát. Tấm sheet thì trượt xuống là xong, mà nền
/// phía sau vẫn thấy.
Future<void> showDeviceInfoSheet(BuildContext context) {
  return showAppSheet<void>(
    context: context,
    title: AppLocalizations.of(context).deviceInfoTitle,
    icon: HugeIcons.strokeRoundedSmartPhone01,
    children: const [DeviceInfoScreen()],
  );
}

/// Nội dung "Thông tin thiết bị": phiên bản app, kiểu máy, hệ điều hành, màn
/// hình.
///
/// Có nút sao chép toàn bộ để người dùng dán thẳng vào tin nhắn cho bộ phận
/// hỗ trợ — hỏi từng dòng qua điện thoại rất mất thời gian.
///
/// Giữ tên cũ dù giờ không còn là một màn: đổi tên lớp là đụng vào mọi chỗ
/// import, mà việc nó làm thì không đổi.
class DeviceInfoScreen extends StatefulWidget {
  const DeviceInfoScreen({super.key});

  @override
  State<DeviceInfoScreen> createState() => _DeviceInfoScreenState();
}

class _DeviceInfoScreenState extends State<DeviceInfoScreen> {
  DeviceReport? _report;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final DeviceReport report = await DeviceReportService.load();
      if (!mounted) return;
      setState(() {
        _report = report;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  String _screenLabel() {
    final MediaQueryData media = MediaQuery.of(context);
    final Size size = media.size;
    return '${size.width.round()} x ${size.height.round()} pt '
        '(x${media.devicePixelRatio.toStringAsFixed(1)})';
  }

  Future<void> _copyAll() async {
    final DeviceReport? report = _report;
    if (report == null) return;

    await Clipboard.setData(
      ClipboardData(
        text: report.toPlainText(
          screen: _screenLabel(),
          language: languageLabel(LocaleController.instance.locale),
        ),
      ),
    );

    if (!mounted) return;
    AppToast.show(
      context,
      kind: AppToastKind.success,
      title: AppLocalizations.of(context).deviceInfoCopied,
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    // Không còn `Scaffold` với AppBar: tiêu đề và nút đóng do `AppSheet` lo.
    return _buildBody(l10n);
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_loading) {
      // Chừa sẵn chiều cao: bên trong tấm sheet, một vòng quay không kích thước
      // làm tấm co lại rồi bung ra khi dữ liệu về — giật một cái rất khó chịu.
      return const SizedBox(
        height: 160,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      );
    }

    final DeviceReport? report = _report;
    if (_failed || report == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l10n.deviceInfoLoadFailed,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    // `Column` chứ không phải `ListView`: tấm sheet đã tự cuộn, lồng thêm một
    // vùng cuộn nữa là hai thứ tranh nhau cử chỉ kéo.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSection(
          title: l10n.deviceInfoAppSection,
          rows: <List<String>>[
            <String>[l10n.deviceInfoAppName, report.appName],
            <String>[l10n.deviceInfoVersion, report.version],
            <String>[l10n.deviceInfoBuildNumber, report.buildNumber],
            <String>[l10n.deviceInfoPackageName, report.packageName],
            <String>[
              l10n.deviceInfoLanguage,
              languageLabel(LocaleController.instance.locale),
            ],
          ],
        ),
        const SizedBox(height: 16),
        _buildSection(
          title: l10n.deviceInfoDeviceSection,
          rows: <List<String>>[
            <String>[l10n.deviceInfoBrand, report.brand],
            <String>[l10n.deviceInfoModel, report.model],
            <String>[l10n.deviceInfoOs, report.os],
            <String>[
              l10n.deviceInfoDeviceType,
              report.isPhysicalDevice
                  ? l10n.deviceInfoPhysical
                  : l10n.deviceInfoEmulator,
            ],
            <String>[l10n.deviceInfoScreen, _screenLabel()],
          ],
        ),
        const SizedBox(height: 24),
        // Nút viền: sao chép là hành động phụ đứng một mình trên màn, không
        // phải việc chính người dùng vào đây để làm. [OutlinedButton] đã ăn sẵn
        // `AppButtons.outlined` từ theme nên không khai style tại chỗ nữa;
        // chiều cao 48 cũng do theme lo, `SizedBox` chỉ còn giữ ý đồ giãn ngang.
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _copyAll,
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedCopy01,
              color: AppColors.accent,
              size: 20.0,
            ),
            label: Text(l10n.deviceInfoCopy),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required List<List<String>> rows,
  }) {
    return Container(
      decoration: AppSurfaces.card(soft: true),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const Divider(height: 8),
          for (int i = 0; i < rows.length; i++)
            Padding(
              padding: EdgeInsets.only(
                top: 12,
                bottom: i == rows.length - 1 ? 12 : 0,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      rows[i][0],
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ),
                  Expanded(
                    flex: 6,
                    child: Text(
                      rows[i][1].isEmpty
                          ? AppLocalizations.of(context).commonNotUpdated
                          : rows[i][1],
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: rows[i][1].isEmpty
                            ? Colors.grey
                            : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
