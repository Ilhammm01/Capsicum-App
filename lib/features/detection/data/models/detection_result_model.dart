import 'dart:ui';

class DetectionResult {
  final String classId;
  final String className;
  final double confidence;
  final Rect boundingBox;
  const DetectionResult({
    required this.classId,
    required this.className,
    required this.confidence,
    required this.boundingBox,
  });

  /// Luas area bounding box (normalized, 0.0–1.0)
  double get normalizedArea => boundingBox.width * boundingBox.height;

  @override
  String toString() =>
      'DetectionResult($className @ ${(confidence * 100).toStringAsFixed(1)}%)';
}
