class ExamSubmissionDto {
  final String studentCode;
  final int shuffledExamPaperId;
  final double? score;
  final int? correctAnswers;
  final int? totalQuestions;
  final DateTime? startTime;
  final DateTime endTime;
  final String studentAnswersString;
  final String answerKey;

  ExamSubmissionDto({
    required this.studentCode,
    required this.shuffledExamPaperId,
    this.score,
    this.correctAnswers,
    this.totalQuestions,
    this.startTime,
    required this.endTime,
    required this.studentAnswersString,
    required this.answerKey,
  });

  factory ExamSubmissionDto.fromJson(Map<String, dynamic> json) {
    return ExamSubmissionDto(
      studentCode: json['studentCode'] ?? '',
      shuffledExamPaperId: json['shuffledExamPaperId'] ?? 0,
      score: json['score'] != null ? (json['score'] as num).toDouble() : null,
      correctAnswers: json['correctAnswers'],
      totalQuestions: json['totalQuestions'],
      startTime: json['startTime'] != null
          ? DateTime.parse(json['startTime'])
          : null,
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'])
          : DateTime.now(),
      studentAnswersString: json['studentAnswersString'] ?? '',
      answerKey: json['answerKey'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studentCode': studentCode,
      'shuffledExamPaperId': shuffledExamPaperId,
      'score': score,
      'correctAnswers': correctAnswers,
      'totalQuestions': totalQuestions,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'studentAnswersString': studentAnswersString,
      'answerKey': answerKey,
    };
  }
}
