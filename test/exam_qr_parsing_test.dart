import 'package:flutter_test/flutter_test.dart';
import 'package:quizz_mobile/screens/scan_qr/utils/qr_validator.dart';

/// Các chuỗi dưới đây KHÔNG phải do tay người viết ra: chúng là kết quả thật của
/// bộ sinh mã QR bên monitor web
/// (`csharp_manage/frontend_manage/src/components/monitor/utils/examQrCode.ts`),
/// chép nguyên si sang đây.
///
/// Hai đầu nằm ở hai kho mã khác nhau nên không có gì tự động phát hiện khi một
/// bên đổi định dạng; bài kiểm tra này chính là chỗ vỡ ra nếu điều đó xảy ra.
void main() {
  const qrBinhThuong =
      'EXAM|v=1|id=3f2a1c94-8b7d-4e2a-9c11-77aa55bb33cc|core=CA_THI-2026_01|'
      'title=Đề_thi_cuối_kỳ_môn_Lập_trình|desc=Đề_gồm_40_câu_trắc_nghiệm|'
      'sub=Lập_trình_hướng_đối_tượng|dur=60|created=2026-08-20T09:30:00.000Z';

  const qrThieuDuLieu =
      'EXAM|v=1|id=11112222-3333-4444-5555-666677778888|core=ESS001|'
      'title=-|desc=-|sub=-|dur=-|created=-';

  const qrCoKyTuPhanTach =
      'EXAM|v=1|id=aaaa1111-2222-3333-4444-555566667777|core=CA-THI-X|'
      'title=Đề_-_có_-_ký_tự_lạ|desc=-|sub=Toán|dur=45|created=2026-01-02T03:04:05.000Z';

  group('validateExamQrFormat', () {
    test('nhận mã do monitor sinh ra', () {
      expect(validateExamQrFormat(qrBinhThuong), isTrue);
      expect(validateExamQrFormat(qrThieuDuLieu), isTrue);
      expect(validateExamQrFormat(qrCoKyTuPhanTach), isTrue);
    });

    test('từ chối mã lạ', () {
      expect(validateExamQrFormat('https://tracnghiem.online'), isFalse);
      expect(validateExamQrFormat('EXAM|v=1|id=abc'), isFalse);
      expect(validateExamQrFormat(''), isFalse);
    });
  });

  group('parseExamQrData', () {
    test('mã ca thi giữ nguyên từng ký tự, kể cả dấu gạch dưới', () {
      final data = parseExamQrData(qrBinhThuong);

      // Đây là giá trị app đem đi tra ca thi. Hoàn '_' về dấu cách ở đây là tra
      // trượt và sinh viên nhận "không tìm thấy ca thi".
      expect(data['core'], 'CA_THI-2026_01');
      expect(data['id'], '3f2a1c94-8b7d-4e2a-9c11-77aa55bb33cc');
    });

    test('phần chữ cho người đọc thì trả dấu cách về', () {
      final data = parseExamQrData(qrBinhThuong);

      expect(data['title'], 'Đề thi cuối kỳ môn Lập trình');
      expect(data['sub'], 'Lập trình hướng đối tượng');
      expect(data['desc'], 'Đề gồm 40 câu trắc nghiệm');
      expect(data['dur'], '60');
    });

    test('thiếu dữ liệu thì ra dấu gạch ngang chứ không phải null', () {
      final data = parseExamQrData(qrThieuDuLieu);

      expect(data['core'], 'ESS001');
      expect(data['title'], '-');
      expect(data['desc'], '-');
      expect(data['sub'], '-');
    });

    test('ký tự phân tách trong dữ liệu không làm vỡ việc tách chuỗi', () {
      final data = parseExamQrData(qrCoKyTuPhanTach);

      // Monitor đã đổi '|' và '=' thành '-' trước khi ghép, nên tất cả 8 field
      // vẫn về đủ và không field nào nuốt mất field sau.
      expect(data.keys.toSet(), {
        'v',
        'id',
        'core',
        'title',
        'desc',
        'sub',
        'dur',
        'created',
      });
      expect(data['core'], 'CA-THI-X');
      expect(data['sub'], 'Toán');
    });
  });
}
