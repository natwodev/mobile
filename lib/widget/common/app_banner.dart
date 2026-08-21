import 'package:flutter/material.dart';

import '../../component/HomeNavigation.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../services/notification_sound_service.dart';
import 'app_colors.dart';

/// Thanh báo đang hiện, giữ ở đây để cú kéo sau dẹp được cú kéo trước.
///
/// Kéo liên tục mấy lần mà cái nào cũng chờ hết giờ thì chúng xếp chồng lên
/// nhau, cái cuối còn nằm lại rất lâu sau khi người dùng đã bỏ đi.
OverlayEntry? _current;

/// Trạng thái của thanh báo — quyết định màu huy hiệu, icon, thanh thời gian
/// và tiếng kêu.
///
/// Bốn trạng thái chứ không phải hai: chỉ có đúng/sai thì mọi thứ "chưa hỏng
/// nhưng cũng chưa xong" đều bị dồn vào một trong hai đầu, và người dùng đọc ra
/// nặng hơn hoặc nhẹ hơn thực tế.
enum AppBannerKind {
  success,
  error,

  /// Việc xong nhưng có điều cần lưu ý.
  warning,

  /// Chỉ thông tin, không phải kết quả của việc gì.
  info,
}

extension _BannerStyle on AppBannerKind {
  Color get color => switch (this) {
    AppBannerKind.success => const Color(0xFF16A34A),
    AppBannerKind.error => AppColors.danger,
    AppBannerKind.warning => const Color(0xFFF59E0B),
    AppBannerKind.info => AppColors.accent,
  };

  IconData get icon => switch (this) {
    AppBannerKind.success => Icons.check,
    AppBannerKind.error => Icons.close,
    AppBannerKind.warning => Icons.priority_high,
    AppBannerKind.info => Icons.info_outline,
  };

  /// Tiếng kêu lấy đúng bộ âm dùng chung với toast, để cùng một loại tin thì
  /// nghe giống nhau dù hiện bằng thanh báo hay bằng toast.
  NotificationSound get sound => switch (this) {
    AppBannerKind.success => NotificationSound.success,
    AppBannerKind.error => NotificationSound.error,
    AppBannerKind.warning => NotificationSound.warning,
    AppBannerKind.info => NotificationSound.multiline,
  };
}

