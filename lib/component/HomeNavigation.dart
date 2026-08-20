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

  @override
  State<HomeNavigation> createState() => _HomeNavigationState();

  static _HomeNavigationState? of(BuildContext context) {
    return context.findAncestorStateOfType<_HomeNavigationState>();
  }
}

class _HomeNavigationState extends State<HomeNavigation> {
  int _currentIndex = 0;

  /// PHẢI cùng thứ tự với danh sách `items` của thanh tab bên dưới — hai danh
  /// sách này chỉ khớp nhau bằng chỉ số, thêm tab vào giữa mà quên một bên là
  /// bấm "Lịch sử" ra màn "Tài khoản".
  final List<Widget> _screens = [
    HomeScreen(),
    ExamHistoryScreen(),
    AccountScreen(),
  ];

  // Thanh tab là một dải nền xanh trời đậm; tab đang chọn là viên thuốc cùng
  // tông nhưng nhạt hơn một nấc. Cả hai nền đều là xanh trung nên chữ và icon
  // dùng trắng, tab không chọn thì trắng ngả xanh cho dịu bớt.
  static const Color _barColor = AppColors.barBg;

  /// Độ đục của dải: đủ dày để chữ/icon còn đọc được, nhưng vẫn thấy nội dung
  /// trôi qua phía sau khi cuộn.
  static const double _barOpacity = 0.72;
  static const Color _pillColor = Color(0xFF57C2FA);
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
  static const double _barLift = 33;

  /// Khoảng hở giữa nội dung và mép trên dải tab.
  static const double _barMarginTop = 6;

  void changeTab(int index) {
    setState(() {
      _currentIndex = index;
    });
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
    final barSpace = _barHeight + _barLift + _barMarginTop;

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
          padding: const EdgeInsets.fromLTRB(12, _barMarginTop, 12, _barLift),
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
                    _navItem(
                      HugeIcons.strokeRoundedClock01,
                      l10n.homeNavHistory,
                    ),
                    _navItem(HugeIcons.strokeRoundedUser, l10n.homeNavAccount),
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
