import 'package:flutter/material.dart';

import '../../component/HomeNavigation.dart';
import '../../helpers/exam_result_helper.dart';
import '../../l10n/generated/app_localizations.dart';

/// Nút về trang chủ.
///
/// Kiểu viền như `btn-secondary` của web: trang kết quả chỉ có đúng một lối
/// đi tiếp, không cần nút đặc to đùng để giành sự chú ý với vòng điểm.
class HomeButton extends StatelessWidget {
  const HomeButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed:
            onPressed ??
            () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => HomeNavigation()),
                (Route<dynamic> route) => false,
              );
            },
        icon: const Icon(Icons.home_outlined, size: 20),
        label: Text(
          AppLocalizations.of(context).examResultHomeButton,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          foregroundColor: ExamResultHelper.sky500,
          side: const BorderSide(color: ExamResultHelper.sky500),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
