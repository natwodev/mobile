import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../widget/common/app_coming_soon.dart';
import '../../widget/common/app_top_bar.dart';

/// Tab "Lớp học" — CHƯA CÓ dữ liệu, mới chỉ là chỗ giữ sẵn.
///
/// Backend chưa có endpoint lớp học nào, nên màn này chỉ dựng khung: vào được,
/// thoát được, và nói rõ là tính năng đang làm. Khi API sẵn sàng thì thay phần
/// thân, phần khung không phải sửa.
class ClassroomScreen extends StatelessWidget {
  const ClassroomScreen({super.key, this.scrollController});

  /// Do [HomeNavigation] giữ, để bấm nút tab là cuộn màn này về đầu.
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppTopBar(
        title: l10n.classroomTitle,
        tab: AppTopBarTab.classroom,
      ),
      body: SafeArea(
        bottom: false,
        child: ComingSoonView(
          icon: HugeIcons.strokeRoundedCourse,
          title: l10n.classroomEmptyTitle,
          message: l10n.classroomEmptyMessage,
          scrollController: scrollController,
        ),
      ),
    );
  }
}
