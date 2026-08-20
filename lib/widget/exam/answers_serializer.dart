/// Dựng chuỗi bài làm gửi kèm `submit-exam`.
///
/// Định dạng lấy ĐÚNG của web (`frontend_manage/src/hooks/useQuiz.ts:46-52`):
///
///     (questionId:value);(questionId:value);...
///
/// Đáp án rỗng ghi thành `-` chứ không bỏ trống, y như web — để máy chủ phân
/// biệt "câu này bỏ trống" với "câu này không có trong bài".
///
/// VÌ SAO PHẢI GỬI: `submit-exam` GHI ĐÈ chuỗi bài làm trên máy chủ chứ không
/// gộp. Trước đây mobile cố ý không gửi, dựa hẳn vào các lần `save-answer` —
/// cách đó chỉ đúng khi mọi câu đều đã lưu xong. Muốn nộp được lúc mất mạng
/// thì buộc phải gửi cả bài trong chính request nộp.
///
/// Khoá ở đây là khoá GỐC của [selectedAnswers] — đúng tập mà
/// `_loadPreviousAnswers` đọc ngược ra, nên vòng dựng-rồi-đọc-lại không lệch.
String serializeAnswers(Map<String, String> answers) {
  if (answers.isEmpty) return '';

  return answers.entries
      .map((entry) {
        final value = entry.value.trim().isEmpty ? '-' : entry.value;
        return '(${entry.key}:$value)';
      })
      .join(';');
}
