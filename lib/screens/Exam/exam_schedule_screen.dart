import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../widget/common/app_coming_soon.dart';
import '../../widget/common/app_top_bar.dart';

/// Tab "Lịch thi" — ca thi SẮP TỚI. Chưa có dữ liệu, mới là chỗ giữ sẵn.
///
/// Đây là trục thời gian còn thiếu của app: Lịch sử lo phần ĐÃ QUA, Trang chủ
/// lo phần ĐANG DIỄN RA, chưa có chỗ nào trả lời "mai thi môn gì, mấy giờ".
///
/// Backend hiện chỉ có `ExamSession-by-user-id`, và endpoint đó trả về các
/// phiên ĐÃ HOÀN THÀNH — chính là nguồn của màn Lịch sử. Chưa có endpoint nào
/// cho ca thi sắp tới, nên màn này còn trống.
///
/// Một nửa hạ tầng thì đã có: app xin quyền `SCHEDULE_EXACT_ALARM` để nhắc
/// "còn 15 phút nữa tới ca thi", tức khái niệm ca thi sắp tới đã tồn tại trong
/// hệ thống. Việc còn lại là bày nó ra.
class ExamScheduleScreen extends StatelessWidget {
  const ExamScheduleScreen({super.key, this.scrollController});

  /// Do [HomeNavigation] giữ, để bấm nút tab là cuộn màn này về đầu.
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppTopBar(
        title: l10n.examScheduleTitle,
        tab: AppTopBarTab.schedule,
      ),
      body: SafeArea(
        bottom: false,
        child: ComingSoonView(
          icon: HugeIcons.strokeRoundedCalendarCheckIn01,
          title: l10n.examScheduleEmptyTitle,
          message: l10n.examScheduleEmptyMessage,
          scrollController: scrollController,
        ),
      ),
    );
  }
}
