import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../l10n/generated/app_localizations.dart';

/// Câu giải thích cho từng lý do không lấy được vị trí.
///
/// Để ở đây vì có HAI lối vào phòng thi cùng cần nó — nhập mã nhanh và quét mã
/// QR; mỗi nơi tự viết một bản là sớm muộn hai nơi nói hai kiểu khác nhau về
/// cùng một sự cố.
String examLocationErrorMessage(
  AppLocalizations l10n,
  ExamLocationError error,
) {
  switch (error) {
    case ExamLocationError.serviceDisabled:
      return l10n.examLocationServiceDisabled;
    case ExamLocationError.denied:
      return l10n.examLocationDenied;
    case ExamLocationError.deniedForever:
      return l10n.examLocationDeniedForever;
    case ExamLocationError.timeout:
    case ExamLocationError.unknown:
      return l10n.examLocationTimeout;
  }
}

/// Vì sao không lấy được vị trí — mỗi lý do cần một câu hướng dẫn khác nhau.
enum ExamLocationError {
  /// Người dùng tắt định vị của máy.
  serviceDisabled,

  /// Từ chối quyền lần này.
  denied,

  /// Chặn vĩnh viễn — phải vào Cài đặt mới mở lại được.
  deniedForever,

  /// Bật đủ thứ nhưng không bắt được tín hiệu trong thời gian chờ.
  timeout,

  unknown,
}

class ExamLocationResult {
  const ExamLocationResult._({this.latitude, this.longitude, this.error});

  factory ExamLocationResult.success(double latitude, double longitude) =>
      ExamLocationResult._(latitude: latitude, longitude: longitude);

  factory ExamLocationResult.failure(ExamLocationError error) =>
      ExamLocationResult._(error: error);

  final double? latitude;
  final double? longitude;
  final ExamLocationError? error;

  bool get isSuccess => error == null && latitude != null && longitude != null;
}

/// Lấy toạ độ GPS cho ca thi bắt buộc định vị.
///
/// Backend từ chối vào thi khi toạ độ không hợp lệ, và coi `{0,0}` là sentinel
/// "không có GPS" (`StudentController.cs:104-122`) — nên ở đây thà báo lỗi rõ
/// ràng còn hơn trả về một cặp số bịa.
///
/// Cách xin quyền lấy theo dự án hqsoft.esales.sfa
/// (`lib/core/location/gps_location_service.dart`) vì đó là bản đã chạy thật
/// trên máy nhân viên đi thị trường: kiểm dịch vụ định vị trước, rồi mới xin
/// quyền, và trên Android dùng `forceLocationManager`.
class ExamLocationService {
  const ExamLocationService._();

  /// 15 giây như SFA thay vì 10 giây của web: máy thật trong phòng thi (nhà
  /// nhiều tầng, cửa sổ ít) bắt tín hiệu chậm hơn hẳn trình duyệt trên laptop.
  static const Duration _timeout = Duration(seconds: 15);

  /// `forceLocationManager: true` — dùng LocationManager của hệ điều hành thay
  /// cho FusedLocationProvider của Google Play Services. SFA phải làm vậy vì
  /// nhiều máy Android không có / hỏng Play Services thì FusedLocationProvider
  /// treo im không trả về gì.
  static LocationSettings get _settings =>
      defaultTargetPlatform == TargetPlatform.android
      ? AndroidSettings(
          forceLocationManager: true,
          accuracy: LocationAccuracy.high,
          timeLimit: _timeout,
        )
      : const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: _timeout,
        );

  static Future<ExamLocationResult> current() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return ExamLocationResult.failure(ExamLocationError.serviceDisabled);
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        return ExamLocationResult.failure(ExamLocationError.deniedForever);
      }
      if (permission == LocationPermission.denied) {
        return ExamLocationResult.failure(ExamLocationError.denied);
      }

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: _settings,
      );

      // Máy trả đúng {0,0} thì backend cũng coi là không có GPS, báo luôn cho
      // sinh viên thay vì để họ bị từ chối ở bước sau mà không hiểu vì sao.
      if (position.latitude == 0 && position.longitude == 0) {
        return ExamLocationResult.failure(ExamLocationError.timeout);
      }

      return ExamLocationResult.success(position.latitude, position.longitude);
    } on LocationServiceDisabledException {
      return ExamLocationResult.failure(ExamLocationError.serviceDisabled);
    } on PermissionDeniedException {
      return ExamLocationResult.failure(ExamLocationError.denied);
    } on TimeoutException {
      return ExamLocationResult.failure(ExamLocationError.timeout);
    } catch (_) {
      return ExamLocationResult.failure(ExamLocationError.unknown);
    }
  }
}
