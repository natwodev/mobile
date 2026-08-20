import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../widget/common/app_buttons.dart';

/// Trang Thông báo.
///
/// Backend chưa có endpoint thông báo nào, nên màn này mới chỉ là cái vỏ: vào
/// được, thoát được, và nói rõ là chưa có gì. Khi API sẵn sàng thì thay phần
/// thân bằng danh sách, phần khung không phải sửa.
class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          l10n.notificationsTitle,
          style: const TextStyle(fontSize: 20, color: Colors.white),
        ),
        backgroundColor: AppColors.barBg,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedNotificationOff02,
                    color: AppColors.accent,
                    size: 44,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.notificationsEmptyTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.notificationsEmptyMessage,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
