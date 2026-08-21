import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../screens/Exam/quick_exam_code_screen.dart';
import '../screens/notification/notification_screen.dart';
import '../screens/scan_qr/scan_exam_qr_screen.dart';
import '../l10n/generated/app_localizations.dart';
import '../widget/common/app_buttons.dart';
import '../widget/home/home_banner_carousel.dart';
import '../widget/home/home_news_section.dart';
import '../widget/common/app_refresh_indicator.dart';
import '../widget/common/app_banner.dart';
import '../widget/home/quiz_answer_banner.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key, this.scrollController});

  /// Do [HomeNavigation] giữ, để bấm nút tab là cuộn màn này về đầu.
  final ScrollController? scrollController;

  /// Chìa để với tới dải tin mà bảo nó tải lại.
  ///
  /// Trang chủ chỉ có DUY NHẤT dải tin là lấy dữ liệu từ mạng — băng ảnh và
  /// hai nút nhanh đều nằm sẵn trong app. Nên "kéo tải lại cả trang" thực chất
  /// là tải lại đúng phần này.
  final GlobalKey<HomeNewsSectionState> _newsKey =
      GlobalKey<HomeNewsSectionState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AppRefreshIndicator(
        // Trang chủ không có AppBar nên phải tự đẩy vòng xoay xuống dưới thanh
        // trạng thái; các màn khác có AppBar thì để 0.
        edgeOffset: MediaQuery.paddingOf(context).top,
        onRefresh: () async {
          final bool ok = await _newsKey.currentState?.reload() ?? false;
          if (!context.mounted) return;
          // Hỏng thì báo đỏ chứ KHÔNG im lặng: kéo xong mà màn hình y như cũ
          // và không có phản hồi nào thì người dùng không biết mạng hỏng hay
          // app đơ, nên kéo tiếp mấy lần nữa cho chắc.
          ok ? showRefreshDone(context) : showRefreshFailed(context);
        },
        child: SingleChildScrollView(
          controller: scrollController,
          // AlwaysScrollable: thiếu dòng này thì hôm nào tin ngắn, nội dung
          // không cao quá màn hình, là RefreshIndicator không bắt được cử chỉ
          // kéo — kéo mãi không ra gì mà chẳng hiểu vì sao.
          physics: const AlwaysScrollableScrollPhysics(),
          // Thanh tab nổi đè lên nội dung, nên phần cuối màn phải chừa đúng chỗ
          // nó chiếm (giá trị do HomeNavigation bơm vào MediaQuery) — không thì
          // cuộn hết cỡ vẫn còn một mẩu nằm khuất dưới thanh.
          padding: EdgeInsets.only(
            bottom: MediaQuery.paddingOf(context).bottom,
          ),
          child: Column(
            children: [
              // Header với Banner + 3 nút nhanh
              _buildHeader(context),
              _buildBannerCarousel(),
              // Dải tin dưới băng ảnh — phần lấp chỗ trống nửa dưới màn hình và
              // là lý do Trang chủ có gì để cuộn.
              HomeNewsSection(key: _newsKey),
            ],
          ),
        ),
      ),
    );
  }

  /// Băng ảnh động dưới thẻ 2 nút nhanh.
  ///
  /// Năm tấm đều 393x165, vẽ thẳng cho khung ngang của băng ảnh bằng
  /// `tool/make_banners.py`. Bản trước lấy từ bộ panel dựng cho khung
  /// 393x280, đặt vào đây là mất gần 40% chiều cao — mà phần mất luôn rơi
  /// đúng vào chỗ có nội dung.
  Widget _buildBannerCarousel() {
    // Dải nền trắng ngả xám chạy hết bề ngang: các tấm ảnh đều có nền sáng,
    // đặt thẳng trên nền trắng của màn thì mép ảnh lẫn vào nền và băng ảnh
    // trông như trôi lơ lửng.
    return Container(
      width: double.infinity,
      // Màu phải chuyển vào `decoration`: `Container` không nhận đồng thời
      // `color` và `decoration` — khai cả hai là Flutter ném assert ngay.
      decoration: const BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      // BẮT BUỘC khi `decoration` có bo góc: `Container` KHÔNG tự cắt widget
      // con theo hình nền của nó. Thiếu dòng này thì hai tấm ảnh hai bên vẫn
      // vẽ tràn qua bốn góc bo và chạy thẳng ra mép màn — nhìn ra là ảnh nằm
      // ĐÈ LÊN dải xám chứ không nằm TRONG nó, và bo góc coi như vô nghĩa.
      clipBehavior: Clip.antiAlias,
      // KHÔNG đệm dọc: dải xám phải cao ĐÚNG BẰNG tấm ảnh giữa.
      //
      // Băng ảnh đặt `aspectRatio` nên chiều cao khung đã cố định theo bề
      // ngang, và `enlargeStrategy: height` cho tấm giữa cao hết khung ấy. Bỏ
      // đệm đi thì mép trên/dưới của dải xám trùng khít mép tấm giữa — thêm 14
      // như trước là thừa ra một viền xám ôm quanh ảnh.
      child: const HomeBannerCarousel(
        slides: [
          HomeBannerSlide(asset: 'assets/banners/38_chon_dap_an.gif'),
          HomeBannerSlide(asset: 'assets/banners/42_diem_10.gif'),
          HomeBannerSlide(asset: 'assets/banners/44_nhom_ban.gif'),
          HomeBannerSlide(asset: 'assets/banners/35_cong_truong.gif'),
          HomeBannerSlide(asset: 'assets/banners/47_but_chi_a_cong.gif'),
        ],
      ),
    );
  }

  // Header: Banner + 3 nút nhanh đè lên (Stack)
  Widget _buildHeader(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Chiều cao Stack = đáy thẻ trắng + một dải đệm mỏng. Phải đủ bọc hết thẻ
    // vì phần thò ra ngoài Stack mất vùng hit-test (nút bấm không ăn); nhưng dư
    // ra bao nhiêu là chừng đó khoảng trắng chen giữa thẻ và băng ảnh bên dưới.
    return SizedBox(
      height: 258,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Banner pixel động "chọn đáp án A B C D": vẽ bằng code, không dùng
          // ảnh nên không tăng dung lượng app và nét ở mọi mật độ điểm ảnh.
          const SizedBox(
            height: 180,
            width: double.infinity,
            child: QuizAnswerBanner(),
          ),

          // Nút chuông đè lên banner. Lấy `padding.top` của MediaQuery thay vì
          // bọc SafeArea: banner cố tình chạy lên tận mép trên, bọc SafeArea là
          // đẩy tụt cả tấm ảnh xuống.
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 12,
            child: _buildNotificationButton(context),
          ),

          // Container 3 nút nhanh đè lên banner với bóng xanh
          // Kích thước thẻ trắng do 3 thứ quyết định, theo mức ảnh hưởng giảm dần:
          //   1. `padding` dưới đây          -> chiều cao
          //   2. ô icon 56x56 trong _buildQuickButton
          //   3. `left`/`right`              -> bề rộng
          // Lưu ý: `bottom` đo từ ĐÁY Stack lên, nên nó vừa là dải đệm dưới
          // thẻ vừa quyết định thẻ thò xuống dưới banner bao nhiêu. Hạ số này
          // là kéo băng ảnh lại gần, nhưng xuống dưới 0 thì thẻ lòi ra khỏi
          // Stack và nút KHÔNG bấm được nữa.
          Positioned(
            bottom: 8,
            left: 16,
            right: 16,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                // Viền cùng màu với bóng mờ, nhưng nhạt hơn hẳn và chỉ 0.5px.
                //
                // Bóng toả rộng nên chỗ giáp mép thẻ đã loãng gần hết màu —
                // thẻ trắng đặt trên băng ảnh sáng thì mất luôn đường bao. Viền
                // này vẽ lại đúng cái mép đó. Cùng khuôn với viền thanh báo
                // (`app_banner.dart`): cùng màu chủ thể, hạ độ đục xuống 40%,
                // dày nửa điểm ảnh logic.
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.4),
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    // Bóng MỎNG mà ĐẬM, thay cho rộng mà nhạt như trước
                    // (25px @ 18%). Toả 25px làm màu bị dàn mỏng đến mức đặt
                    // trên băng ảnh nhiều màu là gần như mất hút, thẻ trông
                    // như dán phẳng lên. Thu về 12px rồi nâng độ đục lên 38%
                    // thì viền sáng bám sát mép thẻ, đọc ra là "nổi lên" rõ
                    // ràng mà không loang ra nền.
                    color: AppColors.accent.withValues(alpha: 0.42),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildQuickButton(
                    child: HugeIcon(
                      // Quiz01: nút này mở màn NHẬP MÃ ca thi để vào làm bài;
                      // icon chìa khoá cũ dễ bị hiểu là đổi mật khẩu.
                      icon: HugeIcons.strokeRoundedQuiz01,
                      color: AppColors.accent,
                      size: 26,
                    ),
                    label: l10n.homeQuickExamButton,
                    color: AppColors.accent,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const QuickExamCodeScreen(),
                        ),
                      );
                    },
                  ),
                  _buildQuickButton(
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedQrCode01,
                      color: AppColors.accent,
                      size: 26,
                    ),
                    label: l10n.homeScanExamQrButton,
                    color: AppColors.accent,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ScanExamQrScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Nút chuông mở trang Thông báo.
  //
  // Vòng trắng tròn phía sau: ảnh banner chỗ sáng chỗ tối, icon trơn là có lúc
  // chìm hẳn vào nền.
  Widget _buildNotificationButton(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: IconButton(
        tooltip: l10n.notificationsTitle,
        // Siết đệm và vùng chạm tối thiểu: mặc định IconButton là 48x48 kèm
        // đệm 8 mỗi bên, để nguyên thì vòng trắng phình thành một mảng to
        // trên banner thay vì ôm sát cái chuông.
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        visualDensity: VisualDensity.compact,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotificationScreen()),
          );
        },
        icon: HugeIcon(
          icon: HugeIcons.strokeRoundedNotification02,
          color: AppColors.accent,
          size: 22,
        ),
      ),
    );
  }

  // Nút nhanh
  Widget _buildQuickButton({
    IconData? icon,
    Widget? child,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    // Ưu tiên widget tùy biến nếu được truyền, fallback dùng IconData
    final Widget iconWidget = child ?? Icon(icon, color: color, size: 26);

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.accentBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(child: iconWidget),
              ),

              SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
