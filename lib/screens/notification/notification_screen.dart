import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';

import '../../controller/notification_badge.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/app_notification.dart';
import '../../services/notification/notification_cache.dart';
import '../../services/notification/notification_service.dart';
import '../../services/notification/push_service.dart';
import '../../widget/common/app_banner.dart';
import '../../widget/common/app_buttons.dart';
import '../../widget/common/app_refresh_indicator.dart';
import '../../widget/common/app_top_bar.dart';

/// Hộp thư của sinh viên.
///
/// Danh sách LUÔN lấy từ `GET /api/notification` — máy chủ giữ bản thật, push
/// của FCM chỉ là tiếng gõ cửa. Chi tiết vì sao không để app tự dựng danh sách
/// từ tin push: xem `HOP-THU-man-chuong-ban-giao.md`.
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  /// Số thư mỗi lần tải, bằng đúng mặc định của máy chủ.
  static const int _pageSize = 20;

  final NotificationService _service = NotificationService();
  final ScrollController _scrollController = ScrollController();

  final List<AppNotification> _items = [];

  bool _loading = true;
  bool _loadingMore = false;

  /// Đã gọi mạng hỏng. Khác với "không có thư nào" — hai thứ này hiện ra màn
  /// hình phải khác nhau, không thì mất mạng lại báo "chưa có thông báo".
  bool _failed = false;

  int _page = 1;
  int _total = 0;

  bool get _hasMore => _items.length < _total;

  @override
  void initState() {
    super.initState();
    _bootstrap();

    // Thư mới tới trong lúc màn này đang mở thì tải lại ngay.
    //
    // Thiếu chỗ này là lỗi người dùng thấy rõ nhất: thông báo vừa hiện trên đầu
    // máy, mở ra thì danh sách vẫn y nguyên, phải tự kéo tải lại mới có.
    PushService.instance.incoming.addListener(_onIncoming);
  }

  @override
  void dispose() {
    PushService.instance.incoming.removeListener(_onIncoming);
    _scrollController.dispose();
    super.dispose();
  }

  /// Có thư mới trong lúc đang mở màn này.
  ///
  /// Tải lại TỪ ĐẦU chứ không chèn thêm một dòng: tin push không mang đủ dữ
  /// liệu để dựng một dòng danh sách — gửi hàng loạt còn không có cả id thư.
  /// Máy chủ sắp sẵn mới nhất trước nên tải lại là thư mới nằm đúng trên cùng.
  ///
  /// Chỉ tải lại trang ĐẦU. Người dùng đang đọc dở trang thứ ba thì phần đã tải
  /// thêm sẽ mất, nhưng đó là đánh đổi đúng: thư mới nhất quan trọng hơn, và
  /// giữ lại các trang cũ thì phải ghép hai mẻ dữ liệu lệch nhau về phân trang.
  void _onIncoming() {
    if (!mounted) return;
    _loadFirstPage();
  }

  /// Hiện bản lưu TRƯỚC, rồi mới hỏi máy chủ.
  ///
  /// Mở chuông là thấy thư ngay thay vì nhìn vòng quay, và mất mạng vẫn còn thư
  /// cũ để đọc lại.
  Future<void> _bootstrap() async {
    final cached = await NotificationCache.load();
    if (!mounted) return;

    if (cached.isNotEmpty) {
      setState(() {
        _items
          ..clear()
          ..addAll(cached);
        // Chưa biết tổng thật, tạm lấy số thư đang có để nút "tải thêm" không
        // hiện lên rồi bấm vào chẳng ra gì.
        _total = cached.length;
        _loading = false;
      });
    }

    await _loadFirstPage();
  }

  /// Tải trang đầu. Trả `true` khi lấy được dữ liệu MỚI từ máy chủ.
  ///
  /// Phải trả kết quả chứ không để nơi gọi tự đoán qua `_failed`: còn thư trong
  /// bản lưu thì `_failed` vẫn là false dù gọi mạng hỏng, nên kéo-tải-lại sẽ
  /// báo "thành công" trong khi thực ra chẳng lấy được gì. Đúng cái bẫy đã mắc
  /// một lần ở màn Tài khoản.
  Future<bool> _loadFirstPage() async {
    final page = await _service.fetch(page: 1, pageSize: _pageSize);
    if (!mounted) return false;

    if (page == null) {
      setState(() {
        _loading = false;
        // Còn thư trong bản lưu thì đừng dựng màn lỗi đè lên: thư cũ vẫn đọc
        // được, báo lỗi bằng thanh báo là đủ.
        _failed = _items.isEmpty;
      });
      return false;
    }

    setState(() {
      _items
        ..clear()
        ..addAll(page.items);
      _page = 1;
      _total = page.total;
      _loading = false;
      _failed = false;
    });

    NotificationBadge.instance.set(page.unreadCount);

    // GHI ĐÈ bản lưu, không trộn: trộn thì thư đã đọc trên web lại hiện chưa
    // đọc trong app, và thư giáo viên thu hồi vẫn nằm nguyên đó.
    await NotificationCache.save(page.items, page.unreadCount);
    return true;
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;

    setState(() => _loadingMore = true);

    final next = await _service.fetch(page: _page + 1, pageSize: _pageSize);
    if (!mounted) return;

    if (next == null) {
      setState(() => _loadingMore = false);
      showErrorBanner(context, AppLocalizations.of(context).notificationsError);
      return;
    }

    setState(() {
      _items.addAll(next.items);
      _page = next.page;
      _total = next.total;
      _loadingMore = false;
    });
  }

  Future<void> _handleRefresh() async {
    final bool ok = await _loadFirstPage();
    if (!mounted) return;

    ok ? showRefreshDone(context) : showRefreshFailed(context);
  }

  /// Chạm vào một thư: đánh dấu đã đọc rồi sửa tại chỗ.
  Future<void> _open(AppNotification item) async {
    if (item.isRead) return;

    final index = _items.indexWhere((e) => e.id == item.id);
    if (index < 0) return;

    // Đổi giao diện NGAY rồi mới gọi mạng: chạm vào mà phải chờ một vòng gọi
    // mạng mới thấy đổi thì người dùng tưởng chạm hụt và chạm lại.
    setState(() => _items[index] = item.copyWith(isRead: true));
    NotificationBadge.instance.decrement();

    final ok = await _service.markRead(item.id);
    if (!mounted || ok) return;

    // Gọi hỏng thì trả lại đúng trạng thái cũ, không im lặng nuốt: để nguyên
    // "đã đọc" là lần mở sau thư lại hiện chưa đọc, người dùng không hiểu vì
    // sao.
    setState(() => _items[index] = item.copyWith(isRead: false));
    NotificationBadge.instance.set(NotificationBadge.instance.count + 1);
    showErrorBanner(context, AppLocalizations.of(context).notificationsError);
  }

  Future<void> _markAllRead() async {
    if (!_items.any((e) => !e.isRead)) return;

    final snapshot = List<AppNotification>.from(_items);

    setState(() {
      for (int i = 0; i < _items.length; i++) {
        _items[i] = _items[i].copyWith(isRead: true);
      }
    });
    NotificationBadge.instance.clear();

    final ok = await _service.markAllRead();
    if (!mounted) return;

    if (ok) {
      await NotificationCache.save(_items, 0);
      return;
    }

    setState(() {
      _items
        ..clear()
        ..addAll(snapshot);
    });
    await NotificationBadge.instance.refresh();
    if (!mounted) return;
    showErrorBanner(context, AppLocalizations.of(context).notificationsError);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bool hasUnread = _items.any((e) => !e.isRead);

    // Bọc NGOÀI Scaffold để vòng xoay nổi trên cả AppBar, cùng kiểu với màn
    // Lịch sử và màn Tài khoản.
    return AppRefreshIndicator(
      edgeOffset: MediaQuery.paddingOf(context).top,
      onRefresh: _handleRefresh,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppTopBar(
          title: l10n.notificationsTitle,
          showBack: true,
          actions: [
            if (hasUnread)
              TextButton(
                onPressed: _markAllRead,
                child: Text(
                  l10n.notificationsMarkAllRead,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        body: SafeArea(child: _buildBody(l10n)),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }

    // Xét CÓ THƯ ĐỂ HIỆN trước, xét `_failed` sau. Ngược lại thì mất mạng là
    // dựng màn lỗi đè lên cả bản lưu còn dùng được — đúng cái bẫy đã mắc một
    // lần ở dải tin Trang chủ.
    if (_items.isEmpty) {
      return _buildEmpty(l10n, failed: _failed);
    }

    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: _items.length + (_hasMore ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index >= _items.length) return _buildLoadMore(l10n);
        return _NotificationTile(
          item: _items[index],
          onTap: () => _open(_items[index]),
        );
      },
    );
  }

  Widget _buildLoadMore(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Center(
        child: _loadingMore
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  color: AppColors.accent,
                  strokeWidth: 2,
                ),
              )
            : OutlinedButton(
                onPressed: _loadMore,
                child: Text(l10n.notificationsLoadMore),
              ),
      ),
    );
  }

  /// Màn rỗng, dùng chung cho hai chuyện khác hẳn nhau nên chữ phải khác nhau:
  /// thật sự chưa có thư, và gọi mạng hỏng.
  Widget _buildEmpty(AppLocalizations l10n, {required bool failed}) {
    // PHẢI cuộn được, dù nội dung ngắn: `AppRefreshIndicator` chỉ nhận cú kéo
    // từ một vùng cuộn. Để `Center` trần thì đúng lúc cần kéo tải lại nhất —
    // màn rỗng vì mất mạng — lại không kéo được.
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.16),
        Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: (failed ? AppColors.danger : AppColors.accent)
                      .withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: HugeIcon(
                  icon: failed
                      ? HugeIcons.strokeRoundedWifiDisconnected01
                      : HugeIcons.strokeRoundedNotificationOff02,
                  color: failed ? AppColors.danger : AppColors.accent,
                  size: 44,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                failed ? l10n.notificationsError : l10n.notificationsEmptyTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                failed
                    ? l10n.notificationsErrorHint
                    : l10n.notificationsEmptyMessage,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Một lá thư trong danh sách.
class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item, required this.onTap});

  final AppNotification item;
  final VoidCallback onTap;

  /// Biểu tượng theo loại thư.
  ///
  /// PHẢI có nhánh mặc định: backend thêm loại mới bất cứ lúc nào mà không báo
  /// trước, và một loại lạ không được phép làm hỏng cả hộp thư.
  static List<List<dynamic>> _iconFor(String type) {
    return switch (type) {
      'TeacherMessage' => HugeIcons.strokeRoundedMessage01,
      'Violation' => HugeIcons.strokeRoundedAlert02,
      'VpnDetected' => HugeIcons.strokeRoundedShield01,
      _ => HugeIcons.strokeRoundedNotification02,
    };
  }

  /// Màu theo mức độ. Loại lạ hay mức lạ đều rơi về màu nhấn thường.
  static Color _colorFor(String severity) {
    return switch (severity) {
      'High' => AppColors.danger,
      'Medium' => AppColors.warning,
      _ => AppColors.accent,
    };
  }

  /// Mốc nhận thư: LUÔN đủ ngày/tháng/năm kèm giờ phút.
  ///
  /// Một dạng duy nhất cho mọi thư, không co giãn theo "hôm nay hay hôm khác".
  /// Bản đầu rút gọn thư trong ngày còn mỗi giờ phút, nên cùng một cột mà hai
  /// dòng liền nhau ghi "16:36" và "20/08/2026 09:12" — đọc lướt không so được
  /// cái nào trước cái nào, phải dừng lại nhận ra một bên là giờ một bên là
  /// ngày.
  ///
  /// Giữ cả giờ phút vì thông báo ca thi hay tính bằng phút: "7h30 mở phòng"
  /// gửi lúc 16:36 hay 06:36 là hai chuyện khác hẳn nhau.
  static String _formatTime(DateTime when) =>
      DateFormat('dd/MM/yyyy HH:mm').format(when);

  @override
  Widget build(BuildContext context) {
    final Color tint = _colorFor(item.severity);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            // Thư chưa đọc có nền xanh rất nhạt, thư đã đọc nền trắng. Phân
            // biệt bằng NỀN chứ không chỉ bằng chấm tròn: lướt mắt xuống một
            // danh sách dài thì mảng màu nhận ra ngay, còn chấm tròn phải nhìn
            // từng dòng mới thấy.
            color: item.isRead ? Colors.white : AppColors.accentBg,
            borderRadius: BorderRadius.circular(12),
            // Thư chưa đọc viền theo màu MỨC ĐỘ của nó, thư đã đọc viền xám
            // trung tính — đọc rồi thì không cần đòi sự chú ý nữa.
            border: item.isRead
                ? Border.all(
                    color: AppColors.line,
                    width: AppSurfaces.borderWidth,
                  )
                : AppSurfaces.border(tint: tint),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: HugeIcon(
                    icon: _iconFor(item.type),
                    color: tint,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 14.5,
                              // Chữ đậm cho thư chưa đọc, cùng quy ước với mọi
                              // hộp thư khác người dùng đã quen.
                              fontWeight: item.isRead
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                              color: AppColors.ink,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!item.isRead) ...[
                          const SizedBox(width: 8),
                          Container(
                            margin: const EdgeInsets.only(top: 6),
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.message,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: AppColors.inkMuted,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatTime(item.createdAt),
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.disabledInk,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
