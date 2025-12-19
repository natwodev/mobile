class SubmitExamResponse {
  final String message;
  final bool success;

  SubmitExamResponse({required this.message, required this.success});

  factory SubmitExamResponse.fromJson(Map<String, dynamic> json) {
    return SubmitExamResponse(
      message: json['message'] ?? '',
      success: json['success'] ?? true,
    );
  }
}
