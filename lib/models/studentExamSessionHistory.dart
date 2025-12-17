class StudentExamSessionHistory {
  int? studentExamSessionId;
  DateTime? startTime;
  DateTime? endTime;
  String? studentCode;
  String? subjectName;
  String? roomName;
  String? examSessionName;
  int? studentId;
  int? examSessionSubjectId;
  int? shuffledExamPaperId;
  int? extraMinutes;
  String? reasonForExtra;
  int? remainingMinutes;
  int? correctAnswers;
  int? totalQuestions;
  double? score;
  bool? isCompleted;
  String? studentAnswersString;
  DateTime? examSessionStartTime;
  DateTime? examSessionEndTime;

  StudentExamSessionHistory({
    this.studentExamSessionId,
    this.startTime,
    this.endTime,
    this.studentCode,
    this.subjectName,
    this.roomName,
    this.examSessionName,
    this.studentId,
    this.examSessionSubjectId,
    this.shuffledExamPaperId,
    this.extraMinutes,
    this.reasonForExtra,
    this.remainingMinutes,
    this.correctAnswers,
    this.totalQuestions,
    this.score,
    this.isCompleted,
    this.studentAnswersString,
    this.examSessionStartTime,
    this.examSessionEndTime,
  });

  factory StudentExamSessionHistory.fromJson(Map<String, dynamic> json) {
    return StudentExamSessionHistory(
      studentExamSessionId: (json['studentExamSessionId'] as num?)?.toInt(),
      startTime: json['startTime'] != null
          ? DateTime.parse(json['startTime'] as String)
          : null,
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      studentCode: json['studentCode'] as String?,
      subjectName: json['subjectName'] as String?,
      roomName: json['roomName'] as String?,
      examSessionName: json['examSessionName'] as String?,
      studentId: (json['studentId'] as num?)?.toInt(),
      examSessionSubjectId: (json['examSessionSubjectId'] as num?)?.toInt(),
      shuffledExamPaperId: (json['shuffledExamPaperId'] as num?)?.toInt(),
      extraMinutes: (json['extraMinutes'] as num?)?.toInt() ?? 0,
      reasonForExtra: json['reasonForExtra']?.toString(),
      remainingMinutes: (json['remainingMinutes'] as num?)?.toInt() ?? 0,
      correctAnswers: (json['correctAnswers'] as num?)?.toInt(),
      totalQuestions: (json['totalQuestions'] as num?)?.toInt(),
      score: json['score'] != null ? (json['score'] as num).toDouble() : null,
      isCompleted: json['isCompleted'] as bool?,
      studentAnswersString: json['studentAnswersString'] as String?,
      examSessionStartTime: json['examSessionStartTime'] != null
          ? DateTime.parse(json['examSessionStartTime'] as String)
          : null,
      examSessionEndTime: json['examSessionEndTime'] != null
          ? DateTime.parse(json['examSessionEndTime'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studentExamSessionId': studentExamSessionId,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'studentCode': studentCode,
      'subjectName': subjectName,
      'roomName': roomName,
      'examSessionName': examSessionName,
      'studentId': studentId,
      'examSessionSubjectId': examSessionSubjectId,
      'shuffledExamPaperId': shuffledExamPaperId,
      'extraMinutes': extraMinutes,
      'reasonForExtra': reasonForExtra,
      'remainingMinutes': remainingMinutes,
      'correctAnswers': correctAnswers,
      'totalQuestions': totalQuestions,
      'score': score,
      'isCompleted': isCompleted,
      'studentAnswersString': studentAnswersString,
      'examSessionStartTime': examSessionStartTime?.toIso8601String(),
      'examSessionEndTime': examSessionEndTime?.toIso8601String(),
    };
  }
}
