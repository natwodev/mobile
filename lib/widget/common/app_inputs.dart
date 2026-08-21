import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'app_colors.dart';

/// Thông số hình học của ô nhập.
///
/// Tách riêng khỏi phần màu để chỗ nào cần dựng ô nhập ĐẶC BIỆT — ô mã đề thi,
/// ô trả lời ngắn trong bài làm — vẫn mượn được đúng bo góc và khoảng đệm, khỏi
/// đoán mò rồi lệch vài pixel so với phần còn lại.
class AppInputMetrics {
  AppInputMetrics._();

  /// Bo góc 8, bằng đúng bo góc của nút.
  ///
  /// Con số này đã ghi sẵn trong `AppButtonMetrics.radius` từ trước như một
  /// tiền đề ("nút bo 8 nằm cạnh ô nhập bo 8 và thẻ bo 12"), nhưng chưa ai thi
  /// hành: các ô nhập vẫn rơi về mặc định Material là bo 4. Đây là chỗ thi hành.
  static const double radius = 8;

  /// Bề dày viền lúc bình thường.
  static const double borderWidth = 1;

  /// Bề dày viền lúc đang gõ. Dày hơn chứ không đổi hẳn màu nền: người dùng cần
  /// biết con trỏ đang ở ô nào khi trên màn có bốn năm ô giống hệt nhau.
  static const double focusedBorderWidth = 1.6;

  /// Khoảng đệm trong ô.
  ///
  /// Dọc 16 để ô cao ngang nút (48) — ô nhập thấp hơn nút đứng ngay dưới nó thì
  /// biểu mẫu trông so le. Mặc định của Material là 12, hụt mất 8px.
  static const EdgeInsets contentPadding = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 16,
  );

  /// Cỡ icon đứng đầu ô. 20 chứ không phải 24: icon 24 trong ô cao 48 chiếm chỗ
  /// quá nhiều, đọc ra như một nút bấm nằm trong ô.
  static const double iconSize = 20;
}

/// Bộ ô nhập dùng chung.
///
/// Trước đây app có bốn kiểu ô nhập khác nhau cho cùng một vai trò "ô nhập biểu
/// mẫu": Đăng nhập, Đổi mật khẩu và Sửa hồ sơ dùng `OutlineInputBorder()` trần
/// nên rơi về bo 4 của Material, còn Góp ý tự bo 8. Cùng một app mà góc ô khác
/// nhau tuỳ màn.
class AppInputs {
  AppInputs._();

