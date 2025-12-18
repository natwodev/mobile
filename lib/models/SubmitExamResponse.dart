class SubmitExamResponse {
  final String message;

  SubmitExamResponse({required this.message});

  factory SubmitExamResponse.fromJson(Map<String, dynamic> json) {
    return SubmitExamResponse(
      message: json['message'] ?? '',
    );
  }
}
