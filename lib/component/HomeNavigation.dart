import 'dart:ui' show ImageFilter;

import 'package:bottom_bar/bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../l10n/generated/app_localizations.dart';
import '../screens/auth/account_screen.dart';
import '../screens/Exam/exam_history_screen.dart';
import '../screens/home_screen.dart';
import '../widget/common/app_buttons.dart';

class HomeNavigation extends StatefulWidget {
  const HomeNavigation({super.key});

  /// Khoảng hở giữa nội dung màn và mép trên dải tab.
  ///
  /// CÔNG KHAI vì thanh báo thành công cần đặt mép dưới của nó đúng vào mép
  /// trên dải tab. Phần chừa mà `HomeNavigation` bơm vào `MediaQuery` đã gồm cả
  /// khoảng hở này, nên muốn nằm SÁT dải tab thì phải trừ nó ra — thiếu bước
  /// đó là còn một khe để lọt nội dung trang phía sau.
  static const double barMarginTop = 6;

  @override
  State<HomeNavigation> createState() => _HomeNavigationState();

  static _HomeNavigationState? of(BuildContext context) {
    return context.findAncestorStateOfType<_HomeNavigationState>();
  }
}

class _HomeNavigationState extends State<HomeNavigation> {
  int _currentIndex = 0;

  /// Mỗi tab một bộ điều khiển cuộn riêng, để bấm vào nút tab là cuộn ĐÚNG màn
  /// đang mở về đầu. Dùng chung một bộ cho cả ba là không được: một
  /// `ScrollController` chỉ gắn được vào một vùng cuộn tại một thời điểm.
  final List<ScrollController> _scrollControllers =
      List<ScrollController>.generate(3, (_) => ScrollController());

  /// PHẢI cùng thứ tự với danh sách `items` của thanh tab bên dưới — hai danh
  /// sách này chỉ khớp nhau bằng chỉ số, thêm tab vào giữa mà quên một bên là
  /// bấm "Lịch sử" ra màn "Tài khoản".
  late final List<Widget> _screens = [
    HomeScreen(scrollController: _scrollControllers[0]),
    ExamHistoryScreen(scrollController: _scrollControllers[1]),
    AccountScreen(scrollController: _scrollControllers[2]),
  ];

