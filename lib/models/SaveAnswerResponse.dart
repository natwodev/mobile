class SaveAnswerResponse {
  final bool success;
  final String message;
  final SaveAnswerData data;

  SaveAnswerResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory SaveAnswerResponse.fromJson(Map<String, dynamic> json) {
    return SaveAnswerResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: SaveAnswerData.fromJson(json['data'] ?? {}),
    );
  }
}

class SaveAnswerData {
  final String newAnswersString;
  final int key;
  final dynamic value;

  SaveAnswerData({
    required this.newAnswersString,
    required this.key,
    required this.value,
  });

  factory SaveAnswerData.fromJson(Map<String, dynamic> json) {
    return SaveAnswerData(
      newAnswersString: json['newAnswersString'] ?? '',
      key: json['key'] ?? 0,
      value: json['value'],
    );
  }
}
