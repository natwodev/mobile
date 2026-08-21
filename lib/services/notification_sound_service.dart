import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Loại âm báo, đặt trùng tên với bản web
/// (`frontend_manage/src/utils/toast.tsx:11-46`) để hai bên kêu giống nhau.
enum NotificationSound {
  success,
  error,
  warning,
  multiline,
  promise,

  /// Tiếng chuông báo kéo-để-tải-lại xong. Tách khỏi [success] vì đây là phản
  /// hồi thao tác của chính người dùng, không phải tin từ hệ thống — dùng
  /// chung một tiếng thì kéo tải lại nghe y hệt lúc giám thị nhắn.
  refresh,
}

/// Phát âm báo kèm thông báo.
///
/// Dùng đúng 5 file mp3 của web, nhưng ĐÓNG GÓI SẴN trong app thay vì tải từ
/// Cloudinary: đang thi mà mạng chập chờn thì tiếng báo là thứ mất đầu tiên,
/// trong khi đó lại đúng lúc cần nghe nhất (giám thị nhắn, bị nộp bài hộ).
class NotificationSoundService {
  const NotificationSoundService._();

  static const Map<NotificationSound, String> _assets =
      <NotificationSound, String>{
    NotificationSound.success: 'sounds/toast-success.mp3',
    NotificationSound.error: 'sounds/toast-error.mp3',
    NotificationSound.warning: 'sounds/toast-warning.mp3',
    NotificationSound.multiline: 'sounds/toast-multiline.mp3',
    NotificationSound.promise: 'sounds/toast-promise.mp3',
    NotificationSound.refresh: 'sounds/refresh-success.mp3',
  };

  /// Một player dùng lại cho mọi lần phát: mỗi lần `AudioPlayer()` mới là một
  /// lần mở tài nguyên native, thông báo dồn dập sẽ rò rất nhanh.
  static AudioPlayer? _player;

  static Future<void> play(NotificationSound sound) async {
    final String? asset = _assets[sound];
    if (asset == null) return;

    try {
      final AudioPlayer player = _player ??= AudioPlayer()
        // Âm báo ngắn: phát xong thì nhả tài nguyên nhưng giữ player.
        ..setReleaseMode(ReleaseMode.stop);

      // Tiếng trước chưa dứt thì cắt, không xếp chồng thành một mớ ồn.
      await player.stop();
      await player.play(AssetSource(asset));
    } catch (e) {
      // Máy tắt tiếng, đang gọi điện, thiếu codec... đều không phải lý do để
      // chặn thông báo hiển thị.
      debugPrint('Không phát được âm báo: $e');
    }
  }

  /// Gọi khi rời màn thi để trả tài nguyên native.
  static Future<void> dispose() async {
    final AudioPlayer? player = _player;
    _player = null;
    await player?.dispose();
  }
}
