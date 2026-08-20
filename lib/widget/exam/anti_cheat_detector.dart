import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:screen_protector/screen_protector.dart';
import 'dart:async';
import '../../l10n/app_l10n.dart';
import '../../l10n/generated/app_localizations.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../services/student_activity_service.dart';
import '../common/app_modal.dart';

class AntiCheatDetector extends StatefulWidget {
  final Widget child;
  final VoidCallback onAutoSubmit;

  final String studentExamSessionId;
  final String studentCode;
  final String baseUrl;
  final String? authToken;

  const AntiCheatDetector({
    Key? key,
    required this.child,
    required this.onAutoSubmit,
    required this.studentExamSessionId,
    required this.studentCode,
    required this.baseUrl,
    this.authToken,
  }) : super(key: key);

  @override
  State<AntiCheatDetector> createState() => _AntiCheatDetectorState();
}

class _AntiCheatDetectorState extends State<AntiCheatDetector>
    with WidgetsBindingObserver {
  int _violationCount = 0;
  static const int _maxViolations = 3;

  bool _isShowingWarning = false;

  // Không cần subscription vì addListener không trả về subscription

  late StudentActivityService _activityService;

  DateTime? _lastViolationTime;
  static const Duration _debounce = Duration(seconds: 2);

  AppLifecycleState? _previousAppState;

  // Timer để detect app switch khi inactive kéo dài (tránh false positive với quick settings)
  Timer? _inactiveTimer;
  static const Duration _inactiveThreshold = Duration(
    seconds: 10,
  ); // 3 giây để phân biệt quick settings vs app khác

  // Track orientation để detect rotation
  Orientation? _previousOrientation;
  bool _isShowingBlackScreen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Log để confirm observer được add
    debugPrint('✅ AntiCheatDetector: WidgetsBindingObserver added');
    debugPrint(
      '   Current lifecycle state: ${WidgetsBinding.instance.lifecycleState}',
    );

    // Chỉ log một lần khi init
    if (widget.authToken != null && widget.authToken!.isNotEmpty) {
      debugPrint(
        '✅ AntiCheatDetector: Auth token present (length: ${widget.authToken!.length})',
      );
    } else {
      debugPrint('⚠️ AntiCheatDetector: No auth token provided');
    }

    _activityService = StudentActivityService(
      baseUrl: widget.baseUrl,
      authToken: widget.authToken,
    );

    _initScreenProtection();
    _lockOrientation();
  }

  /// Lock orientation về portrait để chặn quay màn hình
  Future<void> _lockOrientation() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    debugPrint('🔒 Screen orientation locked to portrait');
  }

  /// Unlock orientation khi dispose
  Future<void> _unlockOrientation() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    debugPrint('🔓 Screen orientation unlocked');
  }

  @override
  void didUpdateWidget(AntiCheatDetector oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Nếu token thay đổi, cập nhật lại service
    if (oldWidget.authToken != widget.authToken) {
      _activityService = StudentActivityService(
        baseUrl: widget.baseUrl,
        authToken: widget.authToken,
      );
      debugPrint('🔄 AntiCheatDetector: Token updated, service recreated');
    }
  }

  @override
  void dispose() {
    _unlockOrientation();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // =========================
  // LIFECYCLE – CORE ANTI CHEAT
  // =========================
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;

    debugPrint('📱 App lifecycle changed: ${_previousAppState} → $state');
    final platform = defaultTargetPlatform;

    // ANDROID: Detect cả PAUSED và INACTIVE (khi có app/overlay đè lên)
    if (platform == TargetPlatform.android) {
      // PAUSED: App vào background hoàn toàn
      if (state == AppLifecycleState.paused) {
        _inactiveTimer?.cancel(); // Hủy timer nếu có
        debugPrint('🚨 Android: App paused - registering violation');
        _registerViolation(
          title: AppL10n.current.questionAntiCheatWarningTitle,
          description: AppL10n.current.questionAntiCheatLeftApp,
          activityType: 'AppBackground',
        );
      }

      // INACTIVE: App mất focus (có thể là app khác đè lên hoặc quick settings)
      // KHÔNG tính vi phạm ngay để tránh false positive với quick settings (đổi mạng)
      // Chỉ tính vi phạm khi inactive kéo dài (app khác đè lên)
      if (state == AppLifecycleState.inactive) {
        debugPrint('🔍 Android: App inactive detected');
        debugPrint('   Previous state: $_previousAppState');

        // Nếu chuyển từ resumed sang inactive, bắt đầu timer
        // Quick settings thường chỉ mất < 3 giây, app khác đè lên sẽ > 3 giây
        if (_previousAppState == AppLifecycleState.resumed) {
          debugPrint(
            '⏱️ Android: App inactive (from resumed) - starting timer (${_inactiveThreshold.inSeconds}s)',
          );
          _inactiveTimer?.cancel();
          _inactiveTimer = Timer(_inactiveThreshold, () {
            // Nếu inactive kéo dài quá threshold → tính là vi phạm (app khác đè lên)
            // Quick settings thường < 3 giây nên không tính vi phạm
            if (_previousAppState == AppLifecycleState.inactive) {
              debugPrint(
                '🚨 Android: App inactive too long (>${_inactiveThreshold.inSeconds}s) - registering violation',
              );
              _registerViolation(
                title: AppL10n.current.questionAntiCheatWarningTitle,
                description: AppL10n.current.questionAntiCheatOverlayDetected,
                activityType: 'AppSwitch',
              );
            } else {
              debugPrint(
                '✅ App quay lại trước ${_inactiveThreshold.inSeconds}s - không tính vi phạm (có thể là quick settings)',
              );
            }
          });
        } else {
          debugPrint('ℹ️ App inactive but not from resumed, skipping');
        }
      }

      // RESUMED: App quay lại foreground
      if (state == AppLifecycleState.resumed) {
        // Hủy timer nếu app quay lại (có thể là quick settings)
        _inactiveTimer?.cancel();
        _inactiveTimer = null;

        if (_previousAppState == AppLifecycleState.paused ||
            _previousAppState == AppLifecycleState.inactive) {
          debugPrint('✅ App resumed - recording foreground');
          _activityService.recordAppForeground(
            studentExamSessionId: widget.studentExamSessionId,
            studentCode: widget.studentCode,
          );
        }
      }
    }

    // IOS: COUNT INACTIVE + PAUSED
    if (platform == TargetPlatform.iOS &&
        (state == AppLifecycleState.inactive ||
            state == AppLifecycleState.paused)) {
      debugPrint('🚨 iOS: App inactive/paused - registering violation');
      _registerViolation(
        title: AppL10n.current.questionAntiCheatWarningTitle,
        description: AppL10n.current.questionAntiCheatLeftApp,
        activityType: 'AppBackground',
      );
    }

    _previousAppState = state;
  }

  // =========================
  // SCREEN PROTECTOR
  // =========================
  Future<void> _initScreenProtection() async {
    if (kIsWeb) return;

    final platform = defaultTargetPlatform;
    if (platform != TargetPlatform.android && platform != TargetPlatform.iOS) {
      return;
    }

    try {
      debugPrint('🖼️ Initializing screen detection for platform: $platform');
      debugPrint('ℹ️ Mode: DETECT ONLY (no blocking)');

      // CHỈ DETECT, KHÔNG CHẶN:
      // - Không gọi preventScreenshotOn() để không chặn screenshot
      // - Chỉ dùng addListener() để phát hiện và đếm vi phạm

      // Listen cho screenshot và screen recording
      // addListener cần 2 positional arguments: callback cho screenshot và callback cho screen recording
      ScreenProtector.addListener(
        // Callback 1: cho screenshot (không có tham số)
        () {
          debugPrint('📸 Screenshot detected via ScreenProtector!');
          _registerViolation(
            title: AppL10n.current.questionAntiCheatWarningTitle,
            description: AppL10n.current.questionAntiCheatScreenshotDetected,
            activityType: 'Screenshot',
          );
        },
        // Callback 2: cho screen recording (nhận tham số bool)
        // LƯU Ý: Screen recording detection có thể chỉ hoạt động trên iOS
        // Trên Android, callback này có thể không được gọi
        (isRecording) {
          debugPrint('🎥 Screen recording callback triggered!');
          debugPrint('   Platform: $platform');
          debugPrint('   isRecording: $isRecording');
          if (isRecording) {
            debugPrint('🚨 Screen recording detected!');
            _registerViolation(
              title: AppL10n.current.questionAntiCheatWarningTitle,
              description:
                  AppL10n.current.questionAntiCheatScreenRecordingDetected,
              activityType: 'ScreenRecording',
            );
          } else {
            debugPrint('✅ Screen recording stopped');
          }
        },
      );
      debugPrint('✅ ScreenProtector.addListener() completed');
    } catch (e, stackTrace) {
      // Không crash app thi
      debugPrint('❌ ScreenProtector init failed: $e');
      debugPrint('   Stack trace: $stackTrace');
    }
  }

  // =========================
  // CORE VIOLATION LOGIC
  // =========================
  void _registerViolation({
    required String title,
    required String description,
    required String activityType,
  }) {
    debugPrint('🔍 _registerViolation called: $activityType');

    if (!mounted) {
      debugPrint('⚠️ Widget not mounted, skipping violation');
      return;
    }

    final now = DateTime.now();
    if (_lastViolationTime != null &&
        now.difference(_lastViolationTime!) < _debounce) {
      debugPrint(
        '⏭️ Debounce: ignoring violation (${now.difference(_lastViolationTime!).inSeconds}s ago)',
      );
      return;
    }

    if (_isShowingWarning) {
      debugPrint('⚠️ Warning dialog already showing, skipping violation');
      return;
    }

    debugPrint(
      '✅ Registering violation: $activityType (count: ${_violationCount + 1}/$_maxViolations)',
    );

    // 🔒 LOCK TRƯỚC (FIX RACE CONDITION)
    _isShowingWarning = true;
    _lastViolationTime = now;

    setState(() {
      _violationCount++;
    });

    _sendActivity(activityType);

    if (_violationCount >= _maxViolations) {
      widget.onAutoSubmit();
      return;
    }

    _showWarningDialog(title, description);
  }

  void _sendActivity(String type) {
    debugPrint('📤 Sending activity: $type');
    debugPrint(
      '   Service token is null: ${_activityService.authToken == null}',
    );
    debugPrint(
      '   Service token isEmpty: ${_activityService.authToken?.isEmpty ?? true}',
    );

    _activityService
        .recordActivity(
          studentExamSessionId: widget.studentExamSessionId,
          studentCode: widget.studentCode,
          activityType: type,
          description: 'Anti-cheat detected',
          metadata: {
            'count': _violationCount,
            'time': DateTime.now().toIso8601String(),
          },
        )
        .catchError((error) {
          debugPrint('❌ Error sending activity: $error');
        });
  }

  // =========================
  // UI WARNING
  // =========================
  void _showWarningDialog(String title, String description) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => WillPopScope(
        onWillPop: () async => false,
        // Không có dấu X: sinh viên buộc phải bấm "Đã hiểu" thì mới đóng được,
        // đúng như barrierDismissible: false và WillPopScope ở trên.
        child: AppModal(
          title: title,
          icon: HugeIcons.strokeRoundedAlert01,
          accentColor: Colors.red,
          children: [
            Text(
              '$description\n\n'
              '${l10n.questionAntiCheatViolationCount(_violationCount, _maxViolations)}\n'
              '${l10n.questionAntiCheatAutoSubmitNotice(_maxViolations)}',
            ),
          ],
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _isShowingWarning = false; // 🔓 UNLOCK
              },
              child: Text(l10n.questionAntiCheatUnderstood),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Detect orientation change và hiển thị màn hình đen nếu quay màn hình
    return OrientationBuilder(
      builder: (context, orientation) {
        // Lần đầu tiên, lưu orientation
        if (_previousOrientation == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _previousOrientation = orientation;
              });
            }
          });
          return widget.child;
        }

        // Nếu orientation thay đổi (quay màn hình)
        if (_previousOrientation != orientation) {
          debugPrint(
            '🔄 Screen rotation detected: $_previousOrientation → $orientation',
          );

          // Tính vi phạm ngay
          _handleScreenRotation();

          // Hiển thị màn hình đen ngay lập tức
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _isShowingBlackScreen = true;
              });
            }
          });

          // Reset về portrait và ẩn màn hình đen sau 2 giây
          Future.delayed(Duration(seconds: 2), () {
            if (mounted) {
              _lockOrientation();
              setState(() {
                _isShowingBlackScreen = false;
                _previousOrientation =
                    Orientation.portrait; // Reset về portrait
              });
            }
          });
        }

        // Nếu đang hiển thị màn hình đen
        if (_isShowingBlackScreen) {
          final l10n = AppLocalizations.of(context);
          return Container(
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const HugeIcon(
                    icon: HugeIcons.strokeRoundedRotate01,
                    color: Colors.white,
                    size: 64.0,
                  ),
                  SizedBox(height: 16),
                  Text(
                    l10n.questionAntiCheatRotationBlockedTitle,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    l10n.questionAntiCheatRotationBlockedSubtitle,
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          );
        }

        return widget.child;
      },
    );
  }

  /// Xử lý khi phát hiện quay màn hình
  void _handleScreenRotation() {
    debugPrint('🚨 Screen rotation violation detected');
    _registerViolation(
      title: AppL10n.current.questionAntiCheatWarningTitle,
      description: AppL10n.current.questionAntiCheatRotationDetected,
      activityType: 'ScreenRotation',
    );
  }
}
