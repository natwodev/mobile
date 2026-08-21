import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/notification_sound_service.dart';
import 'app_colors.dart';

/// Thanh báo đang hiện, giữ ở đây để cú kéo sau dẹp được cú kéo trước.
///
/// Kéo liên tục mấy lần mà cái nào cũng chờ hết giờ thì chúng xếp chồng lên
/// nhau, cái cuối còn nằm lại rất lâu sau khi người dùng đã bỏ đi.
OverlayEntry? _current;

/// Báo một việc người dùng vừa làm đã XONG XUÔI.
///
/// Dùng cho những xác nhận thoáng qua do chính thao tác của người dùng sinh ra:
/// kéo tải lại, lưu hồ sơ, đổi mật khẩu, đổi ảnh đại diện. KHÁC với [AppToast]
/// — toast dành cho tin từ hệ thống (giám thị nhắn, bị chặn khỏi ca thi) và
/// luôn nằm góc trên phải. Trộn hai thứ vào một kiểu hiển thị là mất khả năng
/// nhìn phát biết ngay tin đến từ đâu.
///
/// KHÔNG dùng `SnackBar` của Material: nó cố định trượt từ dưới lên, không có
/// chỗ cho thanh đếm giờ và cũng không có nút đóng. Ba thứ đó phải tự dựng nên
/// đây là một overlay riêng.
///
/// CHỈ gọi khi việc THÀNH CÔNG. Hỏng mà vẫn báo "thành công" thì tệ hơn hẳn
/// việc im lặng.
void showSuccessBanner(BuildContext context, String message) {
  // Âm thanh phát độc lập, không chờ thanh báo dựng xong.
  NotificationSoundService.play(NotificationSound.refresh).ignore();

  final OverlayState overlay = Overlay.of(context);

  // Đọc phần chừa dưới TỪ CONTEXT CỦA MÀN, không phải của overlay: thanh tab
  // nổi do HomeNavigation bơm chiều cao vào MediaQuery của riêng nhánh màn
  // hình. Overlay nằm trên Navigator nên đọc ở đó chỉ ra phần chừa của hệ điều
  // hành, và thanh báo sẽ nằm khuất sau thanh tab.
  final double bottomInset = MediaQuery.paddingOf(context).bottom;

  _current?.remove();
  _current = null;

  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _RefreshBanner(
      message: message,
      bottomInset: bottomInset,
      onClosed: () {
        if (_current == entry) _current = null;
        entry.remove();
      },
    ),
  );

  _current = entry;
  overlay.insert(entry);
}

/// Xác nhận riêng cho cú kéo-để-tải-lại.
///
/// Vòng xoay của `RefreshIndicator` chỉ nói "đang chạy" rồi biến mất, không nói
/// được kết quả. Kéo xong mà màn hình trông y như cũ — vì thật sự không có gì
/// mới — thì người dùng không phân biệt được là đã tải lại hay thao tác bị
/// trượt.
void showRefreshDone(BuildContext context) {
  showSuccessBanner(context, AppLocalizations.of(context).commonReloadSuccess);
}

/// Thanh báo trượt vào từ phải, có thanh đếm ngược và nút đóng.
class _RefreshBanner extends StatefulWidget {
  const _RefreshBanner({
    required this.message,
    required this.bottomInset,
    required this.onClosed,
  });

  final String message;
  final double bottomInset;
  final VoidCallback onClosed;

  @override
  State<_RefreshBanner> createState() => _RefreshBannerState();
}

class _RefreshBannerState extends State<_RefreshBanner>
    with TickerProviderStateMixin {
  /// Thời gian thanh báo nằm lại. Dài hơn mức 2 giây trước đây vì giờ có thanh
  /// đếm ngược — chạy vèo trong hai giây thì người dùng không kịp thấy nó chạy.
  static const Duration _visibleFor = Duration(seconds: 3);
  static const Duration _slideFor = Duration(milliseconds: 260);

  late final AnimationController _slide = AnimationController(
    vsync: this,
    duration: _slideFor,
  );

  /// Vừa là đồng hồ đếm giờ, vừa là nguồn cho thanh tiến trình — một
  /// controller cho cả hai nên thanh chạy hết đúng lúc thanh báo biến mất,
  /// không thể lệch nhau.
  late final AnimationController _timer = AnimationController(
    vsync: this,
    duration: _visibleFor,
  );

  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _slide.forward();
    _timer
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _close();
      })
      ..forward();
  }

  Future<void> _close() async {
    if (_closing) return;
    _closing = true;

    _timer.stop();
    await _slide.reverse();
    if (!mounted) return;
    widget.onClosed();
  }

  @override
  void dispose() {
    _slide.dispose();
    _timer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      // Ngay TRÊN thanh điều hướng: bottomInset đã gồm cả chiều cao thanh tab
      // lẫn phần chừa của hệ điều hành, chỉ cộng thêm một khe hở mỏng.
      bottom: widget.bottomInset + 10,
      child: SlideTransition(
        // Từ PHẢI qua trái. 1.08 thay vì 1.0 để thanh báo bắt đầu từ ngoài hẳn
        // mép màn, kể cả phần đổ bóng cũng không ló ra ở khung hình đầu tiên.
        position: Tween<Offset>(
          begin: const Offset(1.08, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: _slide, curve: Curves.easeOutCubic)),
        child: FadeTransition(
          opacity: _slide,
          child: Material(
            color: Colors.white,
            elevation: 6,
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [_buildRow(), _buildTimeBar()],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      child: Row(
        children: [
          // Huy hiệu tròn đặc: trên nền trắng thì một icon trơn chìm nghỉm,
          // khối tròn thì nhìn phát biết ngay là báo thành công.
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: Color(0xFF16A34A),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.message,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
          ),
          // Nút đóng: người dùng đọc xong rồi thì không phải chờ hết ba giây,
          // nhất là khi thanh báo che mất đúng chỗ vừa vuốt.
          IconButton(
            onPressed: _close,
            icon: const Icon(Icons.close, size: 18),
            color: AppColors.disabledInk,
            splashRadius: 20,
            visualDensity: VisualDensity.compact,
            tooltip: MaterialLocalizations.of(context).closeButtonLabel,
          ),
        ],
      ),
    );
  }

  /// Thanh chạy hết dần theo thời gian còn lại.
  ///
  /// Đi từ đầy về rỗng chứ không phải ngược lại: thanh vơi dần đọc ra ngay là
  /// "sắp hết giờ", còn thanh đầy dần dễ bị hiểu nhầm thành "đang tải".
  Widget _buildTimeBar() {
    return AnimatedBuilder(
      animation: _timer,
      builder: (_, _) => LinearProgressIndicator(
        value: 1 - _timer.value,
        minHeight: 3,
        backgroundColor: AppColors.line,
        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF16A34A)),
      ),
    );
  }
}
