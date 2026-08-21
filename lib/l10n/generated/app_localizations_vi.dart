// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'Trắc nghiệm';

  @override
  String get authAccountTitle => 'Tài khoản';

  @override
  String get authAvatarChangeTitle => 'Ảnh đại diện';

  @override
  String get authAvatarCropTitle => 'Cắt ảnh đại diện';

  @override
  String authAvatarTooLarge(int mb) {
    return 'Ảnh quá lớn, tối đa ${mb}MB.';
  }

  @override
  String get authAvatarFromCamera => 'Chụp ảnh mới';

  @override
  String get authAvatarFromGallery => 'Chọn từ thư viện';

  @override
  String get authAvatarUpdateSuccess => 'Đã cập nhật ảnh đại diện.';

  @override
  String get authChangePasswordFailed => 'Đổi mật khẩu thất bại';

  @override
  String get authChangePasswordSuccess => 'Đổi mật khẩu thành công.';

  @override
  String get authChangePasswordTitle => 'Đổi mật khẩu';

  @override
  String get authConfirmPasswordHint => 'Nhập lại mật khẩu mới...';

  @override
  String get authConfirmPasswordLabel => 'Xác nhận mật khẩu mới';

  @override
  String get authConfirmPasswordMismatch => 'Mật khẩu xác nhận không khớp';

  @override
  String get authConfirmPasswordRequired => 'Vui lòng xác nhận mật khẩu mới';

  @override
  String get authCurrentPasswordHint => 'Nhập mật khẩu đang dùng...';

  @override
  String get authCurrentPasswordLabel => 'Mật khẩu hiện tại';

  @override
  String get authCurrentPasswordRequired => 'Vui lòng nhập mật khẩu hiện tại';

  @override
  String get authDateOfBirthLabel => 'Ngày sinh';

  @override
  String get authEdit => 'Sửa';

  @override
  String get authEditProfileTitle => 'Sửa thông tin cá nhân';

  @override
  String get authEmailRequired => 'Vui lòng nhập email';

  @override
  String get authForgotPasswordTitle => 'Quên mật khẩu';

  @override
  String get authForgotPasswordLink => 'Quên mật khẩu?';

  @override
  String get authForgotPasswordMessage =>
      'Nhập email đã đăng ký với nhà trường. Chúng tôi sẽ gửi đường dẫn đặt lại mật khẩu tới hòm thư đó.';

  @override
  String get authForgotPasswordSend => 'Gửi yêu cầu';

  @override
  String get authForgotPasswordFailed =>
      'Không gửi được yêu cầu. Vui lòng thử lại.';

  @override
  String get authForgotPasswordSentTitle => 'Đã gửi yêu cầu';

  @override
  String get authForgotPasswordSentMessage =>
      'Nếu email này có trong hệ thống, đường dẫn đặt lại mật khẩu sẽ tới trong vài phút. Nhớ xem cả hòm thư rác.';

  @override
  String get authEmailHint => 'Nhập email...';

  @override
  String get authEmailInvalid => 'Email không hợp lệ';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authFullNameHint => 'Nhập họ và tên...';

  @override
  String get authFullNameLabel => 'Họ và tên';

  @override
  String get authFullNameRequired => 'Vui lòng nhập họ và tên';

  @override
  String get authPickGender => 'Chọn giới tính';

  @override
  String get authGenderFemale => 'Nữ';

  @override
  String get authGenderLabel => 'Giới tính';

  @override
  String get authGenderMale => 'Nam';

  @override
  String get authLoginSubtitle => 'Nhập mã sinh viên và mật khẩu để đăng nhập';

  @override
  String get authLoginTitle => 'Đăng nhập';

  @override
  String get authLogout => 'Đăng xuất';

  @override
  String get authLogoutConfirmMessage =>
      'Bạn có chắc muốn đăng xuất khỏi tài khoản này?';

  @override
  String authLogoutFailed(String error) {
    return 'Đăng xuất thất bại: $error';
  }

  @override
  String get authNewPasswordHint => 'Nhập mật khẩu mới...';

  @override
  String get authNewPasswordLabel => 'Mật khẩu mới';

  @override
  String get authNewPasswordRequired => 'Vui lòng nhập mật khẩu mới';

  @override
  String get authNewPasswordSameAsCurrent =>
      'Mật khẩu mới phải khác mật khẩu hiện tại';

  @override
  String get authNoName => 'Chưa có tên';

  @override
  String get authNoStudentId => 'Chưa có MSSV';

  @override
  String get authNotAvailable => 'Chưa có';

  @override
  String get authNotSelected => 'Chưa chọn';

  @override
  String get authPasswordHint => 'Nhập mật khẩu...';

  @override
  String get authPasswordLabel => 'Mật khẩu';

  @override
  String get authPasswordMinLength => 'Mật khẩu phải từ 6 ký tự trở lên';

  @override
  String get authPasswordRequired => 'Vui lòng nhập mật khẩu';

  @override
  String get authPersonalInfoTitle => 'Thông tin cá nhân';

  @override
  String get authPhoneHint => 'Nhập số điện thoại...';

  @override
  String get authPhoneLabel => 'Số điện thoại';

  @override
  String get authPhoneMinLength => 'Số điện thoại phải từ 9 chữ số trở lên';

  @override
  String get authPickDateOfBirth => 'Chọn ngày sinh';

  @override
  String get authProfileLoadFailed => 'Không tải được thông tin cá nhân.';

  @override
  String get authProfileLoadFailedRetry =>
      'Không tải được thông tin cá nhân. Vui lòng thử lại.';

  @override
  String get authProfileUpdateFailed => 'Cập nhật thông tin thất bại';

  @override
  String get authProfileUpdateSuccess =>
      'Cập nhật thông tin cá nhân thành công.';

  @override
  String get authSaveChanges => 'Lưu thay đổi';

  @override
  String get authSelect => 'Chọn';

  @override
  String get authStudentIdHelper =>
      'Mã sinh viên do nhà trường cấp, không thể tự sửa';

  @override
  String get authStudentIdLabel => 'Mã sinh viên';

  @override
  String get authUsernameHint => 'Nhập tên đăng nhập hoặc MSSV...';

  @override
  String get authUsernameLabel => 'Tên đăng nhập / MSSV';

  @override
  String get authUsernameRequired => 'Vui lòng nhập tên đăng nhập hoặc MSSV';

  @override
  String get clearCacheAlreadyEmpty => 'Bộ nhớ đệm đang trống';

  @override
  String get clearCacheConfirm => 'Xoá ngay';

  @override
  String clearCacheDone(String size) {
    return 'Đã xoá $size bộ nhớ đệm';
  }

  @override
  String clearCacheFailed(String error) {
    return 'Không xoá được bộ nhớ đệm: $error';
  }

  @override
  String get clearCacheMessage =>
      'Xoá ảnh tạm và tệp tải về trong máy. Bạn vẫn đăng nhập, không mất bài thi hay cài đặt.';

  @override
  String clearCacheSize(String size) {
    return 'Đang chiếm khoảng $size';
  }

  @override
  String get clearCacheTitle => 'Xoá bộ nhớ đệm';

  @override
  String get examScheduleTitle => 'Lịch thi';

  @override
  String get examScheduleEmptyTitle => 'Sắp có';

  @override
  String get examScheduleEmptyMessage =>
      'Các ca thi sắp tới của bạn sẽ hiện ở đây kèm môn học, giờ thi và phòng thi. Tính năng đang được xây dựng.';

  @override
  String get classroomTitle => 'Lớp học';

  @override
  String get classroomEmptyTitle => 'Sắp có';

  @override
  String get classroomEmptyMessage =>
      'Lớp học, tài liệu và bài tập của bạn sẽ hiện ở đây. Tính năng đang được xây dựng.';

  @override
  String get commonCancel => 'Huỷ';

  @override
  String get commonClose => 'Đóng';

  @override
  String get commonConfirm => 'Xác nhận';

  @override
  String get commonLoading => 'Đang tải...';

  @override
  String get commonNotUpdated => 'Chưa cập nhật';

  @override
  String get commonReloadFailed => 'Tải lại dữ liệu thất bại';

  @override
  String get commonReloadSuccess => 'Tải lại dữ liệu thành công';

  @override
  String get commonRetry => 'Thử lại';

  @override
  String get commonStatusFailed => 'Thất bại';

  @override
  String get commonStatusInfo => 'Thông tin';

  @override
  String get commonStatusSuccess => 'Thành công';

  @override
  String get commonStatusWarning => 'Lưu ý';

  @override
  String get commonSave => 'Lưu';

  @override
  String contactCopied(String value) {
    return 'Đã sao chép $value';
  }

  @override
  String get contactEmail => 'Gửi email';

  @override
  String get contactHotline => 'Gọi hotline';

  @override
  String contactOpenFailed(String value) {
    return 'Không mở được: $value';
  }

  @override
  String get contactTitle => 'Liên hệ hỗ trợ';

  @override
  String get contactWebsite => 'Mở website';

  @override
  String get deviceInfoAppName => 'Tên ứng dụng';

  @override
  String get deviceInfoAppSection => 'Ứng dụng';

  @override
  String get deviceInfoBrand => 'Hãng sản xuất';

  @override
  String get deviceInfoBuildNumber => 'Bản dựng';

  @override
  String get deviceInfoCopied => 'Đã sao chép thông tin thiết bị';

  @override
  String get deviceInfoCopy => 'Sao chép thông tin';

  @override
  String get deviceInfoDeviceSection => 'Thiết bị';

  @override
  String get deviceInfoDeviceType => 'Loại thiết bị';

  @override
  String get deviceInfoEmulator => 'Máy ảo';

  @override
  String get deviceInfoLanguage => 'Ngôn ngữ app';

  @override
  String get deviceInfoLoadFailed => 'Không đọc được thông tin thiết bị';

  @override
  String get deviceInfoModel => 'Kiểu máy';

  @override
  String get deviceInfoOs => 'Hệ điều hành';

  @override
  String get deviceInfoPackageName => 'Mã ứng dụng';

  @override
  String get deviceInfoPhysical => 'Máy thật';

  @override
  String get deviceInfoScreen => 'Màn hình';

  @override
  String get deviceInfoTitle => 'Thông tin thiết bị';

  @override
  String get deviceInfoVersion => 'Phiên bản';

  @override
  String get examAllAnswersSaved => 'Đã lưu xong toàn bộ đáp án.';

  @override
  String examAnsweredProgress(int answered, int total) {
    return 'Đã trả lời: $answered/$total';
  }

  @override
  String examAutoSubmitUnsavedWarning(int count) {
    return 'Có $count câu không lưu được lên máy chủ nên có thể không được chấm.';
  }

  @override
  String get examCannotExitWarning =>
      'Không thể thoát khi đang làm bài! Vui lòng nộp bài để kết thúc.';

  @override
  String get examCodeAppBarTitle => 'Làm kiểm tra';

  @override
  String get examCodeCheckingButton => 'Đang kiểm tra...';

  @override
  String get examCodeCodeLabel => 'Mã ca thi';

  @override
  String get examCodeConfirmMessage =>
      'Bạn có chắc chắn muốn bắt đầu làm bài? Sau khi vào thi, thời gian làm bài sẽ bắt đầu được tính.';

  @override
  String get examCodeConfirmTitle => 'Xác nhận vào thi';

  @override
  String get examCodeCreatingSession => 'Đang tạo phiên thi...';

  @override
  String get examCodeDurationLabel => 'Thời lượng';

  @override
  String examCodeDurationMinutes(int minutes) {
    return '$minutes phút';
  }

  @override
  String get examCodeEmptyError => 'Vui lòng nhập mã bài thi';

  @override
  String get examCodeEndTimeLabel => 'Thời gian kết thúc';

  @override
  String get examCodeEnterRoomButton => 'Tìm ca thi';

  @override
  String get examCodeErrorTitle => 'Không thể bắt đầu làm bài';

  @override
  String get examCodeFieldHint => 'Chỉ chữ cái, số và dấu gạch nối';

  @override
  String get examCodeHeading => 'Làm kiểm tra';

  @override
  String get examCodeHelpText =>
      'Mã ca thi chỉ được chứa chữ cái (A-Z), số (0-9) và dấu gạch nối (-). Ký tự đặc biệt sẽ bị tự động xóa.';

  @override
  String get examCodeLocationRequiredNotice =>
      'Ca thi này bắt buộc gửi vị trí GPS. Ứng dụng di động chưa hỗ trợ định vị nên rất có thể bạn sẽ không vào được từ đây.';

  @override
  String get examCodeSessionInfoTitle => 'Thông tin ca thi';

  @override
  String get examCodeStartButton => 'Vào thi';

  @override
  String get examCodeStartTimeLabel => 'Thời gian bắt đầu';

  @override
  String get examCodeSubjectLabel => 'Môn thi';

  @override
  String get examCodeSubtitle =>
      'Nhập mã bài thi được giáo viên cung cấp để bắt đầu làm bài.';

  @override
  String get examDefaultTitle => 'Bài kiểm tra';

  @override
  String get examEnterOverlayHint => 'Vui lòng không thoát ứng dụng.';

  @override
  String get examEnterOverlayTitle => 'Đang vào phòng thi';

  @override
  String get examInfoQuestionsLabel => 'Câu hỏi';

  @override
  String get examInfoTimeLabel => 'Thời gian';

  @override
  String examLoadError(String error) {
    return 'Lỗi: $error';
  }

  @override
  String get examLocationDenied =>
      'Bạn chưa cho phép ứng dụng truy cập vị trí. Cấp quyền rồi thử lại.';

  @override
  String get examLocationDeniedForever =>
      'Quyền vị trí đang bị chặn. Mở Cài đặt để cấp lại quyền cho ứng dụng.';

  @override
  String get examLocationGetting => 'Đang lấy vị trí của bạn';

  @override
  String get examLocationGettingHint =>
      'Ca thi này yêu cầu định vị. Ra chỗ thoáng giúp máy bắt tín hiệu nhanh hơn.';

  @override
  String get examLocationServiceDisabled =>
      'Định vị trên máy đang tắt. Bật định vị rồi thử lại để vào thi.';

  @override
  String get examLocationTimeout =>
      'Chưa lấy được vị trí. Ra chỗ thoáng hoặc kiểm tra GPS rồi thử lại.';

  @override
  String get examLookupOverlayTitle => 'Đang tìm ca thi';

  @override
  String get examNoData => 'Không có dữ liệu bài kiểm tra';

  @override
  String get examNoQuestions => 'Đề thi không có câu hỏi';

  @override
  String get examNoticeDefaultMessage =>
      'Nếu bạn kiểm tra điểm cao thì chúc mừng bạn, nếu bạn kiểm tra không được tốt thì cũng đừng buồn chúng ta còn cơ hội cho lần sau. À làm gì có lần sau :>>>';

  @override
  String get examPartialLabel => 'Làm dở';

  @override
  String get examPinQuestion => 'Ghim';

  @override
  String get examPinnedHint => 'Ghim để đánh dấu câu cần xem lại';

  @override
  String get examPinnedLabel => 'Đã ghim';

  @override
  String examQuestionProgress(String label, int total) {
    return 'Câu $label/$total';
  }

  @override
  String get examRealtimeAutoSubmittedTitle =>
      'Bài thi bị nộp tự động do vi phạm';

  @override
  String get examRealtimeBlockedMessage =>
      'Giám thị đã dừng ca thi của bạn. Bài làm đã được nộp.';

  @override
  String get examRealtimeBlockedTitle => 'Bạn đã bị chặn khỏi ca thi';

  @override
  String examRealtimeExtraTimeAdded(int minutes) {
    return 'Giám thị cộng thêm $minutes phút';
  }

  @override
  String examRealtimeExtraTimeSubtracted(int minutes) {
    return 'Giám thị trừ $minutes phút';
  }

  @override
  String get examRealtimeTeacherMessageTitle => 'Thông báo từ giám thị';

  @override
  String get examRealtimeTeacherSubmittedTitle => 'Giám thị đã nộp bài hộ bạn';

  @override
  String examRealtimeViolationWarningMessage(int count, int threshold) {
    return 'Bạn đã có $count/$threshold lần vi phạm quy chế. Tiếp tục vi phạm có thể bị nộp bài tự động hoặc bị đình chỉ.';
  }

  @override
  String get examRealtimeViolationWarningTitle => 'Cảnh báo vi phạm';

  @override
  String get examRealtimeViolationWarningUnderstood => 'Tôi đã hiểu';

  @override
  String get examResultHomeButton => 'Về trang chủ';

  @override
  String get examResultPendingSubmitFailed => 'Máy chủ không nhận bài';

  @override
  String get examResultPendingSubmitFailedHint =>
      'Bài của bạn đã bị đóng trước khi gửi được. Hãy báo ngay cho giám thị để được xử lý.';

  @override
  String examResultPendingSubmitHint(String time) {
    return 'Bài làm đã được ghi lại trên máy lúc $time. Ứng dụng sẽ tự gửi ngay khi có mạng — bạn không cần làm gì thêm.';
  }

  @override
  String get examResultPendingSubmitTitle => 'Đang chờ mạng để gửi bài';

  @override
  String get examResultTitle => 'Kết quả bài thi';

  @override
  String get examScoreCommentAverage => 'Trung bình!';

  @override
  String get examScoreCommentExcellent => 'Xuất sắc!';

  @override
  String get examScoreCommentFair => 'Khá!';

  @override
  String get examScoreCommentGood => 'Giỏi!';

  @override
  String get examScoreCommentNeedsImprovement => 'Cần cố gắng thêm!';

  @override
  String get examScoreLabel => 'ĐIỂM CỦA BẠN';

  @override
  String get examSubmitButton => 'Nộp bài';

  @override
  String get examSubmitDialogAllAnswered => 'Bạn đã trả lời hết các câu.';

  @override
  String get examSubmitDialogAnsweredLabel => 'Đã trả lời';

  @override
  String get examSubmitDialogConfirmQuestion =>
      'Bạn có chắc chắn muốn nộp bài không?';

  @override
  String get examSubmitDialogTitle => 'Nộp bài thi';

  @override
  String get examSubmitDialogUnansweredLabel => 'Chưa trả lời';

  @override
  String examSubmitDialogUnansweredWarning(int count) {
    return 'Còn $count câu chưa trả lời. Nộp bài rồi thì không quay lại sửa được nữa.';
  }

  @override
  String examSubmitDialogUnsavedWarning(int count) {
    return '⚠️ Còn $count câu chưa lưu được lên máy chủ. Nếu nộp bây giờ, những câu đó có thể không được chấm.';
  }

  @override
  String examSubmitError(String error) {
    return 'Có lỗi xảy ra khi nộp bài: $error';
  }

  @override
  String get examSubmitFailedMessage =>
      'Máy chủ chưa ghi nhận bài nộp của bạn. Các đáp án đã chọn vẫn được lưu — hãy kiểm tra kết nối mạng rồi bấm Thử lại.';

  @override
  String get examSubmitFailedTitle => 'Lỗi khi nộp bài';

  @override
  String get examSubmitOverlayHint =>
      'Vui lòng giữ ứng dụng mở cho tới khi xong.';

  @override
  String get examSubmitOverlayTitle => 'Đang nộp bài';

  @override
  String get examSubmitQueuedMessage =>
      'Mất kết nối nên bài chưa gửi được. Giờ nộp của bạn đã được ghi lại, ứng dụng sẽ tự gửi khi có mạng.';

  @override
  String get examSubmitQueuedTitle => 'Đã ghi nhận giờ nộp';

  @override
  String get examSubmitSuccess => 'Nộp bài thành công';

  @override
  String get examTimeUpBannerTitle => 'Hết giờ!';

  @override
  String get examTimeUpLockedHint =>
      'Bài đã được khoá, bạn không thể thay đổi đáp án nữa.';

  @override
  String get examTimeUpSavingAnswers =>
      'Đang chờ lưu nốt các đáp án đã chọn...';

  @override
  String get examTimeUpSubmitting => 'Đang tự động nộp bài...';

  @override
  String get examTimeUpToastMessage =>
      'Bài thi đang được nộp tự động. Vui lòng không thoát ứng dụng.';

  @override
  String get examOfflineBannerTitle => 'Mất kết nối';

  @override
  String get examOfflineBannerHint =>
      'Đáp án vẫn được lưu trên máy và sẽ tự gửi lên khi có mạng lại.';

  @override
  String get examOfflineRetryFailed =>
      'Vẫn chưa gửi được. Kiểm tra mạng rồi thử lại.';

  @override
  String get examUnlimitedTime => 'Không giới hạn';

  @override
  String get examUnpinQuestion => 'Bỏ ghim';

  @override
  String get feedbackAttachNote =>
      'Thông tin máy và phiên bản app được đính kèm tự động để dò lỗi nhanh hơn.';

  @override
  String get feedbackContactHint => 'Để bên hỗ trợ liên hệ lại khi cần';

  @override
  String get feedbackContactLabel =>
      'Email / số điện thoại của bạn (không bắt buộc)';

  @override
  String get feedbackContentHint =>
      'Mô tả lỗi bạn gặp, hoặc điều bạn muốn app làm tốt hơn...';

  @override
  String get feedbackContentLabel => 'Nội dung';

  @override
  String get feedbackContentRequired => 'Nhập nội dung trước khi gửi';

  @override
  String feedbackMailFallback(String email) {
    return 'Máy chưa có ứng dụng email. Nội dung đã được sao chép, bạn gửi giúp tới $email.';
  }

  @override
  String get feedbackSend => 'Gửi';

  @override
  String get feedbackTitle => 'Báo lỗi / góp ý';

  @override
  String get feedbackTypeBug => 'Báo lỗi';

  @override
  String get feedbackTypeIdea => 'Góp ý';

  @override
  String historyBadgeExtraMinutes(int count) {
    return '+$count phút';
  }

  @override
  String historyBadgeViolations(int count) {
    return '$count vi phạm';
  }

  @override
  String get historyBlockedClosed => 'Đã hết hạn xem lại';

  @override
  String get historyBlockedNotAllowed => 'Ca thi không cho xem lại bài';

  @override
  String get historyBlockedNotCompleted => 'Bài đang được mở lại để làm lại';

  @override
  String historyBlockedNotOpenYet(String time) {
    return 'Mở xem lại từ $time';
  }

  @override
  String get historyBlockedNotOpenYetGeneric => 'Chưa tới giờ mở xem lại bài';

  @override
  String get historyColCorrect => 'Số câu đúng';

  @override
  String get historyColDuration => 'Thời gian làm';

  @override
  String get historyColExamDate => 'Ngày thi';

  @override
  String get historyColScore => 'Điểm';

  @override
  String historyDurationMinutes(int count) {
    return '$count phút';
  }

  @override
  String get historyEmptyDesc =>
      'Bạn chưa hoàn thành bài thi nào. Sau khi nộp bài, bài làm sẽ xuất hiện ở đây.';

  @override
  String get historyEmptyTitle => 'Chưa có bài thi nào';

  @override
  String get historyGoToExam => 'Vào thi';

  @override
  String get historyLoadFailed => 'Không tải được lịch sử làm bài';

  @override
  String get historyOpenFailed => 'Không mở được bài thi';

  @override
  String get historyOpening => 'Đang mở...';

  @override
  String get historyReview => 'Xem lại';

  @override
  String get historyReviewWithAnswerKey => 'Xem lại bài kèm đáp án đúng';

  @override
  String get historyReviewWithoutAnswerKey =>
      'Xem lại bài, không hiện đáp án đúng';

  @override
  String get historyReviewWithoutQuestionDetail =>
      'Chỉ xem được câu đúng/sai, không có nội dung câu hỏi';

  @override
  String get historyStatAverage => 'Điểm trung bình';

  @override
  String get historyStatBest => 'Điểm cao nhất';

  @override
  String get historyStatTotal => 'Số bài đã thi';

  @override
  String get historyStatViolations => 'Tổng vi phạm';

  @override
  String get historySubtitle => 'Danh sách các bài thi bạn đã hoàn thành';

  @override
  String get historyTitle => 'Lịch sử làm bài';

  @override
  String get historyUnknownSubject => 'Không rõ môn thi';

  @override
  String get homeNavAccount => 'Tài khoản';

  @override
  String get homeNavSchedule => 'Lịch thi';

  @override
  String get homeNavClassroom => 'Lớp học';

  @override
  String get homeNavHistory => 'Lịch sử';

  @override
  String get homeNavHome => 'Trang chủ';

  @override
  String get homeNewsEmpty => 'Chưa có tin nào.';

  @override
  String get homeNewsError => 'Không tải được tin giáo dục.';

  @override
  String get homeNewsLoadMore => 'Tải thêm tin';

  @override
  String get homeNewsOpenFailed => 'Không mở được bài viết.';

  @override
  String get homeNewsRetry => 'Thử lại';

  @override
  String get homeNewsSource => 'Nguồn: VnExpress';

  @override
  String homeNewsTimeDays(int days) {
    return '$days ngày trước';
  }

  @override
  String homeNewsTimeHours(int hours) {
    return '$hours giờ trước';
  }

  @override
  String get homeNewsTimeJustNow => 'Vừa xong';

  @override
  String homeNewsTimeMinutes(int minutes) {
    return '$minutes phút trước';
  }

  @override
  String get homeNewsTitle => 'Tin giáo dục';

  @override
  String get homeQrExamCreatedAt => 'Ngày tạo';

  @override
  String get homeQrExamDescription => 'Mô tả';

  @override
  String get homeQrExamDuration => 'Thời gian';

  @override
  String homeQrExamDurationMinutes(String minutes) {
    return '$minutes phút';
  }

  @override
  String get homeQrExamFallbackTitle => 'Bài thi';

  @override
  String get homeQrExamInfoLabel => 'Thông tin bài thi';

  @override
  String get homeQrExamSubject => 'Môn học';

  @override
  String get homeQrInvalidTitle => 'Mã QR không hợp lệ';

  @override
  String get homeQrMissingExamCode => 'Không tìm thấy mã đề trong QR.';

  @override
  String get homeQrScanTitle => 'Quét mã QR bài thi';

  @override
  String get homeQrStartExamFailed =>
      'Không thể tạo ca thi từ QR.\nVui lòng thử lại.';

  @override
  String get homeQrWrongFormatMessage =>
      'Mã QR không đúng định dạng bài thi.\nVui lòng quét mã QR hợp lệ.';

  @override
  String get homeQuickExamButton => 'Kiểm tra nhanh';

  @override
  String get homeScanExamQrButton => 'Quét mã bài thi';

  @override
  String get msgAuthAccountLocked => 'Tài khoản đã bị khoá.';

  @override
  String get msgAuthInvalidCredentials => 'Sai tài khoản hoặc mật khẩu.';

  @override
  String get msgAuthInvalidData => 'Dữ liệu không hợp lệ.';

  @override
  String get msgAvatarFileTooLarge =>
      'Ảnh vượt quá 10MB. Hãy chọn ảnh nhỏ hơn.';

  @override
  String get msgAvatarFormatUnsupported =>
      'Chỉ nhận ảnh JPG, PNG, GIF, WEBP hoặc BMP.';

  @override
  String get msgAvatarUploadFailed => 'Cập nhật ảnh đại diện thất bại.';

  @override
  String get msgChangePasswordFailed => 'Đổi mật khẩu thất bại';

  @override
  String msgErrorWithDetail(String error) {
    return 'Lỗi: $error';
  }

  @override
  String get msgExamDataUnreadable =>
      'Máy chủ đã nhận yêu cầu nhưng ứng dụng không đọc được dữ liệu đề thi. Đừng thử lại nhiều lần vì mỗi lần vào thi có thể tính một lượt làm bài — hãy báo giáo viên hoặc kỹ thuật viên.';

  @override
  String get msgExamHistoryFetchFailed => 'Không tải được lịch sử làm bài.';

  @override
  String get msgExamReviewNotAllowed => 'Bài này chưa được phép xem lại.';

  @override
  String get msgExamReviewOpenFailed =>
      'Máy chủ gặp lỗi khi mở bài. Vui lòng thử lại.';

  @override
  String get msgExamSessionCoreRequired => 'Vui lòng nhập mã ca thi.';

  @override
  String get msgExamSessionFetchFailed =>
      'Không lấy được thông tin ca thi. Vui lòng thử lại.';

  @override
  String get msgExamSessionNotFound => 'Không tìm thấy phiên thi với mã này';

  @override
  String get msgLoginFailed => 'Đăng nhập thất bại';

  @override
  String get msgLoginPasswordRequired => 'Vui lòng nhập mật khẩu';

  @override
  String get msgLoginPasswordTooShort => 'Mật khẩu phải từ 6 ký tự trở lên';

  @override
  String get msgLoginUserNameRequired => 'Vui lòng nhập tên đăng nhập / MSSV';

  @override
  String get msgProfileUpdateFailed => 'Cập nhật thông tin thất bại';

  @override
  String get msgSaveAnswerFailed =>
      'Máy chủ không nhận đáp án này. Hãy báo giám thị nếu tình trạng lặp lại.';

  @override
  String get msgSaveAnswerOffline =>
      'Mất kết nối nên chưa lưu được đáp án lên máy chủ.';

  @override
  String get msgSaveAnswerServerError =>
      'Máy chủ đang gặp lỗi nên chưa lưu được đáp án.';

  @override
  String get msgServerUnreachable =>
      'Không kết nối được máy chủ. Vui lòng thử lại.';

  @override
  String get msgStudentExamSessionCreateFailed =>
      'Không vào được ca thi này. Có thể chưa tới giờ, đã hết giờ, hết chỗ hoặc bạn đã dùng hết lượt làm bài.';

  @override
  String get msgStudentExamSessionCreateServerError =>
      'Máy chủ gặp lỗi khi tạo phiên thi. Vui lòng thử lại sau.';

  @override
  String get msgStudentLocationRequired =>
      'Ca thi này bắt buộc gửi vị trí GPS. Ứng dụng di động chưa hỗ trợ định vị nên bạn chưa vào được ca thi từ đây; hãy vào bằng trình duyệt trên máy tính.';

  @override
  String get msgStudentProfileFetchFailed =>
      'Không tải được thông tin sinh viên.';

  @override
  String get msgStudentProfileNotFound => 'Không tìm thấy thông tin sinh viên.';

  @override
  String get msgSubmitExamRejected => 'Máy chủ không nhận bài nộp này.';

  @override
  String get msgSubmitExamSuccess => 'Nộp bài thành công';

  @override
  String get msgUserAvatarFileRequired => 'Chưa chọn ảnh để tải lên.';

  @override
  String get msgUserAvatarUpdateFailed =>
      'Tải ảnh lên được nhưng chưa gắn được vào tài khoản.';

  @override
  String get msgUserAvatarUploadFailed =>
      'Máy chủ không nhận được ảnh. Vui lòng thử lại.';

  @override
  String get msgUserChangePasswordFailed => 'Đổi mật khẩu thất bại.';

  @override
  String get msgUserChangePasswordServerError => 'Lỗi server khi đổi mật khẩu.';

  @override
  String get msgUserChangePasswordSuccess => 'Đổi mật khẩu thành công.';

  @override
  String get msgUserProfileUpdateSuccess =>
      'Cập nhật thông tin cá nhân thành công.';

  @override
  String get msgUserTokenMissing =>
      'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';

  @override
  String get msgUserUpdateFailed => 'Không thể cập nhật thông tin người dùng.';

  @override
  String get msgValidationCompareMismatch => 'Giá trị xác nhận không khớp.';

  @override
  String get msgValidationEmailDuplicated => 'Email đã được sử dụng.';

  @override
  String get msgValidationEmailInvalid => 'Email không hợp lệ.';

  @override
  String get msgValidationFieldInvalid => 'Trường dữ liệu không hợp lệ.';

  @override
  String get msgValidationFieldRequired =>
      'Vui lòng nhập đầy đủ thông tin bắt buộc.';

  @override
  String get msgValidationInvalid => 'Dữ liệu không hợp lệ.';

  @override
  String get msgValidationMaxLength => 'Giá trị vượt quá độ dài cho phép.';

  @override
  String get msgValidationMinLength => 'Giá trị chưa đạt độ dài tối thiểu.';

  @override
  String get msgValidationPasswordCurrentIncorrect =>
      'Mật khẩu hiện tại không đúng.';

  @override
  String get msgValidationPasswordRequiresDigit =>
      'Mật khẩu phải có ít nhất một chữ số.';

  @override
  String get msgValidationPasswordRequiresLower =>
      'Mật khẩu phải có ít nhất một chữ thường.';

  @override
  String get msgValidationPasswordRequiresSymbol =>
      'Mật khẩu phải có ít nhất một ký tự đặc biệt.';

  @override
  String get msgValidationPasswordRequiresUniqueChars =>
      'Mật khẩu phải có nhiều ký tự khác nhau hơn.';

  @override
  String get msgValidationPasswordRequiresUpper =>
      'Mật khẩu phải có ít nhất một chữ hoa.';

  @override
  String get msgValidationPasswordTooShort => 'Mật khẩu quá ngắn.';

  @override
  String get msgValidationPhoneInvalid => 'Số điện thoại không hợp lệ.';

  @override
  String get msgValidationTokenInvalid =>
      'Mã xác thực không hợp lệ hoặc đã hết hạn.';

  @override
  String get msgValidationUserNotFound => 'Không tìm thấy người dùng.';

  @override
  String get msgValidationUsernameDuplicated => 'Tên đăng nhập đã tồn tại.';

  @override
  String get notificationsDelete => 'Xoá';

  @override
  String get notificationsDeleteAll => 'Dọn tất cả';

  @override
  String get notificationsDeleteAllTitle => 'Dọn sạch hộp thư?';

  @override
  String get notificationsDeleteAllMessage =>
      'Toàn bộ thông báo sẽ bị gỡ khỏi máy và khỏi tài khoản của bạn. Thao tác này không lùi lại được.';

  @override
  String get notificationsDeleteAllConfirm => 'Dọn sạch';

  @override
  String get notificationsError => 'Không tải được thông báo';

  @override
  String get notificationsErrorHint =>
      'Kiểm tra kết nối mạng rồi kéo xuống để thử lại.';

  @override
  String get notificationsLoadMore => 'Tải thêm';

  @override
  String get notificationsMarkAllRead => 'Đọc tất cả';

  @override
  String get notificationsEmptyMessage =>
      'Thông báo về ca thi, điểm và nhắc nhở của giáo viên sẽ hiện ở đây.';

  @override
  String get notificationsEmptyTitle => 'Chưa có thông báo';

  @override
  String get notificationsTitle => 'Thông báo';

  @override
  String questionAntiCheatAutoSubmitNotice(int max) {
    return 'Đủ $max lần sẽ tự động nộp bài.';
  }

  @override
  String get questionAntiCheatLeftApp => 'Bạn đã rời khỏi ứng dụng thi.';

  @override
  String get questionAntiCheatOverlayDetected =>
      'Phát hiện có ứng dụng hoặc cửa sổ khác đè lên ứng dụng thi!';

  @override
  String get questionAntiCheatRotationBlockedSubtitle =>
      'Màn hình sẽ tự động quay lại sau vài giây';

  @override
  String get questionAntiCheatRotationBlockedTitle =>
      'Không được quay màn hình!';

  @override
  String get questionAntiCheatRotationDetected =>
      'Phát hiện quay màn hình trong lúc thi!';

  @override
  String get questionAntiCheatScreenRecordingDetected =>
      'Phát hiện ghi màn hình!';

  @override
  String get questionAntiCheatScreenshotDetected => 'Phát hiện chụp màn hình!';

  @override
  String get questionAntiCheatUnderstood => 'Tôi hiểu';

  @override
  String questionAntiCheatViolationCount(int count, int max) {
    return 'Vi phạm: $count/$max';
  }

  @override
  String get questionAntiCheatWarningTitle => 'Cảnh báo gian lận!';

  @override
  String get questionBlankClear => 'Gỡ đáp án khỏi ô trống';

  @override
  String questionBlankLabel(int number) {
    return 'Ô trống $number';
  }

  @override
  String questionBlankProgress(int filled, int total) {
    return 'Đã điền $filled/$total';
  }

  @override
  String get questionDifficultyEasy => 'Mức độ: Dễ';

  @override
  String get questionDifficultyHard => 'Mức độ: Khó';

  @override
  String questionDifficultyLevel(int level) {
    return 'Mức độ $level';
  }

  @override
  String get questionDifficultyMedium => 'Mức độ: Trung bình';

  @override
  String get questionDifficultyVeryHard => 'Mức độ: Rất khó';

  @override
  String questionDropdownHint(int number) {
    return '($number) Chọn...';
  }

  @override
  String get questionDropdownInstruction => 'Chạm vào ô trống để chọn đáp án:';

  @override
  String get questionDropdownPlaceholder => '-- Chọn --';

  @override
  String get questionFillBlankAllWordsUsed => 'Đã dùng hết từ trong ngân hàng';

  @override
  String get questionFillBlankInstruction =>
      'Kéo từ vào ô trống, hoặc nhấn từ rồi nhấn ô:';

  @override
  String get questionHighlightClear => 'Bỏ chọn hết';

  @override
  String get questionHighlightExtraHint => 'Nhập nội dung bổ sung...';

  @override
  String get questionHighlightExtraLabel => 'Phần bổ sung (nếu có)';

  @override
  String get questionHighlightInstruction =>
      'Chọn các phần cần bôi trong đoạn văn:';

  @override
  String questionHighlightSelectedCount(int count) {
    return 'Đã chọn $count phần';
  }

  @override
  String get questionImageLoadFailed => 'Không thể tải hình ảnh';

  @override
  String get questionImageNoUrl => 'Không có URL hình ảnh';

  @override
  String get questionLegendAnswered => 'Đã trả lời';

  @override
  String get questionLegendCurrent => 'Đang làm';

  @override
  String get questionListTitle => 'Danh sách câu hỏi';

  @override
  String get questionMatchingColumnA => 'Cột A';

  @override
  String get questionMatchingColumnB => 'Cột B';

  @override
  String get questionMatchingEmptySlot => 'Chưa nối';

  @override
  String get questionMatchingInstruction =>
      'Hướng dẫn: Nhấn vào 1 vế Cột A, sau đó nhấn vế tương ứng ở Cột B để nối.';

  @override
  String questionMatchingLinkedCount(int linked, int total) {
    return 'Đã nối $linked/$total';
  }

  @override
  String get questionMatchingPickColumnAFirst => 'Chọn một vế ở cột A trước';

  @override
  String get questionMultipleChoiceInstruction =>
      'Hãy chọn một hoặc nhiều đáp án:';

  @override
  String get questionNext => 'Tiếp theo';

  @override
  String questionNumberOfTotal(String label, int total) {
    return 'Câu $label / $total';
  }

  @override
  String get questionOrderingInstruction =>
      'Kéo thả các biểu tượng bên phải để sắp xếp theo thứ tự đúng:';

  @override
  String get questionPrevious => 'Trước';

  @override
  String get questionReadingPassageLabel => 'Bài đọc / Ngữ cảnh:';

  @override
  String get questionShortAnswerHint => 'Nhập câu trả lời của bạn tại đây...';

  @override
  String get questionShortAnswerInstruction =>
      'Nhập câu trả lời cho từng ô trống:';

  @override
  String get questionSingleChoiceInstruction => 'Chọn một đáp án đúng:';

  @override
  String get questionStatAnswered => 'Đã làm';

  @override
  String get questionStatTotal => 'Tổng số';

  @override
  String get questionStatUnanswered => 'Chưa làm';

  @override
  String questionStatementNumber(int number) {
    return 'Mệnh đề $number';
  }

  @override
  String get questionSubmit => 'Nộp bài';

  @override
  String get questionTfngInstruction =>
      'Chọn True, False hoặc Not Given cho từng mệnh đề:';

  @override
  String get questionTypeDefault => 'Câu hỏi';

  @override
  String get questionTypeDropdown => 'Chọn từ Menu';

  @override
  String get questionTypeFillInBlank => 'Điền vào chỗ trống';

  @override
  String get questionTypeHighlighting => 'Bôi vùng';

  @override
  String get questionTypeMatching => 'Câu nối';

  @override
  String get questionTypeMultipleChoice => 'Chọn nhiều đáp án';

  @override
  String get questionTypeOrdering => 'Sắp xếp thứ tự';

  @override
  String get questionTypeReading => 'Bài đọc';

  @override
  String get questionTypeShortAnswer => 'Trả lời ngắn';

  @override
  String get questionTypeSingleChoice => 'Trắc nghiệm';

  @override
  String get questionTypeTfng => 'True / False / Not Given';

  @override
  String get questionTypeTrueFalse => 'Đúng / Sai';

  @override
  String get questionViewList => 'Xem danh sách câu hỏi';

  @override
  String get questionWordBankLabel => 'Ngân hàng từ';

  @override
  String get settingsChooseLanguage => 'Chọn ngôn ngữ';

  @override
  String get settingsLanguage => 'Ngôn ngữ';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageVietnamese => 'Tiếng Việt';

  @override
  String get settingsTitle => 'Cài đặt';

  @override
  String get supportClearCache => 'Xoá bộ nhớ đệm';

  @override
  String get supportClearCacheSubtitle =>
      'Xoá ảnh và tệp tạm, vẫn giữ đăng nhập';

  @override
  String get supportContact => 'Liên hệ hỗ trợ';

  @override
  String get supportContactSubtitle => 'Hotline, email, website';

  @override
  String get supportDeviceInfo => 'Thông tin thiết bị';

  @override
  String get supportDeviceInfoSubtitle =>
      'Phiên bản app, kiểu máy, hệ điều hành';

  @override
  String get supportFeedback => 'Báo lỗi / góp ý';

  @override
  String get supportFeedbackSubtitle => 'Gửi mô tả kèm thông tin máy';

  @override
  String get supportSectionTitle => 'Hỗ trợ';

  @override
  String get toastErrorOccurred => 'Có lỗi xảy ra';

  @override
  String get toastProcessing => 'Đang xử lý...';
}
