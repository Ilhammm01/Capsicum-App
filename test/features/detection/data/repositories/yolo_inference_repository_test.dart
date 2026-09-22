import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:capsicum/features/detection/data/models/detection_result_model.dart';
import 'package:capsicum/features/detection/data/repositories/yolo_inference_repository.dart';

void main() {
  group('calculateSeverityRatio', () {
    test('returns 0 for empty results', () {
      expect(calculateSeverityRatio([], 1280, 720), 0.0);
    });

    test('returns 0 for zero frame area', () {
      final results = <DetectionResult>[
        const DetectionResult(
          classId: 'test',
          className: 'Test',
          confidence: 0.9,
          boundingBox: Rect.fromLTWH(0, 0, 100, 100),
        ),
      ];
      expect(calculateSeverityRatio(results, 0, 0), 0.0);
    });

    test('uses bounding box area for single detection', () {
      // Frame: 100x100 = 10000
      // BBox: 10x10 = 100
      // Expected ratio = 0.01
      final results = <DetectionResult>[
        const DetectionResult(
          classId: 'test',
          className: 'Test',
          confidence: 0.9,
          boundingBox: Rect.fromLTWH(0, 0, 10, 10),
        ),
      ];
      expect(
        calculateSeverityRatio(results, 100, 100),
        closeTo(0.01, 0.001),
      );
    });

    test('clamps ratio to maximum 1.0', () {
      // Frame: 10x10 = 100
      // BBox: 20x20 = 400 (larger than frame)
      // Should clamp to 1.0
      final results = <DetectionResult>[
        const DetectionResult(
          classId: 'test',
          className: 'Test',
          confidence: 0.9,
          boundingBox: Rect.fromLTWH(0, 0, 20, 20),
        ),
      ];
      expect(calculateSeverityRatio(results, 10, 10), 1.0);
    });

    test('accumulates area from multiple detections', () {
      // Frame: 100x100 = 10000
      // Detection 1: 10x10 = 100
      // Detection 2: 20x20 = 400
      // Total = 500, ratio = 0.05
      final results = <DetectionResult>[
        const DetectionResult(
          classId: 'test1',
          className: 'Test1',
          confidence: 0.9,
          boundingBox: Rect.fromLTWH(0, 0, 10, 10),
        ),
        const DetectionResult(
          classId: 'test2',
          className: 'Test2',
          confidence: 0.8,
          boundingBox: Rect.fromLTWH(50, 50, 20, 20),
        ),
      ];
      expect(
        calculateSeverityRatio(results, 100, 100),
        closeTo(0.05, 0.001),
      );
    });
  });
}
