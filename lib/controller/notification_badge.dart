import 'package:flutter/foundation.dart';

import '../services/notification/notification_cache.dart';
import '../services/notification/notification_service.dart';

/// Số thư chưa đọc, dùng chung cho con số nhỏ trên nút chuông.
///
/// Là một chỗ duy nhất giữ con số đó, thay vì mỗi màn tự gọi `unread-count`
/// rồi giữ một bản riêng — làm vậy thì đọc thư ở màn chuông xong quay ra Trang
/// chủ, badge vẫn còn nguyên số cũ.
///
/// KHÔNG hỏi lại theo chu kỳ. Theo bàn giao thì chỉ cần làm mới ở ba thời điểm:
/// lúc mở app, sau mỗi lần nhận push, và sau khi người dùng đọc thư. Hỏi lại
/// mỗi vài giây chỉ tổ tốn pin và tốn mạng cho một con số hiếm khi đổi.
class NotificationBadge extends ChangeNotifier {
  NotificationBadge._();

  static final NotificationBadge instance = NotificationBadge._();

  final NotificationService _service = NotificationService();

  int _count = 0;

  /// Số thư chưa đọc đang hiển thị.
  int get count => _count;

  bool get hasUnread => _count > 0;

  /// Dựng lại con số từ bản lưu trên máy, gọi lúc mở app.
  ///
  /// Đọc bản lưu TRƯỚC rồi mới hỏi máy chủ: badge có số ngay, khỏi nhấp nháy từ
  /// 0 nhảy lên. Mất mạng thì vẫn giữ con số của lần trước, hơn là tụt về 0 làm
  /// người dùng tưởng đã đọc hết.
  Future<void> load() async {
    final cached = await NotificationCache.loadUnreadCount();
    if (cached != _count) {
      _count = cached;
      notifyListeners();
    }

    await refresh();
  }

  /// Hỏi lại máy chủ. Gọi sau khi nhận push hoặc sau khi đọc thư.
  ///
  /// Gọi hỏng thì GIỮ NGUYÊN con số cũ, không đặt về 0: rớt mạng một nhịp mà
  /// badge tắt ngóm thì người dùng tưởng hết thư, bỏ qua luôn tin của giám thị.
  Future<void> refresh() async {
    final fresh = await _service.unreadCount();
    if (fresh == null) return;

    set(fresh);
  }

  /// Đặt thẳng con số, dùng khi vừa tải xong danh sách và đã biết chính xác.
  void set(int value) {
    final next = value < 0 ? 0 : value;
    if (next == _count) return;

    _count = next;
    notifyListeners();
  }

  /// Bớt một, dùng ngay khi người dùng đọc một thư.
  ///
  /// Sửa tại chỗ để con số đổi ngay lúc chạm, khỏi chờ một vòng gọi mạng. Máy
  /// chủ vẫn là bản thật — lần [refresh] sau sẽ chỉnh lại nếu có lệch.
  void decrement() => set(_count - 1);

  /// Về 0, dùng khi đánh dấu đã đọc tất cả.
  void clear() => set(0);
}
