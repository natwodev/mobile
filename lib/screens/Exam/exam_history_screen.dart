import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';

import '../../component/HomeNavigation.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/DTOs/ExamSubmissionDto.dart';
import '../../models/exam_history_item.dart';
import '../../services/auth/user_services.dart';
import '../../widget/common/app_buttons.dart';
import '../../widget/common/app_toast.dart';
import '../../widget/common/app_top_bar.dart';
import '../../widget/common/app_refresh_indicator.dart';
import '../../widget/common/success_banner.dart';

/// Màn "Lịch sử làm bài" — tab giữa của thanh điều hướng.
///
/// Bám bản web (`frontend_manage/src/pages/ExamHistory.tsx`) về DỮ LIỆU và
/// LUỒNG, nhưng CỐ Ý không bám bố cục: web đổ danh sách vào một `<table>` 6
/// cột, còn trên máy 320dp thì sáu cột ép nhau đến mức không cột nào đọc nổi.
///
/// Mỗi bài là một THẺ dựng quanh thứ người dùng mở màn này để xem — ĐIỂM SỐ:
/// vòng điểm bên phải đọc được từ khoảng cách lướt, tên môn và ngày bên trái,
/// các số phụ (thời gian làm, số câu đúng, vi phạm) thu thành hàng chip. Bản
/// trước xếp tất cả thành dòng "nhãn — giá trị" nên điểm số chìm nghỉm giữa
/// bốn dòng chữ cùng cỡ.
class ExamHistoryScreen extends StatefulWidget {
  const ExamHistoryScreen({super.key, this.userService, this.scrollController});

  /// Cửa để test cắm bản giả. Màn hình gọi mạng ngay trong `initState` nên nếu
  /// không thay được service thì mọi test bố cục đều treo chờ một request thật.
  final UserService? userService;

  /// Do [HomeNavigation] giữ, để bấm nút tab là cuộn màn này về đầu.
  final ScrollController? scrollController;

  @override
  State<ExamHistoryScreen> createState() => _ExamHistoryScreenState();
}

class _ExamHistoryScreenState extends State<ExamHistoryScreen> {
  late final UserService _userService = widget.userService ?? UserService();

  /// Dấu gạch cho ô KHÔNG CÓ dữ liệu. Không phải câu chữ nên không cần dịch —
  /// và cũng không được thay bằng số 0, vì "không biết" khác "bằng không".
  static const String _noValue = '-';

  static final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');

  List<ExamHistoryItem> _items = const [];
  bool _loading = true;
  String? _error;

  /// Id bài đang xin phiếu xem lại.
  ///
  /// Chỉ cho MỘT bài mở tại một thời điểm: hai lần mở chồng nhau thì bảng chi
  /// tiết hiện ra là của bài về sau, trong khi người dùng đang chờ bài kia.
  String? _openingId;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  /// Tải lại danh sách.
  ///
  /// [showSpinner] để `false` khi người dùng kéo-để-tải-lại: thay cả danh sách
  /// bằng vòng quay giữa lúc vòng xoay của [RefreshIndicator] đang chạy là
  /// nháy màn hai lần cho cùng một việc.
  Future<void> _loadHistory({bool showSpinner = true}) async {
    if (showSpinner) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    final result = await _userService.getExamHistory();
    if (!mounted) return;

    // Backend đã sắp giảm dần theo `endTime`, nhưng màn hình vẫn tự sắp lại để
    // không phụ thuộc thứ tự đó (giống web).
    final sorted = [...result.items]
      ..sort((a, b) => _sortKey(b).compareTo(_sortKey(a)));

    setState(() {
      _loading = false;
      _items = result.success ? sorted : const [];
      _error = result.success
          ? null
          : (result.error ?? AppLocalizations.of(context).historyLoadFailed);
    });
  }

  static int _sortKey(ExamHistoryItem item) =>
      item.sortedAt?.millisecondsSinceEpoch ?? 0;

