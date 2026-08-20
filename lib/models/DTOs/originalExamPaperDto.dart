// ---------------------------------------------------------------------------
// Helper ép kiểu JSON "chịu lỗi".
//
// Toàn bộ file này parse phản hồi của backend cho luồng VÀO THI. Một trường
// phụ bị null / sai kiểu KHÔNG được phép ném exception làm hỏng cả bài thi,
// nên mọi chỗ đọc JSON đều đi qua các helper dưới đây thay vì ép kiểu trực
// tiếp (`as`) hay dựa vào suy luận kiểu ngầm.
// ---------------------------------------------------------------------------

/// Ép một giá trị JSON bất kỳ về `Map<String, dynamic>`.
///
/// Trả về `null` khi giá trị không phải object (null, list, số, chuỗi...) để
/// nơi gọi tự quyết định dùng mặc định hay ném lỗi rõ ràng.
Map<String, dynamic>? _asJsonObject(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, dynamic val) => MapEntry(key.toString(), val));
  }
  return null;
}

/// Lấy danh sách object JSON, bỏ qua các phần tử không phải object.
///
/// Trả về danh sách rỗng khi giá trị không phải mảng — an toàn hơn việc ép
/// `as List<dynamic>?` (ép kiểu này ném TypeError nếu backend trả object).
List<Map<String, dynamic>> _asJsonObjectList(dynamic value) {
  if (value is! List) return <Map<String, dynamic>>[];
  final result = <Map<String, dynamic>>[];
  for (final dynamic item in value) {
    final map = _asJsonObject(item);
    if (map != null) result.add(map);
  }
  return result;
}

String? _asStringOrNull(dynamic value) {
  if (value == null) return null;
  if (value is String) return value;
  return value.toString();
}

String _asString(dynamic value, {String fallback = ''}) =>
    _asStringOrNull(value) ?? fallback;

int? _asIntOrNull(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim());
  return null;
}

int _asInt(dynamic value, {int fallback = 0}) =>
    _asIntOrNull(value) ?? fallback;

double _asDouble(dynamic value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim()) ?? fallback;
  return fallback;
}

bool _asBool(dynamic value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
  }
  return fallback;
}

/// Parse ngày giờ ISO 8601. Dùng `tryParse` để chuỗi hỏng không làm sập màn thi.
DateTime? _asDateTimeOrNull(dynamic value) {
  if (value is DateTime) return value;
  final raw = _asStringOrNull(value);
  if (raw == null || raw.isEmpty) return null;
  return DateTime.tryParse(raw);
}

class QuestionStructureDto {
  final String originalExamPaperDetailId;
  final String? parentQuestionId;
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
      originalExamPaperDetailId: _asString(json['originalExamPaperDetailId']),
      parentQuestionId: _asStringOrNull(json['parentQuestionId']),
      order: _asInt(json['order']),
      questionContent: _asStringOrNull(json['questionContent']),
      childQuestions: _asJsonObjectList(
        json['childQuestions'],
      ).map(QuestionStructureDto.fromJson).toList(),
      answers: _asJsonObjectList(
        json['answers'],
      ).map(AnswerStructureDto.fromJson).toList(),
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
  final String answerId;
  final int order;
  final String answerContent;
  final String originalExamPaperDetailId;

  AnswerStructureDto({
    required this.answerId,
    required this.order,
    required this.answerContent,
    required this.originalExamPaperDetailId,
  });

  factory AnswerStructureDto.fromJson(Map<String, dynamic> json) {
    return AnswerStructureDto(
      answerId: _asString(json['answerId']),
      order: _asInt(json['order']),
      answerContent: _asString(json['answerContent']),
      originalExamPaperDetailId: _asString(json['originalExamPaperDetailId']),
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
  final String originalExamPaperId;
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
      originalExamPaperId: _asString(json['originalExamPaperId']),
      originalExamPaperCore: _asString(json['originalExamPaperCore']),
      title: _asString(json['title']),
      description: _asStringOrNull(json['description']),
      subjectId: _asInt(json['subjectId']),
      allowViewMaterials: _asBool(json['allowViewMaterials']),
      durationMinutes: _asInt(json['durationMinutes']),
      totalQuestions: _asInt(json['totalQuestions']),
      keyValueList: _asStringOrNull(json['keyValueList']),
      details: _asJsonObjectList(
        json['details'],
      ).map(OriginalExamPaperDetailDto.fromJson).toList(),
    );
  }

