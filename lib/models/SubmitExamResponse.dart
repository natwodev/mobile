class SubmitExamResponse {
  final bool success;
  final String message;
  final SubmitExamData? data;

  SubmitExamResponse({required this.success, required this.message, this.data});

  factory SubmitExamResponse.fromJson(Map<String, dynamic> json) {
    return SubmitExamResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? json['code'] ?? '',
      data: json['resultToken'] != null
          ? SubmitExamData(resultToken: json['resultToken'])
          : (json['data'] != null
                ? SubmitExamData.fromJson(json['data'])
                : null),
    );
  }
}

class SubmitExamData {
  final String resultToken;

  SubmitExamData({required this.resultToken});

  factory SubmitExamData.fromJson(Map<String, dynamic> json) {
    return SubmitExamData(resultToken: json['resultToken'] ?? '');
  }
}
