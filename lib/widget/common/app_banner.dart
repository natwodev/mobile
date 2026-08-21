import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../component/HomeNavigation.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../services/notification_sound_service.dart';
import 'app_colors.dart';
import 'app_surfaces.dart';

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
    AppBannerKind.warning => AppColors.warning,
    AppBannerKind.info => AppColors.accent,
  };

  /// Kiểu trả về là `List<List<dynamic>>` chứ không phải `IconData`: HugeIcons
  /// lưu icon dưới dạng dữ liệu đường vẽ, không phải điểm mã phông chữ như
  /// `Icons` của Material.
  List<List<dynamic>> get icon => switch (this) {
    AppBannerKind.success => HugeIcons.strokeRoundedTick01,
    AppBannerKind.error => HugeIcons.strokeRoundedCancel01,
    AppBannerKind.warning => HugeIcons.strokeRoundedAlert02,
    AppBannerKind.info => HugeIcons.strokeRoundedInformationCircle,
  };

  /// Tiếng kêu lấy đúng bộ âm dùng chung với toast, để cùng một loại tin thì
  /// nghe giống nhau dù hiện bằng thanh báo hay bằng toast.
  NotificationSound get sound => switch (this) {
    AppBannerKind.success => NotificationSound.success,
    AppBannerKind.error => NotificationSound.error,
    AppBannerKind.warning => NotificationSound.warning,
    AppBannerKind.info => NotificationSound.multiline,
  };

  /// Dòng tiêu đề — chỉ nói KẾT QUẢ, không nói chi tiết.
  ///
  /// Tách khỏi phần mô tả vì hai thứ trả lời hai câu hỏi khác nhau: "được hay
  /// hỏng" và "việc gì". Gộp vào một dòng thì người dùng phải đọc hết câu mới
  /// biết kết quả, trong khi thanh báo chỉ sống ba giây.
  String title(AppLocalizations l10n) => switch (this) {
    AppBannerKind.success => l10n.commonStatusSuccess,
    AppBannerKind.error => l10n.commonStatusFailed,
    AppBannerKind.warning => l10n.commonStatusWarning,
    AppBannerKind.info => l10n.commonStatusInfo,
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

/// Cú kéo-để-tải-lại KHÔNG lấy được dữ liệu — thường là mất mạng.
///
/// Trước đây nhánh này im lặng, với lý do "báo thành công lúc hỏng còn tệ hơn
/// không báo". Lý do đó chỉ đúng khi thanh báo mới có mỗi trạng thái thành
/// công. Từ khi có trạng thái lỗi thì im lặng lại là dở nhất: người dùng kéo
/// xong thấy màn hình y như cũ, không biết mạng hỏng hay app đơ, nên kéo tiếp
/// mấy lần nữa.
void showRefreshFailed(BuildContext context) => showAppBanner(
  context,
  message: AppLocalizations.of(context).commonReloadFailed,
  kind: AppBannerKind.error,
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
                  // Màu theo TRẠNG THÁI, không cố định xanh. Trước đây viền lấy
                  // theo `kind.color` còn bóng thì luôn `accent`, nên thanh báo
                  // lỗi viền đỏ mà toả sáng xanh.
                  color: widget.kind.color.withValues(alpha: 0.30),
                  // Độ lệch lên LUÔN BẰNG độ toả. Bóng lan ra mọi phía chừng
                  // `blurRadius`, nên đẩy lên đúng chừng ấy thì mép dưới của
                  // bóng dừng lại ngay ở đáy thanh báo — không còn pixel nào
                  // rơi xuống dải tab. Hai số này phải đi cùng nhau: đổi một
                  // cái mà quên cái kia là bóng lại rớt xuống dải tab.
                  blurRadius: 6,
                  offset: const Offset(0, -6),
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
              // Viền lấy ĐÚNG màu của trạng thái — cùng màu với thanh thời gian
              // và huy hiệu — nhưng hạ xuống 40% độ đục.
              //
              // Cùng màu để cả thanh báo là một khối thống nhất: nhìn viền là
              // đã đoán được trạng thái trước khi đọc chữ. Nhạt đi vì viền chạy
              // hết chu vi, để nguyên độ đục thì nó thành thứ đậm nhất trên
              // thanh và kéo mắt khỏi huy hiệu lẫn nội dung — trong khi việc
              // của nó chỉ là tách thanh báo khỏi nền trắng phía sau.
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: AppSurfaces.side(tint: widget.kind.color),
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
      // Đệm dọc 9.5 chứ không phải 11: hai dòng chữ (13px + 12px ≈ 33px) vẫn
      // lọt trong chiều cao huy hiệu 34px, nên chiều cao thanh vẫn do huy hiệu
      // quyết định — hạ đệm là hạ được thật, không bị chữ chống lên.
      padding: const EdgeInsets.fromLTRB(14, 9.5, 6, 9.5),
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
            child: HugeIcon(
              icon: widget.kind.icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Dòng KẾT QUẢ: đậm, màu theo trạng thái. Đọc một chữ là biết
                // được hay hỏng, không phải đọc hết câu mô tả.
                Text(
                  widget.kind.title(AppLocalizations.of(context)),
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                    color: widget.kind.color,
                  ),
                ),
                // Dòng MÔ TẢ: nhạt và nhỏ hơn, nói rõ việc gì vừa xảy ra.
                Text(
                  widget.message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.25,
                    color: AppColors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
          // Nút đóng: người dùng đọc xong rồi thì không phải chờ hết ba giây,
          // nhất là khi thanh báo che mất đúng chỗ vừa vuốt.
          IconButton(
            onPressed: _close,
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedCancel01,
              color: AppColors.disabledInk,
              size: 16,
            ),
            color: AppColors.disabledInk,
            splashRadius: 20,
            visualDensity: VisualDensity.compact,
            // Viền tròn quanh dấu ✕, cùng công thức viền của cả app (màu chủ
            // thể hạ 40% độ đục, 0.5px). Đặt theo màu TRẠNG THÁI nên nó cân
            // với huy hiệu tròn đặc bên trái: một khối đặc, một khối rỗng, hai
            // đầu thanh báo có cùng hình dạng.
            //
            // Icon thu 18 -> 16 để chừa chỗ cho đường viền: giữ 18 thì dấu ✕
            // chạm sát viền, nhìn ra là chật chứ không phải một nút tròn.
            style: IconButton.styleFrom(
              shape: CircleBorder(
                side: AppSurfaces.side(tint: widget.kind.color),
              ),
            ),
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
