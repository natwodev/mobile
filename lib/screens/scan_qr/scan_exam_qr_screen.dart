import 'package:flutter/material.dart';

import '../../widget/common/app_top_bar.dart';

import '../../l10n/generated/app_localizations.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'utils/qr_validator.dart';
import 'widgets/qr_scanner_overlay.dart';
import 'widgets/zoom_controls.dart';
import 'widgets/qr_result_dialog.dart';
import 'widgets/qr_error_dialog.dart';

class ScanExamQrScreen extends StatefulWidget {
  const ScanExamQrScreen({super.key});

  @override
  State<ScanExamQrScreen> createState() => _ScanExamQrScreenState();
}

class _ScanExamQrScreenState extends State<ScanExamQrScreen> {
  final MobileScannerController controller = MobileScannerController(
    // KHÔNG dùng DetectionSpeed.noDuplicates: chế độ đó nhớ mã vừa quét và
    // không phát lại mã ấy nữa cho tới khi có MỘT MÃ KHÁC được quét. Tắt popup
    // rồi soi lại đúng tờ đề vừa quét là onDetect im lặng luôn — người dùng
    // tưởng camera hỏng chứ không biết là bị coi như quét trùng.
    // Chống quét trùng lúc dialog đang mở đã có _isProcessing lo, thêm
    // detectionTimeoutMs để không bắn dồn dập giữa hai lần quét.
    detectionSpeed: DetectionSpeed.normal,
    detectionTimeoutMs: 1000,
    facing: CameraFacing.back,
  );

  bool _isProcessing = false;
  double _zoomFactor = 0.0;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _handleZoomIn() {
    setState(() {
      if (_zoomFactor < 1.0) {
        _zoomFactor += 0.1;
        if (_zoomFactor > 1.0) _zoomFactor = 1.0;
      }
    });
    controller.setZoomScale(_zoomFactor);
  }

  void _handleZoomOut() {
    setState(() {
      if (_zoomFactor > 0.0) {
        _zoomFactor -= 0.1;
        if (_zoomFactor < 0.0) _zoomFactor = 0.0;
      }
    });
    controller.setZoomScale(_zoomFactor);
  }

  void _showErrorDialog(String message) {
    if (_isProcessing) return;
    _isProcessing = true;

    // Delay 300ms trước khi hiển thị dialog
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return QrErrorDialog(
            message: message,
            onRetry: () {
              if (mounted) {
                setState(() {
                  _isProcessing = false;
                });
                Navigator.of(dialogContext).pop();
              }
            },
          );
        },
      ).then((_) {
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
        }
      });
    });
  }

  void _showQrResultDialog(String qrData) {
    if (_isProcessing) return;
    _isProcessing = true;

    // Delay 300ms trước khi hiển thị dialog
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      final examData = parseExamQrData(qrData);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return QrResultDialog(
            examData: examData,
            parentContext: context,
            onCancel: () {
              if (mounted) {
                setState(() {
                  _isProcessing = false;
                });
              }
            },
          );
        },
      ).then((_) {
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final scanWindow = Rect.fromCenter(
      center: MediaQuery.of(context).size.center(const Offset(0, -95)),
      width: 350,
      height: 350,
    );

    return Scaffold(
      appBar: AppTopBar(
        title: AppLocalizations.of(context).homeQrScanTitle,
        showBack: true,
      ),
      body: Stack(
        children: [
          // Camera scanner
          MobileScanner(
            controller: controller,
            scanWindow: scanWindow,
            onDetect: (BarcodeCapture capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && !_isProcessing) {
                final String? code = barcodes.first.rawValue;
                if (code != null && code.isNotEmpty) {
                  debugPrint('[QR] Quét được: $code');
                  if (validateExamQrFormat(code)) {
                    _showQrResultDialog(code);
                  } else {
                    _showErrorDialog(
                      AppLocalizations.of(context).homeQrWrongFormatMessage,
                    );
                  }
                }
              }
            },
          ),

          // Overlay với vùng quét
          CustomPaint(
            painter: QrScannerOverlay(scanWindow),
            child: Container(),
          ),

          // Zoom controls tách riêng widget
          ZoomControls(
            zoomFactor: _zoomFactor,
            onZoomChanged: (value) {
              setState(() {
                _zoomFactor = value;
              });
              controller.setZoomScale(value);
            },
            onZoomIn: _handleZoomIn,
            onZoomOut: _handleZoomOut,
          ),
        ],
      ),
    );
  }
}