  @override
  void dispose() {
    for (final controller in _scrollControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // Dải nền ĐẬM, viên thuốc của tab đang chọn NHẠT hơn — cùng một tông xanh.
  // Chữ và icon dùng trắng trên cả hai; tab không chọn thì trắng ngả xanh cho
  // dịu bớt.
  static const Color _barColor = AppColors.barBg;

  /// Độ đục của dải.
  ///
  /// 0.95 chứ không phải 0.72 như trước. Ở mức 0.72, dải phủ lên nội dung
  /// trắng phía sau nên SÁNG LÊN đáng kể — màu thật `#1E8BCF` đọc ra nhạt hơn
  /// hẳn mã gốc, và dải trông nhạt hơn cả viên thuốc dù mã màu ngược lại. Nói
  /// cách khác, chính độ đục mới quyết định đậm/nhạt ở đây, không phải mã màu.
  /// 0.95 giữ được chút kính mờ mà màu vẫn gần đúng.
  static const double _barOpacity = 0.95;

  /// Viên thuốc: chính `barBg` pha thêm trắng ~30%.
  ///
  /// PHẢI dẫn xuất từ màu dải chứ không chọn rời. Trước đây dải và viên thuốc
  /// là hai mã chọn độc lập (`#1E8BCF` và `#098CDD`) — mà tính ra hai màu đó
  /// sáng gần y hệt nhau (121 và 118 trên thang 255), nên không tài nào ra được
  /// tương phản đậm/nhạt: thứ duy nhất phân biệt chúng là độ đục.
  static const Color _pillColor = Color(0xFF62AEDD);
  static const Color _activeColor = Colors.white;
  static const Color _inactiveColor = Color(0xFFE0F2FE);

  // ===== Các số điều khiển hình dạng dải tab =====
  // Ba số đầu cộng lại đúng bằng _barHeight: đệm ngoài 2 cạnh + đệm viên thuốc
  // 2 cạnh + cỡ icon. Đổi một số mà quên _barHeight là viên thuốc bị dải bo
  // tròn cắt.
  static const double _barHeight = 56;
  static const double _barPadding = 6; // đệm giữa dải và viên thuốc
  static const double _itemPaddingV = 11; // đệm trên/dưới trong viên thuốc
  static const double _iconSize = 22;

  /// Bo góc dải tab. Để đúng `_barHeight / 2` là dải thành viên thuốc tròn
  /// hoàn toàn; số nhỏ hơn cho góc mềm nhưng vẫn ra hình chữ nhật.
  static const double _barRadius = 20;

  /// Khoảng nhấc dải tab lên khỏi mép dưới — cộng thêm vào vùng an toàn của
  /// máy chứ không thay thế nó, nên trên máy có thanh vuốt điều hướng thì dải
  /// vẫn nổi cao hơn thanh đó đúng chừng này.
  static const double _barLift = 30;

  void changeTab(int index) {
    final bool sameTab = index == _currentIndex;

    if (!sameTab) {
      setState(() {
        _currentIndex = index;
      });
    }

    if (sameTab) {
      // Bấm lại tab đang mở: vùng cuộn đã gắn sẵn, cuộn được ngay. Đây là
      // trường hợp chính — người dùng lướt sâu xuống rồi muốn về đầu mà không
      // phải vuốt ngược cả trang.
      _scrollToTop(index);
    } else {
      // Đổi tab: màn mới chưa dựng nên controller chưa gắn vào đâu cả, gọi ngay
      // là không có tác dụng. Chờ hết khung hình rồi mới cuộn.
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToTop(index));
    }
  }

  void _scrollToTop(int index) {
    final ScrollController controller = _scrollControllers[index];
    // `hasClients` false nghĩa là màn đó chưa dựng hoặc nội dung ngắn đến mức
    // không có gì để cuộn — gọi animateTo lúc ấy là ném exception.
    if (!controller.hasClients) return;

    controller.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  /// Một mục của thanh tab.
  ///
  /// `BottomBar` tô icon qua `IconTheme`, nhưng `HugeIcon` nhận màu qua tham số
  /// riêng nên không nghe theo — phải dựng sẵn hai bản icon cho hai trạng thái,
  /// nếu không icon giữ nguyên một màu ở cả tab đang chọn lẫn tab không chọn.
  BottomBarItem _navItem(List<List<dynamic>> icon, String label) {
    return BottomBarItem(
      icon: HugeIcon(icon: icon, color: _activeColor, size: _iconSize),
      inactiveIcon: HugeIcon(
        icon: icon,
        color: _inactiveColor,
        size: _iconSize,
      ),
      title: Text(label),
      // `activeColor` vừa là nền viên thuốc vừa là màu mặc định của icon/chữ
      // khi được chọn: để trắng cho viên thuốc, rồi chỉ định riêng màu xanh cho
      // icon và chữ nằm trên nó.
      activeColor: _pillColor,
      backgroundColorOpacity: 1,
      activeIconColor: _activeColor,
      activeTitleColor: _activeColor,
      inactiveColor: _inactiveColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // Nội dung chạy xuống tận đáy màn hình và luồn dưới dải tab — đây là thứ
    // làm khoảng trống quanh dải trong suốt thật, thay vì lộ ra một mảng nền
    // trắng. Đổi lại, phần cuối mỗi màn phải tự chừa chỗ cho dải: dòng
    // `MediaQuery` bên dưới bơm sẵn khoảng đó vào padding dưới để `SafeArea`
    // và các `ListView` của từng màn cứ thế đọc ra.
    final mq = MediaQuery.of(context);
    final barSpace = _barHeight + _barLift + HomeNavigation.barMarginTop;

    return Scaffold(
      extendBody: true,
      body: MediaQuery(
        data: mq.copyWith(
          padding: mq.padding.copyWith(bottom: mq.padding.bottom + barSpace),
        ),
        child: _screens[_currentIndex],
      ),
      // Dải bo tròn kính mờ nổi trên nội dung: nền chỉ phủ một lớp màu trong
      // nên nội dung cuộn phía sau vẫn nhìn thấy, `BackdropFilter` làm nhòe
      // phần đó để chữ/icon không bị chữ của màn hình phía dưới xen vào.
      //
      // Màu và bo góc nằm ở lớp bọc ngoài chứ không ở `BottomBar`: phần
      // `SafeArea` chừa cho thanh vuốt điều hướng của máy nằm NGOÀI `BottomBar`
      // nên để package tự tô thì màu tràn hết đáy màn hình thay vì dừng lại ở
      // dải bo tròn. `ClipRRect` cũng là thứ giữ vệt nhòe nằm gọn trong dải —
      // thiếu nó thì `BackdropFilter` nhòe cả khoảng trống hai bên.
      bottomNavigationBar: SafeArea(
        top: false,
        left: false,
        right: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            12,
            HomeNavigation.barMarginTop,
            12,
            _barLift,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_barRadius),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: ColoredBox(
                color: _barColor.withValues(alpha: _barOpacity),
                child: BottomBar(
                  selectedIndex: _currentIndex,
                  onTap: changeTab,
                  height: _barHeight,
                  padding: const EdgeInsets.all(_barPadding),
                  itemPadding: const EdgeInsets.symmetric(
                    vertical: _itemPaddingV,
                    horizontal: 20,
                  ),
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  items: [
                    _navItem(HugeIcons.strokeRoundedHome01, l10n.homeNavHome),
                    // CheckList thay cho Clock01: màn này là DANH SÁCH bài đã
                    // làm kèm điểm, không phải thứ liên quan tới giờ giấc. Đồng
                    // hồ đọc ra là "thời gian" hoặc "đang chờ" — sai nội dung.
                    // Ở cỡ 22px thì danh sách có dấu tick cũng rõ hơn tờ giấy
                    // có dấu tick nhỏ xíu bên trong.
                    _navItem(
                      HugeIcons.strokeRoundedTaskDone01,
                      l10n.homeNavHistory,
                    ),
                    // UserCircle thay cho User trơn: ở cỡ 22px, hình người nằm
                    // trong vòng tròn có khối rõ hơn hẳn mấy nét rời, nhất là
                    // khi đứng cạnh icon danh sách toàn nét ngang bên trái.
                    _navItem(
                      HugeIcons.strokeRoundedUserCircle,
                      l10n.homeNavAccount,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
