import 'package:flutter/material.dart';

/// Custom painter cho overlay vùng quét QR
class QrScannerOverlay extends CustomPainter {
  final Rect scanWindow;
  final double scale; // Thêm scale cho hiệu ứng giãn ra co lại

  const QrScannerOverlay(this.scanWindow, {this.scale = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    // Vùng tối xung quanh
    final backgroundPath = Path();
    backgroundPath.addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final cutoutPath = Path();
    cutoutPath.addRRect(
      RRect.fromRectAndRadius(scanWindow, const Radius.circular(12)),
    );

    final overlayPaint = Paint();
    overlayPaint.color = Colors.black.withOpacity(0.1);
    overlayPaint.style = PaintingStyle.fill;

    final path = Path.combine(
      PathOperation.difference,
      backgroundPath,
      cutoutPath,
    );

    canvas.drawPath(path, overlayPaint);

    // Viền bo trắng dạng cong mềm với hiệu ứng giãn ra co lại
    final borderPaint = Paint();
    borderPaint.color = Colors.white;
    borderPaint.strokeWidth = 7;
    borderPaint.style = PaintingStyle.stroke;
    borderPaint.strokeCap = StrokeCap.round;
    borderPaint.strokeJoin = StrokeJoin.round;

    // Tính toán vùng quét mới với scale
    final centerX = scanWindow.left + scanWindow.width / 2;
    final centerY = scanWindow.top + scanWindow.height / 2;
    final scaledWidth = scanWindow.width * scale;
    final scaledHeight = scanWindow.height * scale;
    final scaledScanWindow = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: scaledWidth,
      height: scaledHeight,
    );

    const radius = 18.0;
    const cornerLength = 36.0;

    final borderPath = Path();

    // Top-left
    borderPath.moveTo(
      scaledScanWindow.left + cornerLength,
      scaledScanWindow.top,
    );
    borderPath.lineTo(scaledScanWindow.left + radius, scaledScanWindow.top);
    borderPath.arcToPoint(
      Offset(scaledScanWindow.left, scaledScanWindow.top + radius),
      radius: const Radius.circular(radius),
      clockwise: false,
    );
    borderPath.lineTo(
      scaledScanWindow.left,
      scaledScanWindow.top + cornerLength,
    );

    // Bottom-left
    borderPath.moveTo(
      scaledScanWindow.left,
      scaledScanWindow.bottom - cornerLength,
    );
    borderPath.lineTo(scaledScanWindow.left, scaledScanWindow.bottom - radius);
    borderPath.arcToPoint(
      Offset(scaledScanWindow.left + radius, scaledScanWindow.bottom),
      radius: const Radius.circular(radius),
      clockwise: false,
    );
    borderPath.lineTo(
      scaledScanWindow.left + cornerLength,
      scaledScanWindow.bottom,
    );

    // Bottom-right
    borderPath.moveTo(
      scaledScanWindow.right - cornerLength,
      scaledScanWindow.bottom,
    );
    borderPath.lineTo(scaledScanWindow.right - radius, scaledScanWindow.bottom);
    borderPath.arcToPoint(
      Offset(scaledScanWindow.right, scaledScanWindow.bottom - radius),
      radius: const Radius.circular(radius),
      clockwise: false,
    );
    borderPath.lineTo(
      scaledScanWindow.right,
      scaledScanWindow.bottom - cornerLength,
    );

    // Top-right
    borderPath.moveTo(
      scaledScanWindow.right,
      scaledScanWindow.top + cornerLength,
    );
    borderPath.lineTo(scaledScanWindow.right, scaledScanWindow.top + radius);
    borderPath.arcToPoint(
      Offset(scaledScanWindow.right - radius, scaledScanWindow.top),
      radius: const Radius.circular(radius),
      clockwise: false,
    );
    borderPath.lineTo(
      scaledScanWindow.right - cornerLength,
      scaledScanWindow.top,
    );

    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant QrScannerOverlay oldDelegate) =>
      oldDelegate.scale != scale;
}