  /// Số phút làm bài suy từ HAI MỐC BẤT KỲ.
  ///
  /// Không dùng thẳng `ExamHistoryItem.workedMinutes` ở bảng chi tiết vì mốc
  /// giờ tại đó ưu tiên lấy từ `getSubmissionResult` — có thể lệch với mốc
  /// trong danh sách khi giáo viên chỉnh bài sau lúc nộp.
  static int? _workedMinutes(DateTime? start, DateTime? end) {
    if (start == null || end == null) return null;
    final seconds = end.difference(start).inSeconds;
    if (seconds <= 0) return null;
    return (seconds / 60).round().clamp(1, 1 << 30);
  }

  String _formatDateTime(DateTime? value) =>
      value == null ? _noValue : _dateTimeFormat.format(value);

  /// Câu giải thích VÌ SAO bài không mở xem lại được.
  ///
  /// Nhận [reason] rời chứ không nhận nguyên [ExamHistoryItem]: lúc bấm "Xem
  /// lại" mà bị từ chối, lý do đúng là lý do máy chủ vừa trả về, không phải lý
  /// do đã đóng băng trong danh sách tải từ trước.
  String _blockedReasonText(
    AppLocalizations l10n,
    ExamReviewBlockedReason? reason,
    DateTime? reviewOpensAt,
  ) {
    switch (reason) {
      case ExamReviewBlockedReason.notOpenYet:
        // Không có giờ mở thì đừng in ra chuỗi "Mở xem lại từ -": câu chung
        // chung vẫn nói đúng sự thật, còn dấu gạch thì không nói gì cả.
        return reviewOpensAt == null
            ? l10n.historyBlockedNotOpenYetGeneric
            : l10n.historyBlockedNotOpenYet(_formatDateTime(reviewOpensAt));
      case ExamReviewBlockedReason.closed:
        return l10n.historyBlockedClosed;
      case ExamReviewBlockedReason.notCompleted:
        return l10n.historyBlockedNotCompleted;
      // `notAllowed` và cả `null` (bị chặn mà máy chủ không nói lý do) đều về
      // đây — nói "ca thi không cho xem lại" vẫn đúng bản chất hơn là để trống.
      case ExamReviewBlockedReason.notAllowed:
      case null:
        return l10n.historyBlockedNotAllowed;
    }
  }

  /// Phạm vi được xem khi bài MỞ ĐƯỢC, hiện dưới dạng tooltip (nhấn giữ) —
  /// tương ứng thuộc tính `title` của nút trên web.
  ///
  /// Cờ "không cho xem chi tiết câu hỏi" xét TRƯỚC cờ đáp án: khi không mở
  /// được câu nào thì nói "kèm đáp án đúng" là sai lệch — sinh viên chỉ thấy
  /// lưới đúng/sai, không có đề bài để so đáp án.
  String _reviewScopeText(AppLocalizations l10n, ExamHistoryItem item) {
    if (!item.showQuestionDetail) {
      return l10n.historyReviewWithoutQuestionDetail;
    }
    return item.showAnswerKey
        ? l10n.historyReviewWithAnswerKey
        : l10n.historyReviewWithoutAnswerKey;
  }

  Future<void> _openReview(ExamHistoryItem item) async {
    if (_openingId != null) return;

    setState(() => _openingId = item.studentExamSessionId);

    final result = await _userService.openExamReview(item.studentExamSessionId);
    if (!mounted) return;

    if (!result.success) {
      setState(() => _openingId = null);
      final l10n = AppLocalizations.of(context);

      if (result.blockedReason != null) {
        // Quyền xem lại phụ thuộc cấu hình ca thi VÀ thời điểm hiện tại, nên
        // nó có thể đã đổi kể từ lúc tải danh sách — đó chính là lý do backend
        // trả kèm `reason`. Nói đúng lý do vừa nhận rồi tải lại cho khớp thực
        // tế, nếu không thì nút vẫn sáng và người dùng bấm lại y như cũ.
        _showError(
          _blockedReasonText(l10n, result.blockedReason, item.reviewOpensAt),
        );
        await _loadHistory(showSpinner: false);
        return;
      }

      _showError(result.error ?? l10n.historyOpenFailed);
      return;
    }

    // Vẫn giữ trạng thái "đang mở" qua cả bước lấy chi tiết: từ góc nhìn người
    // dùng, nút sáng lại mà chưa có gì hiện ra nghĩa là bấm hụt, và họ bấm lại.
    final detail = await _userService.getSubmissionResult(
      item.studentExamSessionId,
    );
    if (!mounted) return;

    setState(() => _openingId = null);
    _showDetailSheet(item, detail);
  }

