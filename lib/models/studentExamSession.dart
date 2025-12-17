class StudentExamSession {
  int? examSessionSubjectId;
  String? subjectName;
  String? roomName;
  String? examSessionName;
  int? duration;
  int? extraMinutes;
  int? remainingMinutes;
  DateTime? startTime;
  DateTime? endTime;
  int? studentExamSessionId;
  int? shuffledExamPaperId;
  String? studentAnswersString;
  DateTime? examSessionStartTime;
  DateTime? examSessionEndTime;

  // kept for UI fallback but not populated from JSON per requirement
  double? score;

  StudentExamSession({
    this.examSessionSubjectId,
    this.subjectName,
    this.roomName,
    this.examSessionName,
    this.duration,
    this.extraMinutes,
    this.remainingMinutes,
    this.startTime,
    this.endTime,
    this.studentExamSessionId,
    this.shuffledExamPaperId,
    this.studentAnswersString,
    this.examSessionStartTime,
    this.examSessionEndTime,
    this.score,
  });

  // Chuyển từ JSON sang object Dart
  factory StudentExamSession.fromJson(Map<String, dynamic> json) {
    return StudentExamSession(
      examSessionSubjectId: (json['examSessionSubjectId'] as num?)?.toInt(),
      subjectName: json['subjectName'] as String?,
      roomName: json['roomName'] as String?,
      examSessionName: json['examSessionName'] as String?,
      duration: (json['duration'] as num?)?.toInt(),
      extraMinutes: (json['extraMinutes'] as num?)?.toInt() ?? 0,
      remainingMinutes: (json['remainingMinutes'] as num?)?.toInt() ?? 0,
      startTime: json['startTime'] != null
          ? DateTime.parse(json['startTime'] as String)
          : null,
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      studentExamSessionId: (json['studentExamSessionId'] as num?)?.toInt(),
      shuffledExamPaperId: (json['shuffledExamPaperId'] as num?)?.toInt(),
      studentAnswersString: json['studentAnswersString'] as String? ?? '',
      examSessionStartTime: json['examSessionStartTime'] != null
          ? DateTime.parse(json['examSessionStartTime'] as String)
          : null,
      examSessionEndTime: json['examSessionEndTime'] != null
          ? DateTime.parse(json['examSessionEndTime'] as String)
          : null,
    );
  }

  // Chuyển object Dart sang JSON
  Map<String, dynamic> toJson() {
    return {
      'examSessionSubjectId': examSessionSubjectId,
      'subjectName': subjectName,
      'roomName': roomName,
      'examSessionName': examSessionName,
      'duration': duration,
      'extraMinutes': extraMinutes,
      'remainingMinutes': remainingMinutes,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'studentExamSessionId': studentExamSessionId,
      'shuffledExamPaperId': shuffledExamPaperId,
      'studentAnswersString': studentAnswersString,
      'examSessionStartTime': examSessionStartTime?.toIso8601String(),
      'examSessionEndTime': examSessionEndTime?.toIso8601String(),
    };
  }
}