  /// Dựng đề thi từ khoá `examPaper` mà backend đang trả ở 2 endpoint vào thi
  /// (`GET api/student/resume-quiz/{id}` và `POST api/student/create-exam-session`).
  ///
  /// `examPaper` là `StudentExamPaperDto` phía C# — bản rút gọn CỐ Ý không
  /// chứa đáp án đúng, không chứa đề gốc. Vì vậy một số trường mobile cần
  /// không tồn tại trong nguồn và phải suy ra; xem chú thích từng trường.
  factory OriginalExamPaperDto.fromStudentExamPaperJson(
    Map<String, dynamic> json, {
    Map<String, dynamic>? studentSessionJson,
  }) {
    final questionStructures = _asJsonObjectList(json['questionStructures']);

    return OriginalExamPaperDto(
      originalExamPaperId: _asString(json['originalExamPaperId']),
      // StudentExamPaperDto chỉ có mã ĐỀ HOÁN VỊ. Backend sinh mã này theo
      // dạng "{originalExamPaperCore}_{số thứ tự 3 chữ số}", nên phần trước
      // dấu '_' đầu tiên giống hệt mã đề gốc — đúng thứ exam_screen.dart:228
      // cần để suy ra tên thư mục ảnh (`.split('_').first`).
      originalExamPaperCore: _asString(json['shuffledExamPaperCore']),
      title: _asString(json['title']),
      // StudentExamPaperDto không gửi mô tả đề.
      description: null,
      subjectId: _asInt(json['subjectId']),
      allowViewMaterials: _asBool(json['allowViewMaterials']),
      // Thời lượng thật của sinh viên nằm ở phiên thi (đã tính cả cấu hình ca
      // thi), không nằm trên đề → studentSession.duration là nguồn sự thật.
      durationMinutes: _asInt(studentSessionJson?['duration']),
      // StudentExamPaperDto không có totalQuestions; số câu hiển thị chính là
      // số câu hỏi gốc (cấp 1) của đề.
      totalQuestions: questionStructures.length,
      // keyValueList = bảng đáp án đúng. Backend cố tình KHÔNG gửi cho sinh
      // viên để tránh lộ đáp án → luôn null ở luồng làm bài.
      keyValueList: null,
      details: questionStructures
          .map(
            (question) =>
                OriginalExamPaperDetailDto.fromQuestionStructureJson(question),
          )
          .toList(),
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
  final String originalExamPaperDetailId;
  final int order;
  final String? questionContent;
  final int? correctAnswerIndex;
  final String? parentQuestionId;
  final int chapterId;
  final int
  questionType; // 0=SingleChoice, 1=Reading, 2=Matching, 3=MultipleChoice, 4=TrueFalse, 5=FillInBlank, 6=TFNG, 7=Ordering, 8=ShortAnswer, 9=Dropdown, 10=Highlighting
  final int? difficultyLevel;
  final bool isAudio;
  final int? maxListenCount;
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
    this.questionType = 0,
    this.difficultyLevel,
    this.isAudio = false,
    this.maxListenCount,
    required this.canShuffleQuestion,
    this.answerShuffleInfo,
    this.parentQuestion,
    List<OriginalExamPaperDetailDto>? childQuestions,
    List<AnswerDto>? answers,
  }) : childQuestions = childQuestions ?? [],
       answers = answers ?? [];

  factory OriginalExamPaperDetailDto.fromJson(Map<String, dynamic> json) {
    return OriginalExamPaperDetailDto(
      originalExamPaperDetailId: _asString(json['originalExamPaperDetailId']),
      order: _asInt(json['order']),
      questionContent: _asStringOrNull(json['questionContent']),
      correctAnswerIndex: _asIntOrNull(json['correctAnswerIndex']),
      parentQuestionId: _asStringOrNull(json['parentQuestionId']),
      // Các trường dưới đây có thể vắng mặt ở đề rút gọn cho sinh viên →
      // dùng mặc định an toàn, tuyệt đối không ném lỗi.
      chapterId: _asInt(json['chapterId']),
      questionType: _asInt(json['questionType']),
      difficultyLevel: _asIntOrNull(json['difficultyLevel']),
      isAudio: _asBool(json['isAudio']),
      maxListenCount: _asIntOrNull(json['maxListenCount']),
      canShuffleQuestion: _asBool(json['canShuffleQuestion']),
      answerShuffleInfo: _asStringOrNull(json['answerShuffleInfo']),
      parentQuestion: () {
        final parentJson = _asJsonObject(json['parentQuestion']);
        return parentJson == null
            ? null
            : OriginalExamPaperDetailDto.fromJson(parentJson);
      }(),
      childQuestions: _asJsonObjectList(
        json['childQuestions'],
      ).map(OriginalExamPaperDetailDto.fromJson).toList(),
      answers: _asJsonObjectList(
        json['answers'],
      ).map(AnswerDto.fromJson).toList(),
    );
  }

