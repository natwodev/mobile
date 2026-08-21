class ExamSubmissionDto {
  final String? userCode;
  final String? shuffledExamPaperId;
  final double? score;
  final int? correctAnswers;
  final int? totalQuestions;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? studentAnswersString;
  final String? answerKey;

  ExamSubmissionDto({
    this.userCode,
    this.shuffledExamPaperId,
    this.score,
    this.correctAnswers,
    this.totalQuestions,
    this.startTime,
    this.endTime,
    this.studentAnswersString,
    this.answerKey,
  });

  factory ExamSubmissionDto.fromJson(Map<String, dynamic> json) {
    return ExamSubmissionDto(
      userCode: json['userCode'] ?? json['studentCode'] ?? '',
      shuffledExamPaperId: json['shuffledExamPaperId']?.toString(),
      score: json['score'] != null ? (json['score'] as num).toDouble() : null,
      correctAnswers: (json['correctAnswers'] as num?)?.toInt(),
      totalQuestions: (json['totalQuestions'] as num?)?.toInt(),
      startTime: json['startTime'] != null
          ? DateTime.parse(json['startTime'])
          : null,
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      studentAnswersString: json['studentAnswersString'] ?? '',
      answerKey: json['answerKey'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userCode': userCode,
      'shuffledExamPaperId': shuffledExamPaperId,
      'score': score,
      'correctAnswers': correctAnswers,
      'totalQuestions': totalQuestions,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'studentAnswersString': studentAnswersString,
      'answerKey': answerKey,
    };
  }
}
