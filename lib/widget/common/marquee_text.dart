import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';

/// Một dòng chữ tự chạy ngang khi chỗ không đủ, đứng yên khi vừa.
///
/// Dùng cho tiêu đề đề thi ở header màn làm bài: tên đề dài như "Đề thi cuối
/// kỳ Lập trình hướng đối tượng" trước đây bị cắt cụt thành "Đề thi cuối kỳ
/// Lậ..." nên sinh viên không đọc được mình đang làm đề nào.
///
/// Đo bề rộng chữ trước rồi mới quyết định: chữ ngắn thì vẽ [Text] bình thường
/// chứ không cho chạy — [Marquee] chạy vô điều kiện, tiêu đề ngắn mà vẫn trôi
/// qua trôi lại thì vừa rối mắt vừa tốn khung hình.
class MarqueeText extends StatelessWidget {
  const MarqueeText(
    this.text, {
    super.key,
    this.style,
    this.textAlign = TextAlign.center,
    this.velocity = 30,
    this.blankSpace = 56,
    this.pauseAfterRound = const Duration(seconds: 1),
  });

  final String text;
  final TextStyle? style;

  /// Canh lề khi chữ đủ ngắn để đứng yên. Lúc chạy thì luôn bắt đầu từ mép
  /// trái vì chữ dài hơn khung.
  final TextAlign textAlign;

  /// Tốc độ chạy, pixel mỗi giây.
  final double velocity;

  /// Khoảng trống chèn giữa hai vòng chữ.
  final double blankSpace;

  /// Nghỉ bao lâu ở đầu mỗi vòng, để mắt kịp bắt đầu đọc.
  final Duration pauseAfterRound;

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = DefaultTextStyle.of(context).style.merge(style);

    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: text, style: effectiveStyle),
          maxLines: 1,
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout();

        if (painter.width <= constraints.maxWidth) {
          return Text(
            text,
            style: effectiveStyle,
            textAlign: textAlign,
            maxLines: 1,
          );
        }

        // Marquee đòi chiều cao hữu hạn: nó dựng ListView ngang bên trong nên
        // để trong AppBar/Row mà không ghim chiều cao là văng lỗi bố cục.
        return SizedBox(
          height: painter.height,
          child: Marquee(
            text: text,
            style: effectiveStyle,
            velocity: velocity,
            blankSpace: blankSpace,
            pauseAfterRound: pauseAfterRound,
            startPadding: 0,
            accelerationCurve: Curves.linear,
            decelerationCurve: Curves.linear,
            showFadingOnlyWhenScrolling: false,
            fadingEdgeStartFraction: 0.08,
            fadingEdgeEndFraction: 0.08,
          ),
        );
      },
    );
  }
}
