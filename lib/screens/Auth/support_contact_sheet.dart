import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/support_config.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widget/common/app_buttons.dart';
import '../../widget/common/app_toast.dart';

/// Bảng "Liên hệ hỗ trợ": gọi hotline, gửi email, mở website.
///
/// Chạm là mở ứng dụng tương ứng; máy không có ứng dụng nào nhận (máy ảo, máy
/// gỡ sẵn app gọi điện) thì chép giá trị vào bộ nhớ tạm để người dùng vẫn dùng
/// được, kèm thông báo.
Future<void> showSupportContactSheet(BuildContext context) {
  final AppLocalizations l10n = AppLocalizations.of(context);

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (BuildContext sheetContext) => SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Text(
                  l10n.contactTitle,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          _ContactTile(
            icon: HugeIcons.strokeRoundedCall02,
            title: l10n.contactHotline,
            value: SupportConfig.hotlineDisplay,
            uri: Uri(scheme: 'tel', path: SupportConfig.hotlineDial),
          ),
          _ContactTile(
            icon: HugeIcons.strokeRoundedMail01,
            title: l10n.contactEmail,
            value: SupportConfig.email,
            uri: Uri(scheme: 'mailto', path: SupportConfig.email),
          ),
          _ContactTile(
            icon: HugeIcons.strokeRoundedGlobe02,
            title: l10n.contactWebsite,
            value: SupportConfig.website,
            uri: Uri.parse(SupportConfig.website),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.uri,
  });

  final List<List<dynamic>> icon;
  final String title;
  final String value;
  final Uri uri;

  Future<void> _open(BuildContext context) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final NavigatorState navigator = Navigator.of(context);

    bool opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }

    if (opened) {
      navigator.pop();
      return;
    }

    await Clipboard.setData(ClipboardData(text: value));
    navigator.pop();
    // Đóng sheet xong thì `context` của tile chết theo, phải mượn context của
    // Navigator — toast mới có overlay để bám vào.
    AppToast.show(
      navigator.context,
      kind: AppToastKind.success,
      title: l10n.contactCopied(value),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: HugeIcon(icon: icon, color: AppColors.accent, size: 22.0),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(value),
      trailing: const HugeIcon(
        icon: HugeIcons.strokeRoundedArrowRight01,
        color: Colors.grey,
      ),
      onTap: () => _open(context),
    );
  }
}
