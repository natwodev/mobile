import '../l10n/app_l10n.dart';

/// Dịch mã lỗi máy do backend trả về sang thông báo theo ngôn ngữ đang chọn.
///
/// Backend (csharp_manage) luôn trả `code` dạng SCREAMING_SNAKE_CASE và khối
/// `errors` chứa mã, không chứa câu chữ — phần dịch nằm ở client. Bộ khoá dưới
/// bám theo `frontend_manage/src/locales/*/translation.json` để app mobile và
/// web nói cùng một thứ tiếng.
///
/// Lớp này bị gọi từ tầng service (không có BuildContext) nên tra chuỗi qua
/// [AppL10n.current] thay vì `AppLocalizations.of(context)`.
class ErrorMessageHelper {
  /// Trả về câu đã dịch cho [code]; mã lạ thì dùng [fallback].
  static String translate(String? code, {required String fallback}) {
    if (code == null || code.trim().isEmpty) return fallback;

    final trimmed = code.trim();
    final message = _lookup(trimmed);
    if (message != null) return message;

    // Mã lạ nhưng đã là câu chữ (không phải SCREAMING_SNAKE_CASE) thì hiển thị
    // luôn thay vì nuốt mất thông tin.
    final isMachineCode = RegExp(r'^[A-Z][A-Z0-9_]+$').hasMatch(trimmed);
    return isMachineCode ? fallback : trimmed;
  }

  /// Ánh xạ mã lỗi -> chuỗi đã dịch. Trả `null` nếu không biết mã.
  static String? _lookup(String code) {
    final l10n = AppL10n.current;
    switch (code) {
      // Auth
      case 'AUTH_INVALID_CREDENTIALS':
        return l10n.msgAuthInvalidCredentials;
      case 'AUTH_INVALID_DATA':
        return l10n.msgAuthInvalidData;
      case 'AUTH_ACCOUNT_LOCKED':
        return l10n.msgAuthAccountLocked;
      case 'USER_TOKEN_MISSING':
        return l10n.msgUserTokenMissing;

      // Profile
      case 'USER_UPDATE_FAILED':
        return l10n.msgUserUpdateFailed;
      case 'USER_PROFILE_UPDATE_SUCCESS':
        return l10n.msgUserProfileUpdateSuccess;
      case 'STUDENT_PROFILE_NOT_FOUND':
        return l10n.msgStudentProfileNotFound;
      case 'STUDENT_PROFILE_FETCH_FAILED':
        return l10n.msgStudentProfileFetchFailed;

      // Ảnh đại diện
      case 'USER_AVATAR_FILE_REQUIRED':
        return l10n.msgUserAvatarFileRequired;
      case 'USER_AVATAR_UPLOAD_FAILED':
        return l10n.msgUserAvatarUploadFailed;
      case 'USER_AVATAR_UPDATE_FAILED':
        return l10n.msgUserAvatarUpdateFailed;

      // Lịch sử làm bài / xem lại
      case 'STUDENT_EXAM_HISTORY_FETCH_FAILED':
        return l10n.msgExamHistoryFetchFailed;
      case 'EXAM_REVIEW_NOT_ALLOWED':
        return l10n.msgExamReviewNotAllowed;
      case 'EXAM_REVIEW_OPEN_FAILED':
        return l10n.msgExamReviewOpenFailed;

      // Đổi mật khẩu
      case 'USER_CHANGE_PASSWORD_FAILED':
        return l10n.msgUserChangePasswordFailed;
      case 'USER_CHANGE_PASSWORD_SUCCESS':
        return l10n.msgUserChangePasswordSuccess;
      case 'USER_CHANGE_PASSWORD_SERVER_ERROR':
        return l10n.msgUserChangePasswordServerError;
      case 'VALIDATION_PASSWORD_CURRENT_INCORRECT':
        return l10n.msgValidationPasswordCurrentIncorrect;
      case 'VALIDATION_PASSWORD_TOO_SHORT':
        return l10n.msgValidationPasswordTooShort;
      case 'VALIDATION_PASSWORD_REQUIRES_DIGIT':
        return l10n.msgValidationPasswordRequiresDigit;
      case 'VALIDATION_PASSWORD_REQUIRES_LOWER':
        return l10n.msgValidationPasswordRequiresLower;
      case 'VALIDATION_PASSWORD_REQUIRES_UPPER':
        return l10n.msgValidationPasswordRequiresUpper;
      case 'VALIDATION_PASSWORD_REQUIRES_SYMBOL':
        return l10n.msgValidationPasswordRequiresSymbol;
      case 'VALIDATION_PASSWORD_REQUIRES_UNIQUE_CHARS':
        return l10n.msgValidationPasswordRequiresUniqueChars;

      // Tra ca thi theo mã (GET api/ExamSessionSubject/cores/{core})
      case 'EXAM_SESSION_CORE_REQUIRED':
        return l10n.msgExamSessionCoreRequired;
      case 'EXAM_SESSION_NOT_FOUND':
        return l10n.msgExamSessionNotFound;
      case 'EXAM_SESSION_FETCH_FAILED':
        return l10n.msgExamSessionFetchFailed;

      // Tạo phiên thi (POST api/student/create-exam-session)
      //
      // STUDENT_EXAM_SESSION_CREATE_FAILED gộp chung mọi lý do nghiệp vụ (chưa
      // tới giờ, hết giờ, vào muộn, hết chỗ, phòng bị khoá, hết lượt thi) và
      // không kèm message, nên câu dịch phải liệt kê khả năng thay vì khẳng
      // định một nguyên nhân.
      case 'STUDENT_LOCATION_REQUIRED':
        return l10n.msgStudentLocationRequired;
      case 'STUDENT_EXAM_SESSION_CREATE_FAILED':
        return l10n.msgStudentExamSessionCreateFailed;
      case 'STUDENT_EXAM_SESSION_CREATE_SERVER_ERROR':
        return l10n.msgStudentExamSessionCreateServerError;

      // Validation chung
      case 'VALIDATION_INVALID':
        return l10n.msgValidationInvalid;
      case 'VALIDATION_FIELD_INVALID':
        return l10n.msgValidationFieldInvalid;
      case 'VALIDATION_FIELD_REQUIRED':
        return l10n.msgValidationFieldRequired;
      case 'VALIDATION_MIN_LENGTH':
        return l10n.msgValidationMinLength;
      case 'VALIDATION_MAX_LENGTH':
        return l10n.msgValidationMaxLength;
      case 'VALIDATION_COMPARE_MISMATCH':
        return l10n.msgValidationCompareMismatch;
      case 'VALIDATION_EMAIL_INVALID':
        return l10n.msgValidationEmailInvalid;
      case 'VALIDATION_EMAIL_DUPLICATED':
        return l10n.msgValidationEmailDuplicated;
      case 'VALIDATION_PHONE_INVALID':
        return l10n.msgValidationPhoneInvalid;
      case 'VALIDATION_USERNAME_DUPLICATED':
        return l10n.msgValidationUsernameDuplicated;
      case 'VALIDATION_USER_NOT_FOUND':
        return l10n.msgValidationUserNotFound;
      case 'VALIDATION_TOKEN_INVALID':
        return l10n.msgValidationTokenInvalid;

      default:
        return null;
    }
  }
}
