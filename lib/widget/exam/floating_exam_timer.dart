import 'package:flutter/material.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

import 'quiz_theme.dart';

/// Đồng hồ đếm ngược NỔI trên nội dung bài thi, kéo đặt được ở bất cứ đâu.
///
/// Trước đây nó nằm cố định trong thanh tiêu đề. Vấn đề là đề thi có đủ kiểu bố
/// cục: đoạn văn dài, bảng ghép cặp, ô trống nằm giữa dòng — và ở một số câu,
/// góc trên bên phải lại đúng chỗ có nội dung cần đọc. Cho kéo thì sinh viên tự
/// đẩy nó ra chỗ trống, khỏi phải chọn giữa "thấy giờ" và "thấy đề".
///
/// Vị trí do widget này tự giữ, nên nó sống qua việc lật câu và đổi loại câu.
class FloatingExamTimer extends StatefulWidget {
  const FloatingExamTimer({
    super.key,
    required this.label,
    required this.color,
  });

  /// Chuỗi giờ đã định dạng sẵn, ví dụ `12:34`.
  final String label;

  /// Màu chữ, đổi theo mức thời gian còn lại — do màn thi quyết định.
  ///
  /// Sau khi bỏ nền và icon thì đây là TÍN HIỆU DUY NHẤT còn lại, nên nó gánh
  /// trọn việc cảnh báo mà viền với quầng sáng từng làm.
  final Color color;

  @override
  State<FloatingExamTimer> createState() => _FloatingExamTimerState();
}

class _FloatingExamTimerState extends State<FloatingExamTimer> {
  /// Lề tối thiểu giữa thẻ và mép vùng chứa.
  static const double _margin = 8;

  /// Mép trên của dải tiến độ, tính từ đỉnh vùng an toàn.
  ///
  /// Bằng đúng đệm dọc mà thân màn thi đặt cho nội dung (`vertical: 6` trong
  /// `exam_screen.dart`). Dải tiến độ là thứ đầu tiên trong thân đó, nên đây
  /// cũng là mép trên của nó — và vì dải cao đúng bằng viên nhộng, đặt y ở đây
  /// là hai thứ trùng khít hàng với nhau.
  ///
  /// Đổi đệm dọc bên màn thi mà quên con số này thì đồng hồ lệch khỏi dải một
  /// chút — không hỏng gì, chỉ là mất cái vẻ "nằm trong hàng".
  static const double _stripTop = 6;

  /// Vị trí góc trên-trái của thẻ, tính trong hệ toạ độ của vùng chứa.
  ///
  /// `null` = chưa đặt lần nào, sẽ tự nằm ở góc trên bên phải — đúng chỗ nó vốn
  /// ở khi còn nằm trong thanh tiêu đề, để người quen chỗ cũ không phải đi tìm.
  ///
  /// Là `ValueNotifier` chứ KHÔNG phải trường thường kèm `setState`. Đây chính
  /// là chỗ làm cú kéo bị khựng: `setState` dựng lại cả cây con mỗi lần ngón
  /// tay nhích, tức `LiquidGlassLens` bị tạo lại và shader phải dựng lại từ đầu
  /// sáu chục lần một giây. Với notifier thì chỉ mỗi `Positioned` đổi, còn
  /// widget kính được truyền xuống nguyên vẹn qua tham số `child` nên Flutter
  /// giữ lại đúng element cũ.
  final ValueNotifier<Offset?> _position = ValueNotifier<Offset?>(null);

  /// Kích thước thật của thẻ, đo được sau khung hình đầu.
  ///
  /// Cần để ghim thẻ trong lòng vùng chứa: không biết thẻ rộng bao nhiêu thì
  /// kéo ra mép phải là nửa thẻ lọt ra ngoài màn.
  Size _cardSize = const Size(120, 40);

  final GlobalKey _cardKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Đo sau khi vẽ xong khung hình đầu: trước đó widget chưa có kích thước.
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  @override
  void didUpdateWidget(covariant FloatingExamTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Chữ đổi từ "9:59" sang "10:00" là thẻ rộng thêm một chữ số — đo lại,
    // không thì phép ghim mép dùng số cũ và thẻ thò ra ngoài một chút.
    if (widget.label.length != oldWidget.label.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    }
  }

