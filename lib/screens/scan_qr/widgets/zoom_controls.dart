import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class ZoomControls extends StatelessWidget {
  final double zoomFactor;
  final ValueChanged<double> onZoomChanged;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  const ZoomControls({
    super.key,
    required this.zoomFactor,
    required this.onZoomChanged,
    required this.onZoomIn,
    required this.onZoomOut,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 80,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(50),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Zoom Out Button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onZoomOut,
                  borderRadius: BorderRadius.circular(50),
                  child: Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    child: const HugeIcon(
                      icon: HugeIcons.strokeRoundedMinusSign,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),

              // Zoom Level Display
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Text(
                  '${(1 + zoomFactor).toStringAsFixed(1)}x',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              // Zoom In Button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onZoomIn,
                  borderRadius: BorderRadius.circular(50),
                  child: Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    child: const HugeIcon(
                      icon: HugeIcons.strokeRoundedPlusSign,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
