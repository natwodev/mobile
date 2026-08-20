import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quizz_mobile/widget/common/app_toast.dart';

/// Màu NỀN toast do giám thị cấu hình (`toastColor`, hex `#RRGGBB`).
///
/// Hai thứ được soi ở đây:
/// 1. `parseHexColor` — chuỗi hợp lệ ra đúng màu, MỌI chuỗi hỏng ra null để
///    toast rơi về màu mặc định của kiểu (không được đổi hành vi cũ).
/// 2. `contrastForegroundOn` — máy chủ không gửi màu chữ nên app tự tính: nền
///    tối chữ trắng, nền sáng chữ `#363636`.
void main() {
  group('AppToast.parseHexColor', () {
    test('hex có dấu #', () {
      expect(AppToast.parseHexColor('#0EA5E9'), const Color(0xFF0EA5E9));
    });

    test('hex không có dấu #', () {
      expect(AppToast.parseHexColor('0EA5E9'), const Color(0xFF0EA5E9));
    });

    test('không phân biệt hoa thường', () {
      expect(
        AppToast.parseHexColor('#abcdef'),
        AppToast.parseHexColor('#ABCDEF'),
      );
      expect(AppToast.parseHexColor('#abcdef'), const Color(0xFFABCDEF));
    });

    test('khoảng trắng thừa hai đầu vẫn nhận', () {
      expect(AppToast.parseHexColor('  #FF0000  '), const Color(0xFFFF0000));
    });

    test('luôn đục hoàn toàn (alpha = FF)', () {
      // Nền trong suốt thì chữ đọc trên đó thành ra không đoán được.
      expect(AppToast.parseHexColor('#000000'), const Color(0xFF000000));
    });

    test('chuỗi rác trả null', () {
      expect(AppToast.parseHexColor('không-phải-màu'), isNull);
      expect(AppToast.parseHexColor('#GGGGGG'), isNull);
      // Dạng 3 ký tự và 8 ký tự không nằm trong hợp đồng.
      expect(AppToast.parseHexColor('#FFF'), isNull);
      expect(AppToast.parseHexColor('#FF0EA5E9'), isNull);
      // `int.tryParse` nuốt dấu cộng/trừ, đây là chỗ dễ lọt nhất.
      expect(AppToast.parseHexColor('#+0A5E9'), isNull);
      expect(AppToast.parseHexColor('#-0A5E9'), isNull);
    });

    test('chuỗi rỗng trả null', () {
      expect(AppToast.parseHexColor(''), isNull);
      expect(AppToast.parseHexColor('   '), isNull);
      expect(AppToast.parseHexColor('#'), isNull);
    });

    test('null trả null', () {
      expect(AppToast.parseHexColor(null), isNull);
    });
  });

  group('AppToast.contrastForegroundOn', () {
    const Color ink = Color(0xFF363636);

    test('nền tối cho chữ trắng', () {
      expect(AppToast.contrastForegroundOn(const Color(0xFF000000)),
          Colors.white);
      // Nền của kiểu `dark` trong bảng cấu hình.
      expect(AppToast.contrastForegroundOn(const Color(0xFF1A1A1A)),
          Colors.white);
      // Xanh dương đậm: mắt thấy "màu" nhưng độ sáng vẫn thấp.
      expect(AppToast.contrastForegroundOn(const Color(0xFF1D4ED8)),
          Colors.white);
    });

    test('nền sáng cho chữ đậm #363636', () {
      expect(AppToast.contrastForegroundOn(const Color(0xFFFFFFFF)), ink);
      // Vàng nhạt và hồng nhạt — đúng hai màu làm luật cũ "chữ trắng" hỏng.
      expect(AppToast.contrastForegroundOn(const Color(0xFFFEF08A)), ink);
      expect(AppToast.contrastForegroundOn(const Color(0xFFFBCFE8)), ink);
    });

    test('chữ đậm trùng màu chữ mặc định của toast nền trắng', () {
      // Nền trắng là đường mặc định cũ: phải ra đúng #363636, không phải đen.
      expect(AppToast.contrastForegroundOn(Colors.white), ink);
    });
  });

  group('màu giám thị chọn nối vào màu chữ', () {
    test('hex sáng ⇒ chữ đậm, hex tối ⇒ chữ trắng', () {
      final Color? light = AppToast.parseHexColor('#FEF08A');
      final Color? dark = AppToast.parseHexColor('#0F172A');

      expect(light, isNotNull);
      expect(dark, isNotNull);
      expect(AppToast.contrastForegroundOn(light!), const Color(0xFF363636));
      expect(AppToast.contrastForegroundOn(dark!), Colors.white);
    });
  });
}