  void _measure() {
    final RenderBox? box =
        _cardKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !mounted) return;
    if (box.size == _cardSize) return;
    setState(() => _cardSize = box.size);
  }

  /// Ghim vị trí vào trong lòng vùng chứa.
  Offset _clamp(Offset raw, Size bounds) {
    final double maxX = (bounds.width - _cardSize.width - _margin).clamp(
      _margin,
      double.infinity,
    );
    final double maxY = (bounds.height - _cardSize.height - _margin).clamp(
      _margin,
      double.infinity,
    );

    return Offset(raw.dx.clamp(_margin, maxX), raw.dy.clamp(_margin, maxY));
  }

  @override
  void dispose() {
    _position.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final Size bounds = Size(constraints.maxWidth, constraints.maxHeight);

        // Chỗ đứng mặc định: GIỮA dải tiến độ, ngay khoảng trống nằm giữa
        // "Câu 1/56" bên trái và "Đã trả lời: 2/44" bên phải.
        //
        // Chọn chỗ này chứ không phải góc trên phải vì đó là khoảng trống có
        // sẵn — đặt vào đấy thì đồng hồ không che chữ nào cả, mà vẫn nằm ngay
        // hàng thông tin người ta liếc nhìn nhiều nhất.
        final Offset home = Offset(
          (bounds.width - _cardSize.width) / 2,
          _stripTop,
        );

        // Dựng MỘT LẦN ở đây, ngoài `builder` bên dưới. Đưa vào trong thì mỗi
        // khung hình của cú kéo lại dựng một `LiquidGlassLens` mới.
        final Widget card = GestureDetector(
          // Kéo NGAY, không cần nhấn giữ: thẻ này nổi hẳn trên nội dung và
          // không nằm trong vùng cuộn nào, nên không có cử chỉ nào để tranh
          // chấp. Khác hẳn thẻ từ ở câu điền chỗ trống.
          onPanUpdate: (details) {
            final Offset from = _position.value ?? home;
            _position.value = _clamp(from + details.delta, bounds);
          },
          child: _buildCard(),
        );

        return ValueListenableBuilder<Offset?>(
          valueListenable: _position,
          child: card,
          builder: (context, value, child) {
            final Offset safe = _clamp(value ?? home, bounds);
            return Stack(
              children: [
                Positioned(left: safe.dx, top: safe.dy, child: child!),
              ],
            );
          },
        );
      },
    );
  }

  /// Chiều cao viên nhộng. Ghim cứng vì bán kính bo phải bằng đúng NỬA con số
  /// này mới ra hai đầu tròn hẳn; để chiều cao tự co theo chữ thì bán kính
  /// không bám kịp và hai đầu thành bo góc chứ không thành viên nhộng.
  static const double _pillHeight = 36;

  /// Chỉ còn CON SỐ trên một viên nhộng kính lỏng — không icon.
  ///
  /// Bỏ icon đồng hồ vì chuỗi dạng `119:49` tự nó đã nói đó là thời gian.
  ///
  /// Dùng `LiquidGlassLens` thay cho `BackdropFilter` tự dựng: ngoài làm nhoè,
  /// nó còn KHÚC XẠ nội dung phía sau ở mép viên nhộng, nên thẻ đọc ra như một
  /// miếng kính thật đặt lên trang giấy chứ không phải một lớp mờ dán đè.
  ///
  /// Chạy ĐỘC LẬP, không cần bọc `LiquidGlassView`: trên Impeller — mặc định
  /// của Flutter trên Android — nó lấy thẳng nền sống phía sau. Rơi vào Skia
  /// thì thư viện tự hạ xuống kiểu kính mờ thường, tức đúng bằng thứ đang có
  /// trước khi đổi, nên không có máy nào mất nền cả.
  Widget _buildCard() {
    return SizedBox(
      key: _cardKey,
      height: _pillHeight,
      child: LiquidGlassLens(
        style: LiquidGlassStyle(
          // Bán kính = nửa chiều cao: đó là định nghĩa của hình viên nhộng.
          shape: LiquidGlassShape.continuousRoundedRectangle(
            cornerRadius: _pillHeight / 2,
            // Viền CỰC MỎNG và XÁM TRUNG TÍNH. Không có viền thì viên nhộng
            // chỉ là một vùng nhoè, mà nhoè trên nền trắng của đề bài thì gần
            // như không thấy mép ở đâu — không biết chạm chỗ nào để kéo.
            //
            // Xám chứ không theo màu đồng hồ: để màu thì viền và con số cùng
            // đổi một lúc, thành hai thứ cùng hét lên một điều. Con số đã gánh
            // việc cảnh báo rồi; viền chỉ cần nói "thẻ này kết thúc ở đây".
            borderWidth: 0.5,
            borderColor: QuizColors.lineStrong,
          ),
          refraction: const LiquidGlassRefraction(
            // Mặc định 0.1 loang quá mạnh: chữ sau viên nhộng bị kéo cong thấy
            // rõ, đọc ra như lỗi hiển thị chứ không phải hiệu ứng. Hạ xuống một
            // phần tư — vẫn còn cảm giác kính ở mép mà không méo nội dung.
            distortion: 0.025,
            // Dải khúc xạ hẹp lại theo, để phần cong dồn sát mép chứ không ăn
            // vào giữa viên nhộng nơi con số nằm.
            distortionWidth: 12,
            // Tắt tán sắc: viền cầu vồng quanh chữ làm con số khó đọc, mà đây
            // là thứ sinh viên phải liếc nhìn liên tục trong lúc làm bài.
            chromaticAberration: 0,
          ),
        ),
        child: Padding(
          // Vẫn giữ đệm ngang rộng: đây là vùng chạm để kéo. Bỏ đệm thì chỉ
          // đúng mấy nét chữ bắt được ngón tay, kéo trượt hoài không dính.
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Center(
            widthFactor: 1,
            child: Text(
              widget.label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: widget.color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