  void _showError(String message) {
    AppToast.show(context, kind: AppToastKind.error, title: message);
  }

  @override
  Widget build(BuildContext context) {
    // Bọc NGOÀI Scaffold để vòng xoay nổi trên cả AppBar — xem ghi chú cùng
    // kiểu ở account_screen. Bọc một lần ở đây cũng thay luôn hai
    // AppRefreshIndicator rời trước kia (một cho danh sách, một cho màn rỗng).
    return AppRefreshIndicator(
      edgeOffset: MediaQuery.paddingOf(context).top,
      onRefresh: _handleRefresh,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppTopBar(title: AppLocalizations.of(context).historyTitle),
        // `bottom: false` để danh sách chạy tiếp xuống dưới dải tab kính mờ —
        // khoảng chừa cho dải đã nằm trong padding cuối của `ListView`.
        body: SafeArea(bottom: false, child: _buildBody()),
      ),
    );
  }

  Future<void> _handleRefresh() async {
    await _loadHistory(showSpinner: false);
    // _loadHistory đặt _error khi API trả thất bại; im lặng trong trường hợp
    // đó, chứ kêu "thành công" lúc hỏng còn tệ hơn không báo gì.
    if (!mounted || _error != null) return;
    showRefreshDone(context);
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_items.isEmpty) {
      return _buildRefreshable(child: _buildEmptyState());
    }

    final l10n = AppLocalizations.of(context);

    return ListView(
      controller: widget.scrollController,
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        24 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        Text(
          l10n.historySubtitle,
          style: const TextStyle(fontSize: 13, color: AppColors.inkMuted),
        ),
        const SizedBox(height: 14),
        _buildSummary(l10n),
        const SizedBox(height: 18),
        for (final item in _items) _buildExamCard(l10n, item),
      ],
    );
  }

  /// Bọc một khối nội dung tĩnh vào vùng kéo-để-tải-lại.
  ///
  /// Cần `LayoutBuilder` + `ConstrainedBox`: `SingleChildScrollView` chứa nội
  /// dung ngắn thì cao đúng bằng nội dung, kéo ở khoảng trống bên dưới sẽ
  /// không bắt được cử chỉ — trong khi màn rỗng lại chính là chỗ người dùng
  /// muốn kéo để thử lại nhất.
  Widget _buildRefreshable({required Widget child}) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        // Dùng CHUNG controller với ListView ở nhánh có dữ liệu: hai vùng
        // cuộn này là hai trạng thái loại trừ nhau, không bao giờ cùng tồn
        // tại — nếu cùng lúc thì Flutter ném lỗi gắn trùng controller.
        controller: widget.scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(child: child),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedNoInternet,
              color: Colors.grey[400]!,
              size: 56.0,
            ),
            const SizedBox(height: 12),
            Text(
              _error ?? l10n.historyLoadFailed,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.grey[700]),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadHistory,
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedRefresh,
                color: Colors.white,
                size: 18,
              ),
              label: Text(l10n.commonRetry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const HugeIcon(
            icon: HugeIcons.strokeRoundedFileEmpty02,
            color: AppColors.disabledInk,
            size: 56,
          ),
          const SizedBox(height: 14),
          Text(
            l10n.historyEmptyTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.historyEmptyDesc,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.inkMuted),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            // Về TAB Trang chủ chứ không đẩy thêm màn mới: màn này nằm trong
            // thanh điều hướng, `Navigator.push` sẽ chồng một trang chủ thứ hai
            // lên trên chính thanh đó.
            onPressed: () => HomeNavigation.of(context)?.changeTab(0),
            child: Text(l10n.historyGoToExam),
          ),
        ],
      ),
    );
  }

  /// Thẻ tổng quan đầu màn.
  ///
  /// Tính ngay tại client vì dữ liệu đã có đủ trong danh sách; thêm một endpoint
  /// thống kê riêng chỉ để cộng bốn con số là thừa (web cũng làm y vậy).
  ///
  /// Bốn số nằm chung MỘT thẻ chứ không còn bốn thẻ viền xám xếp 2x2: cả bốn
  /// chỉ là một câu tóm tắt "đã thi bao nhiêu, được bao nhiêu", tách thành bốn
  /// khối rời làm đầu màn vụn ra và đẩy bài thi đầu tiên xuống quá sâu.
  Widget _buildSummary(AppLocalizations l10n) {
    final total = _items.length;
    var best = 0.0;
    var sum = 0.0;
    var violations = 0;
    for (final item in _items) {
      if (item.score > best) best = item.score;
      sum += item.score;
      violations += item.violationCount;
    }
    final average = total == 0 ? 0.0 : sum / total;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.barBg, AppColors.accent],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.20),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SummaryStat(label: l10n.historyStatTotal, value: '$total'),
          const _SummaryDivider(),
          _SummaryStat(
            label: l10n.historyStatBest,
            value: best.toStringAsFixed(2),
          ),
          const _SummaryDivider(),
          _SummaryStat(
            label: l10n.historyStatAverage,
            value: average.toStringAsFixed(2),
          ),
          const _SummaryDivider(),
          _SummaryStat(label: l10n.historyStatViolations, value: '$violations'),
        ],
      ),
    );
  }

  /// Màu theo mức điểm: giỏi xanh lá, khá xanh dương, trung bình vàng, dưới
  /// trung bình đỏ. Màu CHỈ là lớp nhấn thêm — con số luôn nằm ngay đó, nên
  /// người không phân biệt được màu vẫn đọc được kết quả.
  static Color _scoreColor(double score) {
    if (score >= 8) return const Color(0xFF16A34A);
    if (score >= 6.5) return AppColors.accent;
    if (score >= 5) return const Color(0xFFF59E0B);
    return AppColors.danger;
  }

  Widget _buildExamCard(AppLocalizations l10n, ExamHistoryItem item) {
    final isOpening = _openingId == item.studentExamSessionId;
    // Khoá các nút còn lại trong lúc một bài đang mở, nhưng KHÔNG khoá nút của
    // chính bài đó — nó còn phải hiện "Đang mở...".
    final isBlockedByOther = _openingId != null && !isOpening;
    final minutes = item.workedMinutes;
    final correct = item.correctAnswers;
    final total = item.totalQuestions;
    final scoreColor = _scoreColor(item.score);
    final canOpen = item.canReview && !isBlockedByOther && !isOpening;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.subjectName?.isNotEmpty == true
                            ? item.subjectName!
                            : l10n.historyUnknownSubject,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const HugeIcon(
                            icon: HugeIcons.strokeRoundedCalendar03,
                            color: AppColors.inkMuted,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _formatDateTime(item.sortedAt),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.inkMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Vòng điểm: thứ duy nhất trong thẻ được phép to và có màu, để
                // lướt danh sách là thấy ngay kết quả từng bài.
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scoreColor.withValues(alpha: 0.10),
                    border: Border.all(
                      color: scoreColor.withValues(alpha: 0.35),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      item.score.toStringAsFixed(2),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: scoreColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Các số phụ gom thành chip: bản trước cho mỗi số một dòng
          // "nhãn — giá trị", nên bài nào cũng cao bằng nhau dù phần lớn bài
          // chẳng có vi phạm hay cộng giờ để mà kể.
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (minutes != null)
                  _MetaChip(
                    icon: HugeIcons.strokeRoundedClock01,
                    text: l10n.historyDurationMinutes(minutes),
                  ),
                if (correct != null && total != null)
                  _MetaChip(
                    icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                    text: '$correct/$total',
                  ),
                if (item.extraMinutes > 0)
                  _MetaChip(
                    icon: HugeIcons.strokeRoundedTimeQuarterPass,
                    color: AppColors.accent,
                    text: l10n.historyBadgeExtraMinutes(item.extraMinutes),
                  ),
                if (item.violationCount > 0)
                  _MetaChip(
                    icon: HugeIcons.strokeRoundedAlert01,
                    color: AppColors.danger,
                    text: l10n.historyBadgeViolations(item.violationCount),
                  ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1, color: AppColors.line),

          Tooltip(
            message: item.canReview
                ? _reviewScopeText(l10n, item)
                : _blockedReasonText(
                    l10n,
                    item.reviewBlockedReason,
                    item.reviewOpensAt,
                  ),
            // Cả dải cuối thẻ là vùng bấm thay cho nút chữ nhật cũ: rộng hơn
            // hẳn cho ngón tay, mà vẫn nằm gọn trong thẻ.
            child: Material(
              color: Colors.transparent,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
              child: InkWell(
                onTap: canOpen ? () => _openReview(item) : null,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: isOpening
                        ? [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.accent,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                l10n.historyOpening,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.accent,
                                ),
                              ),
                            ),
                          ]
                        : [
                            Flexible(
                              child: Text(
                                l10n.historyReview,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: canOpen
                                      ? AppColors.accent
                                      : AppColors.disabledInk,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            HugeIcon(
                              icon: HugeIcons.strokeRoundedArrowRight01,
                              color: canOpen
                                  ? AppColors.accent
                                  : AppColors.disabledInk,
                              size: 18,
                            ),
                          ],
                  ),
                ),
              ),
            ),
          ),

          // Lý do phải hiện thành CHỮ chứ không chỉ nằm trong tooltip: nút xám
          // mà không nói vì sao thì người dùng chỉ biết bấm mãi không được.
          if (!item.canReview)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Text(
                _blockedReasonText(
                  l10n,
                  item.reviewBlockedReason,
                  item.reviewOpensAt,
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppColors.inkMuted),
              ),
            ),
        ],
      ),
    );
  }

  /// Bảng chi tiết một bài, mở sau khi máy chủ đã cấp phiếu xem lại.
  ///
  /// CỐ Ý KHÔNG mở `ExamResultScreen`:
  ///  - Màn đó nhận `answeredQuestions` (số câu ĐÃ TRẢ LỜI), còn lịch sử chỉ
  ///    có `correctAnswers` (số câu ĐÚNG). Nhét cái này vào chỗ cái kia là dán
  ///    nhãn sai cho con số — sinh viên bỏ trắng 10 câu vẫn thấy "đã trả lời"
  ///    bằng đúng số câu mình làm đúng.
  ///  - File đó đang được người khác sửa song song, đụng vào là chồng chéo.
  void _showDetailSheet(ExamHistoryItem item, ExamSubmissionDto? detail) {
    final l10n = AppLocalizations.of(context);

    // Ưu tiên số liệu vừa lấy từ `getSubmissionResult` (chốt tại thời điểm
    // chấm), thiếu tới đâu mới lấp bằng dòng trong danh sách tới đó.
    final start = detail?.startTime ?? item.startTime;
    final end = detail?.endTime ?? item.endTime;
    final score = detail?.score ?? item.score;
    final correct = detail?.correctAnswers ?? item.correctAnswers;
    final total = detail?.totalQuestions ?? item.totalQuestions;
    final minutes = _workedMinutes(start, end);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      // Nội dung cao hơn nửa màn trên máy 320x568, nên phải tự quản chiều cao
      // rồi cho phần giữa cuộn.
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        final maxHeight = MediaQuery.of(sheetContext).size.height * 0.85;

        return SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.line,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const HugeIcon(
                        icon: HugeIcons.strokeRoundedNoteDone,
                        color: AppColors.accent,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l10n.examResultTitle,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _InfoRow(
                    label: l10n.examCodeSubjectLabel,
                    value: item.subjectName?.isNotEmpty == true
                        ? item.subjectName!
                        : l10n.historyUnknownSubject,
                  ),
                  _InfoRow(
                    label: l10n.examCodeStartTimeLabel,
                    value: _formatDateTime(start),
                  ),
                  _InfoRow(
                    label: l10n.examCodeEndTimeLabel,
                    value: _formatDateTime(end),
                  ),
                  _InfoRow(
                    label: l10n.historyColDuration,
                    value: minutes == null
                        ? _noValue
                        : l10n.historyDurationMinutes(minutes),
                    // Số phút giáo viên cộng thêm đi kèm ngay dưới thời gian
                    // làm — đó là chỗ duy nhất con số đó giải thích được điều
                    // gì. Chỉ hiện khi có: "+0 phút" thì không nói lên gì.
                    note: item.extraMinutes > 0
                        ? l10n.historyBadgeExtraMinutes(item.extraMinutes)
                        : null,
                  ),
                  _InfoRow(
                    label: l10n.historyColCorrect,
                    value: (correct == null || total == null)
                        ? _noValue
                        : '$correct/$total',
                  ),
                  _InfoRow(
                    label: l10n.historyStatViolations,
                    value: '${item.violationCount}',
                  ),
                  _InfoRow(
                    label: l10n.historyColScore,
                    value: score.toStringAsFixed(2),
                    emphasize: true,
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    child: Text(l10n.commonClose),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Một con số trong thẻ tổng quan đầu màn.
///
/// `Expanded` chứ không bề rộng cố định: bốn nhãn tiếng Anh dài hơn hẳn bản
/// tiếng Việt, ghim bề rộng là cái thứ tư tràn ra khỏi thẻ ở 320dp.
class _SummaryStat extends StatelessWidget {
  const _SummaryStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10.5,
              height: 1.25,
              fontWeight: FontWeight.w500,
              // Trắng đục thay vì trắng đặc: nhãn tụt xuống sau con số, không
              // tranh chỗ với nó.
              color: Color(0xCCFFFFFF),
            ),
          ),
        ],
      ),
    );
  }
}

