import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:toastification/toastification.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/notification_sound_service.dart';

/// Kiểu toast — trùng ĐÚNG 8 giá trị `toastStyle` mà giám thị chọn được trong
/// bảng cấu hình thông báo bên web
/// (`frontend_manage/src/components/monitor/ToastOptionsConfig.tsx:38-45`).
enum AppToastKind { success, error, warning, info, multiline, dark, themed, promise }

/// Toast dùng chung, dựng lại đúng bộ toast của quiz web.
///
/// **Icon lấy theo bảng giám thị NHÌN THẤY lúc cấu hình** (ToastOptionsConfig),
/// không phải bộ icon mặc định của react-hot-toast. Lý do: giám thị chọn kiểu
/// "multiline" thì trong form hiện icon căn dòng, gửi xuống máy sinh viên cũng
/// phải là icon đó — có vậy hai bên mới nói cùng một ngôn ngữ khi đối chiếu.
///
/// Phần còn lại bám react-hot-toast của web: nền trắng chữ `#363636` cho
/// success/error/multiline/promise, nền màu cho warning/info/dark/themed;
/// góc trên phải; 3 giây; không có thanh tiến trình.
///
/// Âm báo gọi ngay trong này, đúng như web gói `playNotificationSound` vào
/// `toastUtils` — tách ra là sớm muộn có chỗ hiện toast mà quên kêu.
class AppToast {
  const AppToast._();

  /// Nền thẻ trắng và màu chữ mặc định của react-hot-toast.
  static const Color _surface = Color(0xFFFFFFFF);
  static const Color _ink = Color(0xFF363636);

  /// Web: `defaultOptions = { position: 'top-right', duration: 3000 }`.
  static const Duration _defaultDuration = Duration(milliseconds: 3000);

  /// Bóng của react-hot-toast.
  static const List<BoxShadow> _shadow = <BoxShadow>[
    BoxShadow(color: Color(0x1A000000), blurRadius: 10, offset: Offset(0, 3)),
    BoxShadow(color: Color(0x0D000000), blurRadius: 3, offset: Offset(0, 3)),
  ];

