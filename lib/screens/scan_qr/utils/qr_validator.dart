import 'package:flutter/foundation.dart';

/// Kiểm tra định dạng QR cho bài thi
bool validateExamQrFormat(String qrData) {
  // Format: EXAM|v=1|id=1|core=xxx|title=xxx|desc=xxx|sub=xxx|dur=15|created=xxx
  if (!qrData.startsWith('EXAM|')) {
    return false;
  }

  final parts = qrData.split('|');
  if (parts.length < 9) {
    return false;
  }

  // Kiểm tra các field bắt buộc
  final requiredFields = [
    'v=',
    'id=',
    'core=',
    'title=',
    'desc=',
    'sub=',
    'dur=',
    'created=',
  ];
  int fieldCount = 0;

  for (int i = 1; i < parts.length; i++) {
    for (String field in requiredFields) {
      if (parts[i].startsWith(field)) {
        fieldCount++;
        break;
      }
    }
  }

  final isValid = fieldCount == requiredFields.length;
  if (kDebugMode) {
    print('QR validate result: $isValid');
  }
  return isValid;
}

/// Parse chuỗi QR thành map key/value
Map<String, String> parseExamQrData(String qrData) {
  final parts = qrData.split('|');
  final Map<String, String> data = {};

  for (int i = 1; i < parts.length; i++) {
    final keyValue = parts[i].split('=');
    if (keyValue.length == 2) {
      data[keyValue[0]] = keyValue[1].replaceAll('_', ' ');
    }
  }

  return data;
}
