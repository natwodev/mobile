class SaveAnswerResponse {
  final bool success;
  final String message;
  final SaveAnswerData? data;

  SaveAnswerResponse({required this.success, required this.message, this.data});

  factory SaveAnswerResponse.fromJson(Map<String, dynamic> json) {
    return SaveAnswerResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? json['code'] ?? '',
      data: json['data'] != null ? SaveAnswerData.fromJson(json['data']) : null,
    );
  }
}

class SaveAnswerData {
  final String newAnswersString;
  final dynamic key;
  final dynamic value;

  SaveAnswerData({
    required this.newAnswersString,
    required this.key,
    required this.value,
  });

  factory SaveAnswerData.fromJson(Map<String, dynamic> json) {
    return SaveAnswerData(
      newAnswersString: json['newAnswersString'] ?? '',
      key: json['key'],
      value: json['value'],
    );
  }
}
