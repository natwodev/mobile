import 'package:flutter_test/flutter_test.dart';
import 'package:quizz_mobile/widget/exam/code_content.dart';

void main() {
  group('Nhận diện code trong nội dung câu hỏi', () {
    test('câu chữ thuần thì không coi là có code', () {
      expect(CodeContent.hasCode('Thủ đô của Việt Nam là gì?'), isFalse);
      expect(CodeContent.split('Chỉ là chữ').single.isCode, isFalse);
    });

    test('khối ```python``` thành code khối, giữ nguyên thụt đầu dòng', () {
      const input = 'Đoạn sau in ra gì?\n```python\ndef f(x):\n    return x*2\n```';
      final segments = CodeContent.split(input);

      final code = segments.firstWhere((s) => s.isCode);
      expect(code.isBlock, isTrue);
      expect(code.language, 'python');
      // Thụt đầu dòng là ngữ nghĩa của Python, mất là đề sai.
      expect(code.value, contains('    return x*2'));
      expect(segments.first.value, contains('Đoạn sau in ra gì?'));
    });

    test('<pre> thành code khối', () {
      final segments = CodeContent.split('Xem: <pre><code>SELECT * FROM t;</code></pre>');
      final code = segments.firstWhere((s) => s.isCode);
      expect(code.isBlock, isTrue);
      expect(code.value, 'SELECT * FROM t;');
    });

    test('<code> giữa dòng thành code nội tuyến', () {
      final segments = CodeContent.split('Hàm <code>print()</code> làm gì?');
      final code = segments.firstWhere((s) => s.isCode);
      expect(code.isBlock, isFalse);
      expect(code.value, 'print()');
    });

    test('thẻ HTML bị escape được coi là code, giống ProcessedHTML của web', () {
      final segments = CodeContent.split('Thẻ &lt;div class="a"&gt; dùng để làm gì?');
      final code = segments.firstWhere((s) => s.isCode);
      expect(code.isBlock, isFalse);
      expect(code.language, 'xml');
      // Đã bỏ escape để hiện đúng dấu ngoặc nhọn.
      expect(code.value, '<div class="a">');
    });

    test('đoán ngôn ngữ theo đúng thứ tự luật của web', () {
      expect(CodeContent.detectLanguage('display: flex;'), 'css');
      expect(CodeContent.detectLanguage('<p>xin chào</p>'), 'xml');
      expect(CodeContent.detectLanguage('def main():'), 'python');
      expect(CodeContent.detectLanguage('System.out.println(1);'), 'java');
      expect(CodeContent.detectLanguage('const a = 1;'), 'javascript');
      expect(CodeContent.detectLanguage('1 + 1 = 2'), 'plaintext');
    });

    test('&amp; được bỏ escape sau cùng nên &amp;lt; không thành dấu <', () {
      expect(CodeContent.unescape('&amp;lt;'), '&lt;');
      expect(CodeContent.unescape('&lt;b&gt;'), '<b>');
    });

    test('nhiều mẩu code xen chữ vẫn giữ đúng thứ tự', () {
      final segments = CodeContent.split(
        'Cho <code>a=1</code> và <code>b=2</code>, tính a+b',
      );
      expect(segments.where((s) => s.isCode).map((s) => s.value).toList(),
          <String>['a=1', 'b=2']);
      expect(segments.last.isCode, isFalse);
      expect(segments.last.value, contains('tính a+b'));
    });
  });
}