/// Vạch ngăn giữa hai con số của thẻ tổng quan.
class _SummaryDivider extends StatelessWidget {
  const _SummaryDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 30,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      color: Colors.white.withValues(alpha: 0.28),
    );
  }
}

/// Chip số liệu phụ trong thẻ bài thi (thời gian làm, số câu đúng, vi phạm).
///
/// Không truyền màu thì chip là tông xám trung tính — dành cho số liệu bình
/// thường; màu chỉ để dành cho thứ đáng chú ý như vi phạm hay cộng giờ.
class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.text, this.color});

  final List<List<dynamic>> icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tone = color ?? AppColors.inkMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color == null
            ? AppColors.surfaceMuted
            : tone.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color == null ? AppColors.line : tone.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(icon: icon, color: tone, size: 13),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: color == null ? AppColors.ink : tone,
            ),
          ),
        ],
      ),
    );
  }
}

/// Một dòng "nhãn — giá trị" trong thẻ bài thi và trong bảng chi tiết.
///
/// Hai cột đều là [Expanded] chứ không cột nào ghim bề rộng cố định: nhãn dài
/// nhất của bản tiếng Anh cộng cỡ chữ hệ thống phóng to là đủ tràn ngang ở
/// 320dp nếu cột giá trị không chịu co.
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.note,
    this.emphasize = false,
  });

  final String label;
  final String value;

  /// Dòng phụ nhỏ dưới giá trị (dùng cho số phút được cộng thêm).
  final String? note;

  /// Tô đậm giá trị — dành cho điểm số, thứ người dùng mở màn này để xem.
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppColors.inkMuted),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: emphasize ? 16 : 13,
                    fontWeight: emphasize ? FontWeight.w700 : FontWeight.w600,
                    color: emphasize ? AppColors.accent : AppColors.ink,
                  ),
                ),
                if (note != null)
                  Text(
                    note!,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent,
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
