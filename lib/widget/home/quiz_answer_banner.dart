import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../common/app_colors.dart';

/// Hàm vẽ một khối ô vuông trên lưới pixel.
typedef _Cell = void Function(int x, int y, int w, int h, Color color);

/// Banner đầu màn hình Home: hoạt cảnh pixel "chọn đáp án A B C D".
///
/// Con trỏ chạy lần lượt A → B → C rồi chốt câu C: ô chuyển xanh, hiện dấu
/// tick và tia sáng, sau đó lặp lại (12 khung / 0,96 giây).
///
/// Vẽ hoàn toàn bằng code trên lưới ô vuông nên không cần file ảnh: app không
/// nặng thêm và hình luôn nét ở mọi mật độ điểm ảnh.
///
/// Bố cục TỰ NÉ hai vùng bị che, không cắm cứng toạ độ:
///   * trên: thanh trạng thái (lấy `MediaQuery.padding.top`);
///   * dưới: [bottomCover] điểm ảnh bị thẻ trắng 2 nút nhanh thò lên che.
/// Dải trống còn lại hẹp thì tự hạ chiều cao ô đáp án, hẹp nữa thì hạ cỡ chữ.
class QuizAnswerBanner extends StatefulWidget {
  const QuizAnswerBanner({super.key, this.bottomCover = 34});

  /// Phần đáy banner bị thẻ trắng 2 nút nhanh che (điểm ảnh logic).
  ///
  /// Để dư vài điểm ảnh so với thực tế: nhãn nút dài có thể xuống 2 dòng làm
  /// thẻ cao thêm và mép trên của nó dâng lên.
  final double bottomCover;

  @override
  State<QuizAnswerBanner> createState() => _QuizAnswerBannerState();
}

