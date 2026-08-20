import 'package:flutter/material.dart';

/// Custom painter cho overlay vùng quét QR
class QrScannerOverlay extends CustomPainter {
  final Rect scanWindow;

  const QrScannerOverlay(this.scanWindow);

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
    overlayPaint.color = Colors.black.withOpacity(0.6);
    overlayPaint.style = PaintingStyle.fill;

    final path = Path.combine(
      PathOperation.difference,
      backgroundPath,
      cutoutPath,
    );

    canvas.drawPath(path, overlayPaint);

    // Viền bo trắng dạng cong mềm
    final borderPaint = Paint();
    borderPaint.color = Colors.white;
    borderPaint.strokeWidth = 4;
    borderPaint.style = PaintingStyle.stroke;
    borderPaint.strokeCap = StrokeCap.round;
    borderPaint.strokeJoin = StrokeJoin.round;

    const radius = 16.0;
    const cornerLength = 28.0;

    final borderPath = Path();

    // Top-left
    borderPath.moveTo(scanWindow.left + cornerLength, scanWindow.top);
    borderPath.lineTo(scanWindow.left + radius, scanWindow.top);
    borderPath.arcToPoint(
      Offset(scanWindow.left, scanWindow.top + radius),
      radius: const Radius.circular(radius),
      clockwise: false,
    );
    borderPath.lineTo(scanWindow.left, scanWindow.top + cornerLength);

    // Bottom-left
    borderPath.moveTo(scanWindow.left, scanWindow.bottom - cornerLength);
    borderPath.lineTo(scanWindow.left, scanWindow.bottom - radius);
    borderPath.arcToPoint(
      Offset(scanWindow.left + radius, scanWindow.bottom),
      radius: const Radius.circular(radius),
      clockwise: false,
    );
    borderPath.lineTo(scanWindow.left + cornerLength, scanWindow.bottom);

    // Bottom-right
    borderPath.moveTo(scanWindow.right - cornerLength, scanWindow.bottom);
    borderPath.lineTo(scanWindow.right - radius, scanWindow.bottom);
    borderPath.arcToPoint(
      Offset(scanWindow.right, scanWindow.bottom - radius),
      radius: const Radius.circular(radius),
      clockwise: false,
    );
    borderPath.lineTo(scanWindow.right, scanWindow.bottom - cornerLength);

    // Top-right
    borderPath.moveTo(scanWindow.right, scanWindow.top + cornerLength);
    borderPath.lineTo(scanWindow.right, scanWindow.top + radius);
    borderPath.arcToPoint(
      Offset(scanWindow.right - radius, scanWindow.top),
      radius: const Radius.circular(radius),
      clockwise: false,
    );
    borderPath.lineTo(scanWindow.right - cornerLength, scanWindow.top);

    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
