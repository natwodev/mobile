import 'package:flutter_test/flutter_test.dart';
import 'package:quizz_mobile/widget/exam/answers_serializer.dart';

/// Chuỗi bài làm gửi kèm `submit-exam` GHI ĐÈ bài trên máy chủ, nên định dạng
/// phải khớp đúng bản web (`useQuiz.ts:46-52`) — lệch một ký tự là mất bài.
void main() {
  group('Dựng chuỗi bài làm', () {
    test('rỗng thì trả chuỗi rỗng, không phải "()"', () {
      expect(serializeAnswers(<String, String>{}), '');
    });

    test('một câu -> (id:đáp án)', () {
      expect(serializeAnswers(<String, String>{'q1': 'A'}), '(q1:A)');
    });

    test('nhiều câu nối bằng dấu chấm phẩy, giữ nguyên thứ tự', () {
      expect(
        serializeAnswers(<String, String>{'q1': 'A', 'q2': 'B', 'q3': 'C'}),
        '(q1:A);(q2:B);(q3:C)',
      );
    });

    test('đáp án rỗng ghi thành "-" như web, không bỏ trống', () {
      expect(serializeAnswers(<String, String>{'q1': '', 'q2': 'B'}),
          '(q1:-);(q2:B)');
      expect(serializeAnswers(<String, String>{'q1': '   '}), '(q1:-)');
    });

    test('id câu con của Matching/TFNG cũng vào chuỗi như câu thường', () {
      // Matching lưu đáp án theo TỪNG câu con; nếu bộ dựng chuỗi bỏ sót nhóm
      // này thì nộp bài xong là mất sạch phần ghép cặp.
      expect(
        serializeAnswers(<String, String>{'parent-1-sub-1': 'X', 'parent-1-sub-2': 'Y'}),
        '(parent-1-sub-1:X);(parent-1-sub-2:Y)',
      );
    });

    test('giá trị nhiều lựa chọn giữ nguyên dấu phân tách bên trong', () {
      expect(
        serializeAnswers(<String, String>{'q1': 'a,b,c'}),
        '(q1:a,b,c)',
      );
    });
  });
}