  /// Dựng câu hỏi từ một phần tử `questionStructures` của `examPaper`
  /// (`QuestionStructureDto` phía C#).
  ///
  /// Nguồn này chỉ có: originalExamPaperDetailId, parentQuestionId, order,
  /// questionContent, questionType, childQuestions, answers, isAudio,
  /// maxListenCount, difficultyLevel. Mọi trường khác được suy ra hoặc lấy
  /// mặc định an toàn (xem chú thích trong thân hàm).
  factory OriginalExamPaperDetailDto.fromQuestionStructureJson(
    Map<String, dynamic> json, {
    OriginalExamPaperDetailDto? parentQuestion,
  }) {
    final answers = _asJsonObjectList(
      json['answers'],
    ).map(AnswerDto.fromAnswerStructureJson).toList();

    OriginalExamPaperDetailDto build(
      List<OriginalExamPaperDetailDto> children,
    ) {
      return OriginalExamPaperDetailDto(
        originalExamPaperDetailId: _asString(json['originalExamPaperDetailId']),
        order: _asInt(json['order']),
        questionContent: _asStringOrNull(json['questionContent']),
        // QuestionStructureDto cố tình KHÔNG gửi đáp án đúng cho sinh viên.
        correctAnswerIndex: null,
        parentQuestionId: _asStringOrNull(json['parentQuestionId']),
        // Không có trong QuestionStructureDto và UI làm bài không dùng tới.
        chapterId: 0,
        questionType: _asInt(json['questionType']),
        difficultyLevel: _asIntOrNull(json['difficultyLevel']),
        isAudio: _asBool(json['isAudio']),
        maxListenCount: _asIntOrNull(json['maxListenCount']),
        // Đề đã được backend hoán vị sẵn trước khi trả về, client không được
        // xáo thêm lần nữa → false.
        canShuffleQuestion: false,
        // Thông tin xáo đáp án chỉ tồn tại ở đề gốc phía server.
        answerShuffleInfo: null,
        parentQuestion: parentQuestion,
        childQuestions: children,
        answers: answers,
      );
    }

    // Dựng trước một bản KHÔNG kèm câu con để gắn làm `parentQuestion` cho các
    // câu con: question_content.dart đọc parentQuestion.questionContent để
    // hiển thị đoạn văn đọc hiểu. Bản rút gọn này tránh nhân bản cả cây câu
    // hỏi (và tránh tham chiếu vòng cha ↔ con) khi đề lồng nhiều tầng.
    final selfWithoutChildren = build(<OriginalExamPaperDetailDto>[]);

    final children = _asJsonObjectList(json['childQuestions'])
        .map(
          (child) => OriginalExamPaperDetailDto.fromQuestionStructureJson(
            child,
            parentQuestion: selfWithoutChildren,
          ),
        )
        .toList();

    return children.isEmpty ? selfWithoutChildren : build(children);
  }

  Map<String, dynamic> toJson() {
    return {
      'originalExamPaperDetailId': originalExamPaperDetailId,
      'order': order,
      'questionContent': questionContent,
      'correctAnswerIndex': correctAnswerIndex,
      'parentQuestionId': parentQuestionId,
      'chapterId': chapterId,
      'questionType': questionType,
      'difficultyLevel': difficultyLevel,
      'isAudio': isAudio,
      'maxListenCount': maxListenCount,
      'canShuffleQuestion': canShuffleQuestion,
      'answerShuffleInfo': answerShuffleInfo,
      'parentQuestion': parentQuestion?.toJson(),
      'childQuestions': childQuestions.map((c) => c.toJson()).toList(),
      'answers': answers.map((a) => a.toJson()).toList(),
    };
  }
}

