import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:quizz_mobile/screens/Exam/exam_screen.dart';

/// Giả lập API `submit-exam`: đếm số lần THỰC SỰ gửi lên máy chủ và cho phép
/// giữ request lơ lửng để dựng lại đúng tình huống "hết giờ trùng lúc bấm nộp".
class _FakeSubmitApi {
  _FakeSubmitApi({this.acceptsFrom = 1});

  /// Lần gửi thứ mấy trở đi thì máy chủ ghi nhận (dùng để giả lập nộp hỏng).
  final int acceptsFrom;

  int callCount = 0;
  final List<ExamSubmitTrigger> triggers = [];
  Completer<void>? _gate;

  /// Chặn request đang bay lại cho tới khi [release] được gọi.
  void hold() => _gate = Completer<void>();

  void release() {
    _gate?.complete();
    _gate = null;
  }

  Future<bool> send(ExamSubmitTrigger trigger) async {
    callCount++;
    triggers.add(trigger);
    final gate = _gate;
    if (gate != null) await gate.future;
    return callCount >= acceptsFrom;
  }
}

void main() {
  test('hết giờ và bấm nộp cùng lúc thì chỉ gửi submitExam MỘT lần', () async {
    final api = _FakeSubmitApi();
    final coordinator = ExamSubmitCoordinator(api.send);

    // Request đầu tiên bị giữ lại: mô phỏng lúc app đang chờ máy chủ trả lời.
    api.hold();

    // Hai lời gọi trong CÙNG một vòng lặp sự kiện, không await ở giữa —
    // đúng cảnh đồng hồ về 0 đúng lúc sinh viên bấm "Nộp bài".
    final autoFuture = coordinator.submit(ExamSubmitTrigger.timeUp);
    final manualFuture = coordinator.submit(ExamSubmitTrigger.manual);

    api.release();
    final results = await Future.wait([autoFuture, manualFuture]);

    expect(api.callCount, 1);
    expect(api.triggers, [ExamSubmitTrigger.timeUp]);
    expect(results[0], ExamSubmitOutcome.submitted);
    expect(results[1], ExamSubmitOutcome.alreadyRunning);
    expect(coordinator.hasSubmitted, isTrue);
    expect(coordinator.isSubmitting, isFalse);
  });

  test('bấm nộp trước, đồng hồ về 0 sau thì cũng chỉ gửi một lần', () async {
    final api = _FakeSubmitApi();
    final coordinator = ExamSubmitCoordinator(api.send);

    api.hold();
    final manualFuture = coordinator.submit(ExamSubmitTrigger.manual);
    // Nhường vài nhịp microtask để lời gọi đầu chắc chắn đã vào trong hàm gửi.
    await Future<void>.delayed(Duration.zero);
    final autoFuture = coordinator.submit(ExamSubmitTrigger.timeUp);

    api.release();
    final results = await Future.wait([manualFuture, autoFuture]);

    expect(api.callCount, 1);
    expect(api.triggers, [ExamSubmitTrigger.manual]);
    expect(results[0], ExamSubmitOutcome.submitted);
    expect(results[1], ExamSubmitOutcome.alreadyRunning);
  });

  test('đã nộp thành công thì mọi lời gọi sau đều bị chặn', () async {
    final api = _FakeSubmitApi();
    final coordinator = ExamSubmitCoordinator(api.send);

    expect(
      await coordinator.submit(ExamSubmitTrigger.timeUp),
      ExamSubmitOutcome.submitted,
    );
    expect(
      await coordinator.submit(ExamSubmitTrigger.manual),
      ExamSubmitOutcome.alreadySubmitted,
    );
    expect(
      await coordinator.submit(ExamSubmitTrigger.timeUp),
      ExamSubmitOutcome.alreadySubmitted,
    );

    expect(api.callCount, 1);
    expect(coordinator.isLocked, isTrue);
  });

  test('nộp hỏng thì mở khoá để còn thử lại được', () async {
    // Lần gửi thứ 2 mới được máy chủ ghi nhận.
    final api = _FakeSubmitApi(acceptsFrom: 2);
    final coordinator = ExamSubmitCoordinator(api.send);

    expect(
      await coordinator.submit(ExamSubmitTrigger.timeUp),
      ExamSubmitOutcome.failed,
    );
    expect(coordinator.hasSubmitted, isFalse);
    expect(coordinator.isLocked, isFalse);

    expect(
      await coordinator.submit(ExamSubmitTrigger.manual),
      ExamSubmitOutcome.submitted,
    );
    expect(api.callCount, 2);
    expect(coordinator.isLocked, isTrue);
  });

  test('ngoại lệ khi nộp không làm kẹt cờ đang-nộp', () async {
    var calls = 0;
    final coordinator = ExamSubmitCoordinator((trigger) async {
      calls++;
      throw StateError('mất mạng');
    });

    await expectLater(
      coordinator.submit(ExamSubmitTrigger.timeUp),
      throwsStateError,
    );
    expect(coordinator.isSubmitting, isFalse);
    expect(coordinator.hasSubmitted, isFalse);

    // Vẫn bấm nộp lại được sau khi lỗi.
    await expectLater(
      coordinator.submit(ExamSubmitTrigger.manual),
      throwsStateError,
    );
    expect(calls, 2);
  });

  test('trong lúc nộp, cờ trạng thái đủ để khoá giao diện', () async {
    final api = _FakeSubmitApi();
    final coordinator = ExamSubmitCoordinator(api.send);

    api.hold();
    final future = coordinator.submit(ExamSubmitTrigger.timeUp);

    expect(coordinator.isSubmitting, isTrue);
    expect(coordinator.isLocked, isTrue);
    expect(coordinator.activeTrigger, ExamSubmitTrigger.timeUp);

    api.release();
    await future;

    expect(coordinator.isSubmitting, isFalse);
    expect(coordinator.activeTrigger, isNull);
    expect(coordinator.isLocked, isTrue);
  });
}
