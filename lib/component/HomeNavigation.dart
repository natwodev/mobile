import 'package:bottom_bar/bottom_bar.dart';
import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/class/class_screen.dart';
import '../screens/examHistory/examhistory_screen.dart';
import '../screens/auth/account_screen.dart';
import '../screens/examSession/examsession_screen.dart';
import 'package:hugeicons/hugeicons.dart';

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

  final List<Widget> _screens = [
    HomeScreen(),
    SessionExamScreen(),
    ClassScreen(),
    ExamHistoryScreen(),
    AccountScreen(),
  ];

  void changeTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],

      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashFactory: NoSplash.splashFactory,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: BottomBar(
          backgroundColor: Colors.blue,
          selectedIndex: _currentIndex,

          onTap: (index) {
            setState(() => _currentIndex = index);
          },
          items: <BottomBarItem>[
            BottomBarItem(
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedHome01,
                color: Colors.white,
                size: 26.0,
              ),
              title: Text('Trang chủ'),
              activeColor: Colors.white,
              inactiveColor: Colors.grey,
            ),
            BottomBarItem(
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedCalendar02,
                color: Colors.white,
                size: 26.0,
              ),
              title: Text('Ca thi'),
              activeColor: Colors.white,
              inactiveColor: Colors.grey,
            ),
            BottomBarItem(
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedUserGroup,
                color: Colors.white,
                size: 26.0,
              ),
              title: Text('Lớp học'),
              activeColor: Colors.white,
              inactiveColor: Colors.grey,
            ),
            BottomBarItem(
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedAssignments,
                color: Colors.white,
                size: 26.0,
              ),
              title: Text('Bài kiểm tra'),
              activeColor: Colors.white,
              inactiveColor: Colors.grey,
            ),
            BottomBarItem(
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedUser,
                color: Colors.white,
                size: 26.0,
              ),
              title: Text('Tài khoản'),
              activeColor: Colors.white,
              inactiveColor: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
