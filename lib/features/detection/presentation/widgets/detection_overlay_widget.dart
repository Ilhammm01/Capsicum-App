import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../../data/models/detection_result_model.dart';
import '../../../../app/theme.dart';

class DetectionOverlayWidget extends StatelessWidget {
  final List<DetectionResult> results;
  final Size? previewSize;

  const DetectionOverlayWidget({
    super.key,
    required this.results,
    this.previewSize,
  });

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) return const SizedBox.shrink();

    return CustomPaint(
      painter: _DetectionPainter(
        results: results,
        previewSize: previewSize,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _DetectionPainter extends CustomPainter {
  final List<DetectionResult> results;
  final Size? previewSize;

  _DetectionPainter({required this.results, this.previewSize});

  @override
  void paint(Canvas canvas, Size size) {
    for (final result in results) {
      _drawBoundingBox(canvas, size, result);
      _drawLabel(canvas, size, result);
    }
  }

  void _drawBoundingBox(Canvas canvas, Size size, DetectionResult result) {
    final bbox = result.boundingBox;

    final rect = _mapRect(size, bbox);

    // Border bounding box
    final borderPaint = Paint()
      ..color = AppTheme.bboxColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeJoin = StrokeJoin.round;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(6)),
      borderPaint,
    );

    // Fill semi-transparan
    final fillPaint = Paint()
      ..color = AppTheme.bboxColor.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(6)),
      fillPaint,
    );

    // Corner accent lines
    _drawCornerAccents(canvas, rect, AppTheme.bboxColor);
  }

  void _drawCornerAccents(Canvas canvas, Rect rect, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    const len = 12.0;

    // Top-left
    canvas.drawLine(rect.topLeft, rect.topLeft.translate(len, 0), paint);
    canvas.drawLine(rect.topLeft, rect.topLeft.translate(0, len), paint);
    // Top-right
    canvas.drawLine(rect.topRight, rect.topRight.translate(-len, 0), paint);
    canvas.drawLine(rect.topRight, rect.topRight.translate(0, len), paint);
    // Bottom-left
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft.translate(len, 0), paint);
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft.translate(0, -len), paint);
    // Bottom-right
    canvas.drawLine(
      rect.bottomRight,
      rect.bottomRight.translate(-len, 0),
      paint,
    );
    canvas.drawLine(
      rect.bottomRight,
      rect.bottomRight.translate(0, -len),
      paint,
    );
  }

  Rect _mapRect(Size canvasSize, Rect bbox) {
    if (previewSize == null || previewSize!.isEmpty) return bbox;
    final imageSize = previewSize!;
    final scale = (canvasSize.width / imageSize.width)
        .compareTo(canvasSize.height / imageSize.height) > 0
        ? canvasSize.width / imageSize.width
        : canvasSize.height / imageSize.height;
    final offsetX = (canvasSize.width - imageSize.width * scale) / 2;
    final offsetY = (canvasSize.height - imageSize.height * scale) / 2;
    return Rect.fromLTRB(
      offsetX + bbox.left * scale,
      offsetY + bbox.top * scale,
      offsetX + bbox.right * scale,
      offsetY + bbox.bottom * scale,
    );
  }

  void _drawLabel(Canvas canvas, Size size, DetectionResult result) {
    final rect = _mapRect(size, result.boundingBox);
    final x = rect.left;
    final y = rect.top - 28;

    final label =
        '${result.className}  ${(result.confidence * 100).toStringAsFixed(0)}%';

    final textSpan = TextSpan(
      text: label,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        fontFamily: 'Google Sans',
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: ui.TextDirection.ltr,
    )..layout();

    const hPad = 8.0;
    const vPad = 4.0;

    final bgRect = Rect.fromLTWH(
      x,
      y.clamp(0, size.height - 28),
      textPainter.width + hPad * 2,
      textPainter.height + vPad * 2,
    );

    final bgPaint = Paint()
      ..color = AppTheme.bboxLabelBg
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, const Radius.circular(4)),
      bgPaint,
    );

    textPainter.paint(canvas, Offset(bgRect.left + hPad, bgRect.top + vPad));
  }

  @override
  bool shouldRepaint(covariant _DetectionPainter oldDelegate) {
    return true;
  }
}
