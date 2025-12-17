import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';

Widget buildMarqueeOrText(String text, double maxWidth) {
  final tp = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    ),
    maxLines: 1,
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: double.infinity);

  if (tp.width > maxWidth) {
    return SizedBox(
      height: 30,
      width: maxWidth,
      child: Marquee(
        text: text,
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        scrollAxis: Axis.horizontal,
        blankSpace: 40,
        velocity: 30,
      ),
    );
  }

  return Text(
    text,
    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    overflow: TextOverflow.ellipsis,
  );
}
