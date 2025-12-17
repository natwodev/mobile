class QuestionStructureDto {
  final int originalExamPaperDetailId;
  final int? parentQuestionId;
  final int order;
  final String? questionContent;
  final List<QuestionStructureDto> childQuestions;
  final List<AnswerStructureDto> answers;

  QuestionStructureDto({
    required this.originalExamPaperDetailId,
    this.parentQuestionId,
    required this.order,
    this.questionContent,
    List<QuestionStructureDto>? childQuestions,
    List<AnswerStructureDto>? answers,
  }) : childQuestions = childQuestions ?? [],
       answers = answers ?? [];

  factory QuestionStructureDto.fromJson(Map<String, dynamic> json) {
    return QuestionStructureDto(
      originalExamPaperDetailId: json['originalExamPaperDetailId'] ?? 0,
      parentQuestionId: json['parentQuestionId'],
      order: json['order'] ?? 0,
      questionContent: json['questionContent'],
      childQuestions:
          (json['childQuestions'] as List<dynamic>?)
              ?.map((e) => QuestionStructureDto.fromJson(e))
              .toList() ??
          [],
      answers:
          (json['answers'] as List<dynamic>?)
              ?.map((e) => AnswerStructureDto.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'originalExamPaperDetailId': originalExamPaperDetailId,
      'parentQuestionId': parentQuestionId,
      'order': order,
      'questionContent': questionContent,
      'childQuestions': childQuestions.map((c) => c.toJson()).toList(),
      'answers': answers.map((a) => a.toJson()).toList(),
    };
  }
}

class AnswerStructureDto {
  final int answerId;
  final int order;
  final String? answerContent;
  final int originalExamPaperDetailId;

  AnswerStructureDto({
    required this.answerId,
    required this.order,
    required this.answerContent,
    required this.originalExamPaperDetailId,
  });

  factory AnswerStructureDto.fromJson(Map<String, dynamic> json) {
    return AnswerStructureDto(
      answerId: json['answerId'] ?? 0,
      order: json['order'] ?? 0,
      answerContent: json['answerContent'] ?? "",
      originalExamPaperDetailId: json['originalExamPaperDetailId'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'answerId': answerId,
      'order': order,
      'answerContent': answerContent,
      'originalExamPaperDetailId': originalExamPaperDetailId,
    };
  }
}

class OriginalExamPaperDto {
  final int originalExamPaperId;
  final String originalExamPaperCore;
  final String title;
  final String? description;
  final int subjectId;
  final bool allowViewMaterials;
  final int durationMinutes;
  final int totalQuestions;
  final String? keyValueList;
  final List<OriginalExamPaperDetailDto> details;

  OriginalExamPaperDto({
    required this.originalExamPaperId,
    required this.originalExamPaperCore,
    required this.title,
    this.description,
    required this.subjectId,
    required this.allowViewMaterials,
    required this.durationMinutes,
    required this.totalQuestions,
    this.keyValueList,
    List<OriginalExamPaperDetailDto>? details,
  }) : details = details ?? [];

  factory OriginalExamPaperDto.fromJson(Map<String, dynamic> json) {
    return OriginalExamPaperDto(
      originalExamPaperId: json['originalExamPaperId'] ?? 0,
      originalExamPaperCore: json['originalExamPaperCore'] ?? "",
      title: json['title'] ?? "",
      description: json['description'],
      subjectId: json['subjectId'] ?? 0,
      allowViewMaterials: json['allowViewMaterials'] ?? false,
      durationMinutes: json['durationMinutes'] ?? 0,
      totalQuestions: json['totalQuestions'] ?? 0,
      keyValueList: json['keyValueList'],
      details:
          (json['details'] as List<dynamic>?)
              ?.map((e) => OriginalExamPaperDetailDto.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'originalExamPaperId': originalExamPaperId,
      'originalExamPaperCore': originalExamPaperCore,
      'title': title,
      'description': description,
      'subjectId': subjectId,
      'allowViewMaterials': allowViewMaterials,
      'durationMinutes': durationMinutes,
      'totalQuestions': totalQuestions,
      'keyValueList': keyValueList,
      'details': details.map((d) => d.toJson()).toList(),
    };
  }
}

class OriginalExamPaperDetailDto {
  final int originalExamPaperDetailId;
  final int order;
  final String? questionContent;
  final int? correctAnswerIndex;
  final int? parentQuestionId;
  final int chapterId;
  final bool canShuffleQuestion;
  final String? answerShuffleInfo;
  final OriginalExamPaperDetailDto? parentQuestion;
  final List<OriginalExamPaperDetailDto> childQuestions;
  final List<AnswerDto> answers;

  OriginalExamPaperDetailDto({
    required this.originalExamPaperDetailId,
    required this.order,
    this.questionContent,
    this.correctAnswerIndex,
    this.parentQuestionId,
    required this.chapterId,
    required this.canShuffleQuestion,
    this.answerShuffleInfo,
    this.parentQuestion,
    List<OriginalExamPaperDetailDto>? childQuestions,
    List<AnswerDto>? answers,
  }) : childQuestions = childQuestions ?? [],
       answers = answers ?? [];

  factory OriginalExamPaperDetailDto.fromJson(Map<String, dynamic> json) {
    return OriginalExamPaperDetailDto(
      originalExamPaperDetailId: json['originalExamPaperDetailId'] ?? 0,
      order: json['order'] ?? 0,
      questionContent: json['questionContent'],
      correctAnswerIndex: json['correctAnswerIndex'],
      parentQuestionId: json['parentQuestionId'],
      chapterId: json['chapterId'] ?? 0,
      canShuffleQuestion: json['canShuffleQuestion'] ?? false,
      answerShuffleInfo: json['answerShuffleInfo'],
      parentQuestion: json['parentQuestion'] != null
          ? OriginalExamPaperDetailDto.fromJson(json['parentQuestion'])
          : null,
      childQuestions:
          (json['childQuestions'] as List<dynamic>?)
              ?.map((e) => OriginalExamPaperDetailDto.fromJson(e))
              .toList() ??
          [],
      answers:
          (json['answers'] as List<dynamic>?)
              ?.map((e) => AnswerDto.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'originalExamPaperDetailId': originalExamPaperDetailId,
      'order': order,
      'questionContent': questionContent,
      'correctAnswerIndex': correctAnswerIndex,
      'parentQuestionId': parentQuestionId,
      'chapterId': chapterId,
      'canShuffleQuestion': canShuffleQuestion,
      'answerShuffleInfo': answerShuffleInfo,
      'parentQuestion': parentQuestion?.toJson(),
      'childQuestions': childQuestions.map((c) => c.toJson()).toList(),
      'answers': answers.map((a) => a.toJson()).toList(),
    };
  }
}

class AnswerDto {
  final int answerId;
  final int order;
  final String answerContent;
  final bool isCorrect;
  final bool canShuffleAnswer;
  final int originalExamPaperDetailId;

  AnswerDto({
    required this.answerId,
    required this.order,
    required this.answerContent,
    required this.isCorrect,
    required this.canShuffleAnswer,
    required this.originalExamPaperDetailId,
  });

  factory AnswerDto.fromJson(Map<String, dynamic> json) {
    return AnswerDto(
      answerId: json['answerId'] ?? 0,
      order: json['order'] ?? 0,
      answerContent: json['answerContent'] ?? "",
      isCorrect: json['isCorrect'] ?? false,
      canShuffleAnswer: json['canShuffleAnswer'] ?? false,
      originalExamPaperDetailId: json['originalExamPaperDetailId'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'answerId': answerId,
      'order': order,
      'answerContent': answerContent,
      'isCorrect': isCorrect,
      'canShuffleAnswer': canShuffleAnswer,
      'originalExamPaperDetailId': originalExamPaperDetailId,
    };
  }
}

class StartExamResponseDto {
  final StudentExamSessionCacheDto studentSession;
  final OriginalExamPaperDto originalExamPaper;

  StartExamResponseDto({
    required this.studentSession,
    required this.originalExamPaper,
  });

  factory StartExamResponseDto.fromJson(Map<String, dynamic> json) {
    return StartExamResponseDto(
      studentSession: StudentExamSessionCacheDto.fromJson(
        json['studentSession'],
      ),
      originalExamPaper: OriginalExamPaperDto.fromJson(
        json['originalExamPaper'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studentSession': studentSession.toJson(),
      'originalExamPaper': originalExamPaper.toJson(),
    };
  }
}

class StudentExamSessionCacheDto {
  // Từ Entity
  final int studentExamSessionId;
  final DateTime? startTime;
  final DateTime? endTime;
  final String studentCode;
  final int studentId;
  final int examSessionSubjectId;
  final int? shuffledExamPaperId;
  final int extraMinutes;
  final String? reasonForExtra;
  final int remainingMinutes;
  final int? correctAnswers;
  final int? totalQuestions;
  final double score;
  final bool isCompleted;
  final String? studentAnswersString;
  final int? examRoomId;

  // Từ DTO (những trường Entity không có)
  final String subjectName;
  final String roomName;
  final String examSessionName;
  final int duration;

  // Thời gian được phép làm bài (cached từ ExamSessionSubject)
  final DateTime examSessionStartTime;
  final DateTime examSessionEndTime;

  StudentExamSessionCacheDto({
    required this.studentExamSessionId,
    this.startTime,
    this.endTime,
    required this.studentCode,
    required this.studentId,
    required this.examSessionSubjectId,
    this.shuffledExamPaperId,
    required this.extraMinutes,
    this.reasonForExtra,
    required this.remainingMinutes,
    this.correctAnswers,
    this.totalQuestions,
    required this.score,
    required this.isCompleted,
    required this.studentAnswersString,
    this.examRoomId,
    required this.subjectName,
    required this.roomName,
    required this.examSessionName,
    required this.duration,
    required this.examSessionStartTime,
    required this.examSessionEndTime,
  });

  // Factory constructor từ JSON nếu cần
  factory StudentExamSessionCacheDto.fromJson(Map<String, dynamic> json) {
    return StudentExamSessionCacheDto(
      studentExamSessionId: json['studentExamSessionId'] ?? 0,
      startTime: json['startTime'] != null
          ? DateTime.parse(json['startTime'])
          : null,
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      studentCode: json['studentCode'] ?? "",
      studentId: json['studentId'] ?? 0,
      examSessionSubjectId: json['examSessionSubjectId'] ?? 0,
      shuffledExamPaperId: json['shuffledExamPaperId'],
      extraMinutes: json['extraMinutes'] ?? 0,
      reasonForExtra: json['reasonForExtra'],
      remainingMinutes: json['remainingMinutes'] ?? 0,
      correctAnswers: json['correctAnswers'],
      totalQuestions: json['totalQuestions'],
      score: (json['score'] ?? 0).toDouble(),
      isCompleted: json['isCompleted'] ?? false,
      studentAnswersString: json['studentAnswersString'] ?? "",
      examRoomId: json['examRoomId'],
      subjectName: json['subjectName'] ?? "",
      roomName: json['roomName'] ?? "",
      examSessionName: json['examSessionName'] ?? "",
      duration: json['duration'] ?? 0,
      examSessionStartTime: json['examSessionStartTime'] != null
          ? DateTime.parse(json['examSessionStartTime'])
          : DateTime.fromMillisecondsSinceEpoch(0),
      examSessionEndTime: json['examSessionEndTime'] != null
          ? DateTime.parse(json['examSessionEndTime'])
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  // Chuyển về JSON nếu cần
  Map<String, dynamic> toJson() {
    return {
      'studentExamSessionId': studentExamSessionId,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'studentCode': studentCode,
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
      'examRoomId': examRoomId,
      'subjectName': subjectName,
      'roomName': roomName,
      'examSessionName': examSessionName,
      'duration': duration,
      'examSessionStartTime': examSessionStartTime.toIso8601String(),
      'examSessionEndTime': examSessionEndTime.toIso8601String(),
    };
  }
}
