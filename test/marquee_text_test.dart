import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marquee/marquee.dart';
import 'package:quizz_mobile/widget/common/marquee_text.dart';

Widget _bar(String title) => MaterialApp(
  home: Scaffold(
    appBar: AppBar(
      title: MarqueeText(title, style: const TextStyle(color: Colors.white)),
      centerTitle: true,
      backgroundColor: Colors.blue,
    ),
    body: const SizedBox(),
  ),
);

void main() {
  testWidgets('chữ ngắn thì đứng yên', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_bar('Đề thi'));
    await tester.pump();

    expect(find.byType(Marquee), findsNothing);
    expect(find.text('Đề thi'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('chữ dài thì chạy', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _bar('Đề thi cuối kỳ Lập trình hướng đối tượng - Học kỳ 1 2025-2026'),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));

    expect(find.byType(Marquee), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
