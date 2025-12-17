import 'package:flutter/material.dart';
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
    detectionSpeed: DetectionSpeed.noDuplicates,
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
      appBar: AppBar(
        title: const Text('Quét mã QR bài thi'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
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
                  if (validateExamQrFormat(code)) {
                    _showQrResultDialog(code);
                  } else {
                    _showErrorDialog(
                      'Mã QR không đúng định dạng bài thi.\nVui lòng quét mã QR hợp lệ.',
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
