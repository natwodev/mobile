import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In vi, this message translates to:
  /// **'HUTECH Campus Info'**
  String get appTitle;

  /// No description provided for @authAccountTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản'**
  String get authAccountTitle;

  /// No description provided for @authAvatarChangeTitle.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh đại diện'**
  String get authAvatarChangeTitle;

  /// No description provided for @authAvatarFromCamera.
  ///
  /// In vi, this message translates to:
  /// **'Chụp ảnh mới'**
  String get authAvatarFromCamera;

  /// No description provided for @authAvatarFromGallery.
  ///
  /// In vi, this message translates to:
  /// **'Chọn từ thư viện'**
  String get authAvatarFromGallery;

  /// No description provided for @authAvatarUpdateSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đã cập nhật ảnh đại diện.'**
  String get authAvatarUpdateSuccess;

  /// No description provided for @authChangePasswordFailed.
  ///
  /// In vi, this message translates to:
  /// **'Đổi mật khẩu thất bại'**
  String get authChangePasswordFailed;

  /// No description provided for @authChangePasswordSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đổi mật khẩu thành công.'**
  String get authChangePasswordSuccess;

  /// No description provided for @authChangePasswordTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đổi mật khẩu'**
  String get authChangePasswordTitle;

  /// No description provided for @authConfirmPasswordHint.
  ///
  /// In vi, this message translates to:
  /// **'Nhập lại mật khẩu mới...'**
  String get authConfirmPasswordHint;

  /// No description provided for @authConfirmPasswordLabel.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận mật khẩu mới'**
  String get authConfirmPasswordLabel;

  /// No description provided for @authConfirmPasswordMismatch.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu xác nhận không khớp'**
  String get authConfirmPasswordMismatch;

  /// No description provided for @authConfirmPasswordRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng xác nhận mật khẩu mới'**
  String get authConfirmPasswordRequired;

  /// No description provided for @authCurrentPasswordHint.
  ///
  /// In vi, this message translates to:
  /// **'Nhập mật khẩu đang dùng...'**
  String get authCurrentPasswordHint;

  /// No description provided for @authCurrentPasswordLabel.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu hiện tại'**
  String get authCurrentPasswordLabel;

  /// No description provided for @authCurrentPasswordRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập mật khẩu hiện tại'**
  String get authCurrentPasswordRequired;

  /// No description provided for @authDateOfBirthLabel.
  ///
  /// In vi, this message translates to:
  /// **'Ngày sinh'**
  String get authDateOfBirthLabel;

  /// No description provided for @authEdit.
  ///
  /// In vi, this message translates to:
  /// **'Sửa'**
  String get authEdit;

  /// No description provided for @authEditProfileTitle.
  ///
  /// In vi, this message translates to:
  /// **'Sửa thông tin cá nhân'**
  String get authEditProfileTitle;

  /// No description provided for @authEmailHint.
  ///
  /// In vi, this message translates to:
  /// **'Nhập email...'**
  String get authEmailHint;

  /// No description provided for @authEmailInvalid.
  ///
  /// In vi, this message translates to:
  /// **'Email không hợp lệ'**
  String get authEmailInvalid;

  /// No description provided for @authEmailLabel.
  ///
  /// In vi, this message translates to:
  /// **'Email'**
  String get authEmailLabel;

  /// No description provided for @authFullNameHint.
  ///
  /// In vi, this message translates to:
  /// **'Nhập họ và tên...'**
  String get authFullNameHint;

  /// No description provided for @authFullNameLabel.
  ///
  /// In vi, this message translates to:
  /// **'Họ và tên'**
  String get authFullNameLabel;

  /// No description provided for @authFullNameRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập họ và tên'**
  String get authFullNameRequired;

  /// No description provided for @authGenderFemale.
  ///
  /// In vi, this message translates to:
  /// **'Nữ'**
  String get authGenderFemale;

  /// No description provided for @authGenderLabel.
  ///
  /// In vi, this message translates to:
  /// **'Giới tính'**
  String get authGenderLabel;

  /// No description provided for @authGenderMale.
  ///
  /// In vi, this message translates to:
  /// **'Nam'**
  String get authGenderMale;

  /// No description provided for @authLoginSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Nhập mã sinh viên và mật khẩu để đăng nhập'**
  String get authLoginSubtitle;

  /// No description provided for @authLoginTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập'**
  String get authLoginTitle;

  /// No description provided for @authLogout.
  ///
  /// In vi, this message translates to:
  /// **'Đăng xuất'**
  String get authLogout;

  /// No description provided for @authLogoutConfirmMessage.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có chắc muốn đăng xuất khỏi tài khoản này?'**
  String get authLogoutConfirmMessage;

  /// No description provided for @authLogoutFailed.
  ///
  /// In vi, this message translates to:
  /// **'Đăng xuất thất bại: {error}'**
  String authLogoutFailed(String error);

  /// No description provided for @authNewPasswordHint.
  ///
  /// In vi, this message translates to:
  /// **'Nhập mật khẩu mới...'**
  String get authNewPasswordHint;

  /// No description provided for @authNewPasswordLabel.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu mới'**
  String get authNewPasswordLabel;

  /// No description provided for @authNewPasswordRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập mật khẩu mới'**
  String get authNewPasswordRequired;

  /// No description provided for @authNewPasswordSameAsCurrent.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu mới phải khác mật khẩu hiện tại'**
  String get authNewPasswordSameAsCurrent;

  /// No description provided for @authNoName.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có tên'**
  String get authNoName;

  /// No description provided for @authNoStudentId.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có MSSV'**
  String get authNoStudentId;

  /// No description provided for @authNotAvailable.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có'**
  String get authNotAvailable;

  /// No description provided for @authNotSelected.
  ///
  /// In vi, this message translates to:
  /// **'Chưa chọn'**
  String get authNotSelected;

  /// No description provided for @authPasswordHint.
  ///
  /// In vi, this message translates to:
  /// **'Nhập mật khẩu...'**
  String get authPasswordHint;

  /// No description provided for @authPasswordLabel.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu'**
  String get authPasswordLabel;

  /// No description provided for @authPasswordMinLength.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu phải từ 6 ký tự trở lên'**
  String get authPasswordMinLength;

  /// No description provided for @authPasswordRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập mật khẩu'**
  String get authPasswordRequired;

  /// No description provided for @authPersonalInfoTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin cá nhân'**
  String get authPersonalInfoTitle;

  /// No description provided for @authPhoneHint.
  ///
  /// In vi, this message translates to:
  /// **'Nhập số điện thoại...'**
  String get authPhoneHint;

  /// No description provided for @authPhoneLabel.
  ///
  /// In vi, this message translates to:
  /// **'Số điện thoại'**
  String get authPhoneLabel;

  /// No description provided for @authPhoneMinLength.
  ///
  /// In vi, this message translates to:
  /// **'Số điện thoại phải từ 9 chữ số trở lên'**
  String get authPhoneMinLength;

  /// No description provided for @authPickDateOfBirth.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ngày sinh'**
  String get authPickDateOfBirth;

  /// No description provided for @authProfileLoadFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được thông tin cá nhân.'**
  String get authProfileLoadFailed;

  /// No description provided for @authProfileLoadFailedRetry.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được thông tin cá nhân. Vui lòng thử lại.'**
  String get authProfileLoadFailedRetry;

  /// No description provided for @authProfileUpdateFailed.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật thông tin thất bại'**
  String get authProfileUpdateFailed;

  /// No description provided for @authProfileUpdateSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật thông tin cá nhân thành công.'**
  String get authProfileUpdateSuccess;

  /// No description provided for @authSaveChanges.
  ///
  /// In vi, this message translates to:
  /// **'Lưu thay đổi'**
  String get authSaveChanges;

  /// No description provided for @authSelect.
  ///
  /// In vi, this message translates to:
  /// **'Chọn'**
  String get authSelect;

  /// No description provided for @authStudentIdHelper.
  ///
  /// In vi, this message translates to:
  /// **'Mã sinh viên do nhà trường cấp, không thể tự sửa'**
  String get authStudentIdHelper;

  /// No description provided for @authStudentIdLabel.
  ///
  /// In vi, this message translates to:
  /// **'Mã sinh viên'**
  String get authStudentIdLabel;

  /// No description provided for @authUsernameHint.
  ///
  /// In vi, this message translates to:
  /// **'Nhập tên đăng nhập hoặc MSSV...'**
  String get authUsernameHint;

  /// No description provided for @authUsernameLabel.
  ///
  /// In vi, this message translates to:
  /// **'Tên đăng nhập / MSSV'**
  String get authUsernameLabel;

  /// No description provided for @authUsernameRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập tên đăng nhập hoặc MSSV'**
  String get authUsernameRequired;

  /// No description provided for @clearCacheAlreadyEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Bộ nhớ đệm đang trống'**
  String get clearCacheAlreadyEmpty;

  /// No description provided for @clearCacheConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Xoá ngay'**
  String get clearCacheConfirm;

  /// No description provided for @clearCacheDone.
  ///
  /// In vi, this message translates to:
  /// **'Đã xoá {size} bộ nhớ đệm'**
  String clearCacheDone(String size);

  /// No description provided for @clearCacheFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không xoá được bộ nhớ đệm: {error}'**
  String clearCacheFailed(String error);

  /// No description provided for @clearCacheMessage.
  ///
  /// In vi, this message translates to:
  /// **'Xoá ảnh tạm và tệp tải về trong máy. Bạn vẫn đăng nhập, không mất bài thi hay cài đặt.'**
  String get clearCacheMessage;

  /// No description provided for @clearCacheSize.
  ///
  /// In vi, this message translates to:
  /// **'Đang chiếm khoảng {size}'**
  String clearCacheSize(String size);

  /// No description provided for @clearCacheTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xoá bộ nhớ đệm'**
  String get clearCacheTitle;

  /// No description provided for @commonCancel.
  ///
  /// In vi, this message translates to:
  /// **'Huỷ'**
  String get commonCancel;

  /// No description provided for @commonClose.
  ///
  /// In vi, this message translates to:
  /// **'Đóng'**
  String get commonClose;

  /// No description provided for @commonConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận'**
  String get commonConfirm;

  /// No description provided for @commonLoading.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải...'**
  String get commonLoading;

  /// No description provided for @commonNotUpdated.
  ///
  /// In vi, this message translates to:
  /// **'Chưa cập nhật'**
  String get commonNotUpdated;

  /// No description provided for @commonReloadSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Tải lại dữ liệu thành công'**
  String get commonReloadSuccess;

  /// No description provided for @commonRetry.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại'**
  String get commonRetry;

  /// No description provided for @commonSave.
  ///
  /// In vi, this message translates to:
  /// **'Lưu'**
  String get commonSave;

  /// No description provided for @contactCopied.
  ///
  /// In vi, this message translates to:
  /// **'Đã sao chép {value}'**
  String contactCopied(String value);

  /// No description provided for @contactEmail.
  ///
  /// In vi, this message translates to:
  /// **'Gửi email'**
  String get contactEmail;

  /// No description provided for @contactHotline.
  ///
  /// In vi, this message translates to:
  /// **'Gọi hotline'**
  String get contactHotline;

  /// No description provided for @contactOpenFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không mở được: {value}'**
  String contactOpenFailed(String value);

  /// No description provided for @contactTitle.
  ///
  /// In vi, this message translates to:
  /// **'Liên hệ hỗ trợ'**
  String get contactTitle;

  /// No description provided for @contactWebsite.
  ///
  /// In vi, this message translates to:
  /// **'Mở website'**
  String get contactWebsite;

  /// No description provided for @deviceInfoAppName.
  ///
  /// In vi, this message translates to:
  /// **'Tên ứng dụng'**
  String get deviceInfoAppName;

  /// No description provided for @deviceInfoAppSection.
  ///
  /// In vi, this message translates to:
  /// **'Ứng dụng'**
  String get deviceInfoAppSection;

  /// No description provided for @deviceInfoBrand.
  ///
  /// In vi, this message translates to:
  /// **'Hãng sản xuất'**
  String get deviceInfoBrand;

  /// No description provided for @deviceInfoBuildNumber.
  ///
  /// In vi, this message translates to:
  /// **'Bản dựng'**
  String get deviceInfoBuildNumber;

  /// No description provided for @deviceInfoCopied.
  ///
  /// In vi, this message translates to:
  /// **'Đã sao chép thông tin thiết bị'**
  String get deviceInfoCopied;

  /// No description provided for @deviceInfoCopy.
  ///
  /// In vi, this message translates to:
  /// **'Sao chép thông tin'**
  String get deviceInfoCopy;

  /// No description provided for @deviceInfoDeviceSection.
  ///
  /// In vi, this message translates to:
  /// **'Thiết bị'**
  String get deviceInfoDeviceSection;

  /// No description provided for @deviceInfoDeviceType.
  ///
  /// In vi, this message translates to:
  /// **'Loại thiết bị'**
  String get deviceInfoDeviceType;

  /// No description provided for @deviceInfoEmulator.
  ///
  /// In vi, this message translates to:
  /// **'Máy ảo'**
  String get deviceInfoEmulator;

  /// No description provided for @deviceInfoLanguage.
  ///
  /// In vi, this message translates to:
  /// **'Ngôn ngữ app'**
  String get deviceInfoLanguage;

  /// No description provided for @deviceInfoLoadFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không đọc được thông tin thiết bị'**
  String get deviceInfoLoadFailed;

  /// No description provided for @deviceInfoModel.
  ///
  /// In vi, this message translates to:
  /// **'Kiểu máy'**
  String get deviceInfoModel;

  /// No description provided for @deviceInfoOs.
  ///
  /// In vi, this message translates to:
  /// **'Hệ điều hành'**
  String get deviceInfoOs;

  /// No description provided for @deviceInfoPackageName.
  ///
  /// In vi, this message translates to:
  /// **'Mã ứng dụng'**
  String get deviceInfoPackageName;

  /// No description provided for @deviceInfoPhysical.
  ///
  /// In vi, this message translates to:
  /// **'Máy thật'**
  String get deviceInfoPhysical;

  /// No description provided for @deviceInfoScreen.
  ///
  /// In vi, this message translates to:
  /// **'Màn hình'**
  String get deviceInfoScreen;

  /// No description provided for @deviceInfoTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin thiết bị'**
  String get deviceInfoTitle;

  /// No description provided for @deviceInfoVersion.
  ///
  /// In vi, this message translates to:
  /// **'Phiên bản'**
  String get deviceInfoVersion;

  /// No description provided for @examAllAnswersSaved.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu xong toàn bộ đáp án.'**
  String get examAllAnswersSaved;

  /// No description provided for @examAnsweredProgress.
  ///
  /// In vi, this message translates to:
  /// **'Đã trả lời: {answered}/{total}'**
  String examAnsweredProgress(int answered, int total);

  /// No description provided for @examAutoSubmitUnsavedWarning.
  ///
  /// In vi, this message translates to:
  /// **'Có {count} câu không lưu được lên máy chủ nên có thể không được chấm.'**
  String examAutoSubmitUnsavedWarning(int count);

  /// No description provided for @examCannotExitWarning.
  ///
  /// In vi, this message translates to:
  /// **'Không thể thoát khi đang làm bài! Vui lòng nộp bài để kết thúc.'**
  String get examCannotExitWarning;

  /// No description provided for @examCodeAppBarTitle.
  ///
  /// In vi, this message translates to:
  /// **'Làm kiểm tra'**
  String get examCodeAppBarTitle;

  /// No description provided for @examCodeCheckingButton.
  ///
  /// In vi, this message translates to:
  /// **'Đang kiểm tra...'**
  String get examCodeCheckingButton;

  /// No description provided for @examCodeCodeLabel.
  ///
  /// In vi, this message translates to:
  /// **'Mã ca thi'**
  String get examCodeCodeLabel;

  /// No description provided for @examCodeConfirmMessage.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có chắc chắn muốn bắt đầu làm bài? Sau khi vào thi, thời gian làm bài sẽ bắt đầu được tính.'**
  String get examCodeConfirmMessage;

  /// No description provided for @examCodeConfirmTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận vào thi'**
  String get examCodeConfirmTitle;

  /// No description provided for @examCodeCreatingSession.
  ///
  /// In vi, this message translates to:
  /// **'Đang tạo phiên thi...'**
  String get examCodeCreatingSession;

  /// No description provided for @examCodeDurationLabel.
  ///
  /// In vi, this message translates to:
  /// **'Thời lượng'**
  String get examCodeDurationLabel;

  /// No description provided for @examCodeDurationMinutes.
  ///
  /// In vi, this message translates to:
  /// **'{minutes} phút'**
  String examCodeDurationMinutes(int minutes);

  /// No description provided for @examCodeEmptyError.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập mã bài thi'**
  String get examCodeEmptyError;

  /// No description provided for @examCodeEndTimeLabel.
  ///
  /// In vi, this message translates to:
  /// **'Thời gian kết thúc'**
  String get examCodeEndTimeLabel;

  /// No description provided for @examCodeEnterRoomButton.
  ///
  /// In vi, this message translates to:
  /// **'Tìm ca thi'**
  String get examCodeEnterRoomButton;

  /// No description provided for @examCodeErrorTitle.
  ///
  /// In vi, this message translates to:
  /// **'Không thể bắt đầu làm bài'**
  String get examCodeErrorTitle;

  /// No description provided for @examCodeFieldHint.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ chữ cái, số và dấu gạch nối'**
  String get examCodeFieldHint;

  /// No description provided for @examCodeHeading.
  ///
  /// In vi, this message translates to:
  /// **'Làm kiểm tra'**
  String get examCodeHeading;

  /// No description provided for @examCodeHelpText.
  ///
  /// In vi, this message translates to:
  /// **'Mã ca thi chỉ được chứa chữ cái (A-Z), số (0-9) và dấu gạch nối (-). Ký tự đặc biệt sẽ bị tự động xóa.'**
  String get examCodeHelpText;

  /// No description provided for @examCodeLocationRequiredNotice.
  ///
  /// In vi, this message translates to:
  /// **'Ca thi này bắt buộc gửi vị trí GPS. Ứng dụng di động chưa hỗ trợ định vị nên rất có thể bạn sẽ không vào được từ đây.'**
  String get examCodeLocationRequiredNotice;

  /// No description provided for @examCodeSessionInfoTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin ca thi'**
  String get examCodeSessionInfoTitle;

  /// No description provided for @examCodeStartButton.
  ///
  /// In vi, this message translates to:
  /// **'Vào thi'**
  String get examCodeStartButton;

  /// No description provided for @examCodeStartTimeLabel.
  ///
  /// In vi, this message translates to:
  /// **'Thời gian bắt đầu'**
  String get examCodeStartTimeLabel;

  /// No description provided for @examCodeSubjectLabel.
  ///
  /// In vi, this message translates to:
  /// **'Môn thi'**
  String get examCodeSubjectLabel;

  /// No description provided for @examCodeSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Nhập mã bài thi được giáo viên cung cấp để bắt đầu làm bài.'**
  String get examCodeSubtitle;

  /// No description provided for @examDefaultTitle.
  ///
  /// In vi, this message translates to:
  /// **'Bài kiểm tra'**
  String get examDefaultTitle;

  /// No description provided for @examEnterOverlayHint.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng không thoát ứng dụng.'**
  String get examEnterOverlayHint;

  /// No description provided for @examEnterOverlayTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đang vào phòng thi'**
  String get examEnterOverlayTitle;

  /// No description provided for @examInfoQuestionsLabel.
  ///
  /// In vi, this message translates to:
  /// **'Câu hỏi'**
  String get examInfoQuestionsLabel;

  /// No description provided for @examInfoTimeLabel.
  ///
  /// In vi, this message translates to:
  /// **'Thời gian'**
  String get examInfoTimeLabel;

  /// No description provided for @examLoadError.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi: {error}'**
  String examLoadError(String error);

  /// No description provided for @examLocationDenied.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chưa cho phép ứng dụng truy cập vị trí. Cấp quyền rồi thử lại.'**
  String get examLocationDenied;

  /// No description provided for @examLocationDeniedForever.
  ///
  /// In vi, this message translates to:
  /// **'Quyền vị trí đang bị chặn. Mở Cài đặt để cấp lại quyền cho ứng dụng.'**
  String get examLocationDeniedForever;

  /// No description provided for @examLocationGetting.
  ///
  /// In vi, this message translates to:
  /// **'Đang lấy vị trí của bạn'**
  String get examLocationGetting;

  /// No description provided for @examLocationGettingHint.
  ///
  /// In vi, this message translates to:
  /// **'Ca thi này yêu cầu định vị. Ra chỗ thoáng giúp máy bắt tín hiệu nhanh hơn.'**
  String get examLocationGettingHint;

  /// No description provided for @examLocationServiceDisabled.
  ///
  /// In vi, this message translates to:
  /// **'Định vị trên máy đang tắt. Bật định vị rồi thử lại để vào thi.'**
  String get examLocationServiceDisabled;

  /// No description provided for @examLocationTimeout.
  ///
  /// In vi, this message translates to:
  /// **'Chưa lấy được vị trí. Ra chỗ thoáng hoặc kiểm tra GPS rồi thử lại.'**
  String get examLocationTimeout;

  /// No description provided for @examLookupOverlayTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đang tìm ca thi'**
  String get examLookupOverlayTitle;

  /// No description provided for @examNoData.
  ///
  /// In vi, this message translates to:
  /// **'Không có dữ liệu bài kiểm tra'**
  String get examNoData;

  /// No description provided for @examNoQuestions.
  ///
  /// In vi, this message translates to:
  /// **'Đề thi không có câu hỏi'**
  String get examNoQuestions;

  /// No description provided for @examNoticeDefaultMessage.
  ///
  /// In vi, this message translates to:
  /// **'Nếu bạn kiểm tra điểm cao thì chúc mừng bạn, nếu bạn kiểm tra không được tốt thì cũng đừng buồn chúng ta còn cơ hội cho lần sau. À làm gì có lần sau :>>>'**
  String get examNoticeDefaultMessage;

  /// No description provided for @examPartialLabel.
  ///
  /// In vi, this message translates to:
  /// **'Làm dở'**
  String get examPartialLabel;

  /// No description provided for @examPinQuestion.
  ///
  /// In vi, this message translates to:
  /// **'Ghim'**
  String get examPinQuestion;

  /// No description provided for @examPinnedHint.
  ///
  /// In vi, this message translates to:
  /// **'Ghim để đánh dấu câu cần xem lại'**
  String get examPinnedHint;

  /// No description provided for @examPinnedLabel.
  ///
  /// In vi, this message translates to:
  /// **'Đã ghim'**
  String get examPinnedLabel;

  /// Vị trí câu đang làm; label là nhãn số thứ tự, có thể là dải "3-7" với câu nối / TFNG
  ///
  /// In vi, this message translates to:
  /// **'Câu {label}/{total}'**
  String examQuestionProgress(String label, int total);

  /// No description provided for @examRealtimeAutoSubmittedTitle.
  ///
  /// In vi, this message translates to:
  /// **'Bài thi bị nộp tự động do vi phạm'**
  String get examRealtimeAutoSubmittedTitle;

  /// No description provided for @examRealtimeBlockedMessage.
  ///
  /// In vi, this message translates to:
  /// **'Giám thị đã dừng ca thi của bạn. Bài làm đã được nộp.'**
  String get examRealtimeBlockedMessage;

  /// No description provided for @examRealtimeBlockedTitle.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã bị chặn khỏi ca thi'**
  String get examRealtimeBlockedTitle;

  /// No description provided for @examRealtimeExtraTimeAdded.
  ///
  /// In vi, this message translates to:
  /// **'Giám thị cộng thêm {minutes} phút'**
  String examRealtimeExtraTimeAdded(int minutes);

  /// No description provided for @examRealtimeExtraTimeSubtracted.
  ///
  /// In vi, this message translates to:
  /// **'Giám thị trừ {minutes} phút'**
  String examRealtimeExtraTimeSubtracted(int minutes);

  /// No description provided for @examRealtimeTeacherMessageTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thông báo từ giám thị'**
  String get examRealtimeTeacherMessageTitle;

  /// No description provided for @examRealtimeTeacherSubmittedTitle.
  ///
  /// In vi, this message translates to:
  /// **'Giám thị đã nộp bài hộ bạn'**
  String get examRealtimeTeacherSubmittedTitle;

  /// No description provided for @examRealtimeViolationWarningMessage.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã có {count}/{threshold} lần vi phạm quy chế. Tiếp tục vi phạm có thể bị nộp bài tự động hoặc bị đình chỉ.'**
  String examRealtimeViolationWarningMessage(int count, int threshold);

  /// No description provided for @examRealtimeViolationWarningTitle.
  ///
  /// In vi, this message translates to:
  /// **'Cảnh báo vi phạm'**
  String get examRealtimeViolationWarningTitle;

  /// No description provided for @examRealtimeViolationWarningUnderstood.
  ///
  /// In vi, this message translates to:
  /// **'Tôi đã hiểu'**
  String get examRealtimeViolationWarningUnderstood;

  /// No description provided for @examResultHomeButton.
  ///
  /// In vi, this message translates to:
  /// **'Về trang chủ'**
  String get examResultHomeButton;

  /// No description provided for @examResultPendingSubmitFailed.
  ///
  /// In vi, this message translates to:
  /// **'Máy chủ không nhận bài'**
  String get examResultPendingSubmitFailed;

  /// No description provided for @examResultPendingSubmitFailedHint.
  ///
  /// In vi, this message translates to:
  /// **'Bài của bạn đã bị đóng trước khi gửi được. Hãy báo ngay cho giám thị để được xử lý.'**
  String get examResultPendingSubmitFailedHint;

  /// No description provided for @examResultPendingSubmitHint.
  ///
  /// In vi, this message translates to:
  /// **'Bài làm đã được ghi lại trên máy lúc {time}. Ứng dụng sẽ tự gửi ngay khi có mạng — bạn không cần làm gì thêm.'**
  String examResultPendingSubmitHint(String time);

  /// No description provided for @examResultPendingSubmitTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đang chờ mạng để gửi bài'**
  String get examResultPendingSubmitTitle;

  /// No description provided for @examResultTitle.
  ///
  /// In vi, this message translates to:
  /// **'Kết quả bài thi'**
  String get examResultTitle;

  /// No description provided for @examSavingIndicator.
  ///
  /// In vi, this message translates to:
  /// **'Đang lưu...'**
  String get examSavingIndicator;

  /// No description provided for @examScoreCommentAverage.
  ///
  /// In vi, this message translates to:
  /// **'Trung bình!'**
  String get examScoreCommentAverage;

  /// No description provided for @examScoreCommentExcellent.
  ///
  /// In vi, this message translates to:
  /// **'Xuất sắc!'**
  String get examScoreCommentExcellent;

  /// No description provided for @examScoreCommentFair.
  ///
  /// In vi, this message translates to:
  /// **'Khá!'**
  String get examScoreCommentFair;

  /// No description provided for @examScoreCommentGood.
  ///
  /// In vi, this message translates to:
  /// **'Giỏi!'**
  String get examScoreCommentGood;

  /// No description provided for @examScoreCommentNeedsImprovement.
  ///
  /// In vi, this message translates to:
  /// **'Cần cố gắng thêm!'**
  String get examScoreCommentNeedsImprovement;

  /// No description provided for @examScoreLabel.
  ///
  /// In vi, this message translates to:
  /// **'ĐIỂM CỦA BẠN'**
  String get examScoreLabel;

  /// No description provided for @examSubmitButton.
  ///
  /// In vi, this message translates to:
  /// **'Nộp bài'**
  String get examSubmitButton;

  /// No description provided for @examSubmitDialogAllAnswered.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã trả lời hết các câu.'**
  String get examSubmitDialogAllAnswered;

  /// No description provided for @examSubmitDialogAnsweredLabel.
  ///
  /// In vi, this message translates to:
  /// **'Đã trả lời'**
  String get examSubmitDialogAnsweredLabel;

  /// No description provided for @examSubmitDialogConfirmQuestion.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có chắc chắn muốn nộp bài không?'**
  String get examSubmitDialogConfirmQuestion;

  /// No description provided for @examSubmitDialogTitle.
  ///
  /// In vi, this message translates to:
  /// **'Nộp bài thi'**
  String get examSubmitDialogTitle;

  /// No description provided for @examSubmitDialogUnansweredLabel.
  ///
  /// In vi, this message translates to:
  /// **'Chưa trả lời'**
  String get examSubmitDialogUnansweredLabel;

  /// No description provided for @examSubmitDialogUnansweredWarning.
  ///
  /// In vi, this message translates to:
  /// **'Còn {count} câu chưa trả lời. Nộp bài rồi thì không quay lại sửa được nữa.'**
  String examSubmitDialogUnansweredWarning(int count);

  /// No description provided for @examSubmitDialogUnsavedWarning.
  ///
  /// In vi, this message translates to:
  /// **'⚠️ Còn {count} câu chưa lưu được lên máy chủ. Nếu nộp bây giờ, những câu đó có thể không được chấm.'**
  String examSubmitDialogUnsavedWarning(int count);

  /// No description provided for @examSubmitError.
  ///
  /// In vi, this message translates to:
  /// **'Có lỗi xảy ra khi nộp bài: {error}'**
  String examSubmitError(String error);

  /// No description provided for @examSubmitFailedMessage.
  ///
  /// In vi, this message translates to:
  /// **'Máy chủ chưa ghi nhận bài nộp của bạn. Các đáp án đã chọn vẫn được lưu — hãy kiểm tra kết nối mạng rồi bấm Thử lại.'**
  String get examSubmitFailedMessage;

  /// No description provided for @examSubmitFailedTitle.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi khi nộp bài'**
  String get examSubmitFailedTitle;

  /// No description provided for @examSubmitOverlayHint.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng giữ ứng dụng mở cho tới khi xong.'**
  String get examSubmitOverlayHint;

  /// No description provided for @examSubmitOverlayTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đang nộp bài'**
  String get examSubmitOverlayTitle;

  /// No description provided for @examSubmitQueuedMessage.
  ///
  /// In vi, this message translates to:
  /// **'Mất kết nối nên bài chưa gửi được. Giờ nộp của bạn đã được ghi lại, ứng dụng sẽ tự gửi khi có mạng.'**
  String get examSubmitQueuedMessage;

  /// No description provided for @examSubmitQueuedTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đã ghi nhận giờ nộp'**
  String get examSubmitQueuedTitle;

  /// No description provided for @examSubmitSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Nộp bài thành công'**
  String get examSubmitSuccess;

  /// No description provided for @examTimeUpBannerTitle.
  ///
  /// In vi, this message translates to:
  /// **'Hết giờ!'**
  String get examTimeUpBannerTitle;

  /// No description provided for @examTimeUpLockedHint.
  ///
  /// In vi, this message translates to:
  /// **'Bài đã được khoá, bạn không thể thay đổi đáp án nữa.'**
  String get examTimeUpLockedHint;

  /// No description provided for @examTimeUpSavingAnswers.
  ///
  /// In vi, this message translates to:
  /// **'Đang chờ lưu nốt các đáp án đã chọn...'**
  String get examTimeUpSavingAnswers;

  /// No description provided for @examTimeUpSubmitting.
  ///
  /// In vi, this message translates to:
  /// **'Đang tự động nộp bài...'**
  String get examTimeUpSubmitting;

  /// No description provided for @examTimeUpToastMessage.
  ///
  /// In vi, this message translates to:
  /// **'Bài thi đang được nộp tự động. Vui lòng không thoát ứng dụng.'**
  String get examTimeUpToastMessage;

  /// No description provided for @examOfflineBannerTitle.
  ///
  /// In vi, this message translates to:
  /// **'Mất kết nối'**
  String get examOfflineBannerTitle;

  /// No description provided for @examOfflineBannerHint.
  ///
  /// In vi, this message translates to:
  /// **'Đáp án vẫn được lưu trên máy và sẽ tự gửi lên khi có mạng lại.'**
  String get examOfflineBannerHint;

  /// No description provided for @examOfflineRetryFailed.
  ///
  /// In vi, this message translates to:
  /// **'Vẫn chưa gửi được. Kiểm tra mạng rồi thử lại.'**
  String get examOfflineRetryFailed;

  /// No description provided for @examUnlimitedTime.
  ///
  /// In vi, this message translates to:
  /// **'Không giới hạn'**
  String get examUnlimitedTime;

  /// No description provided for @examUnpinQuestion.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ ghim'**
  String get examUnpinQuestion;

  /// No description provided for @feedbackAttachNote.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin máy và phiên bản app được đính kèm tự động để dò lỗi nhanh hơn.'**
  String get feedbackAttachNote;

  /// No description provided for @feedbackContactHint.
  ///
  /// In vi, this message translates to:
  /// **'Để bên hỗ trợ liên hệ lại khi cần'**
  String get feedbackContactHint;

  /// No description provided for @feedbackContactLabel.
  ///
  /// In vi, this message translates to:
  /// **'Email / số điện thoại của bạn (không bắt buộc)'**
  String get feedbackContactLabel;

  /// No description provided for @feedbackContentHint.
  ///
  /// In vi, this message translates to:
  /// **'Mô tả lỗi bạn gặp, hoặc điều bạn muốn app làm tốt hơn...'**
  String get feedbackContentHint;

  /// No description provided for @feedbackContentLabel.
  ///
  /// In vi, this message translates to:
  /// **'Nội dung'**
  String get feedbackContentLabel;

  /// No description provided for @feedbackContentRequired.
  ///
  /// In vi, this message translates to:
  /// **'Nhập nội dung trước khi gửi'**
  String get feedbackContentRequired;

  /// No description provided for @feedbackMailFallback.
  ///
  /// In vi, this message translates to:
  /// **'Máy chưa có ứng dụng email. Nội dung đã được sao chép, bạn gửi giúp tới {email}.'**
  String feedbackMailFallback(String email);

  /// No description provided for @feedbackSend.
  ///
  /// In vi, this message translates to:
  /// **'Gửi'**
  String get feedbackSend;

  /// No description provided for @feedbackTitle.
  ///
  /// In vi, this message translates to:
  /// **'Báo lỗi / góp ý'**
  String get feedbackTitle;

  /// No description provided for @feedbackTypeBug.
  ///
  /// In vi, this message translates to:
  /// **'Báo lỗi'**
  String get feedbackTypeBug;

  /// No description provided for @feedbackTypeIdea.
  ///
  /// In vi, this message translates to:
  /// **'Góp ý'**
  String get feedbackTypeIdea;

  /// No description provided for @historyBadgeExtraMinutes.
  ///
  /// In vi, this message translates to:
  /// **'+{count} phút'**
  String historyBadgeExtraMinutes(int count);

  /// No description provided for @historyBadgeViolations.
  ///
  /// In vi, this message translates to:
  /// **'{count} vi phạm'**
  String historyBadgeViolations(int count);

  /// No description provided for @historyBlockedClosed.
  ///
  /// In vi, this message translates to:
  /// **'Đã hết hạn xem lại'**
  String get historyBlockedClosed;

  /// No description provided for @historyBlockedNotAllowed.
  ///
  /// In vi, this message translates to:
  /// **'Ca thi không cho xem lại bài'**
  String get historyBlockedNotAllowed;

  /// No description provided for @historyBlockedNotCompleted.
  ///
  /// In vi, this message translates to:
  /// **'Bài đang được mở lại để làm lại'**
  String get historyBlockedNotCompleted;

  /// No description provided for @historyBlockedNotOpenYet.
  ///
  /// In vi, this message translates to:
  /// **'Mở xem lại từ {time}'**
  String historyBlockedNotOpenYet(String time);

  /// No description provided for @historyBlockedNotOpenYetGeneric.
  ///
  /// In vi, this message translates to:
  /// **'Chưa tới giờ mở xem lại bài'**
  String get historyBlockedNotOpenYetGeneric;

  /// No description provided for @historyColCorrect.
  ///
  /// In vi, this message translates to:
  /// **'Số câu đúng'**
  String get historyColCorrect;

  /// No description provided for @historyColDuration.
  ///
  /// In vi, this message translates to:
  /// **'Thời gian làm'**
  String get historyColDuration;

  /// No description provided for @historyColExamDate.
  ///
  /// In vi, this message translates to:
  /// **'Ngày thi'**
  String get historyColExamDate;

  /// No description provided for @historyColScore.
  ///
  /// In vi, this message translates to:
  /// **'Điểm'**
  String get historyColScore;

  /// No description provided for @historyDurationMinutes.
  ///
  /// In vi, this message translates to:
  /// **'{count} phút'**
  String historyDurationMinutes(int count);

  /// No description provided for @historyEmptyDesc.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chưa hoàn thành bài thi nào. Sau khi nộp bài, bài làm sẽ xuất hiện ở đây.'**
  String get historyEmptyDesc;

  /// No description provided for @historyEmptyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có bài thi nào'**
  String get historyEmptyTitle;

  /// No description provided for @historyGoToExam.
  ///
  /// In vi, this message translates to:
  /// **'Vào thi'**
  String get historyGoToExam;

  /// No description provided for @historyLoadFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được lịch sử làm bài'**
  String get historyLoadFailed;

  /// No description provided for @historyOpenFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không mở được bài thi'**
  String get historyOpenFailed;

  /// No description provided for @historyOpening.
  ///
  /// In vi, this message translates to:
  /// **'Đang mở...'**
  String get historyOpening;

  /// No description provided for @historyReview.
  ///
  /// In vi, this message translates to:
  /// **'Xem lại'**
  String get historyReview;

  /// No description provided for @historyReviewWithAnswerKey.
  ///
  /// In vi, this message translates to:
  /// **'Xem lại bài kèm đáp án đúng'**
  String get historyReviewWithAnswerKey;

  /// No description provided for @historyReviewWithoutAnswerKey.
  ///
  /// In vi, this message translates to:
  /// **'Xem lại bài, không hiện đáp án đúng'**
  String get historyReviewWithoutAnswerKey;

  /// No description provided for @historyReviewWithoutQuestionDetail.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ xem được câu đúng/sai, không có nội dung câu hỏi'**
  String get historyReviewWithoutQuestionDetail;

  /// No description provided for @historyStatAverage.
  ///
  /// In vi, this message translates to:
  /// **'Điểm trung bình'**
  String get historyStatAverage;

  /// No description provided for @historyStatBest.
  ///
  /// In vi, this message translates to:
  /// **'Điểm cao nhất'**
  String get historyStatBest;

  /// No description provided for @historyStatTotal.
  ///
  /// In vi, this message translates to:
  /// **'Số bài đã thi'**
  String get historyStatTotal;

  /// No description provided for @historyStatViolations.
  ///
  /// In vi, this message translates to:
  /// **'Tổng vi phạm'**
  String get historyStatViolations;

  /// No description provided for @historySubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Danh sách các bài thi bạn đã hoàn thành'**
  String get historySubtitle;

  /// No description provided for @historyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Lịch sử làm bài'**
  String get historyTitle;

  /// No description provided for @historyUnknownSubject.
  ///
  /// In vi, this message translates to:
  /// **'Không rõ môn thi'**
  String get historyUnknownSubject;

  /// No description provided for @homeNavAccount.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản'**
  String get homeNavAccount;

  /// No description provided for @homeNavHistory.
  ///
  /// In vi, this message translates to:
  /// **'Lịch sử'**
  String get homeNavHistory;

  /// No description provided for @homeNavHome.
  ///
  /// In vi, this message translates to:
  /// **'Trang chủ'**
  String get homeNavHome;

  /// No description provided for @homeNewsEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có tin nào.'**
  String get homeNewsEmpty;

  /// No description provided for @homeNewsError.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được tin giáo dục.'**
  String get homeNewsError;

  /// No description provided for @homeNewsOpenFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không mở được bài viết.'**
  String get homeNewsOpenFailed;

  /// No description provided for @homeNewsRetry.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại'**
  String get homeNewsRetry;

  /// No description provided for @homeNewsSource.
  ///
  /// In vi, this message translates to:
  /// **'Nguồn: VnExpress'**
  String get homeNewsSource;

  /// No description provided for @homeNewsTimeDays.
  ///
  /// In vi, this message translates to:
  /// **'{days} ngày trước'**
  String homeNewsTimeDays(int days);

  /// No description provided for @homeNewsTimeHours.
  ///
  /// In vi, this message translates to:
  /// **'{hours} giờ trước'**
  String homeNewsTimeHours(int hours);

  /// No description provided for @homeNewsTimeJustNow.
  ///
  /// In vi, this message translates to:
  /// **'Vừa xong'**
  String get homeNewsTimeJustNow;

  /// No description provided for @homeNewsTimeMinutes.
  ///
  /// In vi, this message translates to:
  /// **'{minutes} phút trước'**
  String homeNewsTimeMinutes(int minutes);

  /// No description provided for @homeNewsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tin giáo dục'**
  String get homeNewsTitle;

  /// No description provided for @homeQrExamCreatedAt.
  ///
  /// In vi, this message translates to:
  /// **'Ngày tạo'**
  String get homeQrExamCreatedAt;

  /// No description provided for @homeQrExamDescription.
  ///
  /// In vi, this message translates to:
  /// **'Mô tả'**
  String get homeQrExamDescription;

  /// No description provided for @homeQrExamDuration.
  ///
  /// In vi, this message translates to:
  /// **'Thời gian'**
  String get homeQrExamDuration;

  /// No description provided for @homeQrExamDurationMinutes.
  ///
  /// In vi, this message translates to:
  /// **'{minutes} phút'**
  String homeQrExamDurationMinutes(String minutes);

  /// No description provided for @homeQrExamFallbackTitle.
  ///
  /// In vi, this message translates to:
  /// **'Bài thi'**
  String get homeQrExamFallbackTitle;

  /// No description provided for @homeQrExamInfoLabel.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin bài thi'**
  String get homeQrExamInfoLabel;

  /// No description provided for @homeQrExamSubject.
  ///
  /// In vi, this message translates to:
  /// **'Môn học'**
  String get homeQrExamSubject;

  /// No description provided for @homeQrInvalidTitle.
  ///
  /// In vi, this message translates to:
  /// **'Mã QR không hợp lệ'**
  String get homeQrInvalidTitle;

  /// No description provided for @homeQrMissingExamCode.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy mã đề trong QR.'**
  String get homeQrMissingExamCode;

  /// No description provided for @homeQrScanTitle.
  ///
  /// In vi, this message translates to:
  /// **'Quét mã QR bài thi'**
  String get homeQrScanTitle;

  /// No description provided for @homeQrStartExamFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không thể tạo ca thi từ QR.\nVui lòng thử lại.'**
  String get homeQrStartExamFailed;

  /// No description provided for @homeQrWrongFormatMessage.
  ///
  /// In vi, this message translates to:
  /// **'Mã QR không đúng định dạng bài thi.\nVui lòng quét mã QR hợp lệ.'**
  String get homeQrWrongFormatMessage;

  /// No description provided for @homeQuickExamButton.
  ///
  /// In vi, this message translates to:
  /// **'Kiểm tra nhanh'**
  String get homeQuickExamButton;

  /// No description provided for @homeScanExamQrButton.
  ///
  /// In vi, this message translates to:
  /// **'Quét mã bài thi'**
  String get homeScanExamQrButton;

  /// No description provided for @msgAuthAccountLocked.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản đã bị khoá.'**
  String get msgAuthAccountLocked;

  /// No description provided for @msgAuthInvalidCredentials.
  ///
  /// In vi, this message translates to:
  /// **'Sai tài khoản hoặc mật khẩu.'**
  String get msgAuthInvalidCredentials;

  /// No description provided for @msgAuthInvalidData.
  ///
  /// In vi, this message translates to:
  /// **'Dữ liệu không hợp lệ.'**
  String get msgAuthInvalidData;

  /// No description provided for @msgAvatarFileTooLarge.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh vượt quá 10MB. Hãy chọn ảnh nhỏ hơn.'**
  String get msgAvatarFileTooLarge;

  /// No description provided for @msgAvatarFormatUnsupported.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ nhận ảnh JPG, PNG, GIF, WEBP hoặc BMP.'**
  String get msgAvatarFormatUnsupported;

  /// No description provided for @msgAvatarUploadFailed.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật ảnh đại diện thất bại.'**
  String get msgAvatarUploadFailed;

  /// No description provided for @msgChangePasswordFailed.
  ///
  /// In vi, this message translates to:
  /// **'Đổi mật khẩu thất bại'**
  String get msgChangePasswordFailed;

  /// No description provided for @msgErrorWithDetail.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi: {error}'**
  String msgErrorWithDetail(String error);

  /// No description provided for @msgExamDataUnreadable.
  ///
  /// In vi, this message translates to:
  /// **'Máy chủ đã nhận yêu cầu nhưng ứng dụng không đọc được dữ liệu đề thi. Đừng thử lại nhiều lần vì mỗi lần vào thi có thể tính một lượt làm bài — hãy báo giáo viên hoặc kỹ thuật viên.'**
  String get msgExamDataUnreadable;

  /// No description provided for @msgExamHistoryFetchFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được lịch sử làm bài.'**
  String get msgExamHistoryFetchFailed;

  /// No description provided for @msgExamReviewNotAllowed.
  ///
  /// In vi, this message translates to:
  /// **'Bài này chưa được phép xem lại.'**
  String get msgExamReviewNotAllowed;

  /// No description provided for @msgExamReviewOpenFailed.
  ///
  /// In vi, this message translates to:
  /// **'Máy chủ gặp lỗi khi mở bài. Vui lòng thử lại.'**
  String get msgExamReviewOpenFailed;

  /// No description provided for @msgExamSessionCoreRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập mã ca thi.'**
  String get msgExamSessionCoreRequired;

  /// No description provided for @msgExamSessionFetchFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không lấy được thông tin ca thi. Vui lòng thử lại.'**
  String get msgExamSessionFetchFailed;

  /// No description provided for @msgExamSessionNotFound.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy phiên thi với mã này'**
  String get msgExamSessionNotFound;

  /// No description provided for @msgLoginFailed.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập thất bại'**
  String get msgLoginFailed;

  /// No description provided for @msgLoginPasswordRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập mật khẩu'**
  String get msgLoginPasswordRequired;

  /// No description provided for @msgLoginPasswordTooShort.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu phải từ 6 ký tự trở lên'**
  String get msgLoginPasswordTooShort;

  /// No description provided for @msgLoginUserNameRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập tên đăng nhập / MSSV'**
  String get msgLoginUserNameRequired;

  /// No description provided for @msgProfileUpdateFailed.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật thông tin thất bại'**
  String get msgProfileUpdateFailed;

  /// No description provided for @msgSaveAnswerFailed.
  ///
  /// In vi, this message translates to:
  /// **'Máy chủ không nhận đáp án này. Hãy báo giám thị nếu tình trạng lặp lại.'**
  String get msgSaveAnswerFailed;

  /// No description provided for @msgSaveAnswerOffline.
  ///
  /// In vi, this message translates to:
  /// **'Mất kết nối nên chưa lưu được đáp án lên máy chủ.'**
  String get msgSaveAnswerOffline;

  /// No description provided for @msgSaveAnswerServerError.
  ///
  /// In vi, this message translates to:
  /// **'Máy chủ đang gặp lỗi nên chưa lưu được đáp án.'**
  String get msgSaveAnswerServerError;

  /// No description provided for @msgServerUnreachable.
  ///
  /// In vi, this message translates to:
  /// **'Không kết nối được máy chủ. Vui lòng thử lại.'**
  String get msgServerUnreachable;

  /// No description provided for @msgStudentExamSessionCreateFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không vào được ca thi này. Có thể chưa tới giờ, đã hết giờ, hết chỗ hoặc bạn đã dùng hết lượt làm bài.'**
  String get msgStudentExamSessionCreateFailed;

  /// No description provided for @msgStudentExamSessionCreateServerError.
  ///
  /// In vi, this message translates to:
  /// **'Máy chủ gặp lỗi khi tạo phiên thi. Vui lòng thử lại sau.'**
  String get msgStudentExamSessionCreateServerError;

  /// No description provided for @msgStudentLocationRequired.
  ///
  /// In vi, this message translates to:
  /// **'Ca thi này bắt buộc gửi vị trí GPS. Ứng dụng di động chưa hỗ trợ định vị nên bạn chưa vào được ca thi từ đây; hãy vào bằng trình duyệt trên máy tính.'**
  String get msgStudentLocationRequired;

  /// No description provided for @msgStudentProfileFetchFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được thông tin sinh viên.'**
  String get msgStudentProfileFetchFailed;

  /// No description provided for @msgStudentProfileNotFound.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy thông tin sinh viên.'**
  String get msgStudentProfileNotFound;

  /// No description provided for @msgSubmitExamRejected.
  ///
  /// In vi, this message translates to:
  /// **'Máy chủ không nhận bài nộp này.'**
  String get msgSubmitExamRejected;

  /// No description provided for @msgSubmitExamSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Nộp bài thành công'**
  String get msgSubmitExamSuccess;

  /// No description provided for @msgUserAvatarFileRequired.
  ///
  /// In vi, this message translates to:
  /// **'Chưa chọn ảnh để tải lên.'**
  String get msgUserAvatarFileRequired;

  /// No description provided for @msgUserAvatarUpdateFailed.
  ///
  /// In vi, this message translates to:
  /// **'Tải ảnh lên được nhưng chưa gắn được vào tài khoản.'**
  String get msgUserAvatarUpdateFailed;

  /// No description provided for @msgUserAvatarUploadFailed.
  ///
  /// In vi, this message translates to:
  /// **'Máy chủ không nhận được ảnh. Vui lòng thử lại.'**
  String get msgUserAvatarUploadFailed;

  /// No description provided for @msgUserChangePasswordFailed.
  ///
  /// In vi, this message translates to:
  /// **'Đổi mật khẩu thất bại.'**
  String get msgUserChangePasswordFailed;

  /// No description provided for @msgUserChangePasswordServerError.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi server khi đổi mật khẩu.'**
  String get msgUserChangePasswordServerError;

  /// No description provided for @msgUserChangePasswordSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đổi mật khẩu thành công.'**
  String get msgUserChangePasswordSuccess;

  /// No description provided for @msgUserProfileUpdateSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật thông tin cá nhân thành công.'**
  String get msgUserProfileUpdateSuccess;

  /// No description provided for @msgUserTokenMissing.
  ///
  /// In vi, this message translates to:
  /// **'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.'**
  String get msgUserTokenMissing;

  /// No description provided for @msgUserUpdateFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không thể cập nhật thông tin người dùng.'**
  String get msgUserUpdateFailed;

  /// No description provided for @msgValidationCompareMismatch.
  ///
  /// In vi, this message translates to:
  /// **'Giá trị xác nhận không khớp.'**
  String get msgValidationCompareMismatch;

  /// No description provided for @msgValidationEmailDuplicated.
  ///
  /// In vi, this message translates to:
  /// **'Email đã được sử dụng.'**
  String get msgValidationEmailDuplicated;

  /// No description provided for @msgValidationEmailInvalid.
  ///
  /// In vi, this message translates to:
  /// **'Email không hợp lệ.'**
  String get msgValidationEmailInvalid;

  /// No description provided for @msgValidationFieldInvalid.
  ///
  /// In vi, this message translates to:
  /// **'Trường dữ liệu không hợp lệ.'**
  String get msgValidationFieldInvalid;

  /// No description provided for @msgValidationFieldRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập đầy đủ thông tin bắt buộc.'**
  String get msgValidationFieldRequired;

  /// No description provided for @msgValidationInvalid.
  ///
  /// In vi, this message translates to:
  /// **'Dữ liệu không hợp lệ.'**
  String get msgValidationInvalid;

  /// No description provided for @msgValidationMaxLength.
  ///
  /// In vi, this message translates to:
  /// **'Giá trị vượt quá độ dài cho phép.'**
  String get msgValidationMaxLength;

  /// No description provided for @msgValidationMinLength.
  ///
  /// In vi, this message translates to:
  /// **'Giá trị chưa đạt độ dài tối thiểu.'**
  String get msgValidationMinLength;

  /// No description provided for @msgValidationPasswordCurrentIncorrect.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu hiện tại không đúng.'**
  String get msgValidationPasswordCurrentIncorrect;

  /// No description provided for @msgValidationPasswordRequiresDigit.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu phải có ít nhất một chữ số.'**
  String get msgValidationPasswordRequiresDigit;

  /// No description provided for @msgValidationPasswordRequiresLower.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu phải có ít nhất một chữ thường.'**
  String get msgValidationPasswordRequiresLower;

  /// No description provided for @msgValidationPasswordRequiresSymbol.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu phải có ít nhất một ký tự đặc biệt.'**
  String get msgValidationPasswordRequiresSymbol;

  /// No description provided for @msgValidationPasswordRequiresUniqueChars.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu phải có nhiều ký tự khác nhau hơn.'**
  String get msgValidationPasswordRequiresUniqueChars;

  /// No description provided for @msgValidationPasswordRequiresUpper.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu phải có ít nhất một chữ hoa.'**
  String get msgValidationPasswordRequiresUpper;

  /// No description provided for @msgValidationPasswordTooShort.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu quá ngắn.'**
  String get msgValidationPasswordTooShort;

  /// No description provided for @msgValidationPhoneInvalid.
  ///
  /// In vi, this message translates to:
  /// **'Số điện thoại không hợp lệ.'**
  String get msgValidationPhoneInvalid;

  /// No description provided for @msgValidationTokenInvalid.
  ///
  /// In vi, this message translates to:
  /// **'Mã xác thực không hợp lệ hoặc đã hết hạn.'**
  String get msgValidationTokenInvalid;

  /// No description provided for @msgValidationUserNotFound.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy người dùng.'**
  String get msgValidationUserNotFound;

  /// No description provided for @msgValidationUsernameDuplicated.
  ///
  /// In vi, this message translates to:
  /// **'Tên đăng nhập đã tồn tại.'**
  String get msgValidationUsernameDuplicated;

  /// No description provided for @notificationsEmptyMessage.
  ///
  /// In vi, this message translates to:
  /// **'Thông báo về ca thi, điểm và nhắc nhở của giáo viên sẽ hiện ở đây.'**
  String get notificationsEmptyMessage;

  /// No description provided for @notificationsEmptyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có thông báo'**
  String get notificationsEmptyTitle;

  /// No description provided for @notificationsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thông báo'**
  String get notificationsTitle;

  /// Cảnh báo sẽ tự động nộp bài khi đủ số lần vi phạm
  ///
  /// In vi, this message translates to:
  /// **'Đủ {max} lần sẽ tự động nộp bài.'**
  String questionAntiCheatAutoSubmitNotice(int max);

  /// No description provided for @questionAntiCheatLeftApp.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã rời khỏi ứng dụng thi.'**
  String get questionAntiCheatLeftApp;

  /// No description provided for @questionAntiCheatOverlayDetected.
  ///
  /// In vi, this message translates to:
  /// **'Phát hiện có ứng dụng hoặc cửa sổ khác đè lên ứng dụng thi!'**
  String get questionAntiCheatOverlayDetected;

  /// No description provided for @questionAntiCheatRotationBlockedSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Màn hình sẽ tự động quay lại sau vài giây'**
  String get questionAntiCheatRotationBlockedSubtitle;

  /// No description provided for @questionAntiCheatRotationBlockedTitle.
  ///
  /// In vi, this message translates to:
  /// **'Không được quay màn hình!'**
  String get questionAntiCheatRotationBlockedTitle;

  /// No description provided for @questionAntiCheatRotationDetected.
  ///
  /// In vi, this message translates to:
  /// **'Phát hiện quay màn hình trong lúc thi!'**
  String get questionAntiCheatRotationDetected;

  /// No description provided for @questionAntiCheatScreenRecordingDetected.
  ///
  /// In vi, this message translates to:
  /// **'Phát hiện ghi màn hình!'**
  String get questionAntiCheatScreenRecordingDetected;

  /// No description provided for @questionAntiCheatScreenshotDetected.
  ///
  /// In vi, this message translates to:
  /// **'Phát hiện chụp màn hình!'**
  String get questionAntiCheatScreenshotDetected;

  /// No description provided for @questionAntiCheatUnderstood.
  ///
  /// In vi, this message translates to:
  /// **'Tôi hiểu'**
  String get questionAntiCheatUnderstood;

  /// Số lần vi phạm hiện tại trên tổng số lần cho phép
  ///
  /// In vi, this message translates to:
  /// **'Vi phạm: {count}/{max}'**
  String questionAntiCheatViolationCount(int count, int max);

  /// No description provided for @questionAntiCheatWarningTitle.
  ///
  /// In vi, this message translates to:
  /// **'Cảnh báo gian lận!'**
  String get questionAntiCheatWarningTitle;

  /// No description provided for @questionBlankClear.
  ///
  /// In vi, this message translates to:
  /// **'Gỡ đáp án khỏi ô trống'**
  String get questionBlankClear;

  /// No description provided for @questionBlankLabel.
  ///
  /// In vi, this message translates to:
  /// **'Ô trống {number}'**
  String questionBlankLabel(int number);

  /// No description provided for @questionBlankProgress.
  ///
  /// In vi, this message translates to:
  /// **'Đã điền {filled}/{total}'**
  String questionBlankProgress(int filled, int total);

  /// No description provided for @questionDifficultyEasy.
  ///
  /// In vi, this message translates to:
  /// **'Mức độ: Dễ'**
  String get questionDifficultyEasy;

  /// No description provided for @questionDifficultyHard.
  ///
  /// In vi, this message translates to:
  /// **'Mức độ: Khó'**
  String get questionDifficultyHard;

  /// Mức độ khó không xác định, hiển thị bằng số
  ///
  /// In vi, this message translates to:
  /// **'Mức độ {level}'**
  String questionDifficultyLevel(int level);

  /// No description provided for @questionDifficultyMedium.
  ///
  /// In vi, this message translates to:
  /// **'Mức độ: Trung bình'**
  String get questionDifficultyMedium;

  /// No description provided for @questionDifficultyVeryHard.
  ///
  /// In vi, this message translates to:
  /// **'Mức độ: Rất khó'**
  String get questionDifficultyVeryHard;

  /// Gợi ý cho ô chọn thả xuống theo số thứ tự chỗ trống
  ///
  /// In vi, this message translates to:
  /// **'({number}) Chọn...'**
  String questionDropdownHint(int number);

  /// No description provided for @questionDropdownInstruction.
  ///
  /// In vi, this message translates to:
  /// **'Chạm vào ô trống để chọn đáp án:'**
  String get questionDropdownInstruction;

  /// No description provided for @questionDropdownPlaceholder.
  ///
  /// In vi, this message translates to:
  /// **'-- Chọn --'**
  String get questionDropdownPlaceholder;

  /// No description provided for @questionFillBlankAllWordsUsed.
  ///
  /// In vi, this message translates to:
  /// **'Đã dùng hết từ trong ngân hàng'**
  String get questionFillBlankAllWordsUsed;

  /// No description provided for @questionFillBlankInstruction.
  ///
  /// In vi, this message translates to:
  /// **'Nhấn vào từ, sau đó nhấn vào ô trống:'**
  String get questionFillBlankInstruction;

  /// No description provided for @questionHighlightClear.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ chọn hết'**
  String get questionHighlightClear;

  /// No description provided for @questionHighlightExtraHint.
  ///
  /// In vi, this message translates to:
  /// **'Nhập nội dung bổ sung...'**
  String get questionHighlightExtraHint;

  /// No description provided for @questionHighlightExtraLabel.
  ///
  /// In vi, this message translates to:
  /// **'Phần bổ sung (nếu có)'**
  String get questionHighlightExtraLabel;

  /// No description provided for @questionHighlightInstruction.
  ///
  /// In vi, this message translates to:
  /// **'Chọn các phần cần bôi trong đoạn văn:'**
  String get questionHighlightInstruction;

  /// No description provided for @questionHighlightSelectedCount.
  ///
  /// In vi, this message translates to:
  /// **'Đã chọn {count} phần'**
  String questionHighlightSelectedCount(int count);

  /// No description provided for @questionImageLoadFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không thể tải hình ảnh'**
  String get questionImageLoadFailed;

  /// No description provided for @questionImageNoUrl.
  ///
  /// In vi, this message translates to:
  /// **'Không có URL hình ảnh'**
  String get questionImageNoUrl;

  /// No description provided for @questionLegendAnswered.
  ///
  /// In vi, this message translates to:
  /// **'Đã trả lời'**
  String get questionLegendAnswered;

  /// No description provided for @questionLegendCurrent.
  ///
  /// In vi, this message translates to:
  /// **'Đang làm'**
  String get questionLegendCurrent;

  /// No description provided for @questionListTitle.
  ///
  /// In vi, this message translates to:
  /// **'Danh sách câu hỏi'**
  String get questionListTitle;

  /// No description provided for @questionMatchingColumnA.
  ///
  /// In vi, this message translates to:
  /// **'Cột A'**
  String get questionMatchingColumnA;

  /// No description provided for @questionMatchingColumnB.
  ///
  /// In vi, this message translates to:
  /// **'Cột B'**
  String get questionMatchingColumnB;

  /// No description provided for @questionMatchingEmptySlot.
  ///
  /// In vi, this message translates to:
  /// **'Chưa nối'**
  String get questionMatchingEmptySlot;

  /// No description provided for @questionMatchingInstruction.
  ///
  /// In vi, this message translates to:
  /// **'Hướng dẫn: Nhấn vào 1 vế Cột A, sau đó nhấn vế tương ứng ở Cột B để nối.'**
  String get questionMatchingInstruction;

  /// No description provided for @questionMatchingLinkedCount.
  ///
  /// In vi, this message translates to:
  /// **'Đã nối {linked}/{total}'**
  String questionMatchingLinkedCount(int linked, int total);

  /// No description provided for @questionMatchingPickColumnAFirst.
  ///
  /// In vi, this message translates to:
  /// **'Chọn một vế ở cột A trước'**
  String get questionMatchingPickColumnAFirst;

  /// No description provided for @questionMultipleChoiceInstruction.
  ///
  /// In vi, this message translates to:
  /// **'Hãy chọn một hoặc nhiều đáp án:'**
  String get questionMultipleChoiceInstruction;

  /// No description provided for @questionNext.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp theo'**
  String get questionNext;

  /// Nhãn số thứ tự câu hỏi trên tổng số câu; label có thể là dải "3-7" với câu nối / TFNG
  ///
  /// In vi, this message translates to:
  /// **'Câu {label} / {total}'**
  String questionNumberOfTotal(String label, int total);

  /// No description provided for @questionOrderingInstruction.
  ///
  /// In vi, this message translates to:
  /// **'Kéo thả các biểu tượng bên phải để sắp xếp theo thứ tự đúng:'**
  String get questionOrderingInstruction;

  /// No description provided for @questionPrevious.
  ///
  /// In vi, this message translates to:
  /// **'Trước'**
  String get questionPrevious;

  /// No description provided for @questionReadingPassageLabel.
  ///
  /// In vi, this message translates to:
  /// **'Bài đọc / Ngữ cảnh:'**
  String get questionReadingPassageLabel;

  /// No description provided for @questionShortAnswerHint.
  ///
  /// In vi, this message translates to:
  /// **'Nhập câu trả lời của bạn tại đây...'**
  String get questionShortAnswerHint;

  /// No description provided for @questionShortAnswerInstruction.
  ///
  /// In vi, this message translates to:
  /// **'Nhập câu trả lời cho từng ô trống:'**
  String get questionShortAnswerInstruction;

  /// No description provided for @questionSingleChoiceInstruction.
  ///
  /// In vi, this message translates to:
  /// **'Chọn một đáp án đúng:'**
  String get questionSingleChoiceInstruction;

  /// No description provided for @questionStatAnswered.
  ///
  /// In vi, this message translates to:
  /// **'Đã làm'**
  String get questionStatAnswered;

  /// No description provided for @questionStatTotal.
  ///
  /// In vi, this message translates to:
  /// **'Tổng số'**
  String get questionStatTotal;

  /// No description provided for @questionStatUnanswered.
  ///
  /// In vi, this message translates to:
  /// **'Chưa làm'**
  String get questionStatUnanswered;

  /// No description provided for @questionStatementNumber.
  ///
  /// In vi, this message translates to:
  /// **'Mệnh đề {number}'**
  String questionStatementNumber(int number);

  /// No description provided for @questionSubmit.
  ///
  /// In vi, this message translates to:
  /// **'Nộp bài'**
  String get questionSubmit;

  /// No description provided for @questionTfngInstruction.
  ///
  /// In vi, this message translates to:
  /// **'Chọn True, False hoặc Not Given cho từng mệnh đề:'**
  String get questionTfngInstruction;

  /// No description provided for @questionTypeDefault.
  ///
  /// In vi, this message translates to:
  /// **'Câu hỏi'**
  String get questionTypeDefault;

  /// No description provided for @questionTypeDropdown.
  ///
  /// In vi, this message translates to:
  /// **'Chọn từ Menu'**
  String get questionTypeDropdown;

  /// No description provided for @questionTypeFillInBlank.
  ///
  /// In vi, this message translates to:
  /// **'Điền vào chỗ trống'**
  String get questionTypeFillInBlank;

  /// No description provided for @questionTypeHighlighting.
  ///
  /// In vi, this message translates to:
  /// **'Bôi vùng'**
  String get questionTypeHighlighting;

  /// No description provided for @questionTypeMatching.
  ///
  /// In vi, this message translates to:
  /// **'Câu nối'**
  String get questionTypeMatching;

  /// No description provided for @questionTypeMultipleChoice.
  ///
  /// In vi, this message translates to:
  /// **'Chọn nhiều đáp án'**
  String get questionTypeMultipleChoice;

  /// No description provided for @questionTypeOrdering.
  ///
  /// In vi, this message translates to:
  /// **'Sắp xếp thứ tự'**
  String get questionTypeOrdering;

  /// No description provided for @questionTypeReading.
  ///
  /// In vi, this message translates to:
  /// **'Bài đọc'**
  String get questionTypeReading;

  /// No description provided for @questionTypeShortAnswer.
  ///
  /// In vi, this message translates to:
  /// **'Trả lời ngắn'**
  String get questionTypeShortAnswer;

  /// No description provided for @questionTypeSingleChoice.
  ///
  /// In vi, this message translates to:
  /// **'Trắc nghiệm'**
  String get questionTypeSingleChoice;

  /// No description provided for @questionTypeTfng.
  ///
  /// In vi, this message translates to:
  /// **'True / False / Not Given'**
  String get questionTypeTfng;

  /// No description provided for @questionTypeTrueFalse.
  ///
  /// In vi, this message translates to:
  /// **'Đúng / Sai'**
  String get questionTypeTrueFalse;

  /// No description provided for @questionViewList.
  ///
  /// In vi, this message translates to:
  /// **'Xem danh sách câu hỏi'**
  String get questionViewList;

  /// No description provided for @questionWordBankLabel.
  ///
  /// In vi, this message translates to:
  /// **'Ngân hàng từ'**
  String get questionWordBankLabel;

  /// No description provided for @settingsChooseLanguage.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ngôn ngữ'**
  String get settingsChooseLanguage;

  /// No description provided for @settingsLanguage.
  ///
  /// In vi, this message translates to:
  /// **'Ngôn ngữ'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageEnglish.
  ///
  /// In vi, this message translates to:
  /// **'English'**
  String get settingsLanguageEnglish;

  /// No description provided for @settingsLanguageVietnamese.
  ///
  /// In vi, this message translates to:
  /// **'Tiếng Việt'**
  String get settingsLanguageVietnamese;

  /// No description provided for @settingsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Cài đặt'**
  String get settingsTitle;

  /// No description provided for @supportClearCache.
  ///
  /// In vi, this message translates to:
  /// **'Xoá bộ nhớ đệm'**
  String get supportClearCache;

  /// No description provided for @supportClearCacheSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Xoá ảnh và tệp tạm, vẫn giữ đăng nhập'**
  String get supportClearCacheSubtitle;

  /// No description provided for @supportContact.
  ///
  /// In vi, this message translates to:
  /// **'Liên hệ hỗ trợ'**
  String get supportContact;

  /// No description provided for @supportContactSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Hotline, email, website'**
  String get supportContactSubtitle;

  /// No description provided for @supportDeviceInfo.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin thiết bị'**
  String get supportDeviceInfo;

  /// No description provided for @supportDeviceInfoSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Phiên bản app, kiểu máy, hệ điều hành'**
  String get supportDeviceInfoSubtitle;

  /// No description provided for @supportFeedback.
  ///
  /// In vi, this message translates to:
  /// **'Báo lỗi / góp ý'**
  String get supportFeedback;

  /// No description provided for @supportFeedbackSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Gửi mô tả kèm thông tin máy'**
  String get supportFeedbackSubtitle;

  /// No description provided for @supportSectionTitle.
  ///
  /// In vi, this message translates to:
  /// **'Hỗ trợ'**
  String get supportSectionTitle;

  /// No description provided for @toastErrorOccurred.
  ///
  /// In vi, this message translates to:
  /// **'Có lỗi xảy ra'**
  String get toastErrorOccurred;

  /// No description provided for @toastProcessing.
  ///
  /// In vi, this message translates to:
  /// **'Đang xử lý...'**
  String get toastProcessing;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
