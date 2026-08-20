import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../common/app_colors.dart';

/// Bảng màu PHẲNG, lấy đúng theo web `frontend_manage/src/styles/quiz.css`
/// và `variables.css`.
///
/// KHÔNG CÓ GRADIENT trong cả file này lẫn các widget câu hỏi. Web không dùng
/// gradient ở bất kỳ đâu trong luồng làm bài; mobile trước đây tự bịa ra một
/// bảng tím-hồng riêng nên hai nền tảng nhìn như hai sản phẩm khác nhau. Trạng
/// thái ở đây chỉ nói bằng ba thứ: MÀU NỀN, MÀU VIỀN, ĐỘ DÀY VIỀN.
///
/// Hằng số `accentGradient` / `selectedGradient` đã bị XOÁ HẲN (không phải để
/// đó cho vui): còn chỗ nào import chúng thì `flutter analyze` báo lỗi ngay,
/// đó là cách rẻ nhất để gradient không lẻn về sau này.
///
/// Những màu dùng chung với phần còn lại của app (nhấn, chữ, viền, trạng thái
/// tắt) KHÔNG khai lại giá trị ở đây mà trỏ về [AppColors]. Khai hai lần cùng
/// một mã màu dưới hai cái tên là cách chắc chắn nhất để mai kia sửa một bên
/// và bỏ quên bên còn lại.
class QuizColors {
  QuizColors._();

  /// Chữ đề bài — web `.quiz-question-text { color: #1e293b }`.
  static const Color ink = AppColors.ink;

  /// Chữ trong hộp đáp án — web `.option-text { color: #374151 }`.
  static const Color inkBody = Color(0xFF374151);
  static const Color inkMuted = AppColors.inkMuted;

  static const Color surfaceRest = Color(0xFFF8FAFC);
  static const Color line = AppColors.line;
  static const Color lineStrong = Color(0xFFCBD5E1);

  /// Xanh chủ đạo của web (`--color-primary-dark`), thay cho tím `#6366F1` cũ.
  static const Color accent = AppColors.accent;
  static const Color accentDeep = AppColors.accentPressed;

  /// Nền hộp đáp án đang chọn — web `.answer-option.selected { background: #eff6ff }`.
  static const Color accentSoft = Color(0xFFEFF6FF);
  static const Color accentBorder = Color(0xFFBFDBFE);

  /// Tông phụ (xanh trời) dùng cho chip TRUE/FALSE/NOT GIVEN, lấy theo web
  /// `TFNGQuiz.tsx`: nền `#e0f2fe`, chữ `#075985`, viền `#0ea5e9`.
  static const Color info = Color(0xFF0EA5E9);
  static const Color infoSoft = Color(0xFFE0F2FE);
  static const Color infoDeep = Color(0xFF075985);

  /// Khối đoạn văn của câu cha — web `.parent-context`.
  static const Color passageSurface = Color(0xFFF0F9FF);
  static const Color passageBorder = Color(0xFFBAE6FD);
  static const Color passageLabel = Color(0xFF0369A1);
  static const Color passageInk = Color(0xFF0C4A6E);

  static const Color success = Color(0xFF10B981);
  static const Color successSoft = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningSoft = Color(0xFFFEF3C7);

  static const Color disabled = AppColors.disabledInk;
  static const Color disabledSurface = AppColors.surfaceMuted;
}

/// Thang khoảng cách đã siết lại một nấc so với bản cũ.
///
/// Màn 320-360dp phải cõng: lề thẻ câu hỏi + padding thẻ + padding hộp đáp án
/// + ô đánh dấu. Mỗi lớp rộng thêm 4px là bề ngang chữ mất 8px, câu dài vì thế
/// vỡ thêm một dòng. Con số dưới đây là mức đã cắt hết phần thừa mà vùng chạm
/// vẫn còn ≥40px.
/// THANG CỠ CHỮ dùng chung — mỗi vai trò đúng MỘT cỡ.
///
/// Đã hạ toàn bộ một nấc so với bản trước: màn thi phải cõng đề bài + đáp án +
/// (với câu Reading) cả đoạn văn cha trong một trang cuộn, chữ to một nấc là
/// mất thêm một màn cuộn cho mỗi câu. Mức thấp nhất ở đây là 11 (chú thích),
/// vẫn trên ngưỡng 11pt của hướng dẫn tiếp cận trên di động.
class QuizFont {
  QuizFont._();