  static OutlineInputBorder _border(Color color, double width) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppInputMetrics.radius),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  /// Icon đứng đầu/cuối ô, đúng cỡ và tự đổi màu theo trạng thái của ô.
  ///
  /// PHẢI đi qua hàm này chứ không đặt thẳng `HugeIcon`, vì hai lý do:
  ///
  /// 1. MÀU. HugeIcon vẽ bằng SVG nên KHÔNG ăn màu của [IconTheme] như [Icon]
  ///    của Material. Đặt thẳng thì icon giữ nguyên một màu, ô đang gõ hay đang
  ///    báo lỗi cũng thế — mất hẳn tín hiệu mà Material vốn cho không. Cách chữa
  ///    giống hệt chỗ nút quay lại trên AppBar trong `main.dart`: đọc màu đang
  ///    hiệu lực ra rồi truyền thẳng vào `color`.
  ///
  /// 2. CỠ. Đây mới là chỗ khó thấy. HugeIcon dựng bằng `SizedBox.square`, mà
  ///    `SizedBox` TUÂN THEO ràng buộc tối thiểu của cha. Material đặt
  ///    `prefixIconConstraints` có bề tối thiểu, nên hộp 20px bị ép giãn lên
  ///    đúng bằng mức tối thiểu đó và SVG co giãn lấp đầy — cỡ truyền vào bị bỏ
  ///    qua sạch.
  ///
  /// Cách chữa là [Align] KÈM `widthFactor`/`heightFactor`, và phải đủ cả hai
  /// thứ nó làm: cấp ràng buộc LỎNG cho con nên icon giữ đúng cỡ, đồng thời co
  /// về cỡ con nên không chiếm chỗ thừa.
  ///
  /// KHÔNG dùng [Center] (hay `Align` trần): thiếu hai hệ số đó thì nó nở ra
  /// bằng `constraints.biggest`, tức chiếm TRỌN bề ngang ô — icon nằm chình
  /// ình giữa ô còn chữ bị đẩy ra ngoài, và ô ngày sinh phình cao cả màn hình.
  ///
  /// Lỗi cỡ này có từ trước: các `prefixIcon` cũ để HugeIcon mặc định 24 cũng bị
  /// thổi lên y hệt, chỉ là không ai đối chiếu nên không nhận ra.
  static Widget icon(List<List<dynamic>> data) {
    return Builder(
      builder: (context) {
        final IconThemeData theme = IconTheme.of(context);
        return Align(
          widthFactor: 1,
          heightFactor: 1,
          child: HugeIcon(
            icon: data,
            color: theme.color ?? AppColors.inkMuted,
            size: AppInputMetrics.iconSize,
          ),
        );
      },
    );
  }

  /// Tấm danh sách xổ ra của một `DropdownButtonFormField`.
  ///
  /// PHẢI tô tại chỗ gọi chứ không cắm được vào theme: `DropdownButtonFormField`
  /// dựng danh sách bằng route riêng của nó, không đọc `dropdownMenuTheme`
  /// (theme đó dành cho widget `DropdownMenu` mới). Gom mấy tham số vào đây để
  /// chỗ gọi khỏi nhớ, và để lần sau thêm ô chọn thứ hai thì không lệch.
  static const Color dropdownColor = Colors.white;
  static const double dropdownRadius = AppInputMetrics.radius;

  /// Mũi tên xổ xuống, cùng cỡ và cùng màu với icon đầu ô.
  ///
  /// Mặc định của Material là tam giác đặc màu xám đậm — nặng hơn hẳn nét mảnh
  /// của HugeIcons dùng khắp app, đứng cạnh icon đầu ô là lộ ra hai bộ icon.
  static Widget get dropdownIcon => const HugeIcon(
    icon: HugeIcons.strokeRoundedArrowDown01,
    color: AppColors.inkMuted,
    size: AppInputMetrics.iconSize,
  );

  /// Ô CHỈ ĐỌC: nền xám, không cho gõ.
  ///
  /// Dùng cho mã số sinh viên — thứ hiện ra để đối chiếu chứ không phải để sửa.
  /// Nền xám nói điều đó ngay từ cái nhìn đầu, khỏi phải bấm vào mới biết.
  static InputDecoration readOnly({
    required String label,
    List<List<dynamic>>? prefixIcon,
    String? helperText,
  }) {
    return InputDecoration(
      labelText: label,
      helperText: helperText,
      prefixIcon: prefixIcon == null ? null : icon(prefixIcon),
      filled: true,
      fillColor: AppColors.surfaceMuted,
    );
  }
}

