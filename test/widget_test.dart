// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:quizz_mobile/main.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(HutechCampusApp());

    // Verify that the app loads with bottom navigation
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Lớp học'), findsOneWidget);
    expect(find.text('Bài kiểm tra'), findsOneWidget);
    expect(find.text('Tài khoản'), findsOneWidget);
  });
}