  /// Đề bài của chính câu đang làm.
  static const double stem = 14;

  /// Đoạn văn của câu cha (Reading) và vế câu hỏi ở Cột A của câu nối.
  static const double passage = 13;

  /// Nội dung một đáp án.
  static const double option = 12.5;

  /// Chú thích, nhãn phụ.
  static const double caption = 11;
}

class QuizSpacing {
  QuizSpacing._();
  static const double xs = 4;
  static const double sm = 6;
  static const double md = 8;
  static const double lg = 10;
  static const double xl = 14;
  static const double betweenOptions = 6;
}

class QuizRadius {
  QuizRadius._();
  static const double option = 10;
  static const double marker = 6;
  static const double card = 10;
  static const double pill = 999;
}

/// Đổ bóng gần như không còn.
///
/// Web chỉ để `0 1px 4px rgba(0,0,0,0.02)` cho hộp đáp án và KHÔNG đổ bóng khi
/// chọn — ranh giới do viền đảm nhiệm. Bóng dày như bản cũ (blur 16-20, dịch
/// xuống 6-8px) ăn thêm khoảng trống dọc giữa hai hộp vì phải chừa chỗ cho vệt
/// bóng, đúng thứ đang làm trang thi dài ra.
class QuizShadow {
  QuizShadow._();

  static List<BoxShadow> get soft => [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.03),
      blurRadius: 3,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> get selected => const [];

  static List<BoxShadow> get marker => const [];
}

enum QuizMarkerShape { circle, square, ordinal }

/// Ô đánh dấu A/B/C hoặc số thứ tự.
///
/// HÌNH DẠNG mã hoá luật trả lời: tròn = chọn một, vuông = chọn nhiều,
/// [QuizMarkerShape.ordinal] = số thứ tự (nối / ô trống / sắp xếp).
///
/// Trạng thái bật: nền đặc [QuizColors.accent], chữ trắng, KHÔNG bóng —
/// giống `.ordering-index` và `.checkbox-indicator.checked` của web.
class QuizMarker extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isDisabled;
  final QuizMarkerShape shape;
  final double size;
  final IconData? icon;
  final bool isFilled;

  const QuizMarker({
    super.key,
    required this.label,
    required this.isSelected,
    this.isDisabled = false,
    this.shape = QuizMarkerShape.circle,
    this.size = 20,
    this.icon,
    this.isFilled = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool active = isSelected || isFilled;

    final Color background;
    final Color border;
    final Color foreground;

    if (isDisabled && active) {
      background = QuizColors.disabled;
      border = QuizColors.disabled;
      foreground = Colors.white;
    } else if (isDisabled) {
      background = QuizColors.disabledSurface;
      border = QuizColors.line;
      foreground = QuizColors.disabled;
    } else if (active) {
      background = QuizColors.accent;
      border = QuizColors.accent;
      foreground = Colors.white;
    } else {
      background = Colors.white;
      border = QuizColors.lineStrong;
      foreground = QuizColors.inkMuted;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: border, width: 1.5),
        shape: shape == QuizMarkerShape.circle
            ? BoxShape.circle
            : BoxShape.rectangle,
        borderRadius: shape == QuizMarkerShape.circle
            ? null
            : BorderRadius.circular(QuizRadius.marker),
      ),
      alignment: Alignment.center,
      child: icon != null
          ? Icon(icon, size: size * 0.56, color: foreground)
          : Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: foreground,
                height: 1,
              ),
            ),
    );
  }
}