/// Cắm bộ ô nhập trên vào `ThemeData`.
///
/// Đây mới là phần quan trọng, y như `appButtonThemes`: nhờ nó một
/// [TextFormField] KHÔNG khai `border` nào cũng đã đúng chuẩn. Nhờ vậy các màn
/// bỏ được hẳn dòng `border: OutlineInputBorder()` lặp ở mọi ô — mà chính dòng
/// lặp đó là nguồn gốc của việc mỗi màn một kiểu.
ThemeData appInputThemes(ThemeData base) {
  return base.copyWith(
    inputDecorationTheme: InputDecorationThemeData(
      // Nền trắng chứ không để trong suốt: các màn biểu mẫu đều nền trắng nên
      // nhìn không khác gì, nhưng ô nhập đặt trong thẻ xám hay hộp thoại vẫn
      // nổi lên đúng như một ô nhập.
      filled: true,
      fillColor: Colors.white,
      contentPadding: AppInputMetrics.contentPadding,

      // Thu hộp icon lại từ 48x48 mặc định. Vẫn đủ rộng cho vùng chạm, nhưng
      // icon không còn ngồi giữa một khoảng trống thừa cách xa chữ.
      prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      suffixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),

      border: AppInputs._border(AppColors.line, AppInputMetrics.borderWidth),
      enabledBorder: AppInputs._border(
        AppColors.line,
        AppInputMetrics.borderWidth,
      ),
      focusedBorder: AppInputs._border(
        AppColors.accent,
        AppInputMetrics.focusedBorderWidth,
      ),
      errorBorder: AppInputs._border(
        AppColors.danger,
        AppInputMetrics.borderWidth,
      ),
      focusedErrorBorder: AppInputs._border(
        AppColors.danger,
        AppInputMetrics.focusedBorderWidth,
      ),
      // Ô khoá vẫn có viền, chỉ nhạt đi. Bỏ viền hẳn thì ô chỉ đọc trông như
      // một dòng chữ trôi nổi, không ai biết đó vốn là một ô.
      disabledBorder: AppInputs._border(
        AppColors.line,
        AppInputMetrics.borderWidth,
      ),

      labelStyle: const TextStyle(fontSize: 14, color: AppColors.inkMuted),
      // Nhãn nổi lên CHỈ xanh khi đang gõ, cùng lúc với viền đậm lên — hai tín
      // hiệu cho một trạng thái, nhìn hướng nào cũng thấy.
      //
      // Tô xanh mọi nhãn nổi thì hỏng: ô đã có sẵn dữ liệu là nhãn nổi luôn từ
      // đầu, nên cả biểu mẫu xanh lè và cái ô đang thật sự gõ chẳng còn gì phân
      // biệt.
      floatingLabelStyle: WidgetStateTextStyle.resolveWith((states) {
        if (states.contains(WidgetState.error)) {
          return const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.danger,
          );
        }
        if (states.contains(WidgetState.focused)) {
          return const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.accent,
          );
        }
        return const TextStyle(fontSize: 14, color: AppColors.inkMuted);
      }),
      hintStyle: const TextStyle(fontSize: 14, color: AppColors.disabledInk),
      helperStyle: const TextStyle(fontSize: 12, color: AppColors.inkMuted),
      errorStyle: const TextStyle(fontSize: 12, color: AppColors.danger),
      counterStyle: const TextStyle(fontSize: 11, color: AppColors.disabledInk),

      // Màu icon đầu/cuối ô theo trạng thái. Chỉ có tác dụng khi icon đi qua
      // `AppInputs.icon` — xem ghi chú ở đó.
      prefixIconColor: WidgetStateColor.resolveWith((states) {
        if (states.contains(WidgetState.error)) return AppColors.danger;
        if (states.contains(WidgetState.focused)) return AppColors.accent;
        if (states.contains(WidgetState.disabled)) return AppColors.disabledInk;
        return AppColors.inkMuted;
      }),
      suffixIconColor: WidgetStateColor.resolveWith((states) {
        if (states.contains(WidgetState.error)) return AppColors.danger;
        if (states.contains(WidgetState.focused)) return AppColors.accent;
        if (states.contains(WidgetState.disabled)) return AppColors.disabledInk;
        return AppColors.inkMuted;
      }),
    ),

    // Hộp thoại chọn NGÀY. Mặc định Material 3 lạc hẳn khỏi app: nó pha màu
    // chủ đạo lên nền theo `surfaceTint` nên tấm lịch trắng ngả tím, bo góc
    // theo hệ riêng, và ngày đang chọn tô bằng sắc độ mà `fromSeed` tự sinh ra
    // chứ không phải màu nhấn của app.
    datePickerTheme: DatePickerThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      headerBackgroundColor: AppColors.accent,
      headerForegroundColor: Colors.white,
      dayForegroundColor: WidgetStateColor.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? Colors.white
            : AppColors.ink,
      ),
      dayBackgroundColor: WidgetStateColor.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.accent
            : Colors.transparent,
      ),
      // Vòng tròn quanh NGÀY HÔM NAY: chỉ là đường viền, không tô đặc — tô đặc
      // thì nó tranh chấp với ngày đang chọn, nhìn ra hai ngày cùng được chọn.
      todayForegroundColor: WidgetStateColor.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? Colors.white
            : AppColors.accent,
      ),
      todayBorder: const BorderSide(color: AppColors.accent, width: 1),
      yearForegroundColor: WidgetStateColor.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? Colors.white
            : AppColors.ink,
      ),
      yearBackgroundColor: WidgetStateColor.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.accent
            : Colors.transparent,
      ),
    ),
  );
}
