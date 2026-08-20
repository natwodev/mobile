import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Thông tin máy + phiên bản app, dùng chung cho màn "Thông tin thiết bị" và
/// phần đính kèm của "Báo lỗi / góp ý".
class DeviceReport {
  const DeviceReport({
    required this.appName,
    required this.version,
    required this.buildNumber,
    required this.packageName,
    required this.model,
    required this.brand,
    required this.os,
    required this.isPhysicalDevice,
  });

  final String appName;
  final String version;
  final String buildNumber;
  final String packageName;
  final String model;
  final String brand;
  final String os;
  final bool isPhysicalDevice;

  /// Dạng văn bản thuần để dán vào email hỗ trợ.
  String toPlainText({String? screen, String? language}) {
    final StringBuffer buffer = StringBuffer()
      ..writeln('App: $appName $version ($buildNumber)')
      ..writeln('Package: $packageName')
      ..writeln('Device: $brand $model')
      ..writeln('OS: $os')
      ..writeln('Physical device: ${isPhysicalDevice ? 'yes' : 'no'}');
    if (screen != null) buffer.writeln('Screen: $screen');
    if (language != null) buffer.writeln('App language: $language');
    return buffer.toString();
  }
}

class DeviceReportService {
  const DeviceReportService._();

  /// Đọc thông tin app + máy. Máy nào chặn quyền đọc thông tin thì trả về
  /// chuỗi rỗng cho phần đó chứ không ném lỗi, tránh chặn cả màn hình.
  static Future<DeviceReport> load() async {
    final PackageInfo package = await PackageInfo.fromPlatform();
    final DeviceInfoPlugin plugin = DeviceInfoPlugin();

    String model = '';
    String brand = '';
    String os = '';
    bool physical = true;

    try {
      if (Platform.isAndroid) {
        final AndroidDeviceInfo info = await plugin.androidInfo;
        model = info.model;
        brand = info.manufacturer.isNotEmpty ? info.manufacturer : info.brand;
        os = 'Android ${info.version.release} (SDK ${info.version.sdkInt})';
        physical = info.isPhysicalDevice;
      } else if (Platform.isIOS) {
        final IosDeviceInfo info = await plugin.iosInfo;
        model = info.utsname.machine;
        brand = 'Apple';
        os = '${info.systemName} ${info.systemVersion}';
        physical = info.isPhysicalDevice;
      } else {
        os = '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
      }
    } catch (_) {
      os = '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
    }

    return DeviceReport(
      appName: package.appName,
      version: package.version,
      buildNumber: package.buildNumber,
      packageName: package.packageName,
      model: model,
      brand: brand,
      os: os,
      isPhysicalDevice: physical,
    );
  }
}