/// Hộp đáp án dùng chung cho MỌI loại câu.
///
/// So với bản cũ đã bỏ hai thứ ăn bề ngang mà không nói thêm điều gì:
///   * Thanh nhấn dọc 5px ở mép trái — trạng thái chọn đã có nền + viền lo.
///     Bỏ nó cũng bỏ luôn [IntrinsicHeight] vốn phải đo lại cả hàng mỗi lần
///     dựng.
///   * Bóng đổ dày khi được chọn.
/// Padding còn `10 x 8` (cũ `10 x 6` + 5px thanh + 12px bóng), `minHeight` 40
/// vẫn trên ngưỡng chạm 40px.
class QuizOptionTile extends StatelessWidget {
  final Widget? leading;
  final Widget child;
  final Widget? trailing;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback? onTap;
  final bool isFocused;
  final double gap;
  final double minHeight;
  final CrossAxisAlignment crossAxisAlignment;

  const QuizOptionTile({
    super.key,
    required this.child,
    this.leading,
    this.trailing,
    this.isSelected = false,
    this.isDisabled = false,
    this.onTap,
    this.isFocused = false,
    this.gap = QuizSpacing.betweenOptions,
    this.minHeight = 40,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final bool highlighted = isSelected || isFocused;

    final Color background;
    final Color borderColor;
    final double borderWidth;

    if (isDisabled) {
      background = QuizColors.disabledSurface;
      borderColor = QuizColors.line;
      borderWidth = 1;
    } else if (highlighted) {
      background = QuizColors.accentSoft;
      borderColor = QuizColors.accent;
      borderWidth = 1.5;
    } else {
      background = Colors.white;
      borderColor = QuizColors.line;
      borderWidth = 1;
    }

    return Padding(
      padding: EdgeInsets.only(bottom: gap),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabled ? null : onTap,
          borderRadius: BorderRadius.circular(QuizRadius.option),
          splashColor: QuizColors.accent.withValues(alpha: 0.06),
          highlightColor: QuizColors.accent.withValues(alpha: 0.03),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            constraints: BoxConstraints(minHeight: minHeight),
            padding: const EdgeInsets.symmetric(
              horizontal: QuizSpacing.lg,
              vertical: QuizSpacing.md,
            ),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(QuizRadius.option),
              border: Border.all(color: borderColor, width: borderWidth),
              boxShadow: isDisabled ? const [] : QuizShadow.soft,
            ),
            child: Row(
              crossAxisAlignment: crossAxisAlignment,
              children: [
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: QuizSpacing.md),
                ],
                Expanded(child: child),
                if (trailing != null) ...[
                  const SizedBox(width: QuizSpacing.sm),
                  trailing!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Chip trả lời NGẮN, xếp ngang và tự xuống dòng.
///
/// Dành cho bộ đáp án chỉ vài từ (TRUE / FALSE / NOT GIVEN). Xếp dọc mỗi đáp
/// án một hộp full-width như trước tốn 3 dòng cho thứ vốn vừa gọn trong một
/// dòng — đó là nguồn chiều cao lớn nhất của trang TFNG. Kiểu dáng lấy theo
/// web `TFNGQuiz.tsx`.
///
/// `minHeight` 40 chứ không phải chiều cao tự nhiên của chữ (~28px như bản
/// web): web nhắm chuột, đây là ngón tay. Chip nằm sát nhau trong [Wrap] mà
/// mỗi chip là một ĐÁP ÁN — bấm nhầm sang chip cạnh bên là mất điểm, nên 40px
/// là sàn KHÔNG được hạ để lấy thêm chỗ. Vì chúng xếp ngang, chiều cao này
/// không nhân lên theo số đáp án.
class QuizChoiceChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback? onTap;

  const QuizChoiceChip({
    super.key,
    required this.label,
    required this.isSelected,
    this.isDisabled = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color background;
    final Color borderColor;
    final Color foreground;

    if (isDisabled && isSelected) {
      background = QuizColors.disabledSurface;
      borderColor = QuizColors.lineStrong;
      foreground = QuizColors.inkMuted;
    } else if (isDisabled) {
      background = QuizColors.disabledSurface;
      borderColor = QuizColors.line;
      foreground = QuizColors.disabled;
    } else if (isSelected) {
      background = QuizColors.infoSoft;
      borderColor = QuizColors.info;
      foreground = QuizColors.infoDeep;
    } else {
      background = Colors.white;
      borderColor = QuizColors.line;
      foreground = QuizColors.inkMuted;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        borderRadius: BorderRadius.circular(QuizRadius.marker),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          constraints: const BoxConstraints(minHeight: 40, minWidth: 64),
          padding: const EdgeInsets.symmetric(
            horizontal: QuizSpacing.lg,
            vertical: QuizSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(QuizRadius.marker),
            border: Border.all(color: borderColor),
          ),
          // [Align] có `widthFactor`/`heightFactor` chứ KHÔNG phải
          // `Container.alignment`.
          //
          // `Container.alignment` bọc con trong một [Align] KHÔNG có factor, mà
          // Align không factor thì NỞ HẾT ràng buộc lỏng nó nhận được. Trong
          // [Wrap], ràng buộc lỏng đó rộng bằng cả hàng — nên mọi chip phình ra
          // full bề ngang và [Wrap] chỉ nhét vừa MỘT chip mỗi dòng. Kết quả:
          // "Đúng"/"Sai" lại xếp dọc y như hộp đáp án full-width mà chip sinh ra
          // để thay thế, chỉ khác là mất luôn ô đánh dấu A/B.
          //
          // Đặt cả hai factor = 1 thì chip rộng đúng bằng chữ (vẫn tôn
          // `minWidth` 64 và `minHeight` 40 vì factor còn bị kẹp lại theo ràng
          // buộc), và chữ vẫn nằm giữa. ĐỪNG đổi về `Container.alignment`.
          child: Align(
            alignment: Alignment.center,
            widthFactor: 1,
            heightFactor: 1,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: foreground,
                height: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Dòng hướng dẫn luật trả lời.
///
/// Là MỘT DÒNG CHỮ, không còn là cái hộp có nền + viền + icon bọc trong ô
/// vuông màu. Hộp cũ chiếm ~44px chiều cao và thụt lề nội dung vào thêm 10px
/// mỗi bên chỉ để nói một câu mà sinh viên đọc đúng một lần. Web thậm chí ẩn
/// hẳn dòng này (`.ordering-instruction { display: none }`); giữ lại vì trên
/// mobile không có tiêu đề cột nào khác nói thay, nhưng để đúng trọng lượng
/// của một chú thích.
class QuizInstruction extends StatelessWidget {
  final String text;

  /// Icon HugeIcons (`HugeIcons.strokeRounded...`).
  ///
  /// Trước đây là [IconData] của Material — cả app xài HugeIcons, riêng mấy
  /// dòng hướng dẫn này lạc bộ, nét và độ dày khác hẳn phần còn lại.
  final List<List<dynamic>> icon;

  const QuizInstruction({super.key, required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: QuizSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HugeIcon(icon: icon, size: 12.0, color: QuizColors.inkMuted),
          const SizedBox(width: QuizSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 11,
                color: QuizColors.inkMuted,
                height: 1.3,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String quizOptionLabel(int order, int index) {
  final position = order > 0 ? order - 1 : index;
  return String.fromCharCode(65 + position.clamp(0, 25));
}

/// Dấu tích ở đuôi hộp đáp án — nền đặc, không bóng, không gradient.
class QuizSelectionMark extends StatelessWidget {
  final bool isSelected;
  final bool isDisabled;

  const QuizSelectionMark({
    super.key,
    required this.isSelected,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, anim) =>
            ScaleTransition(scale: anim, child: child),
        child: isDisabled && isSelected
            ? const HugeIcon(
                icon: HugeIcons.strokeRoundedSquareLock01,
                key: ValueKey('lock'),
                size: 18.0,
                color: QuizColors.disabled,
              )
            : (isSelected
                  ? Container(
                      key: const ValueKey('check'),
                      decoration: const BoxDecoration(
                        color: QuizColors.accent,
                        shape: BoxShape.circle,
                      ),
                      child: const HugeIcon(
                        icon: HugeIcons.strokeRoundedTick02,
                        size: 13.0,
                        color: Colors.white,
                      ),
                    )
                  : const SizedBox.shrink()),
      ),
    );
  }
}

/// Thẻ gom một cụm (một mệnh đề TFNG, một ô trống…).
///
/// Viền 1px, nền trắng, KHÔNG bóng. Trạng thái "đang cần làm" nói bằng màu
/// viền chứ không bằng nền pha màu — nền pha làm chữ trong thẻ giảm tương phản
/// mà không ai đọc ra đó là trạng thái gì.
class QuizGroupCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool isActive;

  const QuizGroupCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(QuizSpacing.lg),
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: QuizSpacing.md),
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(QuizRadius.card),
        border: Border.all(
          color: isActive ? QuizColors.accentBorder : QuizColors.line,
          width: 1,
        ),
      ),
      child: child,
    );
  }
}

/// Tiêu đề của một cụm — chữ IN HOA nhỏ, giống `.context-label` của web.
///
/// Vạch màu bên trái chỉ còn 2px và tô MỘT màu đặc.
class QuizSectionHeader extends StatelessWidget {
  final String label;
  final Widget? trailing;
  final bool isActive;

  const QuizSectionHeader({
    super.key,
    required this.label,
    this.trailing,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: QuizSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 2,
            height: 12,
            decoration: BoxDecoration(
              color: isActive ? QuizColors.accent : QuizColors.lineStrong,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(width: QuizSpacing.sm),
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: isActive ? QuizColors.accent : QuizColors.inkMuted,
              ),
            ),
          ),
          if (trailing != null)
            Flexible(
              child: Align(alignment: Alignment.centerRight, child: trailing!),
            ),
        ],
      ),
    );
  }
}

/// Chip đếm "Đã nối 2/5", "3/8 ô trống".
class QuizCountChip extends StatelessWidget {
  final String label;

