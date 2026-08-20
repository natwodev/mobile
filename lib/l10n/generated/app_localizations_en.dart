// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'HUTECH Campus Info';

  @override
  String get authAccountTitle => 'Account';

  @override
  String get authAvatarChangeTitle => 'Profile photo';

  @override
  String get authAvatarFromCamera => 'Take a photo';

  @override
  String get authAvatarFromGallery => 'Choose from library';

  @override
  String get authAvatarUpdateSuccess => 'Profile photo updated.';

  @override
  String get authChangePasswordFailed => 'Could not change your password';

  @override
  String get authChangePasswordSuccess =>
      'Your password has been changed successfully.';

  @override
  String get authChangePasswordTitle => 'Change password';

  @override
  String get authConfirmPasswordHint => 'Re-enter your new password...';

  @override
  String get authConfirmPasswordLabel => 'Confirm new password';

  @override
  String get authConfirmPasswordMismatch =>
      'The confirmation password does not match';

  @override
  String get authConfirmPasswordRequired => 'Please confirm your new password';

  @override
  String get authCurrentPasswordHint => 'Enter your current password...';

  @override
  String get authCurrentPasswordLabel => 'Current password';

  @override
  String get authCurrentPasswordRequired =>
      'Please enter your current password';

  @override
  String get authDateOfBirthLabel => 'Date of birth';

  @override
  String get authEdit => 'Edit';

  @override
  String get authEditProfileTitle => 'Edit personal information';

  @override
  String get authEmailHint => 'Enter your email...';

  @override
  String get authEmailInvalid => 'Invalid email address';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authFullNameHint => 'Enter your full name...';

  @override
  String get authFullNameLabel => 'Full name';

  @override
  String get authFullNameRequired => 'Please enter your full name';

  @override
  String get authGenderFemale => 'Female';

  @override
  String get authGenderLabel => 'Gender';

  @override
  String get authGenderMale => 'Male';

  @override
  String get authLoginSubtitle =>
      'Enter your student ID and password to sign in';

  @override
  String get authLoginTitle => 'Sign in';

  @override
  String get authLogout => 'Log out';

  @override
  String get authLogoutConfirmMessage =>
      'Are you sure you want to log out of this account?';

  @override
  String authLogoutFailed(String error) {
    return 'Log out failed: $error';
  }

  @override
  String get authNewPasswordHint => 'Enter your new password...';

  @override
  String get authNewPasswordLabel => 'New password';

  @override
  String get authNewPasswordRequired => 'Please enter your new password';

  @override
  String get authNewPasswordSameAsCurrent =>
      'The new password must be different from the current one';

  @override
  String get authNoName => 'No name yet';

  @override
  String get authNoStudentId => 'No student ID yet';

  @override
  String get authNotAvailable => 'Not available';

  @override
  String get authNotSelected => 'Not selected';

  @override
  String get authPasswordHint => 'Enter your password...';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authPasswordMinLength => 'Password must be at least 6 characters';

  @override
  String get authPasswordRequired => 'Please enter your password';

  @override
  String get authPersonalInfoTitle => 'Personal information';

  @override
  String get authPhoneHint => 'Enter your phone number...';

  @override
  String get authPhoneLabel => 'Phone number';

  @override
  String get authPhoneMinLength => 'Phone number must be at least 9 digits';

  @override
  String get authPickDateOfBirth => 'Select date of birth';

  @override
  String get authProfileLoadFailed => 'Could not load your profile.';

  @override
  String get authProfileLoadFailedRetry =>
      'Could not load your profile. Please try again.';

  @override
  String get authProfileUpdateFailed => 'Could not update your profile';

  @override
  String get authProfileUpdateSuccess =>
      'Your profile has been updated successfully.';

  @override
  String get authSaveChanges => 'Save changes';

  @override
  String get authSelect => 'Select';

  @override
  String get authStudentIdHelper =>
      'Your student ID is issued by the university and cannot be edited';

  @override
  String get authStudentIdLabel => 'Student ID';

  @override
  String get authUsernameHint => 'Enter your username or student ID...';

  @override
  String get authUsernameLabel => 'Username / Student ID';

  @override
  String get authUsernameRequired => 'Please enter your username or student ID';

  @override
  String get clearCacheAlreadyEmpty => 'The cache is already empty';

  @override
  String get clearCacheConfirm => 'Clear now';

  @override
  String clearCacheDone(String size) {
    return 'Cleared $size of cache';
  }

  @override
  String clearCacheFailed(String error) {
    return 'Could not clear the cache: $error';
  }

  @override
  String get clearCacheMessage =>
      'Remove cached images and downloaded temp files. You stay signed in and keep your exams and settings.';

  @override
  String clearCacheSize(String size) {
    return 'Currently using about $size';
  }

  @override
  String get clearCacheTitle => 'Clear cache';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonClose => 'Close';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonLoading => 'Loading...';

  @override
  String get commonNotUpdated => 'Not updated';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonSave => 'Save';

  @override
  String contactCopied(String value) {
    return 'Copied $value';
  }

  @override
  String get contactEmail => 'Send an email';

  @override
  String get contactHotline => 'Call the hotline';

  @override
  String contactOpenFailed(String value) {
    return 'Could not open: $value';
  }

  @override
  String get contactTitle => 'Contact support';

  @override
  String get contactWebsite => 'Open the website';

  @override
  String get deviceInfoAppName => 'App name';

  @override
  String get deviceInfoAppSection => 'Application';

  @override
  String get deviceInfoBrand => 'Manufacturer';

  @override
  String get deviceInfoBuildNumber => 'Build';

  @override
  String get deviceInfoCopied => 'Device information copied';

  @override
  String get deviceInfoCopy => 'Copy information';

  @override
  String get deviceInfoDeviceSection => 'Device';

  @override
  String get deviceInfoDeviceType => 'Device type';

  @override
  String get deviceInfoEmulator => 'Emulator';

  @override
  String get deviceInfoLanguage => 'App language';

  @override
  String get deviceInfoLoadFailed => 'Could not read device information';

  @override
  String get deviceInfoModel => 'Model';

  @override
  String get deviceInfoOs => 'Operating system';

  @override
  String get deviceInfoPackageName => 'Package name';

  @override
  String get deviceInfoPhysical => 'Physical device';

  @override
  String get deviceInfoScreen => 'Screen';

  @override
  String get deviceInfoTitle => 'Device information';

  @override
  String get deviceInfoVersion => 'Version';

  @override
  String get examAllAnswersSaved => 'All answers have been saved.';

  @override
  String examAnsweredProgress(int answered, int total) {
    return 'Answered: $answered/$total';
  }

  @override
  String examAutoSubmitUnsavedWarning(int count) {
    return '$count answer(s) could not be saved to the server and may not be graded.';
  }

  @override
  String get examCannotExitWarning =>
      'You cannot leave while the exam is in progress! Please submit your exam to finish.';

  @override
  String get examCodeAppBarTitle => 'Take Exam';

  @override
  String get examCodeCheckingButton => 'Checking...';

  @override
  String get examCodeCodeLabel => 'Session Code';

  @override
  String get examCodeConfirmMessage =>
      'Are you sure you want to start the exam? Once you enter, the exam timer will begin.';

  @override
  String get examCodeConfirmTitle => 'Confirm Exam Entry';

  @override
  String get examCodeCreatingSession => 'Creating exam session...';

  @override
  String get examCodeDurationLabel => 'Duration';

  @override
  String examCodeDurationMinutes(int minutes) {
    return '$minutes mins';
  }

  @override
  String get examCodeEmptyError => 'Please enter exam code';

  @override
  String get examCodeEndTimeLabel => 'End Time';

  @override
  String get examCodeEnterRoomButton => 'Find Session';

  @override
  String get examCodeErrorTitle => 'Could not start the exam';

  @override
  String get examCodeFieldHint => 'Letters, numbers and hyphens only';

  @override
  String get examCodeHeading => 'Take Exam';

  @override
  String get examCodeHelpText =>
      'Exam code can only contain letters (A-Z), numbers (0-9) and hyphens (-). Special characters will be automatically removed.';

  @override
  String get examCodeLocationRequiredNotice =>
      'This exam session requires a GPS location. The mobile app cannot send your location yet, so you will most likely not be able to enter from here.';

  @override
  String get examCodeSessionInfoTitle => 'Exam Session Info';

  @override
  String get examCodeStartButton => 'Enter Exam';

  @override
  String get examCodeStartTimeLabel => 'Start Time';

  @override
  String get examCodeSubjectLabel => 'Subject';

  @override
  String get examCodeSubtitle =>
      'Enter the exam code provided by your teacher to begin.';

  @override
  String get examDefaultTitle => 'Exam';

  @override
  String get examEnterOverlayHint => 'Please don\'t close the app.';

  @override
  String get examEnterOverlayTitle => 'Entering the exam room';

  @override
  String get examInfoQuestionsLabel => 'Questions';

  @override
  String get examInfoTimeLabel => 'Time';

  @override
  String examLoadError(String error) {
    return 'Error: $error';
  }

  @override
  String get examLocationDenied =>
      'You haven\'t allowed the app to access your location. Grant the permission and try again.';

  @override
  String get examLocationDeniedForever =>
      'Location access is blocked. Open Settings to grant the permission again.';

  @override
  String get examLocationGetting => 'Getting your location';

  @override
  String get examLocationGettingHint =>
      'This exam requires your location. Move to an open area for a faster fix.';

  @override
  String get examLocationServiceDisabled =>
      'Location services are off. Turn them on and try again to start the exam.';

  @override
  String get examLocationTimeout =>
      'Couldn\'t get your location. Move to an open area or check GPS, then try again.';

  @override
  String get examLookupOverlayTitle => 'Looking up the exam';

  @override
  String get examNoData => 'No exam data available';

  @override
  String get examNoQuestions => 'This exam has no questions';

  @override
  String get examNoticeDefaultMessage =>
      'If you scored high, congratulations! If it did not go well, do not be sad, there is always a next time. Well, is there really a next time :>>>';

  @override
  String get examPartialLabel => 'Partly done';

  @override
  String get examPinQuestion => 'Pin';

  @override
  String get examPinnedHint => 'Pin a question to revisit it later';

  @override
  String get examPinnedLabel => 'Pinned';

  @override
  String examQuestionProgress(String label, int total) {
    return 'Question $label/$total';
  }

  @override
  String get examRealtimeAutoSubmittedTitle =>
      'Your exam was auto-submitted for violations';

  @override
  String get examRealtimeBlockedMessage =>
      'The proctor ended your exam session. Your answers have been submitted.';

  @override
  String get examRealtimeBlockedTitle => 'You were blocked from this exam';

  @override
  String examRealtimeExtraTimeAdded(int minutes) {
    return 'The proctor added $minutes minutes';
  }

  @override
  String examRealtimeExtraTimeSubtracted(int minutes) {
    return 'The proctor removed $minutes minutes';
  }

  @override
  String get examRealtimeTeacherMessageTitle => 'Message from the proctor';

  @override
  String get examRealtimeTeacherSubmittedTitle =>
      'The proctor submitted your exam';

  @override
  String examRealtimeViolationWarningMessage(int count, int threshold) {
    return 'You have $count/$threshold rule violations. Further violations may auto-submit your exam or suspend you.';
  }

  @override
  String get examRealtimeViolationWarningTitle => 'Violation warning';

  @override
  String get examRealtimeViolationWarningUnderstood => 'I understand';

  @override
  String get examResultHomeButton => 'Back to home';

  @override
  String get examResultPendingSubmitFailed =>
      'The server did not accept your submission';

  @override
  String get examResultPendingSubmitFailedHint =>
      'Your exam was closed before the submission got through. Tell the proctor right away.';

  @override
  String examResultPendingSubmitHint(String time) {
    return 'Your answers were saved on this device at $time. The app will send them as soon as you are back online — nothing else for you to do.';
  }

  @override
  String get examResultPendingSubmitTitle =>
      'Waiting for a connection to submit';

  @override
  String get examResultTitle => 'Exam result';

  @override
  String get examSavingIndicator => 'Saving...';

  @override
  String get examScoreCommentAverage => 'Average!';

  @override
  String get examScoreCommentExcellent => 'Excellent!';

  @override
  String get examScoreCommentFair => 'Good!';

  @override
  String get examScoreCommentGood => 'Very good!';

  @override
  String get examScoreCommentNeedsImprovement => 'Keep trying!';

  @override
  String get examScoreLabel => 'YOUR SCORE';

  @override
  String get examSubmitButton => 'Submit';

  @override
  String get examSubmitDialogAllAnswered => 'You have answered every question.';

  @override
  String get examSubmitDialogAnsweredLabel => 'Answered';

  @override
  String get examSubmitDialogConfirmQuestion =>
      'Are you sure you want to submit?';

  @override
  String get examSubmitDialogTitle => 'Submit exam';

  @override
  String get examSubmitDialogUnansweredLabel => 'Unanswered';

  @override
  String examSubmitDialogUnansweredWarning(int count) {
    return '$count questions are still unanswered. You cannot come back to change them after submitting.';
  }

  @override
  String examSubmitDialogUnsavedWarning(int count) {
    return '⚠️ $count question(s) could not be saved to the server. If you submit now, they may not be graded.';
  }

  @override
  String examSubmitError(String error) {
    return 'An error occurred while submitting: $error';
  }

  @override
  String get examSubmitFailedMessage =>
      'The server has not recorded your submission. Your saved answers are still there — check your connection, then tap Retry.';

  @override
  String get examSubmitFailedTitle => 'Error submitting exam';

  @override
  String get examSubmitOverlayHint =>
      'Please keep the app open until this finishes.';

  @override
  String get examSubmitOverlayTitle => 'Submitting';

  @override
  String get examSubmitQueuedMessage =>
      'You are offline, so the exam has not been sent yet. Your submission time is recorded and the app will send it automatically once you are back online.';

  @override
  String get examSubmitQueuedTitle => 'Submission time recorded';

  @override
  String get examSubmitSuccess => 'Exam submitted successfully';

  @override
  String get examTimeUpBannerTitle => 'Time is up!';

  @override
  String get examTimeUpLockedHint =>
      'The exam is locked, you can no longer change your answers.';

  @override
  String get examTimeUpSavingAnswers => 'Saving your remaining answers...';

  @override
  String get examTimeUpSubmitting => 'Submitting your exam automatically...';

  @override
  String get examTimeUpToastMessage =>
      'Your exam is being submitted automatically. Please stay in the app.';

  @override
  String get examOfflineBannerTitle => 'Connection lost';

  @override
  String get examOfflineBannerHint =>
      'Your answers are stored on this device and will upload automatically once you are back online.';

  @override
  String get examOfflineRetryFailed =>
      'Still not sent. Check your connection and try again.';

  @override
  String get examUnlimitedTime => 'Unlimited';

  @override
  String get examUnpinQuestion => 'Unpin';

  @override
  String get feedbackAttachNote =>
      'Device details and app version are attached automatically to speed up debugging.';

  @override
  String get feedbackContactHint => 'So support can get back to you';

  @override
  String get feedbackContactLabel => 'Your email / phone number (optional)';

  @override
  String get feedbackContentHint =>
      'Describe the bug you hit, or what the app could do better...';

  @override
  String get feedbackContentLabel => 'Message';

  @override
  String get feedbackContentRequired => 'Enter a message before sending';

  @override
  String feedbackMailFallback(String email) {
    return 'No email app found. The message was copied — please send it to $email.';
  }

  @override
  String get feedbackSend => 'Send';

  @override
  String get feedbackTitle => 'Report a bug / feedback';

  @override
  String get feedbackTypeBug => 'Bug report';

  @override
  String get feedbackTypeIdea => 'Feedback';

  @override
  String historyBadgeExtraMinutes(int count) {
    return '+$count min';
  }

  @override
  String historyBadgeViolations(int count) {
    return '$count violations';
  }

  @override
  String get historyBlockedClosed => 'The review period has ended';

  @override
  String get historyBlockedNotAllowed =>
      'This exam session does not allow review';

  @override
  String get historyBlockedNotCompleted =>
      'This exam has been reopened for a retake';

  @override
  String historyBlockedNotOpenYet(String time) {
    return 'Review opens at $time';
  }

  @override
  String get historyBlockedNotOpenYetGeneric =>
      'The review period has not started yet';

  @override
  String get historyColCorrect => 'Correct answers';

  @override
  String get historyColDuration => 'Time spent';

  @override
  String get historyColExamDate => 'Exam date';

  @override
  String get historyColScore => 'Score';

  @override
  String historyDurationMinutes(int count) {
    return '$count min';
  }

  @override
  String get historyEmptyDesc =>
      'You have not completed any exam yet. Submitted exams will show up here.';

  @override
  String get historyEmptyTitle => 'No exams yet';

  @override
  String get historyGoToExam => 'Take an exam';

  @override
  String get historyLoadFailed => 'Could not load your exam history';

  @override
  String get historyOpenFailed => 'Could not open this exam';

  @override
  String get historyOpening => 'Opening...';

  @override
  String get historyReview => 'Review';

  @override
  String get historyReviewWithAnswerKey =>
      'Review the exam with correct answers';

  @override
  String get historyReviewWithoutAnswerKey =>
      'Review the exam without correct answers';

  @override
  String get historyReviewWithoutQuestionDetail =>
      'Review right/wrong answers only, without the question content';

  @override
  String get historyStatAverage => 'Average score';

  @override
  String get historyStatBest => 'Best score';

  @override
  String get historyStatTotal => 'Exams taken';

  @override
  String get historyStatViolations => 'Total violations';

  @override
  String get historySubtitle => 'Exams you have completed';

  @override
  String get historyTitle => 'Exam History';

  @override
  String get historyUnknownSubject => 'Unknown subject';

  @override
  String get homeNavAccount => 'Account';

  @override
  String get homeNavHistory => 'History';

  @override
  String get homeNavHome => 'Home';

  @override
  String get homeNewsEmpty => 'No news yet.';

  @override
  String get homeNewsError => 'Couldn\'t load education news.';

  @override
  String get homeNewsOpenFailed => 'Couldn\'t open the article.';

  @override
  String get homeNewsRetry => 'Try again';

  @override
  String get homeNewsSource => 'Source: VnExpress';

  @override
  String homeNewsTimeDays(int days) {
    return '${days}d ago';
  }

  @override
  String homeNewsTimeHours(int hours) {
    return '${hours}h ago';
  }

  @override
  String get homeNewsTimeJustNow => 'Just now';

  @override
  String homeNewsTimeMinutes(int minutes) {
    return '${minutes}m ago';
  }

  @override
  String get homeNewsTitle => 'Education news';

  @override
  String get homeQrExamCreatedAt => 'Created on';

  @override
  String get homeQrExamDescription => 'Description';

  @override
  String get homeQrExamDuration => 'Duration';

  @override
  String homeQrExamDurationMinutes(String minutes) {
    return '$minutes minutes';
  }

  @override
  String get homeQrExamFallbackTitle => 'Exam';

  @override
  String get homeQrExamInfoLabel => 'Exam information';

  @override
  String get homeQrExamSubject => 'Subject';

  @override
  String get homeQrInvalidTitle => 'Invalid QR code';

  @override
  String get homeQrMissingExamCode => 'No exam paper ID found in the QR code.';

  @override
  String get homeQrScanTitle => 'Scan exam QR code';

  @override
  String get homeQrStartExamFailed =>
      'Could not start the exam from this QR code.\nPlease try again.';

  @override
  String get homeQrWrongFormatMessage =>
      'This QR code is not in the exam format.\nPlease scan a valid QR code.';

  @override
  String get homeQuickExamButton => 'Quick test';

  @override
  String get homeScanExamQrButton => 'Scan exam code';

  @override
  String get msgAuthAccountLocked => 'This account is locked.';

  @override
  String get msgAuthInvalidCredentials => 'Incorrect account or password.';

  @override
  String get msgAuthInvalidData => 'Invalid data.';

  @override
  String get msgAvatarFileTooLarge =>
      'The image is larger than 10MB. Please pick a smaller one.';

  @override
  String get msgAvatarFormatUnsupported =>
      'Only JPG, PNG, GIF, WEBP or BMP images are accepted.';

  @override
  String get msgAvatarUploadFailed => 'Could not update the profile photo.';

  @override
  String get msgChangePasswordFailed => 'Could not change your password';

  @override
  String msgErrorWithDetail(String error) {
    return 'Error: $error';
  }

  @override
  String get msgExamDataUnreadable =>
      'The server accepted the request but the app could not read the exam data. Do not retry repeatedly — each entry may consume one exam attempt. Please contact your teacher or technical support.';

  @override
  String get msgExamHistoryFetchFailed => 'Could not load your exam history.';

  @override
  String get msgExamReviewNotAllowed =>
      'This exam is not available for review.';

  @override
  String get msgExamReviewOpenFailed =>
      'The server failed to open this exam. Please try again.';

  @override
  String get msgExamSessionCoreRequired =>
      'Please enter the exam session code.';

  @override
  String get msgExamSessionFetchFailed =>
      'Could not load the exam session. Please try again.';

  @override
  String get msgExamSessionNotFound => 'No exam session found with this code';

  @override
  String get msgLoginFailed => 'Sign in failed';

  @override
  String get msgLoginPasswordRequired => 'Please enter your password';

  @override
  String get msgLoginPasswordTooShort =>
      'Password must be at least 6 characters';

  @override
  String get msgLoginUserNameRequired =>
      'Please enter your username / student ID';

  @override
  String get msgProfileUpdateFailed => 'Could not update your profile';

  @override
  String get msgSaveAnswerFailed =>
      'The server did not accept this answer. Tell your proctor if it keeps happening.';

  @override
  String get msgSaveAnswerOffline =>
      'The connection dropped, so the answer has not been saved to the server.';

  @override
  String get msgSaveAnswerServerError =>
      'The server is having trouble, so the answer has not been saved.';

  @override
  String get msgServerUnreachable =>
      'Cannot reach the server. Please try again.';

  @override
  String get msgStudentExamSessionCreateFailed =>
      'You cannot enter this exam session. It may not have started yet, may already be over, may be full, or you may have used up all of your attempts.';

  @override
  String get msgStudentExamSessionCreateServerError =>
      'The server failed while creating the exam session. Please try again later.';

  @override
  String get msgStudentLocationRequired =>
      'This exam session requires a GPS location. The mobile app cannot send your location yet, so you cannot enter this session from here; please use a web browser on a computer.';

  @override
  String get msgStudentProfileFetchFailed =>
      'Could not load student information.';

  @override
  String get msgStudentProfileNotFound => 'Student information was not found.';

  @override
  String get msgSubmitExamRejected =>
      'The server did not accept this submission.';

  @override
  String get msgSubmitExamSuccess => 'Submitted successfully';

  @override
  String get msgUserAvatarFileRequired => 'No image was selected for upload.';

  @override
  String get msgUserAvatarUpdateFailed =>
      'The image uploaded but could not be attached to the account.';

  @override
  String get msgUserAvatarUploadFailed =>
      'The server did not receive the image. Please try again.';

  @override
  String get msgUserChangePasswordFailed => 'Could not change password.';

  @override
  String get msgUserChangePasswordServerError =>
      'Server error while changing password.';

  @override
  String get msgUserChangePasswordSuccess => 'Password changed successfully.';

  @override
  String get msgUserProfileUpdateSuccess => 'Profile updated successfully.';

  @override
  String get msgUserTokenMissing =>
      'Your session has expired. Please sign in again.';

  @override
  String get msgUserUpdateFailed => 'Could not update user information.';

  @override
  String get msgValidationCompareMismatch =>
      'Confirmation value does not match.';

  @override
  String get msgValidationEmailDuplicated => 'This email is already in use.';

  @override
  String get msgValidationEmailInvalid => 'Email is invalid.';

  @override
  String get msgValidationFieldInvalid => 'Field value is invalid.';

  @override
  String get msgValidationFieldRequired =>
      'Please fill in all required information.';

  @override
  String get msgValidationInvalid => 'Invalid data.';

  @override
  String get msgValidationMaxLength => 'Value exceeds the allowed length.';

  @override
  String get msgValidationMinLength =>
      'Value is shorter than the minimum length.';

  @override
  String get msgValidationPasswordCurrentIncorrect =>
      'Current password is incorrect.';

  @override
  String get msgValidationPasswordRequiresDigit =>
      'Password must contain at least one digit.';

  @override
  String get msgValidationPasswordRequiresLower =>
      'Password must contain at least one lowercase letter.';

  @override
  String get msgValidationPasswordRequiresSymbol =>
      'Password must contain at least one special character.';

  @override
  String get msgValidationPasswordRequiresUniqueChars =>
      'Password must use more distinct characters.';

  @override
  String get msgValidationPasswordRequiresUpper =>
      'Password must contain at least one uppercase letter.';

  @override
  String get msgValidationPasswordTooShort => 'Password is too short.';

  @override
  String get msgValidationPhoneInvalid => 'Phone number is invalid.';

  @override
  String get msgValidationTokenInvalid =>
      'The verification code is invalid or has expired.';

  @override
  String get msgValidationUserNotFound => 'User not found.';

  @override
  String get msgValidationUsernameDuplicated => 'This username already exists.';

  @override
  String get notificationsEmptyMessage =>
      'Notices about exam sessions, results and reminders from your teacher will show up here.';

  @override
  String get notificationsEmptyTitle => 'No notifications yet';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String questionAntiCheatAutoSubmitNotice(int max) {
    return 'Your exam will be submitted automatically after $max violations.';
  }

  @override
  String get questionAntiCheatLeftApp => 'You left the exam app.';

  @override
  String get questionAntiCheatOverlayDetected =>
      'Another app or window was detected on top of the exam app!';

  @override
  String get questionAntiCheatRotationBlockedSubtitle =>
      'The screen will rotate back automatically in a few seconds';

  @override
  String get questionAntiCheatRotationBlockedTitle =>
      'Do not rotate the screen!';

  @override
  String get questionAntiCheatRotationDetected =>
      'Screen rotation detected during the exam!';

  @override
  String get questionAntiCheatScreenRecordingDetected =>
      'Screen recording detected!';

  @override
  String get questionAntiCheatScreenshotDetected => 'Screenshot detected!';

  @override
  String get questionAntiCheatUnderstood => 'I understand';

  @override
  String questionAntiCheatViolationCount(int count, int max) {
    return 'Violations: $count/$max';
  }

  @override
  String get questionAntiCheatWarningTitle => 'Cheating warning!';

  @override
  String get questionBlankClear => 'Clear this blank';

  @override
  String questionBlankLabel(int number) {
    return 'Blank $number';
  }

  @override
  String questionBlankProgress(int filled, int total) {
    return 'Filled $filled/$total';
  }

  @override
  String get questionDifficultyEasy => 'Difficulty: Easy';

  @override
  String get questionDifficultyHard => 'Difficulty: Hard';

  @override
  String questionDifficultyLevel(int level) {
    return 'Difficulty $level';
  }

  @override
  String get questionDifficultyMedium => 'Difficulty: Medium';

  @override
  String get questionDifficultyVeryHard => 'Difficulty: Very hard';

  @override
  String questionDropdownHint(int number) {
    return '($number) Select...';
  }

  @override
  String get questionDropdownInstruction => 'Tap a blank to choose an answer:';

  @override
  String get questionDropdownPlaceholder => '-- Select --';

  @override
  String get questionFillBlankAllWordsUsed =>
      'All words in the bank have been used';

  @override
  String get questionFillBlankInstruction => 'Tap a word, then tap a blank:';

  @override
  String get questionHighlightClear => 'Clear selection';

  @override
  String get questionHighlightExtraHint => 'Enter additional text...';

  @override
  String get questionHighlightExtraLabel => 'Additional text (optional)';

  @override
  String get questionHighlightInstruction =>
      'Select the parts to highlight in the passage:';

  @override
  String questionHighlightSelectedCount(int count) {
    return '$count selected';
  }

  @override
  String get questionImageLoadFailed => 'Could not load the image';

  @override
  String get questionImageNoUrl => 'No image URL';

  @override
  String get questionLegendAnswered => 'Answered';

  @override
  String get questionLegendCurrent => 'Current';

  @override
  String get questionListTitle => 'Question list';

  @override
  String get questionMatchingColumnA => 'Column A';

  @override
  String get questionMatchingColumnB => 'Column B';

  @override
  String get questionMatchingEmptySlot => 'Not linked';

  @override
  String get questionMatchingInstruction =>
      'Instructions: Tap an item in Column A, then tap the matching item in Column B to link them.';

  @override
  String questionMatchingLinkedCount(int linked, int total) {
    return 'Linked $linked/$total';
  }

  @override
  String get questionMatchingPickColumnAFirst =>
      'Pick an item in column A first';

  @override
  String get questionMultipleChoiceInstruction => 'Select one or more answers:';

  @override
  String get questionNext => 'Next';

  @override
  String questionNumberOfTotal(String label, int total) {
    return 'Question $label / $total';
  }

  @override
  String get questionOrderingInstruction =>
      'Drag the handles on the right to arrange the items in the correct order:';

  @override
  String get questionPrevious => 'Previous';

  @override
  String get questionReadingPassageLabel => 'Passage / Context:';

  @override
  String get questionShortAnswerHint => 'Enter your answer here...';

  @override
  String get questionShortAnswerInstruction =>
      'Type your answer for each blank:';

  @override
  String get questionSingleChoiceInstruction => 'Select one answer:';

  @override
  String get questionStatAnswered => 'Answered';

  @override
  String get questionStatTotal => 'Total';

  @override
  String get questionStatUnanswered => 'Unanswered';

  @override
  String questionStatementNumber(int number) {
    return 'Statement $number';
  }

  @override
  String get questionSubmit => 'Submit';

  @override
  String get questionTfngInstruction =>
      'Choose True, False or Not Given for each statement:';

  @override
  String get questionTypeDefault => 'Question';

  @override
  String get questionTypeDropdown => 'Dropdown selection';

  @override
  String get questionTypeFillInBlank => 'Fill in the blank';

  @override
  String get questionTypeHighlighting => 'Highlighting';

  @override
  String get questionTypeMatching => 'Matching';

  @override
  String get questionTypeMultipleChoice => 'Multiple answers';

  @override
  String get questionTypeOrdering => 'Ordering';

  @override
  String get questionTypeReading => 'Reading passage';

  @override
  String get questionTypeShortAnswer => 'Short answer';

  @override
  String get questionTypeSingleChoice => 'Multiple choice';

  @override
  String get questionTypeTfng => 'True / False / Not Given';

  @override
  String get questionTypeTrueFalse => 'True / False';

  @override
  String get questionViewList => 'View question list';

  @override
  String get questionWordBankLabel => 'Word bank';

  @override
  String get settingsChooseLanguage => 'Choose language';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageVietnamese => 'Tiếng Việt';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get supportClearCache => 'Clear cache';

  @override
  String get supportClearCacheSubtitle =>
      'Remove cached images and temp files, stay signed in';

  @override
  String get supportContact => 'Contact support';

  @override
  String get supportContactSubtitle => 'Hotline, email, website';

  @override
  String get supportDeviceInfo => 'Device information';

  @override
  String get supportDeviceInfoSubtitle =>
      'App version, model, operating system';

  @override
  String get supportFeedback => 'Report a bug / feedback';

  @override
  String get supportFeedbackSubtitle =>
      'Send a description with device details';

  @override
  String get supportSectionTitle => 'Support';

  @override
  String get toastErrorOccurred => 'An error occurred';

  @override
  String get toastProcessing => 'Processing...';
}