class AnswerDto {
  final String answerId;
  final int order;
  final String answerContent;
  final bool isCorrect;
  final bool canShuffleAnswer;
  final String originalExamPaperDetailId;

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
      answerId: _asString(json['answerId']),
      order: _asInt(json['order']),
      answerContent: _asString(json['answerContent']),
      // Đề trả cho sinh viên không kèm cờ đáp án đúng → mặc định false.
      isCorrect: _asBool(json['isCorrect']),
      canShuffleAnswer: _asBool(json['canShuffleAnswer']),
      originalExamPaperDetailId: _asString(json['originalExamPaperDetailId']),
    );
  }

  /// Dựng đáp án từ `AnswerStructureDto` phía C# (khoá `answers` trong
  /// `questionStructures`). DTO đó chỉ có answerId, order, answerContent,
  /// originalExamPaperDetailId, canShuffleAnswer — KHÔNG có isCorrect, đúng
  /// theo thiết kế "không lộ đáp án cho sinh viên".
  factory AnswerDto.fromAnswerStructureJson(Map<String, dynamic> json) {
    return AnswerDto(
      answerId: _asString(json['answerId']),
      order: _asInt(json['order']),
      answerContent: _asString(json['answerContent']),
      // Không có trong AnswerStructureDto — luôn false ở luồng làm bài.
      isCorrect: false,
      // Đáp án đã được backend xáo sẵn; giữ cờ nếu backend gửi, mặc định false.
      canShuffleAnswer: _asBool(json['canShuffleAnswer']),
      originalExamPaperDetailId: _asString(json['originalExamPaperDetailId']),
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

  /// Đọc phản hồi vào thi của cả 2 endpoint:
  ///   - `GET  api/student/resume-quiz/{id}`      → { studentSession, examPaper, originalExamPaper }
  ///   - `POST api/student/create-exam-session`   → { success, code, studentSession, examPaper, originalExamPaper }
  ///
  /// Backend hiện tại LUÔN trả `originalExamPaper = null` và đặt đề thi thật
  /// ở khoá `examPaper` (StudentController.cs:193-200 và 682-691). Trước đây
  /// hàm này parse thẳng `originalExamPaper` nên ném TypeError và cả luồng
  /// vào thi hỏng dù server đã tạo phiên thành công.
  ///
  /// Thứ tự ưu tiên: `examPaper` → `originalExamPaper` (tương thích ngược với
  /// phản hồi kiểu cũ và với dữ liệu do chính `toJson()` sinh ra).
  factory StartExamResponseDto.fromJson(Map<String, dynamic> json) {
    final studentSessionJson = _asJsonObject(json['studentSession']);
    if (studentSessionJson == null) {
      // Không có phiên thi thì không thể làm bài — để lỗi nổi lên rõ ràng
      // thay vì dựng một phiên rỗng rồi hỏng ở màn thi.
      throw FormatException(
        'StartExamResponseDto: phản hồi vào thi thiếu "studentSession". '
        'Các khoá nhận được: ${json.keys.toList()}',
      );
    }

    final examPaperJson = _asJsonObject(json['examPaper']);
    final originalExamPaperJson = _asJsonObject(json['originalExamPaper']);

    final OriginalExamPaperDto examPaper;
    if (examPaperJson != null) {
      // Dạng backend đang trả.
      examPaper = OriginalExamPaperDto.fromStudentExamPaperJson(
        examPaperJson,
        studentSessionJson: studentSessionJson,
      );
    } else if (originalExamPaperJson != null) {
      // Dạng cũ / dữ liệu cache cục bộ.
      examPaper = OriginalExamPaperDto.fromJson(originalExamPaperJson);
    } else {
      // Cả hai khoá đều rỗng → không dựng nổi đề. Ném lỗi rõ ràng thay vì trả
      // về đề rỗng khiến màn thi im lặng hiện "không có câu hỏi".
      throw FormatException(
        'StartExamResponseDto: phản hồi vào thi không có đề thi — cả '
        '"examPaper" lẫn "originalExamPaper" đều null/không hợp lệ. '
        'Các khoá nhận được: ${json.keys.toList()}',
      );
    }

    return StartExamResponseDto(
      studentSession: StudentExamSessionCacheDto.fromJson(studentSessionJson),
      originalExamPaper: examPaper,
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
  final String studentExamSessionId;
  final DateTime? startTime;
  final DateTime? endTime;
  final String studentCode;

  /// Họ / tên / họ tên đầy đủ của thí sinh.
  ///
  /// Cần cho `ReportViolation` qua SignalR: hub bỏ qua IM LẶNG mọi báo cáo
  /// thiếu `firstName`/`lastName` (NotificationHub.cs:148-156).
  final String studentFirstName;
  final String studentLastName;
  final String studentFullName;

  final String studentId;
  final String examSessionSubjectId;
  final String? shuffledExamPaperId;
  final int extraMinutes;
  final String? reasonForExtra;
  final int remainingMinutes;
  final int? correctAnswers;
  final int? totalQuestions;
  final double score;
  final bool isCompleted;
  final String? studentAnswersString;
  final String? examRoomId;

  final String subjectName;
  final String roomName;
  final String examSessionName;
  final int duration;

  final DateTime examSessionStartTime;
  final DateTime examSessionEndTime;

  /// Ca thi không giới hạn thời gian. Web đọc cờ này để KHÔNG chạy đồng hồ
  /// (`useQuiz.ts:383-384`); thiếu nó thì mobile đếm ngược rồi tự nộp bài oan.
  final bool isUnlimitedTime;

  StudentExamSessionCacheDto({
    required this.studentExamSessionId,
    this.startTime,
    this.endTime,
    required this.studentCode,
    this.studentFirstName = '',
    this.studentLastName = '',
    this.studentFullName = '',
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
    this.isUnlimitedTime = false,
    required this.examSessionStartTime,
    required this.examSessionEndTime,
  });

  factory StudentExamSessionCacheDto.fromJson(Map<String, dynamic> json) {
    return StudentExamSessionCacheDto(
      studentExamSessionId: _asString(json['studentExamSessionId']),
      startTime: _asDateTimeOrNull(json['startTime']),
      endTime: _asDateTimeOrNull(json['endTime']),
      // Backend serialize property `UserCode` -> JSON `userCode`. Trước đây
      // mobile đọc `studentCode` nên trường này LUÔN rỗng; giữ lại khoá cũ làm
      // phương án dự phòng cho các endpoint khác.
      studentCode: _asString(json['userCode'] ?? json['studentCode']),
      studentFirstName: _asString(json['studentFirstName']),
      studentLastName: _asString(json['studentLastName']),
      studentFullName: _asString(json['studentFullName']),
      studentId: _asString(json['studentId']),
      examSessionSubjectId: _asString(json['examSessionSubjectId']),
      shuffledExamPaperId: _asStringOrNull(json['shuffledExamPaperId']),
      extraMinutes: _asInt(json['extraMinutes']),
      reasonForExtra: _asStringOrNull(json['reasonForExtra']),
      remainingMinutes: _asInt(json['remainingMinutes']),
      correctAnswers: _asIntOrNull(json['correctAnswers']),
      totalQuestions: _asIntOrNull(json['totalQuestions']),
      score: _asDouble(json['score']),
      isCompleted: _asBool(json['isCompleted']),
      studentAnswersString: _asString(json['studentAnswersString']),
      examRoomId: _asStringOrNull(json['examRoomId']),
      subjectName: _asString(json['subjectName']),
      roomName: _asString(json['roomName']),
      examSessionName: _asString(json['examSessionName']),
      duration: _asInt(json['duration']),
      isUnlimitedTime: _asBool(json['isUnlimitedTime']),
      // Ngày giờ hỏng/thiếu → mốc epoch, giữ nguyên hành vi cũ và không ném lỗi.
      examSessionStartTime:
          _asDateTimeOrNull(json['examSessionStartTime']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      examSessionEndTime:
          _asDateTimeOrNull(json['examSessionEndTime']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studentExamSessionId': studentExamSessionId,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'userCode': studentCode,
      'studentCode': studentCode,
      'studentFirstName': studentFirstName,
      'studentLastName': studentLastName,
      'studentFullName': studentFullName,
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
      'isUnlimitedTime': isUnlimitedTime,
      'examSessionStartTime': examSessionStartTime.toIso8601String(),
      'examSessionEndTime': examSessionEndTime.toIso8601String(),
    };
  }
}