  /// Icon HugeIcons, xem [QuizInstruction.icon].
  final List<List<dynamic>>? icon;
  final bool isComplete;

  const QuizCountChip({
    super.key,
    required this.label,
    this.icon,
    this.isComplete = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isComplete ? QuizColors.accent : QuizColors.inkMuted;
    final bgColor = isComplete ? QuizColors.accentSoft : QuizColors.surfaceRest;
    final borderColor = isComplete ? QuizColors.accentBorder : QuizColors.line;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: QuizSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(QuizRadius.pill),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            HugeIcon(icon: icon!, size: 11.0, color: color),
            const SizedBox(width: QuizSpacing.xs),
          ],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ô trống nhúng giữa câu (điền từ / trả lời ngắn / chọn từ danh sách).
class QuizBlankSlot extends StatelessWidget {
  final int number;
  final String? label;
  final Widget? trailing;
  final Widget? filled;
  final String emptyHint;
  final bool isFocused;
  final bool isDisabled;
  final VoidCallback? onTap;
  final double maxWidth;

  const QuizBlankSlot({
    super.key,
    required this.number,
    required this.emptyHint,
    this.filled,
    this.isFocused = false,
    this.isDisabled = false,
    this.onTap,
    this.maxWidth = 240,
    this.label,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasValue = filled != null;
    final bool highlighted = (hasValue || isFocused) && !isDisabled;

    final Color background = isDisabled
        ? QuizColors.disabledSurface
        : (highlighted ? QuizColors.accentSoft : Colors.white);
    final Color borderColor = isDisabled
        ? QuizColors.line
        : (highlighted ? QuizColors.accent : QuizColors.lineStrong);

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth, minHeight: 40),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabled ? null : onTap,
          borderRadius: BorderRadius.circular(QuizRadius.marker),
          splashColor: QuizColors.accent.withValues(alpha: 0.06),
          highlightColor: QuizColors.accent.withValues(alpha: 0.03),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(
              horizontal: QuizSpacing.sm,
              vertical: QuizSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(QuizRadius.marker),
              border: Border.all(
                color: borderColor,
                width: highlighted ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                QuizMarker(
                  label: label ?? '$number',
                  isSelected: false,
                  isFilled: hasValue,
                  isDisabled: isDisabled,
                  shape: QuizMarkerShape.ordinal,
                  size: 18,
                ),
                const SizedBox(width: QuizSpacing.sm),
                Flexible(
                  child: hasValue
                      ? filled!
                      : Text(
                          emptyHint,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: QuizColors.inkMuted,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: QuizSpacing.xs),
                  trailing!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
