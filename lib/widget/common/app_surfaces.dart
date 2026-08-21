import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Mặt nổi dùng chung: thẻ, nút tròn, thanh báo — những mảng trắng nổi lên khỏi
/// nền bằng một viền mảnh và một quầng sáng CÙNG MÀU.
///
/// Gom lại vì công thức này đã chép qua chép lại khắp nơi: thẻ 2 nút nhanh và
/// nút chuông ở Trang chủ, thẻ tin, nút tải thêm, thanh báo, bốn thẻ ở màn Tài
/// khoản, dòng thư chưa đọc ở hộp thư. Chép tay nhiều lần là chắc chắn có chỗ
/// lệch — mà lệch kiểu này (0.35 thay vì 0.4 độ đục, viền 1.0 thay vì 0.5) thì
/// nhìn ra ngay là "sai sai" nhưng không gọi tên được.
///
/// [tint] là MÀU CHỦ THỂ của chỗ dùng, không phải một màu cố định. Thanh báo
/// lỗi thì đỏ, báo thành công thì xanh lá, thẻ thường thì màu nhấn. Trước khi
/// gom về đây, thanh báo đã sai đúng chỗ này: viền lấy theo màu trạng thái còn
/// bóng thì luôn xanh, nên thanh báo lỗi viền đỏ mà toả sáng xanh.
class AppSurfaces {
  AppSurfaces._();

  /// Bề dày viền. Nửa điểm ảnh logic — đủ vẽ lại đường bao mà không thành nét
  /// kẻ. Dày 1.0 trên màn 3x là ba điểm ảnh vật lý, đủ nặng để cái khung hút
  /// mắt hơn chính nội dung nó bao.
  static const double borderWidth = 0.5;

  /// Độ đục của viền.
  static const double borderAlpha = 0.4;

  /// Độ đục của bóng.
  static const double shadowAlpha = 0.42;

  /// Độ toả mặc định của bóng.
  ///
  /// MỎNG mà ĐẬM, thay cho rộng mà nhạt. Toả rộng (25px @ 18% như bản đầu) làm
  /// màu bị dàn mỏng đến mức đặt trên băng ảnh nhiều màu là gần như mất hút,
  /// thẻ trông như dán phẳng lên. Thu về 8px rồi nâng độ đục thì quầng sáng bám
  /// sát mép thẻ, đọc ra là "nổi lên" rõ ràng mà không loang ra nền.
  static const double blurRadius = 8;

  static const Offset shadowOffset = Offset(0, 3);

  /// Viền mảnh cùng màu chủ thể.
  ///
  /// Nhạt hơn hẳn quầng sáng là có lý do: bóng toả ra nên chỗ giáp mép đã loãng
  /// gần hết màu, mà mảng trắng đặt trên nền sáng thì mất luôn đường bao. Viền
  /// này vẽ lại đúng cái mép đó.
  static Border border({Color tint = AppColors.accent}) => Border.all(
    color: tint.withValues(alpha: borderAlpha),
    width: borderWidth,
  );

  /// Cùng viền trên nhưng ở dạng [BorderSide], cho `OutlinedButton` và
  /// `RoundedRectangleBorder`.
  static BorderSide side({Color tint = AppColors.accent}) => BorderSide(
    color: tint.withValues(alpha: borderAlpha),
    width: borderWidth,
  );

  /// Quầng sáng cùng màu chủ thể.
  ///
  /// [blur] và [offset] mở ra vì có chỗ cần hình học khác: thanh báo nằm sát
  /// dải tab nên phải đẩy bóng LÊN đúng bằng độ toả, để mép dưới của bóng dừng
  /// ngay ở đáy thanh, không rơi một điểm ảnh nào xuống dải tab.
  static List<BoxShadow> glow({
    Color tint = AppColors.accent,
    double? blur,
    Offset? offset,
    double? alpha,
  }) => [
    BoxShadow(
      color: tint.withValues(alpha: alpha ?? shadowAlpha),
      blurRadius: blur ?? blurRadius,
      offset: offset ?? shadowOffset,
    ),
  ];

  /// Độ toả và độ đục cho thẻ nằm trong DANH SÁCH DÀI.
  ///
  /// Toả rộng hơn nhưng nhạt đi quá nửa. Một thẻ đứng lẻ thì quầng sáng đậm là
  /// vừa đẹp, nhưng xếp mươi thẻ liền nhau thì mươi quầng đậm chồng mép vào
  /// nhau, đọc ra là cả trang bị ám màu chứ không còn là từng thẻ nổi lên.
  static const double softBlur = 12;
  static const double softAlpha = 0.16;

  /// Thẻ bo góc: viền mảnh kèm quầng sáng.
  ///
  /// Ba mức chỉnh, từ thô tới tinh:
  ///
  /// - [shadow] `false` — không quầng sáng, chỉ còn viền.
  /// - [soft] `true` — quầng nhạt cho thẻ nằm trong danh sách dài.
  /// - [blur] / [alpha] / [offset] — chỉnh tay từng số, đè lên cả [soft].
  ///
  /// Có [soft] rồi vẫn mở ba số cuối vì hai mức có sẵn chỉ là hai điểm dùng
  /// nhiều nhất, không phải giới hạn. Không mở thì chỗ nào cần khác đi một chút
  /// lại phải tự ghép [border] với [glow] — mà tự ghép là lại có cơ hội quên
  /// một số và lệch khỏi phần còn lại, đúng thứ lớp này sinh ra để chặn.
  static BoxDecoration card({
    Color color = Colors.white,
    Color tint = AppColors.accent,
    double radius = 12,
    bool shadow = true,
    bool soft = false,
    double? blur,
    double? alpha,
    Offset? offset,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: border(tint: tint),
      boxShadow: shadow
          ? glow(
              tint: tint,
              blur: blur ?? (soft ? softBlur : null),
              alpha: alpha ?? (soft ? softAlpha : null),
              offset: offset,
            )
          : null,
    );
  }

  /// Nút tròn, ví dụ nút chuông trên băng ảnh Trang chủ.
  ///
  /// Dùng cái này thay cho `elevation` của Material: bóng của Material là xám
  /// trung tính, đứng cạnh mấy mảng xanh còn lại thì lạc tông, trên nền ảnh
  /// sáng thì gần như mất hút, và nó toả đều bốn phía nên không chọn hướng
  /// được.
  ///
  /// Nhận cùng bộ tham số quầng sáng như [card] — chỉ khác hình.
  static BoxDecoration circle({
    Color color = Colors.white,
    Color tint = AppColors.accent,
    bool shadow = true,
    bool soft = false,
    double? blur,
    double? alpha,
    Offset? offset,
  }) => BoxDecoration(
    color: color,
    shape: BoxShape.circle,
    border: border(tint: tint),
    boxShadow: shadow
        ? glow(
            tint: tint,
            blur: blur ?? (soft ? softBlur : null),
            alpha: alpha ?? (soft ? softAlpha : null),
            offset: offset,
          )
        : null,
  );
}