/// Thanh báo trượt vào từ phải, nằm ngay trên dải tab.
///
/// Dùng cho phản hồi thoáng qua do chính thao tác của người dùng sinh ra: kéo
/// tải lại, lưu hồ sơ, đổi mật khẩu, đổi ảnh đại diện — cả lúc xong lẫn lúc
/// hỏng. KHÁC với [AppToast]: toast dành cho tin từ HỆ THỐNG (giám thị nhắn,
/// bị chặn khỏi ca thi) và luôn nằm góc trên phải. Trộn hai thứ vào một kiểu
/// hiển thị là mất khả năng nhìn phát biết ngay tin đến từ đâu.
///
/// KHÔNG dùng `SnackBar` của Material: nó cố định trượt từ dưới lên, không có
/// chỗ cho thanh đếm giờ và cũng không có nút đóng.
void showAppBanner(
  BuildContext context, {
  required String message,
  AppBannerKind kind = AppBannerKind.success,
  NotificationSound? sound,
}) {
  // Âm thanh phát độc lập, không chờ thanh báo dựng xong.
  NotificationSoundService.play(sound ?? kind.sound).ignore();

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
    builder: (_) => _AppBanner(
      message: message,
      kind: kind,
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

/// Việc người dùng vừa làm đã xong xuôi.
void showSuccessBanner(BuildContext context, String message) =>
    showAppBanner(context, message: message);

/// Việc người dùng vừa làm KHÔNG xong.
///
/// Hiện bằng thanh báo chứ không bằng toast, vì nó là phản hồi cho đúng thao
/// tác người dùng vừa bấm — cùng chỗ, cùng kiểu với lúc thành công. Bắt người
/// ta nhìn xuống đáy màn khi xong rồi ngước lên góc trên khi hỏng là bắt họ
/// học hai chỗ cho một việc.
void showErrorBanner(BuildContext context, String message) =>
    showAppBanner(context, message: message, kind: AppBannerKind.error);

/// Xác nhận riêng cho cú kéo-để-tải-lại.
///
/// Vòng xoay của `RefreshIndicator` chỉ nói "đang chạy" rồi biến mất, không nói
/// được kết quả. Kéo xong mà màn hình trông y như cũ — vì thật sự không có gì
/// mới — thì người dùng không phân biệt được là đã tải lại hay thao tác bị
/// trượt.
///
/// Giữ tiếng chuông riêng của việc tải lại thay vì tiếng "thành công" chung:
/// kéo tải lại là thao tác lặp đi lặp lại nhiều lần trong một phiên, nghe mãi
/// một tiếng với lúc lưu hồ sơ thì hai việc lẫn vào nhau.
void showRefreshDone(BuildContext context) => showAppBanner(
  context,
  message: AppLocalizations.of(context).commonReloadSuccess,
  sound: NotificationSound.refresh,
);

/// Thanh báo trượt vào từ phải, có thanh đếm ngược và nút đóng.
class _AppBanner extends StatefulWidget {
  const _AppBanner({
    required this.message,
    required this.kind,
    required this.bottomInset,
    required this.onClosed,
  });

  final String message;
  final AppBannerKind kind;
  final double bottomInset;
  final VoidCallback onClosed;

  @override
  State<_AppBanner> createState() => _AppBannerState();
}

class _AppBannerState extends State<_AppBanner> with TickerProviderStateMixin {
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
      // Trùng lề ngang với dải tab để hai thanh thẳng cột với nhau.
      left: 12,
      right: 12,
      // Mép dưới thanh báo nằm ngay trên dải tab, chừa đúng một khe rất mảnh.
      //
      // `bottomInset` là phần chừa mà HomeNavigation bơm vào MediaQuery, và nó
      // đã gồm cả `barMarginTop` — khoảng hở giữa nội dung và dải tab. Không
      // trừ ra thì khe rộng tới 16px, đủ để nội dung trang lọt qua giữa hai
      // thanh và nhìn thành hai mảnh rời.
      //
      // Nhưng trừ hết sạch thì hai thanh dính liền, mất luôn ranh giới giữa
      // thanh báo và thanh điều hướng. Cộng lại 1.5px: đủ thành một đường chỉ
      // tách bạch, chưa đủ để hở ra nội dung phía sau.
      bottom: widget.bottomInset - HomeNavigation.barMarginTop + 1.5,
      child: SlideTransition(
        // Từ PHẢI qua trái. 1.08 thay vì 1.0 để thanh báo bắt đầu từ ngoài hẳn
        // mép màn, kể cả phần đổ bóng cũng không ló ra ở khung hình đầu tiên.
        position: Tween<Offset>(
          begin: const Offset(1.08, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: _slide, curve: Curves.easeOutCubic)),
        child: FadeTransition(
          opacity: _slide,
          // Bóng XANH toả quanh, cùng ngôn ngữ với thẻ hai nút nhanh ở Trang
          // chủ (`home_screen.dart`) — bóng màu chủ đạo chứ không phải xám đen,
          // nên thanh báo trông như phát sáng thay vì bị dán đè lên màn.
          //
          // Khác thẻ nút nhanh ở hai điểm, đều có lý do:
          //   • blurRadius 14 thay vì 25 — mỏng hơn. Thanh báo chỉ cao 58px,
          //     bóng toả 25px làm nó trông như chìm trong sương.
          //   • alpha 0.28 thay vì 0.18 — đậm hơn, bù lại cho việc toả hẹp.
          //
          // Và offset lệch LÊN chứ không xuống: dải tab nằm sát ngay bên dưới,
          // bóng đổ xuống là rơi thẳng lên nó thành một vệt bẩn đúng chỗ hai
          // thanh giáp nhau. Đây cũng là lý do không dùng `elevation` của
          // Material — elevation toả đều bốn phía, không chọn hướng được.
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.30),
                  // Độ lệch lên ĐÚNG BẰNG độ toả. Bóng toả ra mọi phía chừng
                  // `blurRadius`, nên đẩy lên đúng chừng ấy thì mép dưới của
                  // bóng dừng lại ngay ở đáy thanh báo — không còn pixel nào
                  // rơi xuống dải tab. Lệch ít hơn (ví dụ -4) là vẫn rớt vài
                  // pixel xuống, thành vệt xám mờ đúng chỗ hai thanh giáp nhau.
                  blurRadius: 10,
                  offset: const Offset(0, -10),
                ),
              ],
            ),
            child: Material(
              color: Colors.white,
              elevation: 0,
              // Viền 0.5px màu xanh chủ đạo. Mảnh đến mức trên màn 3x chỉ dày
              // đúng một điểm ảnh vật lý — vừa đủ tách thanh báo khỏi nền
              // trắng phía sau, chưa đủ để thành một khung viền lộ liễu.
              //
              // Viền giữ MÀU XANH ở cả bốn trạng thái, không đổi theo `kind`:
              // nó là đường bao của thanh báo — thứ luôn giống nhau — còn trạng
              // thái đã có huy hiệu và thanh thời gian nói hộ.
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppColors.accent, width: 0.5),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [_buildRow(), _buildTimeBar()],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 11, 6, 11),
      child: Row(
        children: [
          // Huy hiệu tròn đặc: trên nền trắng thì một icon trơn chìm nghỉm,
          // khối tròn thì nhìn phát biết ngay là báo thành công.
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: widget.kind.color,
              shape: BoxShape.circle,
            ),
            child: Icon(widget.kind.icon, color: Colors.white, size: 20),
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
            // Ghim kích thước lại: IconButton mặc định cao 40px, lớn hơn cả
            // huy hiệu 34px — tức chính nó mới quyết định chiều cao thanh báo.
            // Không ghim thì giảm đệm bao nhiêu cũng không thấy thanh thấp đi.
            // 34 để bằng đúng huy hiệu bên trái, vẫn đủ rộng để bấm trúng.
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
            tooltip: MaterialLocalizations.of(context).closeButtonLabel,
          ),
          const SizedBox(width: 6),
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
        minHeight: 2,
        backgroundColor: AppColors.line,
        valueColor: AlwaysStoppedAnimation<Color>(widget.kind.color),
      ),
    );
  }
}
