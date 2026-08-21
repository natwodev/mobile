import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

/// Dọn bộ nhớ đệm của app: ảnh đã tải và tệp tạm.
///
/// KHÔNG đụng tới SharedPreferences — token đăng nhập, ngôn ngữ và các cài đặt
/// khác nằm ở đó, xoá là người dùng bị văng ra màn đăng nhập.
class CacheService {
  const CacheService._();

  /// Các thư mục cache của app.
  ///
  /// Phải hỏi path_provider chứ không dùng `Directory.systemTemp`: trên Android
  /// hằng số đó phụ thuộc biến môi trường TMPDIR, không chắc trỏ vào cache của
  /// app — dọn nhầm chỗ thì nút bấm xong mà chẳng giải phóng được gì.
  static Future<List<Directory>> _cacheDirs() async {
    final List<Directory> dirs = <Directory>[];

    try {
      dirs.add(await getTemporaryDirectory());
    } catch (_) {
      // Nền tảng không hỗ trợ thì bỏ qua, còn thư mục dưới.
    }

    try {
      final Directory appCache = await getApplicationCacheDirectory();
      if (dirs.every((Directory d) => d.path != appCache.path)) {
        dirs.add(appCache);
      }
    } catch (_) {
      // iOS cũ / nền tảng chưa hỗ trợ: chỉ dọn thư mục tạm là đủ.
    }

    return dirs;
  }

  /// Tổng dung lượng tệp tạm, tính bằng byte. Tệp nào đọc không được thì bỏ qua.
  static Future<int> size() async {
    return _walk((File file, int length) => length);
  }

  /// Xoá tệp tạm + bộ nhớ ảnh, trả về số byte đã giải phóng.
  static Future<int> clear() async {
    final int freed = await _walk((File file, int length) {
      try {
        file.deleteSync();
        return length;
      } catch (_) {
        // Tệp đang mở (log, ảnh đang hiển thị...) thì để nguyên.
        return 0;
      }
    });

    PaintingBinding.instance.imageCache
      ..clear()
      ..clearLiveImages();

    return freed;
  }

  static Future<int> _walk(int Function(File file, int length) handle) async {
    int total = 0;

    for (final Directory dir in await _cacheDirs()) {
      if (!await dir.exists()) continue;

      try {
        await for (final FileSystemEntity entity in dir.list(
          recursive: true,
          followLinks: false,
        )) {
          if (entity is! File) continue;
          try {
            total += handle(entity, await entity.length());
          } catch (_) {
            // Tệp biến mất giữa chừng — bỏ qua, không tính vào tổng.
          }
        }
      } catch (_) {
        // Không liệt kê được thư mục thì coi như không có gì để dọn.
      }
    }

    return total;
  }

  /// "12,4 MB" — đủ dùng cho một dòng thông báo, không cần intl.
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(0)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1).replaceAll('.', ',')} MB';
  }
}
