import 'package:flutter/material.dart';

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
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red),
          SizedBox(width: 8),
          Text('Mã QR không hợp lệ'),
        ],
      ),
      content: Text(message),
      actions: [TextButton(onPressed: onRetry, child: const Text('Thử lại'))],
    );
  }
}
