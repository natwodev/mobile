import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../widget/common/app_modal.dart';

class QrErrorDialog extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const QrErrorDialog({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    // Không có dấu X: đóng bằng cách khác thì màn quét vẫn kẹt ở trạng thái
    // đang xử lý, nên lối ra duy nhất là nút "Thử lại".
    return AppModal(
      title: AppLocalizations.of(context).homeQrInvalidTitle,
      icon: HugeIcons.strokeRoundedAlert01,
      accentColor: Colors.red,
      children: [Text(message)],
      actions: [
        // ElevatedButton chứ không phải TextButton: "Thử lại" là lối ra DUY
        // NHẤT của hộp thoại này, nút chữ mờ đọc ra như hành động phụ.
        ElevatedButton(
          onPressed: onRetry,
          child: Text(AppLocalizations.of(context).commonRetry),
        ),
      ],
    );
  }
}