  static void show(
    BuildContext context, {
    required AppToastKind kind,
    required String title,
    String? description,
    Duration? duration,
    bool playSound = true,
    /// Vị trí do máy chủ chỉ định (`toastPosition`), mặc định góc trên phải.
    AlignmentGeometry? alignment,
    /// Nền/chữ tự đặt, dùng cho thông báo có kiểu riêng (ví dụ "bị chặn").
    Color? backgroundColor,
    Color? foregroundColor,
    /// Âm báo khác mặc định của [kind].
    NotificationSound? sound,
    /// Icon tự đặt (vòng xoay của [showPromise]).
    Widget? icon,
    /// Ghi đè kiểu chữ tiêu đề — web có chỗ phóng to chữ cho thông báo nặng
    /// (bị chặn khỏi ca thi: 18px in đậm, `useQuiz.ts:787-797`).
    TextStyle? titleTextStyle,
  }) {
    if (playSound) {
      NotificationSoundService.play(sound ?? _soundOf(kind)).ignore();
    }

    final Color background = backgroundColor ?? _backgroundOf(kind);
    final bool filled = background != _surface;

    // Nền do NGƯỜI GỌI truyền vào (màu giám thị chọn) thì không đoán được nó
    // sáng hay tối, phải tính chữ theo độ sáng thật của nền: bảng mặc định chỉ
    // toàn nền tối nên luật cũ "khác trắng ⇒ chữ trắng" đúng với nó, nhưng gặp
    // vàng nhạt hay hồng nhạt là chữ trắng mất hút.
    final bool custom = backgroundColor != null;
    final Color foreground = foregroundColor ??
        (custom
            ? contrastForegroundOn(background)
            : (filled ? Colors.white : _ink));

    // Icon vẫn giữ nguyên hình theo [kind]; chỉ MÀU chạy theo tương phản của
    // nền mới, nếu không icon accent (vàng, xanh nhạt...) chìm y như chữ.
    final Color iconTint =
        custom ? foreground : (filled ? Colors.white : iconColorOf(kind));

    toastification.show(
      context: context,
      type: _typeOf(kind),
      // flat: toastification chỉ vẽ nền + chữ theo màu mình đưa, không tự tô
      // màu theo `type` như fillColored.
      style: ToastificationStyle.flat,
      alignment: alignment ?? Alignment.topRight,
      backgroundColor: background,
      foregroundColor: foreground,
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
      boxShadow: _shadow,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      icon: icon ??
          HugeIcon(
            icon: iconOf(kind),
            color: iconTint,
            size: 22.0,
          ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: foreground,
        ).merge(titleTextStyle),
      ),
      description: (description == null || description.isEmpty)
          ? null
          : Text(
              description,
              // Web đặt `whiteSpace: pre-line, textAlign: left` cho multiline.
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: foreground.withValues(alpha: filled ? 0.95 : 0.75),
              ),
            ),
      autoCloseDuration: duration ?? _defaultDuration,
      // react-hot-toast không có thanh tiến trình.
      showProgressBar: false,
      dragToClose: true,
    );
  }

  /// Kiểu `promise`: vòng xoay "Đang xử lý..." trước, sau [pending] mới đổi
  /// thành toast success mang nội dung thật (`toast.tsx:317-331`).
  ///
  /// Icon là `Loading03` xoay — đúng icon giám thị thấy ở ô chọn kiểu
  /// (`ToastOptionsConfig.tsx:42`).
  static Future<void> showPromise(
    BuildContext context, {
    required String title,
    String? description,
    Duration pending = const Duration(seconds: 2),
    AlignmentGeometry? alignment,
    Duration? duration,
    /// Nền do giám thị chọn, CHỈ áp cho toast kết quả (pha thứ hai).
    ///
    /// Pha vòng xoay giữ nền trắng như web: nó là trạng thái "đang xử lý" chung
    /// của react-hot-toast, chưa phải nội dung giám thị gửi.
    Color? backgroundColor,
  }) async {
    final String processing = AppLocalizations.of(context).toastProcessing;

    NotificationSoundService.play(NotificationSound.promise).ignore();

    final ToastificationItem loading = toastification.show(
      context: context,
      type: ToastificationType.info,
      style: ToastificationStyle.flat,
      alignment: alignment ?? Alignment.topRight,
      backgroundColor: _surface,
      foregroundColor: _ink,
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
      boxShadow: _shadow,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      icon: const _SpinningIcon(
        icon: HugeIcons.strokeRoundedLoading03,
        color: Color(0xFF6366F1),
      ),
      title: Text(
        processing,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: _ink,
        ),
      ),
      // Giữ nguyên cho tới khi đổi sang toast kết quả.
      autoCloseDuration: null,
      showProgressBar: false,
      dragToClose: false,
    );

    await Future<void>.delayed(pending);
    toastification.dismiss(loading);

    if (!context.mounted) return;
    show(
      context,
      kind: AppToastKind.success,
      title: title,
      description: description,
      duration: duration,
      alignment: alignment,
      backgroundColor: backgroundColor,
    );
  }

  /// Đổi chuỗi hex `toastColor` của máy chủ thành [Color].
  ///
  /// Nhận cả `#0EA5E9` lẫn `0ea5e9`, không phân biệt hoa thường. Mọi thứ khác
  /// (null, rỗng, thiếu/thừa ký tự, có ký tự lạ) trả null để chỗ gọi rơi về màu
  /// mặc định của kiểu toast — đây là điều kiện bắt buộc: giám thị chưa chọn
  /// màu thì toast phải y hệt như trước khi có tính năng này.
  ///
  /// Chỉ chấp nhận 6 ký tự (RRGGBB); độ trong suốt luôn là đục hoàn toàn.
  static Color? parseHexColor(String? hex) {
    if (hex == null) return null;

    final String value = hex.trim().replaceFirst('#', '');
    if (value.length != 6) return null;
    // `int.tryParse` nuốt cả dấu `+`/`-` và khoảng trắng nên phải tự soi ký tự.
    if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(value)) return null;

    final int? rgb = int.tryParse(value, radix: 16);
    if (rgb == null) return null;
    return Color(0xFF000000 | rgb);
  }

  /// Màu chữ/icon đọc được trên [background].
  ///
  /// Máy chủ không gửi màu chữ, app tự chọn: nền tối thì chữ trắng, nền sáng
  /// thì chữ `#363636` — đúng màu chữ mặc định của toast react-hot-toast, để
  /// toast nền sáng do giám thị chọn nhìn vẫn cùng một nhà với toast nền trắng.
  ///
  /// Ngưỡng 0.5 trên [Color.computeLuminance] (đã tính sẵn hiệu chỉnh gamma).
  static Color contrastForegroundOn(Color background) =>
      background.computeLuminance() > 0.5 ? _ink : Colors.white;

  /// Đổi chuỗi `toastStyle` của máy chủ thành [AppToastKind].
  ///
  /// Web: mọi giá trị lạ đều rơi về `success` (`useQuiz.ts:636-640`).
  static AppToastKind kindFromStyle(String? style) => switch (style) {
        'error' => AppToastKind.error,
        'warning' => AppToastKind.warning,
        'info' => AppToastKind.info,
        'multiline' => AppToastKind.multiline,
        'dark' => AppToastKind.dark,
        'themed' => AppToastKind.themed,
        'promise' => AppToastKind.promise,
        _ => AppToastKind.success,
      };

  /// Icon của từng kiểu — chép nguyên bảng `styleConfig` của monitor
  /// (`ToastOptionsConfig.tsx:38-45`).
  static List<List<dynamic>> iconOf(AppToastKind kind) => switch (kind) {
        AppToastKind.success => HugeIcons.strokeRoundedCheckmarkCircle02,
        AppToastKind.error => HugeIcons.strokeRoundedCancel01,
        AppToastKind.warning => HugeIcons.strokeRoundedAlert01,
        AppToastKind.info => HugeIcons.strokeRoundedNotification01,
        AppToastKind.promise => HugeIcons.strokeRoundedLoading03,
        AppToastKind.multiline => HugeIcons.strokeRoundedTextAlignJustifyLeft,
        AppToastKind.dark => HugeIcons.strokeRoundedViewOffSlash,
        AppToastKind.themed => HugeIcons.strokeRoundedSettings02,
      };

  /// Màu icon, cũng từ bảng `styleConfig` của monitor.
  static Color iconColorOf(AppToastKind kind) => switch (kind) {
        AppToastKind.success => const Color(0xFF16A34A),
        AppToastKind.error => const Color(0xFFDC2626),
        AppToastKind.warning => const Color(0xFFF59E0B),
        AppToastKind.info => const Color(0xFF0EA5E9),
        AppToastKind.promise => const Color(0xFF6366F1),
        AppToastKind.multiline => const Color(0xFF64748B),
        AppToastKind.dark => const Color(0xFF111827),
        AppToastKind.themed => const Color(0xFF8B5CF6),
      };

  /// Nền, theo đúng cách web dựng từng loại toast (`toast.tsx:271-315`).
  static Color _backgroundOf(AppToastKind kind) => switch (kind) {
        AppToastKind.warning => const Color(0xFFF59E0B),
        AppToastKind.info => const Color(0xFFFFAE44),
        AppToastKind.dark => const Color(0xFF1A1A1A),
        // Web dùng gradient tím #667eea → #764ba2; toast mobile chỉ nhận một
        // màu nền nên lấy màu giữa.
        AppToastKind.themed => const Color(0xFF6D5BB8),
        _ => _surface,
      };

  static ToastificationType _typeOf(AppToastKind kind) => switch (kind) {
        AppToastKind.success || AppToastKind.promise =>
          ToastificationType.success,
        AppToastKind.error => ToastificationType.error,
        AppToastKind.warning => ToastificationType.warning,
        _ => ToastificationType.info,
      };

  /// Âm báo theo đúng bảng của web.
  static NotificationSound _soundOf(AppToastKind kind) => switch (kind) {
        AppToastKind.success => NotificationSound.success,
        AppToastKind.error => NotificationSound.error,
        AppToastKind.warning => NotificationSound.warning,
        AppToastKind.promise => NotificationSound.promise,
        // `dark` và `themed` từng rơi vào nhánh bao quát bên dưới và kêu tiếng
        // của `multiline`. Web có âm riêng cho hai kiểu này, mà đây lại đúng
        // hai kiểu giám thị chọn được khi gửi thông báo giữa phiên thi — kêu
        // sai tiếng là sinh viên nghe một đằng, giám thị tưởng một nẻo.
        AppToastKind.dark => NotificationSound.dark,
        AppToastKind.themed => NotificationSound.themed,
        _ => NotificationSound.multiline,
      };
}

/// Icon xoay tròn, dùng cho trạng thái "đang xử lý".
class _SpinningIcon extends StatefulWidget {
  const _SpinningIcon({required this.icon, required this.color});

  final List<List<dynamic>> icon;
  final Color color;

  @override
  State<_SpinningIcon> createState() => _SpinningIconState();
}

class _SpinningIconState extends State<_SpinningIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: HugeIcon(icon: widget.icon, color: widget.color, size: 22.0),
    );
  }
}