class _QuizAnswerBannerState extends State<QuizAnswerBanner>
    with SingleTickerProviderStateMixin {
  static const int _frameCount = 12;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 960),
  )..repeat();

  /// Chỉ vẽ lại khi đổi khung (12 lần/giây) thay vì mỗi nhịp màn hình.
  final ValueNotifier<int> _frame = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTick);
  }

  void _onTick() {
    final int next = (_controller.value * _frameCount).floor() % _frameCount;
    if (next != _frame.value) _frame.value = next;
  }

  @override
  void dispose() {
    _controller.removeListener(_onTick);
    _controller.dispose();
    _frame.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _QuizAnswerPainter(
          frame: _frame,
          topInset: MediaQuery.of(context).padding.top,
          bottomCover: widget.bottomCover,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _QuizAnswerPainter extends CustomPainter {
  _QuizAnswerPainter({
    required this.frame,
    required this.topInset,
    required this.bottomCover,
  }) : super(repaint: frame);

  final ValueNotifier<int> frame;
  final double topInset;
  final double bottomCover;

  /// Số cột của lưới; chiều cao ô luôn bằng chiều rộng để pixel vuông.
  static const int _cols = 131;

  // Bảng màu lấy theo tone sáng của app (xem lib/widget/exam/quiz_theme.dart).
  // Nền chuyển từ trắng ngà xuống xanh nhạt để thẻ trắng 2 nút nhanh nằm đè
  // bên dưới vẫn nổi khối.
  static const List<Color> _bands = <Color>[
    Color(0xFFF8FAFC),
    Color(0xFFEFF6FF),
    Color(0xFFE0F2FE),
    Color(0xFFDBEAFE),
    Color(0xFFBFDBFE),
  ];
  static const Color _grid = Color(0xFFBFDBFE);

  // Trỏ về bảng chung thay vì khai lại mã màu: hai nơi cùng giữ một mã là
  // cách chắc chắn để mai kia sửa một bên và bỏ quên bên còn lại.
  static const Color _accent = AppColors.accent;
  static const Color _accentDeep = Color(0xFF1D4ED8);
  static const Color _accentBorder = Color(0xFF93C5FD);
  static const Color _line = Color(0xFFBFDBFE);
  static const Color _lineBar = Color(0xFFCBD5E1);
  static const Color _ink = Color(0xFF1E293B);
  static const Color _white = Color(0xFFFFFFFF);

  static const Color _ok = Color(0xFF10B981);
  static const Color _okSoft = Color(0xFFD1FAE5);
  static const Color _okBar = Color(0xFF6EE7B7);
  static const Color _okInk = Color(0xFF047857);
  static const Color _spark = Color(0xFFF59E0B);

  /// Font pixel 3x5 tự dựng, chỉ giữ các chữ cần dùng.
  static const Map<String, List<String>> _font = <String, List<String>>{
    'A': <String>['XXX', 'X.X', 'XXX', 'X.X', 'X.X'],
    'B': <String>['XX.', 'X.X', 'XX.', 'X.X', 'XX.'],
    'C': <String>['XXX', 'X..', 'X..', 'X..', 'XXX'],
    'D': <String>['XX.', 'X.X', 'X.X', 'X.X', 'XX.'],
    'E': <String>['XXX', 'X..', 'XXX', 'X..', 'XXX'],
    'I': <String>['XXX', '.X.', '.X.', '.X.', 'XXX'],
    'M': <String>['X.X', 'XXX', 'XXX', 'X.X', 'X.X'],
    'Q': <String>['XXX', 'X.X', 'X.X', 'XXX', '..X'],
    'T': <String>['XXX', '.X.', '.X.', '.X.', '.X.'],
    'U': <String>['X.X', 'X.X', 'X.X', 'X.X', 'XXX'],
    'Z': <String>['XXX', '..X', '.X.', 'X..', 'XXX'],
  };

  static const List<String> _tick6 = <String>[
    '......X',
    '.....XX',
    'X...XX.',
    'XX.XX..',
    '.XXX...',
    '..X....',
  ];

  static const List<String> _tick5 = <String>[
    '.....X',
    'X...XX',
    'XX.XX.',
    '.XXX..',
    '..X...',
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final double c = size.width / _cols; // cạnh một ô (pixel vuông)
    final Paint paint = Paint()..isAntiAlias = false;

    // Vẽ theo mép ô để hai khối cạnh nhau không hở đường chỉ.
    void cell(int x, int y, int w, int h, Color color) {
      paint.color = color;
      canvas.drawRect(
        Rect.fromLTRB(x * c, y * c, (x + w) * c, (y + h) * c),
        paint,
      );
    }

    final int totalRows = (size.height / c).ceil();

    // Nền + lưới mờ phủ kín, kể cả phần bị che (tránh hở nền trắng).
    for (int i = 0; i < _bands.length; i++) {
      final int y0 = (totalRows * i / _bands.length).floor();
      final int y1 = (totalRows * (i + 1) / _bands.length).ceil();
      cell(0, y0, _cols, y1 - y0, _bands[i]);
    }
    for (int gy = 0; gy < totalRows; gy += 8) {
      cell(0, gy, _cols, 1, _grid);
    }

    // Dải còn trống giữa thanh trạng thái và mép thẻ trắng.
    final int topRow = ((topInset + 6) / c).ceil();
    final int bottomRow = ((size.height - bottomCover) / c).floor();
    final int avail = bottomRow - topRow;
    if (avail < 12) return; // quá hẹp thì để nền trơn

    // Co dần cho vừa: hạ cỡ tiêu đề trước vì 4 ô đáp án mới là phần chính,
    // ô mỏng quá là chữ A B C D dính vào viền.
    int titleScale = 2;
    int rowH = 7;
    while (5 * titleScale + 2 + 4 * rowH + 3 > avail) {
      if (titleScale > 1) {
        titleScale--;
      } else if (rowH > 5) {
        rowH--;
      } else {
        break;
      }
    }

    final int titleH = 5 * titleScale;
    final int contentH = titleH + 2 + 4 * rowH + 3;
    final int top = topRow + math.max(0, (avail - contentH) ~/ 2);

    _drawText(cell, 'QUIZ TIME', 8, top, _accentDeep, titleScale);

    final int f = frame.value;
    final int cursor = math.min(2, f ~/ 3); // con trỏ dừng ở câu C
    final bool picked = f >= 9; // rồi chốt đáp án
    final int rowsTop = top + titleH + 2;
    final List<String> tick = rowH >= 7 ? _tick6 : _tick5;

    for (int i = 0; i < 4; i++) {
      final int y = rowsTop + i * (rowH + 1);
      final bool hovered = i == cursor;
      final bool correct = picked && i == 2;
      final int barH = rowH >= 7 ? 3 : 2;

      // viền: xanh lá khi đúng, xanh đậm khi con trỏ đang trỏ tới, còn lại nhạt
      cell(8, y, 96, rowH, correct ? _ok : (hovered ? _accent : _line));
      cell(9, y + 1, 94, rowH - 2, correct ? _okSoft : _white);
      _drawText(
        cell,
        'ABCD'[i],
        12,
        y + (rowH - 5) ~/ 2,
        correct ? _okInk : (hovered ? _accent : _ink),
        1,
      );
      cell(
        22,
        y + (rowH - barH) ~/ 2,
        30 + i * 10,
        barH,
        correct ? _okBar : (hovered ? _accentBorder : _lineBar),
      );

      if (correct) {
        _drawSprite(cell, tick, 88, y + (rowH - tick.length) ~/ 2, _ok, 1);
      }
    }

    // Tia sáng xoay quanh dấu tick của câu đúng.
    if (picked && f.isEven) {
      final int cy = rowsTop + 2 * (rowH + 1) + rowH ~/ 2;
      for (int k = 0; k < 6; k++) {
        final double a = (k * 60 + f * 15) * math.pi / 180;
        cell(
          (94 + 8 * math.cos(a)).round(),
          (cy + 6 * math.sin(a)).round(),
          1,
          1,
          _spark,
        );
      }
    }
  }

  void _drawSprite(
    _Cell cell,
    List<String> rows,
    int x,
    int y,
    Color color,
    int scale,
  ) {
    for (int j = 0; j < rows.length; j++) {
      final String row = rows[j];
      for (int i = 0; i < row.length; i++) {
        if (row[i] != '.') {
          cell(x + i * scale, y + j * scale, scale, scale, color);
        }
      }
    }
  }

  void _drawText(
    _Cell cell,
    String text,
    int x,
    int y,
    Color color,
    int scale,
  ) {
    int cx = x;
    for (final String ch in text.toUpperCase().split('')) {
      if (ch == ' ') {
        cx += 3 * scale;
        continue;
      }
      final List<String>? glyph = _font[ch];
      if (glyph != null) {
        _drawSprite(cell, glyph, cx, y, color, scale);
        cx += 4 * scale;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QuizAnswerPainter oldDelegate) =>
      oldDelegate.topInset != topInset ||
      oldDelegate.bottomCover != bottomCover;
}
